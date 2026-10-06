// Brings the RAG index up to date:
//  1. extracts + chunks any material that has no chunks yet
//     (e.g. uploaded before RAG existed)
//  2. embeds every chunk that is still missing an embedding
//
// Usage: npm run rag:index        (safe to run any time)
import path from "path";
import { fileURLToPath } from "url";
import pool from "../src/db.js";
import { indexMaterial, embedPending } from "../src/rag.js";

const backendDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..");

try {
  const { rows } = await pool.query(
    `SELECT m.id, m.subject_id, m.title, m.file_url, m.file_type
     FROM learning_materials m
     WHERE NOT EXISTS (SELECT 1 FROM material_chunks c WHERE c.material_id = m.id)`
  );
  for (const m of rows) {
    try {
      const n = await indexMaterial({
        materialId: m.id,
        subjectId: m.subject_id,
        filePath: path.join(backendDir, m.file_url),
        mimeType: m.file_type,
      });
      console.log(`"${m.title}": ${n ? `${n} chunks` : "no readable text, skipped"}`);
    } catch (e) {
      console.error(`"${m.title}": could not be read (${e.message})`);
    }
  }

  console.log("Embedding chunks... (a large file can take a minute)");
  const started = Date.now();
  const n = await embedPending();
  console.log(`Embedded ${n} chunks in ${((Date.now() - started) / 1000).toFixed(1)}s.`);
} catch (e) {
  console.error("RAG indexing failed:", e.message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
