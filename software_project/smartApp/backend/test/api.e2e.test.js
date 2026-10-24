// API / end-to-end tests for the AI teacher + RAG, run against the REAL running server.
// Needs: PostgreSQL + Ollama running, the backend started (npm run dev),
// and the seed accounts (npm run seed). Run with: npm run test:e2e
//
// Test data is kept apart from real data: two fresh student accounts are
// registered for the chat tests, and the uploaded test material is deleted
// again. Everything is cleaned up in after(), even when a test fails.
import { test, describe, before, after } from "node:test";
import assert from "node:assert";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const BASE = process.env.API_URL || "http://localhost:4000";
const FIXTURE = path.join(path.dirname(fileURLToPath(import.meta.url)), "fixtures", "pythagoras.pdf");
const AI = { timeout: 120_000 }; // an AI answer takes ~15-20 s on this PC
const STAMP = Date.now();

async function api(method, url, { token, body, form } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body) headers["Content-Type"] = "application/json";
  const started = Date.now();
  const r = await fetch(BASE + url, { method, headers, body: form ?? (body && JSON.stringify(body)) });
  const text = await r.text();
  let json = null;
  try { json = JSON.parse(text); } catch { /* not JSON */ }
  return { status: r.status, body: json, text, ms: Date.now() - started };
}

const login = async (email) => {
  const r = await api("POST", "/api/auth/login", { body: { email, password: "password" } });
  assert.strictEqual(r.status, 200, `login ${email} failed: ${r.text}`);
  return r.body.token;
};
const ask = (token, subject, message) =>
  api("POST", "/api/ai/teacher", { token, body: { subject, message } });

const tokens = {};
const testUsers = []; // { id, token } — deleted in after()
let materialId = null; // uploaded in E1, deleted in E4 (or in after())

before(async () => {
  try {
    await fetch(BASE + "/api/auth/me");
  } catch {
    throw new Error(`Backend not reachable at ${BASE}. Start it with: npm run dev`);
  }
  tokens.teacher = await login("teacher@classroom.com");
  tokens.admin = await login("admin@classroom.com");
  for (const name of ["a", "b"]) {
    const r = await api("POST", "/api/auth/register", {
      body: { email: `e2e-${name}-${STAMP}@test.com`, password: "password", role: "student" },
    });
    assert.strictEqual(r.status, 201, `register failed: ${r.text}`);
    testUsers.push({ id: r.body.user.id, token: r.body.token });
  }
  tokens.student = testUsers[0].token;
  tokens.studentB = testUsers[1].token;
});

after(async () => {
  if (materialId) await api("DELETE", `/api/materials/${materialId}`, { token: tokens.teacher });
  for (const u of testUsers) {
    // chat_messages has no foreign key to users, so clear them first
    for (const s of ["Mathematics", "Computer Science", "General"]) {
      await api("DELETE", `/api/ai/history?subject=${encodeURIComponent(s)}`, { token: u.token });
    }
    await api("DELETE", `/api/auth/users/${u.id}`, { token: tokens.admin });
  }
});

// ---------- A. Authentication and security ----------
describe("A. Authentication and security", () => {
  test("A1: login with correct password → 200 + token", async () => {
    const r = await api("POST", "/api/auth/login", { body: { email: "teacher@classroom.com", password: "password" } });
    assert.strictEqual(r.status, 200);
    assert.ok(typeof r.body.token === "string" && r.body.token.length > 20);
    assert.strictEqual(r.body.user.role, "teacher");
  });

  test("A2: login with wrong password → 401", async () => {
    const r = await api("POST", "/api/auth/login", { body: { email: "teacher@classroom.com", password: "wrong-pass" } });
    assert.strictEqual(r.status, 401);
    assert.strictEqual(r.body.message, "Invalid credentials");
  });

  test("A3: ask the AI teacher with no token → 401", async () => {
    const r = await ask(null, "Mathematics", "hi");
    assert.strictEqual(r.status, 401);
    assert.strictEqual(r.body.message, "Missing authentication token");
  });

  test("A4: ask the AI teacher with a fake token → 401", async () => {
    const r = await ask("abc", "Mathematics", "hi");
    assert.strictEqual(r.status, 401);
    assert.strictEqual(r.body.message, "Invalid or expired token");
  });

  test("A5: student opens the AI overview → 403", async () => {
    const r = await api("GET", "/api/ai/overview", { token: tokens.student });
    assert.strictEqual(r.status, 403);
  });

  test("A6: teacher opens the AI overview → 200 with RAG counts", async () => {
    const r = await api("GET", "/api/ai/overview", { token: tokens.teacher });
    assert.strictEqual(r.status, 200);
    const maths = r.body.subjects.find((s) => s.subject === "Mathematics");
    assert.ok(maths, "Mathematics missing from overview");
    for (const k of ["materials", "chunks", "embedded", "questions"]) {
      assert.ok(Number.isInteger(maths[k]), `${k} is not a number`);
    }
  });

  test("A7: student opens the staff Student Chats list → 403", async () => {
    const r = await api("GET", "/api/ai/students", { token: tokens.student });
    assert.strictEqual(r.status, 403);
  });
});

