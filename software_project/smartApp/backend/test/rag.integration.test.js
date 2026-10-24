// Integration tests for the RAG pipeline: real files, real PostgreSQL, real Ollama.
// Needs: PostgreSQL running (backend/.env), Ollama running with nomic-embed-text pulled,
// and sql/rag.sql applied. Run with: npm run test:integration
//
// Everything is created under a throwaway test subject and deleted afterwards,
// so the real subjects and materials are never touched.
import { test, describe, before, after } from "node:test";
import assert from "node:assert";
import path from "path";
import { fileURLToPath } from "url";
import pool from "../src/db.js";
import {
  extractText,
  chunkText,
  indexMaterial,
  embed,
  embedPending,
  retrieve,
  cosine,
} from "../src/rag.js";

const FIXTURES = path.join(path.dirname(fileURLToPath(import.meta.url)), "fixtures");
const PDF = "application/pdf";
const DOCX = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
const MIN_SCORE = Number(process.env.RAG_MIN_SCORE || 0.65);
const EMBED_DIM = 768; // nomic-embed-text

const fixture = (name) => path.join(FIXTURES, name);

// ---------- extractText (files only) ----------
describe("extractText", () => {
  test("PDF → returns the text written in it", async () => {
    const text = await extractText(fixture("pythagoras.pdf"), PDF);
    assert.ok(text.includes("The Pythagorean theorem describes right-angled triangles."));
    assert.ok(text.includes("a^2 + b^2 = c^2"));
  });

  test("DOCX → returns the text written in it", async () => {
    const text = await extractText(fixture("photosynthesis.docx"), DOCX);
    assert.ok(text.includes("Photosynthesis is how green plants make food from sunlight."));
  });

  test("PDF with no text (like a scanned book) → no chunks", async () => {
    const text = await extractText(fixture("no-text.pdf"), PDF);
    assert.deepStrictEqual(chunkText(text), []);
  });

  test("unsupported type (image) → null", async () => {
    assert.strictEqual(await extractText(fixture("pythagoras.pdf"), "image/png"), null);
  });
});

// ---------- embed (Ollama only) ----------
describe("embed", () => {
  test("returns one 768-number vector per text", async () => {
    const vectors = await embed(["first text", "second text"]);
    assert.strictEqual(vectors.length, 2);
    vectors.forEach((v) => {
      assert.strictEqual(v.length, EMBED_DIM);
      assert.ok(v.every((x) => typeof x === "number" && Number.isFinite(x)));
    });
  });

  test("query and document modes both work and give different vectors", async () => {
    const [doc] = await embed(["Pythagorean theorem"], "document");
    const [query] = await embed(["Pythagorean theorem"], "query");
    assert.strictEqual(query.length, EMBED_DIM);
    assert.notDeepStrictEqual(doc, query); // different task prefix
  });

  test("a related question is closer than an unrelated one", async () => {
    const [q] = await embed(["How do I find the hypotenuse of a triangle?"], "query");
    const [maths, biology] = await embed([
      "The square of the hypotenuse equals the sum of the squares of the other two sides.",
      "Plants take in carbon dioxide and water and release oxygen.",
    ]);
    assert.ok(cosine(q, maths) > cosine(q, biology));
  });

  test("Ollama not reachable → throws an error", async () => {
    // Load a second copy of rag.js that points at a port where nothing listens.
    const realUrl = process.env.OLLAMA_URL;
    process.env.OLLAMA_URL = "http://127.0.0.1:1";
    const offline = await import("../src/rag.js?ollama-down");
    process.env.OLLAMA_URL = realUrl;
    await assert.rejects(() => offline.embed(["hello"]));
  });
});

