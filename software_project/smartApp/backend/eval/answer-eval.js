// Answer quality evaluation for the AI teacher (step 1 of 2: generate).
// Asks every question in answer-golden.json through the same steps as
// POST /api/ai/teacher, once WITH the course notes (RAG) and once WITHOUT,
// then runs automatic checks and writes a blind rating sheet for a human.
//
// Needs: PostgreSQL + Ollama running, materials embedded. The server itself is not needed.
// Run:   npm run eval:answers            (takes ~10 min: each answer is ~15-20 s)
// Then:  fill in the rating sheet, and run npm run eval:answers:score -- <sheet.csv>
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import pool from "../src/db.js";
import { retrieve } from "../src/rag.js";
import {
  teacherFor,
  loadRoster,
  classifySubject,
  redirectReply,
  buildSystemPrompt,
  askModel,
} from "../src/routes/aiTeacher.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const golden = JSON.parse(fs.readFileSync(path.join(HERE, "answer-golden.json"), "utf8")).questions;
// Same temperature as the real endpoint; a fixed seed so a re-run gives the same answers.
const GEN_OPTIONS = { temperature: 0.4, seed: 42 };
const MAX_WORDS = 120; // from the prompt rules

const pct = (x) => (x * 100).toFixed(1) + "%";
const avg = (xs) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null);
const fmt = (x) => (x === null ? "-" : pct(x));
const r2 = (x) => Number(x.toFixed(2));

// ---------- automatic checks ----------
const STOP = new Set(
  "the and that this with from have were they their there which what when where your about into also more than then them these those will would could should been being does done just like very such only some many most each other over under after before because while using used make made can its it's for are was not but you all any how why who".split(" ")
);
const contentWords = (s) =>
  s.toLowerCase().match(/[a-z0-9]+/g)?.filter((w) => w.length > 3 && !STOP.has(w)) ?? [];

// Share of the answer's content words that also appear in the notes:
// a rough, automatic sign of how much the answer drew on the notes.
function grounding(answer, passages) {
  if (!passages.length) return null;
  const notes = new Set(contentWords(passages.map((p) => p.content).join(" ")));
  const words = contentWords(answer);
  return words.length ? words.filter((w) => notes.has(w)).length / words.length : 0;
}

function keyPointScore(answer, keyPoints) {
  if (!keyPoints?.length) return null;
  const a = answer.toLowerCase();
  return keyPoints.filter((group) => group.some((p) => a.includes(p.toLowerCase()))).length / keyPoints.length;
}