// ---------- B. Input validation ----------
describe("B. Input validation", () => {
  test("B1: empty message → 400", async () => {
    const r = await ask(tokens.student, "Mathematics", "");
    assert.strictEqual(r.status, 400);
    assert.strictEqual(r.body.error, "message is required");
  });

  test("B2: message of only spaces → 400", async () => {
    const r = await ask(tokens.student, "Mathematics", "     ");
    assert.strictEqual(r.status, 400);
  });

  test("B3: no subject → answered by the General teacher", AI, async () => {
    const r = await api("POST", "/api/ai/teacher", { token: tokens.student, body: { message: "What is 2 + 2?" } });
    assert.strictEqual(r.status, 200, r.text);
    assert.strictEqual(r.body.teacher.subject, "General");
    assert.ok(r.body.reply.length > 0);
  });
});

// ---------- C. RAG answer flow ----------
describe("C. RAG answer flow", () => {
  let c1;

  test("C1: covered question → answer + sources from the notes", AI, async () => {
    c1 = await ask(tokens.student, "Mathematics", "How do you solve a quadratic equation?");
    assert.strictEqual(c1.status, 200, c1.text);
    assert.ok(c1.body.reply.trim().length > 0, "empty reply");
    assert.strictEqual(c1.body.teacher.subject, "Mathematics");
    assert.ok(c1.body.sources.length >= 1, "expected at least one source");
    console.log(`    C1 sources: ${c1.body.sources.map((s) => s.title).join(", ")}  (${c1.ms} ms)`);
  });

  test("C2: question not in the notes → answer, no sources", AI, async () => {
    const r = await ask(tokens.student, "Computer Science", "What is cloud computing?");
    assert.strictEqual(r.status, 200, r.text);
    assert.ok(r.body.reply.trim().length > 0);
    assert.deepStrictEqual(r.body.sources, []);
  });

  test("C3: wrong-subject question → fast redirect to Science, no sources", AI, async () => {
    const r = await ask(tokens.student, "Mathematics", "How does photosynthesis work?");
    assert.strictEqual(r.status, 200, r.text);
    assert.ok(r.body.reply.includes("Science"), `reply does not name Science: ${r.body.reply}`);
    assert.deepStrictEqual(r.body.sources, []);
    assert.ok(r.ms < 10_000, `redirect took ${r.ms} ms`);
    console.log(`    C3 redirect took ${r.ms} ms`);
  });

  test("C4: response has the shape the app expects", () => {
    assert.ok(c1, "C1 did not run");
    const b = c1.body;
    assert.strictEqual(typeof b.reply, "string");
    assert.strictEqual(typeof b.teacher.subject, "string");
    assert.strictEqual(typeof b.teacher.name, "string");
    assert.ok(Array.isArray(b.sources));
    b.sources.forEach((s) => {
      assert.ok(Number.isInteger(s.id));
      assert.strictEqual(typeof s.title, "string");
    });
  });
});

