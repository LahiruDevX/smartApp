-- RAG (retrieval-augmented generation) for the AI teacher.
-- Each uploaded learning material is split into small text passages
-- ("chunks"). The AI teacher later searches the chunks of the current
-- subject and adds the best matches to its prompt.
--
-- Run after learning_materials.sql:
--   psql -U postgres -d smartapp -f sql/rag.sql

CREATE TABLE IF NOT EXISTS material_chunks (
  id          SERIAL PRIMARY KEY,
  material_id INTEGER NOT NULL REFERENCES learning_materials(id) ON DELETE CASCADE,
  subject_id  INTEGER REFERENCES subjects(id),
  chunk_index INT NOT NULL,
  content     TEXT NOT NULL,
  -- filled in by the embedding step; same storage style as face_descriptors
  embedding   DOUBLE PRECISION[],
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (material_id, chunk_index)
);

CREATE INDEX IF NOT EXISTS idx_material_chunks_subject ON material_chunks(subject_id);
