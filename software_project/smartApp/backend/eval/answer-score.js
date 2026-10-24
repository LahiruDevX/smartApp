// Answer quality evaluation (step 2 of 2: score).
// Reads the rating sheet you filled in, joins it with the hidden A/B key from
// the matching .json, and reports human scores for RAG vs no-RAG.
//
// Run: npm run eval:answers:score -- eval/results/answers-<time>-sheet.csv
import fs from "fs";
import path from "path";

const sheetPath = process.argv[2];
if (!sheetPath || !fs.existsSync(sheetPath)) {
  console.error("Usage: npm run eval:answers:score -- eval/results/answers-<time>-sheet.csv");
  process.exit(1);
}
const keyPath = sheetPath.replace(/-sheet\.csv$/, ".json");
if (!fs.existsSync(keyPath)) {
  console.error(`Key file not found: ${keyPath} (keep the sheet's original file name)`);
  process.exit(1);
}

// Small CSV parser: quoted fields, "" escapes, newlines inside quotes, and the
// ; separator some Excel locales use.
function parseCsv(text) {
  text = text.replace(/^﻿/, "");
  const sep = text.slice(0, text.indexOf("\n")).includes(";") && !text.slice(0, text.indexOf("\n")).includes(",") ? ";" : ",";
  const out = [];
  let row = [], field = "", quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') quoted = false;
      else field += c;
    } else if (c === '"') quoted = true;
    else if (c === sep) { row.push(field); field = ""; }
    else if (c === "\n" || c === "\r") {
      if (c === "\r" && text[i + 1] === "\n") i++;
      row.push(field); out.push(row); row = []; field = "";
    } else field += c;
  }
  if (field || row.length) { row.push(field); out.push(row); }
  const [header, ...body] = out.filter((r) => r.some((f) => f.trim()));
  return body.map((r) => Object.fromEntries(header.map((h, i) => [h.trim(), (r[i] ?? "").trim()])));
}

const CRITERIA = ["correct", "relevant", "agrees_with_notes"];
const key = Object.fromEntries(JSON.parse(fs.readFileSync(keyPath, "utf8")).rows.map((r) => [r.rowId, r]));
const ratings = parseCsv(fs.readFileSync(sheetPath, "utf8"));

const rows = [];
const problems = [];
for (const r of ratings) {
  const k = key[r.id];
  if (!k) { problems.push(`${r.id}: not in the key file`); continue; }
  const scores = {};
  for (const c of CRITERIA) {
    if (r[c] === "") { scores[c] = null; continue; }
    const n = Number(r[c]);
    if (![1, 2, 3].includes(n)) problems.push(`${r.id}: ${c} = "${r[c]}" (must be 1, 2 or 3)`);
    scores[c] = [1, 2, 3].includes(n) ? n : null;
  }
  if (scores.correct === null || scores.relevant === null) problems.push(`${r.id}: correct/relevant not scored`);
  rows.push({ ...k, ...scores, comment: r.comment });
}
if (problems.length) {
  console.warn("Check these rows (they are left out of the averages where empty):");
  problems.forEach((p) => console.warn("  " + p));
}

const avg = (xs) => {
  const v = xs.filter((x) => x !== null && x !== undefined);
  return v.length ? Number((v.reduce((a, b) => a + b, 0) / v.length).toFixed(2)) : "-";
};

// ---------- 1. averages per variant ----------
const answered = rows.filter((r) => !r.redirected);
const byVariant = {};
for (const variant of ["rag", "norag"]) {
  const v = answered.filter((r) => r.variant === variant);
  if (v.length) byVariant[variant] = { answers: v.length, ...Object.fromEntries(CRITERIA.map((c) => [c, avg(v.map((r) => r[c]))])) };
}
console.log("\nHUMAN SCORES, 1-3 (answered questions):");
console.table(byVariant);

// ---------- 2. per question type (real system = rag) ----------
const byType = {};
for (const type of ["covered", "not_covered", "wrong_subject", "off_topic"]) {
  const v = rows.filter((r) => r.type === type && r.variant === "rag");
  if (v.length) byType[type] = { answers: v.length, ...Object.fromEntries(CRITERIA.map((c) => [c, avg(v.map((r) => r[c]))])) };
}
console.log("REAL SYSTEM BY QUESTION TYPE:");
console.table(byType);

// ---------- 3. paired: same question, RAG vs no-RAG ----------
const pairs = Object.values(Object.groupBy(answered, (r) => r.qid)).filter((g) => g.length === 2);
const paired = {};
for (const c of CRITERIA) {
  let better = 0, same = 0, worse = 0;
  for (const g of pairs) {
    const rag = g.find((r) => r.variant === "rag")[c];
    const norag = g.find((r) => r.variant === "norag")[c];
    if (rag === null || norag === null) continue;
    if (rag > norag) better++;
    else if (rag < norag) worse++;
    else same++;
  }
  paired[c] = { "RAG better": better, same, "RAG worse": worse };
}
console.log(`PAIRED (${pairs.length} questions answered both ways):`);
console.table(paired);

// ---------- 4. each question side by side ----------
console.log("PER QUESTION (scores as correct/relevant/agrees):");
const s = (r) => (r ? CRITERIA.map((c) => r[c] ?? "-").join("/") : "");
console.table(
  Object.values(Object.groupBy(rows, (r) => r.qid)).map((g) => ({
    id: g[0].qid,
    type: g[0].type,
    question: g[0].question.slice(0, 45),
    rag: s(g.find((r) => r.variant === "rag")),
    norag: s(g.find((r) => r.variant === "norag")),
  }))
);

const outPath = sheetPath.replace(/-sheet\.csv$/, "-scores.json");
fs.writeFileSync(outPath, JSON.stringify({ date: new Date().toISOString(), byVariant, byType, paired, rows }, null, 2));
console.log(`Saved: ${outPath}`);