// ---------- D. Chat history ----------
describe("D. Chat history", () => {
  test("D1: the C1 question and reply were saved", async () => {
    const r = await api("GET", "/api/ai/history?subject=Mathematics", { token: tokens.student });
    assert.strictEqual(r.status, 200);
    const msgs = r.body.messages;
    assert.ok(msgs.length >= 2);
    const userMsg = msgs.find((m) => m.role === "user" && m.content === "How do you solve a quadratic equation?");
    assert.ok(userMsg, "question not in history");
    assert.ok(msgs.some((m) => m.role === "ai"), "no AI reply in history");
  });

  test("D2: sessions list has a Mathematics row", async () => {
    const r = await api("GET", "/api/ai/sessions", { token: tokens.student });
    assert.strictEqual(r.status, 200);
    const maths = r.body.sessions.find((s) => s.subject === "Mathematics");
    assert.ok(maths, "no Mathematics session");
    assert.ok(maths.count >= 2);
  });

  test("D3: another student cannot see this student's history", async () => {
    const r = await api("GET", "/api/ai/history?subject=Mathematics", { token: tokens.studentB });
    assert.strictEqual(r.status, 200);
    assert.ok(!r.body.messages.some((m) => m.content === "How do you solve a quadratic equation?"));
  });

  test("D4: clearing history empties it", async () => {
    const del = await api("DELETE", "/api/ai/history?subject=Mathematics", { token: tokens.student });
    assert.strictEqual(del.status, 200);
    assert.strictEqual(del.body.message, "Cleared");
    const r = await api("GET", "/api/ai/history?subject=Mathematics", { token: tokens.student });
    assert.deepStrictEqual(r.body.messages, []);
  });
});

// ---------- E. Full pipeline: upload → index → ask → source → delete ----------
describe("E. Full RAG pipeline", () => {
  const title = `E2E Pythagoras notes ${STAMP}`;
  let mathsId;
  let baseline;

  const mathsOverview = async () =>
    (await api("GET", "/api/ai/overview", { token: tokens.teacher })).body.subjects.find(
      (s) => s.subject === "Mathematics"
    );

  const uploadForm = () => {
    const form = new FormData();
    form.append("subject_id", String(mathsId));
    form.append("title", title);
    form.append("file", new Blob([fs.readFileSync(FIXTURE)], { type: "application/pdf" }), "pythagoras.pdf");
    return form;
  };

  test("E1: teacher uploads a PDF → 201 and it is split into chunks", async () => {
    const subjects = await api("GET", "/api/learning/subjects", { token: tokens.teacher });
    mathsId = subjects.body.subjects.find((s) => s.name === "Mathematics").id;
    baseline = await mathsOverview();

    const r = await api("POST", "/api/materials", { token: tokens.teacher, form: uploadForm() });
    assert.strictEqual(r.status, 201, r.text);
    materialId = r.body.material.id;
    assert.strictEqual(r.body.material.title, title);
    assert.ok(r.body.chunks >= 1, "no chunks stored");
  });

  test("E2: the new chunks get embedded in the background", AI, async () => {
    assert.ok(materialId, "E1 did not upload");
    let now;
    for (let i = 0; i < 90; i++) {
      now = await mathsOverview();
      if (now.chunks > baseline.chunks && now.embedded === now.chunks) break;
      await new Promise((res) => setTimeout(res, 1000));
    }
    assert.strictEqual(now.materials, baseline.materials + 1);
    assert.ok(now.chunks > baseline.chunks, "chunk count did not go up");
    assert.strictEqual(now.embedded, now.chunks, "embedding did not finish within 90 s");
  });

  test("E3: asking about it lists the new material as a source", AI, async () => {
    const r = await ask(tokens.student, "Mathematics", "What is the Pythagorean theorem about the hypotenuse?");
    assert.strictEqual(r.status, 200, r.text);
    assert.ok(
      r.body.sources.some((s) => s.id === materialId && s.title === title),
      `new material not in sources: ${JSON.stringify(r.body.sources)}`
    );
  });

  test("E4: deleting the material removes its chunks", async () => {
    const r = await api("DELETE", `/api/materials/${materialId}`, { token: tokens.teacher });
    assert.strictEqual(r.status, 200);
    materialId = null;
    const now = await mathsOverview();
    assert.strictEqual(now.materials, baseline.materials);
    assert.strictEqual(now.chunks, baseline.chunks);
  });

  test("E5: student tries to upload → 403", async () => {
    const r = await api("POST", "/api/materials", { token: tokens.student, form: uploadForm() });
    assert.strictEqual(r.status, 403);
  });
});
