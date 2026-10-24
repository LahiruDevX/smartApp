import { test, describe } from "node:test";
import assert from "node:assert";
import { chunkText, cosine } from "../src/rag.js";
import { buildSystemPrompt, redirectReply } from "../src/routes/aiTeacher.js";

// ---------- chunkText ----------
describe("chunkText", () => {
  test("empty text returns no chunks", () => {
    assert.deepStrictEqual(chunkText(""), []);
  });

  test("short text returns exactly one chunk", () => {
    const chunks = chunkText("Pythagoras: a² + b² = c².");
    assert.strictEqual(chunks.length, 1);
  });

  test("long text is split into chunks of at most 800 chars", () => {
    const chunks = chunkText("word ".repeat(1000));
    assert.ok(chunks.length > 1);
    chunks.forEach(c => assert.ok(c.length <= 800, `chunk too long: ${c.length}`));
  });

  test("chunks do not cut words in half", () => {
    const words = Array.from({ length: 600 }, (_, i) => `word${i}`);
    const valid = new Set(words);
    const chunks = chunkText(words.join(" "));
    for (const c of chunks) {
      for (const w of c.trim().split(/\s+/)) {
        assert.ok(valid.has(w), `broken word found: "${w}"`);
      }
    }
  });

  test("neighbouring chunks overlap", () => {
    const words = Array.from({ length: 600 }, (_, i) => `word${i}`);
    const chunks = chunkText(words.join(" "));
    for (let i = 0; i < chunks.length - 1; i++) {
      const firstWordOfNext = chunks[i + 1].trim().split(/\s+/)[0];
      assert.ok(chunks[i].includes(firstWordOfNext),
        `no overlap between chunk ${i} and ${i + 1}`);
    }
  });
});

// ---------- cosine ----------
describe("cosine", () => {
  test("identical vectors → 1", () => {
    assert.ok(Math.abs(cosine([1, 2, 3], [1, 2, 3]) - 1) < 1e-9);
  });
  test("opposite vectors → -1", () => {
    assert.ok(Math.abs(cosine([1, 2, 3], [-1, -2, -3]) + 1) < 1e-9);
  });
  test("perpendicular vectors → 0", () => {
    assert.ok(Math.abs(cosine([1, 0], [0, 1])) < 1e-9);
  });
  test("vector length does not matter, only direction", () => {
    assert.ok(Math.abs(cosine([1, 2, 3], [10, 20, 30]) - 1) < 1e-9);
  });
});

// ---------- buildSystemPrompt ----------
// Fixed teacher objects so the tests don't depend on teachers.json.
const mathsTeacher = { subject: "Mathematics", name: "Ms. Silva", style: "patient, step by step" };
const generalTeacher = { subject: "General", name: "the AI teacher", style: "clear and friendly" };
const passages = [
  { content: "Pythagoras: a² + b² = c².", score: 0.75, materialId: 3, title: "Basic Mathematics" },
  { content: "The area of a circle is πr².", score: 0.7, materialId: 3, title: "Basic Mathematics" },
];

describe("buildSystemPrompt", () => {
  test("names the teacher and the subject", () => {
    const p = buildSystemPrompt(mathsTeacher, []);
    assert.ok(p.includes("You are Ms. Silva, a Mathematics teacher"));
    assert.ok(p.includes("You teach Mathematics."));
  });

  test("includes the teaching style", () => {
    const p = buildSystemPrompt(mathsTeacher, []);
    assert.ok(p.includes("Teaching style: patient, step by step."));
  });

  test("with passages → adds a numbered Course notes block", () => {
    const p = buildSystemPrompt(mathsTeacher, passages);
    assert.ok(p.includes("Course notes:"));
    assert.ok(p.includes("[1] Pythagoras: a² + b² = c²."));
    assert.ok(p.includes("[2] The area of a circle is πr²."));
    assert.ok(p.includes("Use them when they answer the question"));
  });

  test("without passages → no notes block and no notes rule", () => {
    const p = buildSystemPrompt(mathsTeacher, []);
    assert.ok(!p.includes("Course notes"));
    assert.ok(!p.includes("Use them when they answer the question"));
  });

  test("rules are numbered 1, 2, 3 ... in order", () => {
    const p = buildSystemPrompt(mathsTeacher, passages);
    const numbers = p.split("\n")
      .map(line => line.match(/^(\d+)\. /))
      .filter(Boolean)
      .map(m => Number(m[1]));
    assert.deepStrictEqual(numbers, [1, 2, 3, 4, 5]);
  });

  test("General teacher can help with any subject", () => {
    const p = buildSystemPrompt(generalTeacher, []);
    assert.ok(p.includes("a general teacher"));
    assert.ok(p.includes("You can help with any school subject."));
    assert.ok(!p.includes("You teach General"));
  });

  test("room and schedule are added only when given", () => {
    const without = buildSystemPrompt(mathsTeacher, []);
    assert.ok(!without.includes("Room:"));
    assert.ok(!without.includes("Schedule:"));

    const schedule = { day: "Monday", time: "09:00" };
    const withBoth = buildSystemPrompt(mathsTeacher, [], { roomId: "R101", schedule });
    assert.ok(withBoth.includes("Room: R101"));
    assert.ok(withBoth.includes(`Schedule: ${JSON.stringify(schedule)}`));
  });

  test("has no empty lines (unused parts are dropped)", () => {
    const p = buildSystemPrompt(mathsTeacher, []);
    assert.ok(!p.split("\n").some(line => line.trim() === ""));
  });
});

// ---------- redirectReply ----------
describe("redirectReply", () => {
  test("points the student to the other subject's teacher", () => {
    const r = redirectReply(mathsTeacher, "History");
    assert.ok(r.includes("it belongs to History"));
    assert.ok(r.includes("ask the History teacher"));
  });

  test("offers help with the teacher's own subject", () => {
    const r = redirectReply(mathsTeacher, "History");
    assert.ok(r.includes("anything about Mathematics"));
  });
});