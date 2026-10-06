import express from "express";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import pool from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { retrieve } from "../rag.js";

const router = express.Router();

/* ---- teacher roster: one named teacher per subject -----------------------
   Shared with the 3D page (served statically at /teacher3d/teachers.json), so
   the avatar, voice and the AI persona always agree. Re-read on every request
   so edits take effect without a restart (it is a tiny file).             */
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROSTER_PATH = path.join(__dirname, "..", "..", "public_teacher3d", "teachers.json");

export function loadRoster() {
  try {
    const r = JSON.parse(fs.readFileSync(ROSTER_PATH, "utf8"));
    delete r._comment;
    return r;
  } catch (e) {
    console.error("teachers.json unreadable:", e.message);
    return {};
  }
}

// case-insensitive lookup; unknown subjects get the General teacher
// `gender` picks which of the subject's two characters (female/male) is
// speaking — the roster entry's own fields, or its `alt` when the student has
// switched to the other one. Falls back to the default character when the
// requested gender has no `alt` defined, or none was requested.
export function teacherFor(subject, gender) {
  const roster = loadRoster();
  const key = Object.keys(roster).find((k) => k.toLowerCase() === subject.toLowerCase());
  const t = roster[key] || roster.General || { name: "the AI teacher", style: "clear and friendly" };
  const alt = t.alt;
  const g = (gender || "").toLowerCase();
  const merged = alt && alt.gender === g && g !== t.gender ? { ...t, ...alt } : t;
  return { subject: key || subject, ...merged };
}

// GET /api/ai/teachers -> { teachers:[{subject,name,title,gender,accent,avatar,greeting}] }
router.get("/teachers", requireAuth, (_req, res) => {
  const roster = loadRoster();
  res.json({
    teachers: Object.entries(roster).map(([subject, t]) => ({
      subject,
      name: t.name,
      title: t.title,
      gender: t.gender,
      accent: t.accent,
      avatar: t.avatar,
      greeting: t.greeting,
      // the subject's other character (female/male), if the roster defines one
      alt: t.alt
        ? {
            name: t.alt.name,
            title: t.alt.title || t.title,
            gender: t.alt.gender,
            avatar: t.alt.avatar,
            greeting: t.alt.greeting,
          }
        : null,
    })),
  });
});

// Configurable so you can swap models/host without touching code.
const OLLAMA_URL = process.env.OLLAMA_URL || "http://127.0.0.1:11434";
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || "llama3.2:3b";

// Step 1 of answering: which subject does the question belong to?
// A separate, one-word classification is far more reliable on a small model
// than asking the teacher to both judge the topic and answer in one prompt
// (it used to refuse on-topic questions its notes didn't cover).
// Returns a roster subject name, or "General" when nothing fits.
export async function classifySubject(question, subjects, model = OLLAMA_MODEL) {
  const choices = subjects.filter((s) => s.toLowerCase() !== "general");
  const reply = await askModel(
    `Classify the student's question into exactly one school subject from this list: ` +
      `${choices.join(", ")}. If it fits none of them, answer General. ` +
      `Reply with only the subject name.`,
    question,
    model,
    { temperature: 0, num_predict: 8 }
  );
  const lower = reply.toLowerCase();
  return choices.find((s) => lower.includes(s.toLowerCase())) || "General";
}

// Fixed reply for a question that belongs to another subject's teacher.
export function redirectReply(t, otherSubject) {
  return (
    `That's a great question, but it belongs to ${otherSubject}. ` +
    `Please ask the ${otherSubject} teacher in their classroom. ` +
    `I'm happy to help with anything about ${t.subject}.`
  );
}

// The teacher's instructions. Kept short and as numbered rules: small local
// models follow a few direct rules far better than a long paragraph.
// Off-topic questions never reach this prompt (see classifySubject), so the
// teacher only has to answer.
export function buildSystemPrompt(t, passages, { roomId, schedule } = {}) {
  const isGeneral = t.subject.toLowerCase() === "general";

  const rules = [
    isGeneral
      ? "You can help with any school subject."
      : `You teach ${t.subject}. Answer the student's question fully from your own knowledge, ` +
        `including topics that are not in any course notes.`,
    "Never say your name or introduce yourself unless the student asks who you are. " +
      "Never talk about being an AI, an avatar or a program.",
    "Your answer is spoken aloud: use plain sentences only, no markdown, lists, headings or symbols like * and #. " +
      "Keep it under 120 words unless the student asks for more detail.",
    `Teaching style: ${t.style}.`,
  ];
  if (passages.length) {
    rules.push(
      "Course notes from the class materials are below. Use them when they answer the question. " +
        "If they do not, ignore them and answer from your own knowledge. " +
        "Never mention the notes, and never say a topic is missing from them."
    );
  }

  return [
    `You are ${t.name}, a ${isGeneral ? "general" : t.subject} teacher talking with a student.`,
    "Rules:",
    ...rules.map((r, i) => `${i + 1}. ${r}`),
    roomId ? `Room: ${roomId}` : "",
    schedule ? `Schedule: ${JSON.stringify(schedule)}` : "",
    passages.length
      ? `Course notes:\n${passages.map((p, i) => `[${i + 1}] ${p.content}`).join("\n")}`
      : "",
  ]
    .filter(Boolean)
    .join("\n");
}