function ruleChecks(answer, t) {
  const words = answer.split(/\s+/).filter(Boolean).length;
  const names = [t.name, t.alt?.name].filter(Boolean).map((n) => n.toLowerCase());
  return {
    words,
    shortEnough: words <= MAX_WORDS,
    noMarkdown: !/[*#]|^\s*[-•]\s|^\s*\d+\.\s/m.test(answer),
    noSelfIntro: !names.some((n) => answer.toLowerCase().includes(n)) && !/\bmy name is\b/i.test(answer),
    noAITalk: !/\b(as an ai|language model|avatar|chatbot|i am a program|i'm a program)\b/i.test(answer),
    noNotesTalk: !/\b(notes|course materials?|class materials?|the text provided|provided text)\b/i.test(answer),
  };
}
const RULES = ["shortEnough", "noMarkdown", "noSelfIntro", "noAITalk", "noNotesTalk"];

// ---------- generate ----------
const roster = Object.keys(loadRoster());
const rows = []; // one per generated answer
console.log(`Generating answers for ${golden.length} questions (this takes a while)...\n`);

for (const [i, q] of golden.entries()) {
  const qid = `Q${String(i + 1).padStart(2, "0")}`;
  const t = teacherFor(q.subject);
  const isGeneral = t.subject.toLowerCase() === "general";

  // the same two best-effort steps the endpoint runs side by side
  const [topic, found] = await Promise.all([
    isGeneral ? null : classifySubject(q.question, roster).catch(() => null),
    retrieve(t.subject, q.question).catch(() => []),
  ]);
  const redirected = Boolean(topic && topic !== "General" && topic.toLowerCase() !== t.subject.toLowerCase());

  const variants = redirected ? ["rag"] : found.length ? ["rag", "norag"] : ["rag"];
  for (const variant of variants) {
    const passages = redirected || variant === "norag" ? [] : found;
    const started = Date.now();
    const answer = redirected
      ? redirectReply(t, topic)
      : await askModel(buildSystemPrompt(t, passages), q.question, undefined, GEN_OPTIONS);
    const ms = Date.now() - started;

    rows.push({
      qid,
      subject: q.subject,
      type: q.type,
      question: q.question,
      variant, // rag = the real system; norag = same model without notes
      classifiedAs: topic,
      redirected,
      redirectCorrect: q.expectRedirect ? redirected && topic === q.expectRedirect : null,
      sources: [...new Set(passages.map((p) => p.title))],
      notes: found.map((p) => p.content), // shown to the rater for both variants
      answer,
      ms,
      keyPoints: keyPointScore(answer, q.keyPoints),
      grounding: grounding(answer, found),
      ...ruleChecks(answer, t),
    });
    console.log(`${qid} ${variant.padEnd(5)} ${(ms / 1000).toFixed(1)}s  ${q.question}`);
  }
}

// ---------- automatic results ----------
console.log("\nPER ANSWER (automatic checks):");
console.table(
  rows.map((r) => ({
    id: r.qid,
    type: r.type,
    variant: r.variant,
    redirected: r.redirected ? r.classifiedAs : "",
    words: r.words,
    "key points": r.keyPoints === null ? "-" : pct(r.keyPoints),
    grounding: r.grounding === null ? "-" : pct(r.grounding),
    "rules ok": RULES.every((k) => r[k]) ? "yes" : RULES.filter((k) => !r[k]).join(","),
    sec: r2(r.ms / 1000),
  }))
);

const answered = rows.filter((r) => !r.redirected);
const summary = {};
for (const variant of ["rag", "norag"]) {
  const v = answered.filter((r) => r.variant === variant);
  if (!v.length) continue;
  summary[variant] = {
    answers: v.length,
    "key points": fmt(avg(v.filter((r) => r.keyPoints !== null).map((r) => r.keyPoints))),
    grounding: fmt(avg(v.filter((r) => r.grounding !== null).map((r) => r.grounding))),
    ...Object.fromEntries(RULES.map((k) => [k, fmt(avg(v.map((r) => +r[k])))])),
    "avg words": r2(avg(v.map((r) => r.words))),
    "avg sec": r2(avg(v.map((r) => r.ms)) / 1000),
  };
}
console.log("RAG vs NO-RAG (answered questions; key points / grounding = higher is better):");
console.table(summary);

// Paired: only questions that got both a RAG and a no-RAG answer
const pairs = Object.values(Object.groupBy(answered, (r) => r.qid)).filter((g) => g.length === 2);
const paired = (field) => {
  let better = 0, same = 0, worse = 0;
  for (const g of pairs) {
    const rag = g.find((r) => r.variant === "rag")[field];
    const norag = g.find((r) => r.variant === "norag")[field];
    if (rag === null || norag === null) continue;
    if (rag > norag) better++;
    else if (rag < norag) worse++;
    else same++;
  }
  return { "RAG better": better, same, "RAG worse": worse };
};
console.log(`PAIRED (${pairs.length} questions answered both ways):`);
console.table({ "key points": paired("keyPoints"), grounding: paired("grounding") });

const real = rows.filter((r) => r.variant === "rag"); // what students actually get
const behaviour = {
  "covered → got sources": fmt(avg(real.filter((r) => r.type === "covered").map((r) => +(r.sources.length > 0)))),
  "not covered → no sources": fmt(avg(real.filter((r) => r.type === "not_covered").map((r) => +(r.sources.length === 0)))),
  "wrong subject → redirected to right teacher": fmt(avg(real.filter((r) => r.type === "wrong_subject").map((r) => +r.redirectCorrect))),
  "own-subject question wrongly redirected": fmt(avg(real.filter((r) => ["covered", "not_covered"].includes(r.type)).map((r) => +r.redirected))),
  "off topic → redirected": fmt(avg(real.filter((r) => r.type === "off_topic").map((r) => +r.redirected))),
  "redirect avg sec": r2((avg(real.filter((r) => r.redirected).map((r) => r.ms)) ?? 0) / 1000),
};
console.log("SYSTEM BEHAVIOUR (real RAG answers):");
console.table(behaviour);

// ---------- blind rating sheet ----------
// RAG and no-RAG answers of a question are shuffled into A / B so the rater
// cannot tell which is which. The key is kept in the .json file.
const sheet = [];
for (const g of Object.values(Object.groupBy(rows, (r) => r.qid))) {
  const order = g.length === 2 && Math.random() < 0.5 ? [g[1], g[0]] : g;
  order.forEach((r, i) => {
    r.label = "AB"[i];
    r.rowId = `${r.qid}-${r.label}`;
    sheet.push(r);
  });
}
const outDir = path.join(HERE, "results");
fs.mkdirSync(outDir, { recursive: true });
const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
const cell = (v) => `"${String(v ?? "").replace(/"/g, '""')}"`;
const header = ["id", "subject", "question", "answer", "course_notes", "correct", "relevant", "agrees_with_notes", "comment"];
const csv = [
  header.join(","),
  ...sheet.map((r) =>
    [r.rowId, r.subject, r.question, r.answer, r.notes.map((n, i) => `[${i + 1}] ${n}`).join("\n\n"), "", "", "", ""]
      .map(cell)
      .join(",")
  ),
].join("\r\n");
const sheetPath = path.join(outDir, `answers-${stamp}-sheet.csv`);
fs.writeFileSync(sheetPath, "﻿" + csv); // BOM so Excel opens it as UTF-8
fs.writeFileSync(
  path.join(outDir, `answers-${stamp}.json`),
  JSON.stringify({ date: new Date().toISOString(), options: GEN_OPTIONS, summary, behaviour, rows }, null, 2)
);

console.log(`
Saved: eval/results/answers-${stamp}.json  (all answers + automatic checks + the A/B key)
       eval/results/answers-${stamp}-sheet.csv  (blind rating sheet)

NEXT: open the sheet in Excel and score every row 1-3 (do NOT look at the .json first):
  correct           3 = fully correct   2 = partly correct / small error   1 = wrong
  relevant          3 = answers the question   2 = partly / drifts   1 = does not answer it
  agrees_with_notes 3 = matches the notes   2 = partly   1 = contradicts them   (leave empty if course_notes is empty)
  A redirect ("please ask the X teacher") is correct if X is the right subject.
Save as CSV (keep the file name), then run:
  npm run eval:answers:score -- eval/results/answers-${stamp}-sheet.csv
`);

await pool.end();
