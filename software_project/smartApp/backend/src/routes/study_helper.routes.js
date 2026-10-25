import express from "express";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { askOllama } from "../services/ollama.service.js";

const router = express.Router();
router.use(requireAuth);

const SYSTEM_INSTRUCTION =
  "You are a helpful, patient tutor for a student using a smart classroom app. " +
  "Explain clearly, use examples, and keep answers appropriately concise for a student.";

// POST /api/study-helper/ask  { message, history?: [{role, content}] }
router.post("/ask", requireRole("student"), async (req, res) => {
  try {
    const { message, history } = req.body;
    if (!message || !message.trim()) {
      return res.status(400).json({ error: "message is required" });
    }

    const { text: reply, error } = await askOllama({
      prompt: message,
      systemInstruction: SYSTEM_INSTRUCTION,
      history,
    });

    if (error) {
      return res.status(502).json({ error });
    }

    return res.json({ reply });
  } catch (e) {
    console.error(e);
    return res
      .status(502)
      .json({ error: "Cannot reach the AI model. Please try again." });
  }
});

export default router;