// One reply from the local model. The rules go in the system message so the
// model treats them as instructions, not as part of the student's question.
// `options` are Ollama generation options; the default temperature keeps
// answers steady and factual.
export async function askModel(system, question, model = OLLAMA_MODEL, options = { temperature: 0.4 }) {
  const r = await fetch(`${OLLAMA_URL}/api/chat`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model,
      stream: false,
      options,
      messages: [
        { role: "system", content: system },
        { role: "user", content: question },
      ],
    }),
  });
  if (!r.ok) {
    throw new Error(`Ollama error (${r.status}): ${(await r.text()).slice(0, 200)}`);
  }
  return (await r.json()).message.content.trim();
}

// GET /api/ai/overview (staff) -> per-subject AI teacher status for the
// AI Management screen: { subjects:[{ subject, teacher, title, accent,
//   materials, chunks, embedded, questions }] }. `embedded < chunks` means
// RAG indexing is still running for that subject.
router.get("/overview", requireAuth, requireRole("admin", "teacher"), async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT s.name AS subject,
              (SELECT COUNT(*) FROM learning_materials m WHERE m.subject_id = s.id)::int AS materials,
              (SELECT COUNT(*) FROM material_chunks c WHERE c.subject_id = s.id)::int AS chunks,
              (SELECT COUNT(c.embedding) FROM material_chunks c WHERE c.subject_id = s.id)::int AS embedded,
              (SELECT COUNT(*) FROM chat_messages q
                 WHERE q.role = 'user' AND lower(q.subject) = lower(s.name))::int AS questions
       FROM subjects s ORDER BY s.sort_order, s.id`
    );
    const general = await pool.query(
      `SELECT COUNT(*)::int AS n FROM chat_messages
       WHERE role = 'user' AND lower(subject) = 'general'`
    );
    const all = [
      { subject: "General", materials: 0, chunks: 0, embedded: 0, questions: general.rows[0].n },
      ...rows,
    ];
    res.json({
      subjects: all.map((r) => {
        const t = teacherFor(r.subject);
        return { ...r, teacher: t.name, title: t.title, accent: t.accent };
      }),
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Server error" });
  }
});

// GET /api/ai/students (staff) -> every student account with a summary of
// their AI-teacher chats: { students:[{ id, email, questions, subjects,
// lastAt }] }, most recently active first. Read-only oversight.
router.get("/students", requireAuth, requireRole("admin", "teacher"), async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT u.id, u.email,
              COUNT(c.id) FILTER (WHERE c.role = 'user')::int AS questions,
              COUNT(DISTINCT c.subject)::int AS subjects,
              MAX(c.created_at) AS last_at
       FROM users u
       LEFT JOIN chat_messages c ON c.user_id = u.id::text
       WHERE u.role = 'student'
       GROUP BY u.id
       ORDER BY MAX(c.created_at) DESC NULLS LAST, u.email`
    );
    res.json({
      students: rows.map((r) => ({
        id: r.id,
        email: r.email,
        questions: r.questions,
        subjects: r.subjects,
        lastAt: r.last_at,
      })),
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Server error" });
  }
});

// GET /api/ai/students/:id/chats (staff) -> one student's full chat history,
// grouped by subject: { student:{id,email}, sessions:[{ subject, lastAt,
// messages:[{role,content,createdAt}] }] }, most recent subject first.
router.get("/students/:id/chats", requireAuth, requireRole("admin", "teacher"), async (req, res) => {
  try {
    const { rows: users } = await pool.query(
      `SELECT id, email FROM users WHERE id = $1 AND role = 'student'`,
      [req.params.id]
    );
    if (!users.length) return res.status(404).json({ error: "Student not found" });

    const { rows } = await pool.query(
      `SELECT subject, role, content, created_at FROM chat_messages
       WHERE user_id = $1 ORDER BY created_at ASC, id ASC`,
      [String(users[0].id)]
    );
    const bySubject = new Map();
    for (const r of rows) {
      if (!bySubject.has(r.subject)) bySubject.set(r.subject, []);
      bySubject.get(r.subject).push({ role: r.role, content: r.content, createdAt: r.created_at });
    }
    const sessions = [...bySubject]
      .map(([subject, messages]) => ({
        subject,
        lastAt: messages[messages.length - 1].createdAt,
        messages,
      }))
      .sort((a, b) => new Date(b.lastAt) - new Date(a.lastAt));

    res.json({ student: users[0], sessions });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Server error" });
  }
});

