// Performance test for the AI teacher + RAG.
//   Part 1  component timings  (each step on its own: embed, DB, ranking, classify, LLM)
//   Part 2  API response times (POST /api/ai/teacher per question type + light endpoints)
//   Part 3  concurrent users   (several students asking at the same moment)
//   Part 4  light-endpoint load (many quick requests in parallel)
//   Part 5  indexing speed     (upload pipeline: extract + chunk + store + embed)
//
// Needs: PostgreSQL + Ollama running, the backend running (npm run dev), seed accounts.
// Run:   npm run perf            (about 6-8 minutes)
//        $env:PERF_RUNS=5; npm run perf   (PowerShell) for more repetitions: slower, steadier numbers
// Output: tables in the console + eval/results/performance-<time>.json
//
// A fresh test student is registered for the chat requests and deleted at the
// end; Part 5 uses a throwaway subject that is deleted too.
import fs from "fs";
import os from "os";
import path from "path";
import { fileURLToPath } from "url";
import pool from "../src/db.js";
import { embed, cosine, retrieve, extractText, chunkText, indexMaterial, embedPending } from "../src/rag.js";
import { teacherFor, loadRoster, classifySubject, buildSystemPrompt, askModel } from "../src/routes/aiTeacher.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const BASE = process.env.API_URL || "http://localhost:4000";
const OLLAMA_URL = process.env.OLLAMA_URL || "http://127.0.0.1:11434";
const RUNS = Number(process.env.PERF_RUNS || 3); // repetitions of each slow (LLM) measurement
const FAST_RUNS = 20; // repetitions of each fast measurement
const FIXTURE = path.join(HERE, "..", "test", "fixtures", "pythagoras.pdf");

const QUESTIONS = {
  covered: { subject: "Mathematics", message: "How do you solve a quadratic equation?" },
  not_covered: { subject: "Computer Science", message: "What is cloud computing?" },
  wrong_subject: { subject: "Mathematics", message: "How does photosynthesis work?" },
};

// ---------- helpers ----------
const now = () => performance.now();
async function timeIt(fn) {
  const t = now();
  const value = await fn();
  return { ms: now() - t, value };
}
function stats(ms) {
  const s = [...ms].sort((a, b) => a - b);
  const p = (q) => s[Math.min(s.length - 1, Math.ceil(q * s.length) - 1)];
  const r = (x) => Math.round(x);
  return { n: s.length, min: r(s[0]), mean: r(s.reduce((a, b) => a + b, 0) / s.length), p50: r(p(0.5)), p95: r(p(0.95)), max: r(s.at(-1)) };
}
async function repeat(n, fn) {
  const ms = [];
  for (let i = 0; i < n; i++) ms.push((await timeIt(fn)).ms);
  return stats(ms);
}
async function api(method, url, { token, body } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body) headers["Content-Type"] = "application/json";
  const r = await fetch(BASE + url, { method, headers, body: body && JSON.stringify(body) });
  const json = await r.json().catch(() => null);
  return { status: r.status, body: json };
}
const section = (title) => console.log(`\n${"=".repeat(70)}\n${title}\n${"=".repeat(70)}`);
const results = {};

// ---------- setup ----------
try {
  await fetch(BASE + "/api/auth/me");
} catch {
  console.error(`Backend not reachable at ${BASE}. Start it with: npm run dev`);
  process.exit(1);
}
const login = async (email) =>
  (await api("POST", "/api/auth/login", { body: { email, password: "password" } })).body.token;
const teacherToken = await login("teacher@classroom.com");
const adminToken = await login("admin@classroom.com");
const reg = await api("POST", "/api/auth/register", {
  body: { email: `perf-${Date.now()}@test.com`, password: "password", role: "student" },
});
if (reg.status !== 201) throw new Error("could not register the perf test student");
const student = { id: reg.body.user.id, token: reg.body.token };

// machine + model info for the report
results.machine = {
  cpu: os.cpus()[0]?.model,
  threads: os.cpus().length,
  ramGB: Math.round(os.totalmem() / 2 ** 30),
  os: `${os.type()} ${os.release()}`,
  node: process.version,
  chatModel: process.env.OLLAMA_MODEL || "llama3.2:3b",
  embedModel: process.env.OLLAMA_EMBED_MODEL || "nomic-embed-text",
};
section("MACHINE");
console.table(results.machine);

