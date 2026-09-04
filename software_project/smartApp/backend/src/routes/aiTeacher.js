import express from "express";
import { requireAuth } from "../middleware/auth.js";

const router = express.Router();

router.post("/teacher", requireAuth, async (req, res) => {
  try {
    const { message, roomId, schedule } = req.body;

    const prompt = `
You are a smart classroom AI teacher.
Room: ${roomId || "unknown"}
Schedule: ${schedule ? JSON.stringify(schedule) : "not provided"}

Student question: ${message}
Answer clearly like a teacher.
`;

    const r = await fetch("http://127.0.0.1:11434/api/generate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "gemma3:4b",
        prompt,
        stream: false
      })
    });

    const data = await r.json();
    return res.json({ reply: data.response });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Ollama connection failed" });
  }
});

export default router;