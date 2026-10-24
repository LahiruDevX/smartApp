// Retrieval quality evaluation for the AI teacher's RAG.
// Asks every question in retrieval-golden.json against the REAL embedded
// materials in the database and reports how well the right passages are found.
//
// Needs: PostgreSQL + Ollama running, materials embedded (npm run rag:index).
// Run:   npm run eval:retrieval
// Output: tables in the console + eval/results/retrieval-<time>.csv / .json
//
// It ranks every chunk itself (same cosine + same TOP_K / MIN_SCORE as
// retrieve() in src/rag.js) so it can also see scores BELOW the threshold,
// which is what the threshold sweep needs.
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import pool from "../src/db.js";
import { embed, cosine, TOP_K, MIN_SCORE } from "../src/rag.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const golden = JSON.parse(fs.readFileSync(path.join(HERE, "retrieval-golden.json"), "utf8")).questions;

const pct = (x) => (x * 100).toFixed(1) + "%";
const avg = (xs) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : 0);
const r3 = (x) => Number(x.toFixed(3));

// ---------- load every embedded chunk once per subject ----------
const chunksBySubject = {};
for (const subject of [...new Set(golden.map((q) => q.subject))]) {
  const { rows } = await pool.query(
    `SELECT c.id, c.chunk_index, c.content, c.embedding
     FROM material_chunks c JOIN subjects s ON s.id = c.subject_id
     WHERE lower(s.name) = lower($1) AND c.embedding IS NOT NULL`,
    [subject]
  );
  chunksBySubject[subject] = rows;
  if (!rows.length) console.warn(`WARNING: "${subject}" has no embedded chunks`);
}

const isRelevant = (content, phrases = []) =>
  phrases.some((p) => content.toLowerCase().includes(p.toLowerCase()));

// ---------- ask every question ----------
const results = [];
for (const q of golden) {
  const chunks = chunksBySubject[q.subject];
  const [qv] = await embed([q.question], "query");
  const ranked = chunks
    .map((c) => ({ ...c, score: cosine(qv, c.embedding), relevant: isRelevant(c.content, q.relevant) }))
    .sort((a, b) => b.score - a.score);

  // what retrieve() would actually hand to the teacher
  const returned = ranked.filter((c) => c.score >= MIN_SCORE).slice(0, TOP_K);
  // the same top TOP_K ignoring the threshold
  const topRaw = ranked.slice(0, TOP_K);

  const firstHit = returned.findIndex((c) => c.relevant); // -1 = none
  const firstHitRaw = topRaw.findIndex((c) => c.relevant);

  results.push({
    ...q,
    relevantInNotes: chunks.filter((c) => isRelevant(c.content, q.relevant)).length,
    topScore: ranked[0]?.score ?? 0,
    returnedCount: returned.length,
    rank: firstHit + 1, // 0 = no relevant passage returned
    hit1: firstHit === 0,
    hitK: firstHit !== -1,
    hitKRaw: firstHitRaw !== -1,
    rr: firstHit === -1 ? 0 : 1 / (firstHit + 1),
    precision: returned.length ? returned.filter((c) => c.relevant).length / returned.length : 0,
    topChunk: ranked[0] ? `#${ranked[0].chunk_index}: ${ranked[0].content.slice(0, 90).replace(/\s+/g, " ")}` : "",
  });
}

// ---------- check the golden set itself ----------
for (const r of results) {
  if (r.type === "covered" && r.relevantInNotes === 0)
    console.warn(`WARNING: no chunk contains ${JSON.stringify(r.relevant)} — fix "${r.question}"`);
}

const covered = results.filter((r) => r.type === "covered");
const negatives = results.filter((r) => r.type !== "covered");

// ---------- 1. per-question table ----------
console.log(`\nRetrieval evaluation — ${results.length} questions, TOP_K=${TOP_K}, MIN_SCORE=${MIN_SCORE}\n`);
console.log("COVERED questions (answer is in the notes):");
console.table(
  covered.map((r) => ({
    subject: r.subject,
    question: r.question.slice(0, 48),
    top: r3(r.topScore),
    returned: r.returnedCount,
    rank: r.rank || "-",
    "P@k": r3(r.precision),
  }))
);
console.log("NEGATIVE questions (ideal: 0 passages returned):");
console.table(
  negatives.map((r) => ({
    subject: r.subject,
    type: r.type,
    question: r.question.slice(0, 48),
    top: r3(r.topScore),
    returned: r.returnedCount,
    ok: r.returnedCount === 0 ? "yes" : "NO",
  }))
);