// ---------- indexMaterial + embedPending + retrieve (PostgreSQL + Ollama) ----------
describe("indexing and retrieval with the database", () => {
  const subjectName = `RAG Test Subject ${Date.now()}`;
  let subjectId;
  let materialId;
  let emptyMaterialId;

  async function addMaterial(title, fileName, fileType) {
    const { rows } = await pool.query(
      `INSERT INTO learning_materials (subject_id, title, file_url, file_name, file_type)
       VALUES ($1, $2, $3, $4, $5) RETURNING id`,
      [subjectId, title, `/test/fixtures/${fileName}`, fileName, fileType]
    );
    return rows[0].id;
  }

  const chunksOf = async (id) =>
    (
      await pool.query(
        "SELECT chunk_index, content, embedding FROM material_chunks WHERE material_id = $1 ORDER BY chunk_index",
        [id]
      )
    ).rows;

  before(async () => {
    const { rows } = await pool.query("INSERT INTO subjects (name) VALUES ($1) RETURNING id", [
      subjectName,
    ]);
    subjectId = rows[0].id;
    materialId = await addMaterial("Pythagoras notes", "pythagoras.pdf", PDF);
    emptyMaterialId = await addMaterial("Scanned book", "no-text.pdf", PDF);
  });

  after(async () => {
    // material_chunks are removed by ON DELETE CASCADE
    await pool.query("DELETE FROM learning_materials WHERE subject_id = $1", [subjectId]);
    await pool.query("DELETE FROM subjects WHERE id = $1", [subjectId]);
    await pool.end();
  });

  test("indexMaterial stores one row per chunk, in order, not embedded yet", async () => {
    const filePath = fixture("pythagoras.pdf");
    const expected = chunkText(await extractText(filePath, PDF));

    const count = await indexMaterial({ materialId, subjectId, filePath, mimeType: PDF });

    assert.strictEqual(count, expected.length);
    const rows = await chunksOf(materialId);
    assert.deepStrictEqual(rows.map((r) => r.chunk_index), expected.map((_, i) => i));
    assert.deepStrictEqual(rows.map((r) => r.content), expected);
    assert.ok(rows.every((r) => r.embedding === null));
  });

  test("indexing the same material again replaces its chunks (no duplicates)", async () => {
    const first = await chunksOf(materialId);
    await indexMaterial({ materialId, subjectId, filePath: fixture("pythagoras.pdf"), mimeType: PDF });
    const second = await chunksOf(materialId);
    assert.strictEqual(second.length, first.length);
  });

  test("a material with no text stores 0 chunks", async () => {
    const count = await indexMaterial({
      materialId: emptyMaterialId,
      subjectId,
      filePath: fixture("no-text.pdf"),
      mimeType: PDF,
    });
    assert.strictEqual(count, 0);
    assert.strictEqual((await chunksOf(emptyMaterialId)).length, 0);
  });

  test("embedPending embeds every chunk with a 768-number vector", async () => {
    const total = (await chunksOf(materialId)).length;
    const done = await embedPending(materialId);
    assert.strictEqual(done, total);
    const rows = await chunksOf(materialId);
    assert.ok(rows.every((r) => Array.isArray(r.embedding) && r.embedding.length === EMBED_DIM));
  });

  test("running embedPending again does nothing (already embedded)", async () => {
    assert.strictEqual(await embedPending(materialId), 0);
  });

  test("on-topic question → passages from the material, best first", async () => {
    const found = await retrieve(subjectName, "What does the Pythagorean theorem say about the hypotenuse?");
    assert.ok(found.length > 0, "expected at least one passage");
    assert.ok(found.length <= 4, "at most TOP_K = 4 passages");
    found.forEach((p) => {
      assert.strictEqual(p.materialId, materialId);
      assert.strictEqual(p.title, "Pythagoras notes");
      assert.ok(p.score >= MIN_SCORE, `score ${p.score} below ${MIN_SCORE}`);
      assert.ok(typeof p.content === "string" && p.content.length > 0);
    });
    for (let i = 1; i < found.length; i++) {
      assert.ok(found[i - 1].score >= found[i].score, "not sorted by score");
    }
  });

  test("subject name is matched case-insensitively", async () => {
    const found = await retrieve(subjectName.toUpperCase(), "What is the Pythagorean theorem?");
    assert.ok(found.length > 0);
  });

  test("unrelated question → no passages (below the score threshold)", async () => {
    const found = await retrieve(subjectName, "Who won the football world cup in 2018?");
    assert.deepStrictEqual(found, []);
  });

  test("subject with no materials → no passages", async () => {
    const found = await retrieve(`No Such Subject ${Date.now()}`, "What is the Pythagorean theorem?");
    assert.deepStrictEqual(found, []);
  });
});
