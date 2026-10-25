import { GoogleGenerativeAI } from "@google/generative-ai";

const API_KEY = process.env.GEMINI_API_KEY;
const MODEL_NAME = process.env.GEMINI_MODEL || "gemini-1.5-flash";

let client = null;
function getClient() {
  if (!API_KEY) return null;
  if (!client) client = new GoogleGenerativeAI(API_KEY);
  return client;
}

const MAX_ATTEMPTS = 3;
const RETRY_DELAYS_MS = [800, 1600]; // before attempt 2, then attempt 3

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Gemini's free tier occasionally replies 503 ("model overloaded") under
// load — that's transient, so retry a couple of times with backoff before
// giving up. Any other error status is rethrown immediately, unretried.
async function generateWithRetry(model, contents) {
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    try {
      return await model.generateContent({ contents });
    } catch (err) {
      const status = err?.status ?? err?.response?.status;
      if (status !== 503 || attempt === MAX_ATTEMPTS) throw err;
      console.warn(
        `Gemini returned 503 (attempt ${attempt}/${MAX_ATTEMPTS}), retrying in ${RETRY_DELAYS_MS[attempt - 1]}ms...`
      );
      await sleep(RETRY_DELAYS_MS[attempt - 1]);
    }
  }
}

// Accepts either {role:'user'|'model', content} pairs (chat_messages'
// 'user'/'ai' roles included) and converts them into the {role, parts}
// shape the Gemini SDK expects.
function toGeminiContents(history) {
  if (!Array.isArray(history)) return [];
  return history
    .filter((h) => h && typeof h.content === "string" && h.content.trim())
    .map((h) => ({
      role: ["model", "assistant", "ai"].includes(h.role) ? "model" : "user",
      parts: [{ text: h.content }],
    }));
}

/**
 * Calls the Gemini API. Never throws — returns `{ text }` on success or
 * `{ error }` (a message safe to show/turn into an HTTP error) on any
 * failure, so a network hiccup, quota limit, or blocked-content response
 * can't crash the server.
 */
export async function askGemini({ prompt, systemInstruction, history }) {
  if (!prompt || !prompt.trim()) {
    return { error: "prompt is required" };
  }

  const genAI = getClient();
  if (!genAI) {
    return { error: "GEMINI_API_KEY is not configured on the server." };
  }

  try {
    const model = genAI.getGenerativeModel({
      model: MODEL_NAME,
      ...(systemInstruction ? { systemInstruction } : {}),
    });

    const contents = [
      ...toGeminiContents(history),
      { role: "user", parts: [{ text: prompt }] },
    ];

    const result = await generateWithRetry(model, contents);
    const response = result.response;

    const blockReason = response?.promptFeedback?.blockReason;
    if (blockReason) {
      return { error: `The AI model declined to answer (${blockReason}).` };
    }

    const text = response.text();
    if (!text || !text.trim()) {
      return { error: "The AI model returned an empty response." };
    }
    return { text };
  } catch (err) {
    console.error("Gemini request failed:", err);
    const status = err?.status ?? err?.response?.status;
    if (status === 503) {
      return {
        error: "The AI model is currently busy. Please try again in a moment.",
      };
    }
    if (status === 429) {
      return {
        error: "The AI model is rate-limited right now. Please try again shortly.",
      };
    }
    if (status === 400 || status === 403) {
      return {
        error: "The AI model rejected the request. Check the server's Gemini configuration.",
      };
    }
    return { error: "Could not reach the AI model. Please try again." };
  }
}
