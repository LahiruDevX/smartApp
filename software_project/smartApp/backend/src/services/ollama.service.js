const OLLAMA_URL = process.env.OLLAMA_URL || "http://127.0.0.1:11434";
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || "llama3.2:3b";

// Accepts either {role:'user'|'model'|'assistant'|'ai', content} pairs
// (chat_messages' 'user'/'ai' roles included) and converts them into the
// {role, content} shape Ollama's /api/chat expects — role is 'user' or
// 'assistant' there, never 'model'.
function toOllamaMessages(history) {
  if (!Array.isArray(history)) return [];
  return history
    .filter((h) => h && typeof h.content === "string" && h.content.trim())
    .map((h) => ({
      role: ["model", "assistant", "ai"].includes(h.role) ? "assistant" : "user",
      content: h.content,
    }));
}

/**
 * Calls a local Ollama server (POST /api/chat). Never throws — returns
 * `{ text }` on success or `{ error }` (a message safe to show/turn into an
 * HTTP error) on any failure, so Ollama being unreachable, slow, or down
 * can't crash the server. Same interface as gemini.service.js's askGemini,
 * so routes can swap between the two without changing their own code.
 */
export async function askOllama({ prompt, systemInstruction, history }) {
  if (!prompt || !prompt.trim()) {
    return { error: "prompt is required" };
  }

  const messages = [
    ...(systemInstruction ? [{ role: "system", content: systemInstruction }] : []),
    ...toOllamaMessages(history),
    { role: "user", content: prompt },
  ];

  try {
    const r = await fetch(`${OLLAMA_URL}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        stream: false,
        // keeps answers steady and factual, same default main's askModel used
        options: { temperature: 0.4 },
        messages,
      }),
    });

    if (!r.ok) {
      const body = await r.text().catch(() => "");
      console.error(`Ollama error (${r.status}): ${body.slice(0, 200)}`);
      return {
        error: `The AI model is unreachable (Ollama returned ${r.status}). Is Ollama running?`,
      };
    }

    const data = await r.json();
    const text = data?.message?.content?.trim();
    if (!text) {
      return { error: "The AI model returned an empty response." };
    }
    return { text };
  } catch (err) {
    console.error("Ollama request failed:", err);
    return { error: "Cannot reach the AI model. Is Ollama running?" };
  }
}