try {
  // ======================================================================
  section(`PART 1 — COMPONENT TIMINGS (ms)   fast steps x${FAST_RUNS}, LLM steps x${RUNS}`);
  // Warm-up: the first call loads the models into memory (cold start).
  const cold = await timeIt(() => askModel("Reply with one word.", "hello"));
  const coldEmbed = await timeIt(() => embed(["warm up"], "query"));
  console.log(`Warm-up (model load if it was not in memory): chat ${Math.round(cold.ms)} ms, embed ${Math.round(coldEmbed.ms)} ms`);

  const comp = {};
  comp["embed 1 question"] = await repeat(FAST_RUNS, () => embed(["How do you solve a quadratic equation?"], "query"));

  // retrieve() split into its 3 steps, on every subject (bigger subject = more chunks)
  const chunkCounts = {};
  for (const subject of ["Mathematics", "Computer Science", "Science", "History"]) {
    const sql = `SELECT c.content, c.embedding, m.id AS material_id, m.title
                 FROM material_chunks c JOIN learning_materials m ON m.id = c.material_id
                 JOIN subjects s ON s.id = c.subject_id
                 WHERE lower(s.name) = lower($1) AND c.embedding IS NOT NULL`;
    const { rows } = await pool.query(sql, [subject]);
    chunkCounts[subject] = rows.length;
    const [q] = await embed(["test question"], "query");
    comp[`DB load chunks: ${subject} (${rows.length})`] = await repeat(FAST_RUNS, () => pool.query(sql, [subject]));
    comp[`cosine rank: ${subject} (${rows.length})`] = await repeat(FAST_RUNS, async () =>
      rows.map((r) => cosine(q, r.embedding)).sort((a, b) => b - a)
    );
    comp[`retrieve() total: ${subject}`] = await repeat(FAST_RUNS, () => retrieve(subject, "test question"));
  }

  const roster = Object.keys(loadRoster());
  comp["classifySubject (LLM, 1 word)"] = await repeat(RUNS, () => classifySubject("How do you solve a quadratic equation?", roster));

  const t = teacherFor("Mathematics");
  const passages = await retrieve("Mathematics", QUESTIONS.covered.message);
  const genOpts = { temperature: 0.4, seed: 42 };
  comp[`askModel WITH notes (${passages.length} passages)`] = await repeat(RUNS, () =>
    askModel(buildSystemPrompt(t, passages), QUESTIONS.covered.message, undefined, genOpts)
  );
  comp["askModel WITHOUT notes"] = await repeat(RUNS, () =>
    askModel(buildSystemPrompt(t, []), QUESTIONS.covered.message, undefined, genOpts)
  );
  console.table(comp);
  results.coldStart = { chatMs: Math.round(cold.ms), embedMs: Math.round(coldEmbed.ms) };
  results.components = comp;
  results.chunkCounts = chunkCounts;

  // Is Ollama running on the GPU? (size_vram = part of the model in GPU memory)
  const loaded = (await fetch(`${OLLAMA_URL}/api/ps`).then((r) => r.json()).catch(() => ({ models: [] }))).models;
  results.ollamaModels = loaded.map((m) => ({
    model: m.name,
    sizeMB: Math.round(m.size / 2 ** 20),
    gpuPercent: m.size ? Math.round((100 * (m.size_vram || 0)) / m.size) : 0,
  }));
  console.log("Models in memory (gpuPercent 100 = fully on the GPU, 0 = CPU only):");
  console.table(results.ollamaModels);

  // ======================================================================
  section(`PART 2 — API RESPONSE TIMES (ms, full HTTP request)   AI x${RUNS}, others x${FAST_RUNS}`);
  const apiTimes = {};
  for (const [type, q] of Object.entries(QUESTIONS)) {
    apiTimes[`POST /api/ai/teacher — ${type}`] = await repeat(RUNS, async () => {
      const r = await api("POST", "/api/ai/teacher", { token: student.token, body: q });
      if (r.status !== 200) throw new Error(`${type}: HTTP ${r.status}`);
    });
  }
  apiTimes["GET /api/ai/history"] = await repeat(FAST_RUNS, () => api("GET", "/api/ai/history?subject=Mathematics", { token: student.token }));
  apiTimes["GET /api/ai/sessions"] = await repeat(FAST_RUNS, () => api("GET", "/api/ai/sessions", { token: student.token }));
  apiTimes["GET /api/ai/overview (teacher)"] = await repeat(FAST_RUNS, () => api("GET", "/api/ai/overview", { token: teacherToken }));
  apiTimes["POST /api/auth/login"] = await repeat(FAST_RUNS, () => login("teacher@classroom.com"));
  console.table(apiTimes);
  results.api = apiTimes;

  // ======================================================================
  section("PART 3 — CONCURRENT STUDENTS (covered question, all sent at the same moment)");
  const conc = {};
  for (const users of [1, 2, 4]) {
    const started = now();
    const each = await Promise.all(
      Array.from({ length: users }, () =>
        timeIt(() => api("POST", "/api/ai/teacher", { token: student.token, body: QUESTIONS.covered }))
      )
    );
    const wall = now() - started;
    const s = stats(each.map((e) => e.ms));
    conc[`${users} at once`] = {
      ok: each.filter((e) => e.value.status === 200).length + "/" + users,
      fastest: s.min,
      slowest: s.max,
      mean: s.mean,
      "total wall ms": Math.round(wall),
      "answers / min": Number(((users / wall) * 60000).toFixed(1)),
    };
  }
  console.table(conc);
  console.log("If 'slowest' grows ~linearly with users, Ollama is answering one request at a time (queueing).");
  results.concurrency = conc;

  // ======================================================================
  section("PART 4 — LIGHT ENDPOINT LOAD (200 requests, 20 in parallel)");
  async function load(label, total, parallel, fn) {
    const times = [];
    let errors = 0, next = 0;
    const started = now();
    await Promise.all(
      Array.from({ length: parallel }, async () => {
        while (next < total) {
          next++;
          const { ms, value } = await timeIt(fn);
          times.push(ms);
          if (value.status !== 200) errors++;
        }
      })
    );
    const wall = now() - started;
    return { label, ...stats(times), errors, "req/sec": Math.round((total / wall) * 1000) };
  }
  const loadRes = [
    await load("GET /api/ai/history", 200, 20, () => api("GET", "/api/ai/history?subject=Mathematics", { token: student.token })),
    await load("GET /api/ai/overview", 200, 20, () => api("GET", "/api/ai/overview", { token: teacherToken })),
  ];
  console.table(loadRes);
  results.load = loadRes;

  // ======================================================================
  section("PART 5 — INDEXING SPEED (upload pipeline on the test PDF, x3)");
  const subj = await pool.query("INSERT INTO subjects (name) VALUES ($1) RETURNING id", [`Perf Test ${Date.now()}`]);
  const subjectId = subj.rows[0].id;
  try {
    const mat = await pool.query(
      `INSERT INTO learning_materials (subject_id, title, file_url, file_name, file_type)
       VALUES ($1, 'perf', '/perf', 'pythagoras.pdf', 'application/pdf') RETURNING id`,
      [subjectId]
    );
    const materialId = mat.rows[0].id;
    const idx = { extract: [], chunk: [], store: [], embed: [] };
    let chunks = 0;
    for (let i = 0; i < 3; i++) {
      const ex = await timeIt(() => extractText(FIXTURE, "application/pdf"));
      const ch = await timeIt(async () => chunkText(ex.value));
      const st = await timeIt(() => indexMaterial({ materialId, subjectId, filePath: FIXTURE, mimeType: "application/pdf" }));
      const em = await timeIt(() => embedPending(materialId));
      idx.extract.push(ex.ms); idx.chunk.push(ch.ms); idx.store.push(st.ms); idx.embed.push(em.ms);
      chunks = st.value;
    }
    const idxStats = Object.fromEntries(Object.entries(idx).map(([k, v]) => [k, stats(v)]));
    const embedPerChunk = idxStats.embed.mean / chunks;
    console.table(idxStats);
    console.log(`${chunks} chunks per run → embedding ≈ ${Math.round(embedPerChunk)} ms per chunk`);
    const biggest = Math.max(...Object.values(chunkCounts));
    console.log(`Estimate for your largest textbook (${biggest} chunks): ≈ ${Math.round((biggest * embedPerChunk) / 1000)} s to embed`);
    results.indexing = { chunksPerRun: chunks, steps: idxStats, embedMsPerChunk: Math.round(embedPerChunk), largestTextbookChunks: biggest, largestTextbookEstimateSec: Math.round((biggest * embedPerChunk) / 1000) };
  } finally {
    await pool.query("DELETE FROM learning_materials WHERE subject_id = $1", [subjectId]);
    await pool.query("DELETE FROM subjects WHERE id = $1", [subjectId]);
  }
} finally {
  // ---------- cleanup ----------
  for (const s of ["Mathematics", "Computer Science"]) {
    await api("DELETE", `/api/ai/history?subject=${encodeURIComponent(s)}`, { token: student.token });
  }
  await api("DELETE", `/api/auth/users/${student.id}`, { token: adminToken });

  const outDir = path.join(HERE, "results");
  fs.mkdirSync(outDir, { recursive: true });
  const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
  fs.writeFileSync(path.join(outDir, `performance-${stamp}.json`), JSON.stringify({ date: new Date().toISOString(), runs: RUNS, ...results }, null, 2));
  console.log(`\nSaved: eval/results/performance-${stamp}.json`);
  await pool.end();
}