// GET /api/ai/sessions -> one row per subject the user has chatted about
router.get("/sessions", requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT DISTINCT ON (subject)
              subject,
              content     AS last_message,
              created_at  AS updated_at,
              (SELECT COUNT(*)::int FROM chat_messages c2
                 WHERE c2.user_id = c.user_id AND c2.subject = c.subject) AS count
       FROM chat_messages c
       WHERE user_id = $1
       ORDER BY subject, created_at DESC`,
      [String(req.user.id)]
    );
    rows.sort((a, b) => new Date(b.updated_at) - new Date(a.updated_at));
    res.json({
      sessions: rows.map((r) => ({
        subject: r.subject,
        lastMessage: r.last_message,
        count: r.count,
        updatedAt: r.updated_at,
      })),
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Server error" });
  }
});

// GET /api/ai/history?subject=Mathematics -> { messages:[{role,content,createdAt}] }
router.get("/history", requireAuth, async (req, res) => {
  try {
    const subject = (req.query.subject || "General").toString();
    const { rows } = await pool.query(
      `SELECT role, content, created_at FROM chat_messages
       WHERE user_id = $1 AND subject = $2
       ORDER BY created_at ASC, id ASC`,
      [String(req.user.id), subject]
    );
    res.json({
      messages: rows.map((r) => ({
        role: r.role,
        content: r.content,
        createdAt: r.created_at,
      })),
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Server error" });
  }
});

// DELETE /api/ai/history?subject=Mathematics -> clears that subject's history
router.delete("/history", requireAuth, async (req, res) => {
  try {
    const subject = (req.query.subject || "General").toString();
    await pool.query(
      `DELETE FROM chat_messages WHERE user_id = $1 AND subject = $2`,
      [String(req.user.id), subject]
    );
    res.json({ message: "Cleared" });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Server error" });
  }
});

router.post("/teacher", requireAuth, async (req, res) => {
  try {
    const { message, roomId, schedule, gender } = req.body;
    const subject = (req.body.subject || "General").toString();
    if (!message || !message.trim()) {
      return res.status(400).json({ error: "message is required" });
    }

    const t = teacherFor(subject, gender);

    // RAG: passages from this subject's uploaded materials that match the
    // question. Best-effort — if retrieval fails the teacher still answers.
    const isGeneral = t.subject.toLowerCase() === "general";

    // Run the topic check and the RAG search side by side. Both are
    // best-effort: if either fails, the teacher just answers normally.
    const [topic, found] = await Promise.all([
      isGeneral
        ? null
        : classifySubject(message, Object.keys(loadRoster())).catch((e) => {
            console.error("topic check failed:", e.message);
            return null;
          }),
      retrieve(t.subject, message).catch((e) => {
        console.error("RAG retrieval failed:", e.message);
        return [];
      }),
    ]);
    const offTopic =
      topic && topic !== "General" && topic.toLowerCase() !== t.subject.toLowerCase();
    const passages = offTopic ? [] : found;

    let reply;
    try {
      reply = offTopic
        ? redirectReply(t, topic)
        : await askModel(buildSystemPrompt(t, passages, { roomId, schedule }), message);
    } catch (llmErr) {
      return res.status(502).json({ error: llmErr.message });
    }

    // Persist the turn (best-effort — a DB hiccup must not lose the reply).
    try {
      await pool.query(
        `INSERT INTO chat_messages (user_id, subject, role, content)
         VALUES ($1, $2, 'user', $3), ($1, $2, 'ai', $4)`,
        [String(req.user.id), subject, message, reply]
      );
    } catch (dbErr) {
      console.error("chat history save failed:", dbErr);
    }

    // one entry per material the answer drew on, for a "Source:" line in the UI
    const sources = [...new Map(passages.map((p) => [p.materialId, p.title]))].map(
      ([id, title]) => ({ id, title })
    );

    return res.json({ reply, teacher: { subject: t.subject, name: t.name }, sources });
  } catch (e) {
    console.error(e);
    return res.status(502).json({
      error: "Cannot reach the AI model. Is Ollama running?",
    });
  }
});

export default router;