// ---------- 2. headline metrics ----------
const metrics = (cov, neg) => ({
  covered: cov.length,
  negatives: neg.length,
  "Hit@1": pct(avg(cov.map((r) => +r.hit1))),
  [`Hit@${TOP_K}`]: pct(avg(cov.map((r) => +r.hitK))),
  [`Hit@${TOP_K} (no threshold)`]: pct(avg(cov.map((r) => +r.hitKRaw))),
  MRR: r3(avg(cov.map((r) => r.rr))),
  [`Precision@${TOP_K}`]: pct(avg(cov.filter((r) => r.returnedCount).map((r) => r.precision))),
  "Covered answered": pct(avg(cov.map((r) => +(r.returnedCount > 0)))),
  "False-positive rate": pct(avg(neg.map((r) => +(r.returnedCount > 0)))),
});
const overall = metrics(covered, negatives);
console.log("OVERALL METRICS:");
console.table(overall);

const perSubject = {};
for (const s of Object.keys(chunksBySubject)) {
  perSubject[s] = metrics(
    covered.filter((r) => r.subject === s),
    negatives.filter((r) => r.subject === s)
  );
}
console.log("PER SUBJECT:");
console.table(perSubject);

// ---------- 3. score distribution (top-1 score per question type) ----------
const dist = {};
for (const type of ["covered", "not_covered", "wrong_subject", "off_topic"]) {
  const s = results.filter((r) => r.type === type).map((r) => r.topScore);
  if (s.length) dist[type] = { n: s.length, min: r3(Math.min(...s)), mean: r3(avg(s)), max: r3(Math.max(...s)) };
}
console.log("TOP-1 SCORE DISTRIBUTION (covered should sit clearly above the others):");
console.table(dist);

// ---------- 4. threshold sweep ----------
// At each threshold: % of covered questions that still get a correct passage,
// and % of negative questions correctly getting nothing.
const sweep = [];
for (let t = 0.5; t <= 0.8001; t += 0.01) {
  const keptHit = avg(covered.map((r) => +(r.topScore >= t && r.hitKRaw)));
  const rejected = avg(negatives.map((r) => +(r.topScore < t)));
  sweep.push({ threshold: r3(t), "covered with hit": keptHit, "negatives rejected": rejected, balanced: (keptHit + rejected) / 2 });
}
const best = sweep.reduce((a, b) => (b.balanced > a.balanced ? b : a));
console.log("THRESHOLD SWEEP (every 0.02):");
console.table(
  sweep
    .filter((_, i) => i % 2 === 0 || sweep[i] === best)
    .map((s) => ({
      threshold: s.threshold + (Math.abs(s.threshold - MIN_SCORE) < 0.005 ? " (current)" : "") + (s === best ? " (best)" : ""),
      "covered with hit": pct(s["covered with hit"]),
      "negatives rejected": pct(s["negatives rejected"]),
      balanced: pct(s.balanced),
    }))
);
console.log(`Best balanced threshold: ${best.threshold} (current: ${MIN_SCORE})`);

// ---------- 5. save for the report ----------
const outDir = path.join(HERE, "results");
fs.mkdirSync(outDir, { recursive: true });
const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
const csvCell = (v) => `"${String(v).replace(/"/g, '""')}"`;
const cols = ["subject", "type", "question", "relevantInNotes", "topScore", "returnedCount", "rank", "hit1", "hitK", "hitKRaw", "rr", "precision", "topChunk"];
fs.writeFileSync(
  path.join(outDir, `retrieval-${stamp}.csv`),
  [cols.join(","), ...results.map((r) => cols.map((c) => csvCell(typeof r[c] === "number" ? r3(r[c]) : r[c])).join(","))].join("\n")
);
fs.writeFileSync(
  path.join(outDir, `retrieval-${stamp}.json`),
  JSON.stringify({ date: new Date().toISOString(), TOP_K, MIN_SCORE, overall, perSubject, scoreDistribution: dist, bestThreshold: best.threshold, sweep }, null, 2)
);
console.log(`\nSaved: eval/results/retrieval-${stamp}.csv and .json`);

await pool.end();
