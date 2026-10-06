// RAG helpers: turn an uploaded learning material into searchable text chunks.
// Step 1 = extract + chunk + store. Step 2 = embed each chunk with Ollama.
import fs from "fs";
import { PDFParse } from "pdf-parse";
import mammoth from "mammoth";
import pool from "./db.js";

const CHUNK_SIZE = 800; // characters per passage
const CHUNK_OVERLAP = 150; // shared characters between neighbouring passages

const OLLAMA_URL = process.env.OLLAMA_URL || "http://127.0.0.1:11434";
const EMBED_MODEL = process.env.OLLAMA_EMBED_MODEL || "nomic-embed-text";
const EMBED_BATCH = 32; // chunks sent to Ollama per request

const DOCX ="application/vnd.openxmlformats-officedocument.wordprocessingml.document";

// Plain text of a PDF or .docx file; null for types we can't read (images, old .doc).
export async function extractText(filePath, mimeType) {
  if (mimeType === "application/pdf") {
    const parser = new PDFParse({ data: fs.readFileSync(filePath) });
    try {
      return (await parser.getText()).text;
    } finally {
      await parser.destroy();
    }
  }
  if (mimeType === DOCX) {
    return (await mammoth.extractRawText({ path: filePath })).value;
  }
  return null;
}

// Split text into ~CHUNK_SIZE passages, ending each at a sentence or word
// boundary where possible, with CHUNK_OVERLAP characters repeated so an idea
// cut at a boundary still appears whole in one of the two passages.
export function chunkText(text) {
  const clean = text
    .replace(/-- \d+ of \d+ --/g, " ") // page markers added by pdf-parse
    .replace(/\s+/g, " ")
    .trim();
  const chunks = [];
  let start = 0;
  while (start < clean.length) {
    let end = Math.min(start + CHUNK_SIZE, clean.length);
    if (end < clean.length) {
      const window = clean.slice(start, end);
      const sentence = window.lastIndexOf(". ");
      const space = window.lastIndexOf(" ");
      if (sentence > CHUNK_SIZE / 2) end = start + sentence + 1;
      else if (space > CHUNK_SIZE / 2) end = start + space;
    }
    const piece = clean.slice(start, end).trim();
    if (piece) chunks.push(piece);
    if (end >= clean.length) break;
    // step back for the overlap, then forward to the next word so a passage
    // never starts mid-word
    let next = Math.max(end - CHUNK_OVERLAP, start + 1);
    const wordStart = clean.indexOf(" ", next);
    if (wordStart !== -1 && wordStart < end) next = wordStart + 1;
    start = next;
  }
  return chunks;
}

// Extract, chunk and store one material. Replaces any chunks it already had.
// Returns the number of chunks stored (0 when the file has no readable text).
export async function indexMaterial({ materialId, subjectId, filePath, mimeType }) {
  const text = await extractText(filePath, mimeType);
  const chunks = text ? chunkText(text) : [];

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query("DELETE FROM material_chunks WHERE material_id = $1", [materialId]);
    for (let i = 0; i < chunks.length; i++) {
      await client.query(
        `INSERT INTO material_chunks (material_id, subject_id, chunk_index, content)
         VALUES ($1, $2, $3, $4)`,
        [materialId, subjectId, i, chunks[i]]
      );
    }
    await client.query("COMMIT");
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
  return chunks.length;
}

// Embedding vectors for a list of texts, via Ollama's /api/embed.
// nomic-embed-text expects a task prefix: "search_document: " for stored
// passages, "search_query: " for the question being searched with.
export async function embed(texts, kind = "document") {
  const prefix = kind === "query" ? "search_query: " : "search_document: ";
  const r = await fetch(`${OLLAMA_URL}/api/embed`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ model: EMBED_MODEL, input: texts.map((t) => prefix + t) }),
  });
  if (!r.ok) {
    throw new Error(`Ollama embed error (${r.status}): ${(await r.text()).slice(0, 200)}`);
  }
  return (await r.json()).embeddings;
}

// Embed every chunk that doesn't have an embedding yet (optionally only one
// material's). Safe to re-run: it only picks up the chunks still missing one.
// Returns the number of chunks embedded.
export async function embedPending(materialId = null) {
  let done = 0;
  for (;;) {
    const { rows } = await pool.query(
      `SELECT id, content FROM material_chunks
       WHERE embedding IS NULL AND ($1::int IS NULL OR material_id = $1)
       ORDER BY id LIMIT $2`,
      [materialId, EMBED_BATCH]
    );
    if (!rows.length) return done;
    const vectors = await embed(rows.map((r) => r.content));
    for (let i = 0; i < rows.length; i++) {
      await pool.query("UPDATE material_chunks SET embedding = $2 WHERE id = $1", [
        rows[i].id,
        vectors[i],
      ]);
    }
    done += rows.length;
  }
}

const TOP_K = 4; // passages added to the prompt
const MIN_SCORE = Number(process.env.RAG_MIN_SCORE || 0.65); // measured on 4 subjects: covered >= 0.676, not covered <= 0.633

function cosine(a, b) {
  let dot = 0, na = 0, nb = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return dot / Math.sqrt(na * nb);
}

// The TOP_K passages of this subject's materials closest in meaning to the
// question: [{ content, score, materialId, title }]. Empty when the subject
// has no embedded materials or nothing scores above MIN_SCORE.
export async function retrieve(subjectName, question) {
  const { rows } = await pool.query(
    `SELECT c.content, c.embedding, m.id AS material_id, m.title
     FROM material_chunks c
     JOIN learning_materials m ON m.id = c.material_id
     JOIN subjects s ON s.id = c.subject_id
     WHERE lower(s.name) = lower($1) AND c.embedding IS NOT NULL`,
    [subjectName]
  );
  if (!rows.length) return [];

  const [q] = await embed([question], "query");
  return rows
    .map((r) => ({
      content: r.content,
      score: cosine(q, r.embedding),
      materialId: r.material_id,
      title: r.title,
    }))
    .filter((r) => r.score >= MIN_SCORE)
    .sort((a, b) => b.score - a.score)
    .slice(0, TOP_K);
}
