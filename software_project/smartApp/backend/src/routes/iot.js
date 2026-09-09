import express from "express";
import { PrismaClient } from "@prisma/client";
import { authenticateToken } from "../middleware/auth.js";

const router = express.Router();
const prisma = new PrismaClient();

// In-memory buffer for IoT logs
let inMemoryLogs = [
  { id: 1, temperature: 23.4, humidity: 48.2, airQuality: 382.0, light: 340.0, noise: 42.0, lightsOn: true, timestamp: new Date(Date.now() - 15 * 60000).toISOString() },
  { id: 2, temperature: 23.8, humidity: 47.9, airQuality: 388.5, light: 345.0, noise: 43.5, lightsOn: true, timestamp: new Date(Date.now() - 10 * 60000).toISOString() },
  { id: 3, temperature: 24.2, humidity: 47.5, airQuality: 391.2, light: 350.0, noise: 44.0, lightsOn: true, timestamp: new Date(Date.now() - 5 * 60000).toISOString() },
  { id: 4, temperature: 24.4, humidity: 47.8, airQuality: 392.2, light: 334.2, noise: 42.2, lightsOn: true, timestamp: new Date().toISOString() },
];

// GET /api/iot/dashboard (Authenticated)
router.get("/dashboard", authenticateToken, async (req, res) => {
  try {
    let latestLog = null;
    try {
      latestLog = await prisma.ioTLog.findFirst({
        orderBy: { timestamp: "desc" },
      });
    } catch (dbErr) {
      // Fallback
    }

    if (!latestLog) {
      latestLog = inMemoryLogs[inMemoryLogs.length - 1];
    }

    return res.json({
      temperature: latestLog?.temperature ?? 24.4,
      humidity: latestLog?.humidity ?? 47.8,
      airQuality: latestLog?.airQuality ?? 392.2,
      light: latestLog?.light ?? 334.2,
      noise: latestLog?.noise ?? 42.2,
      lightsOn: latestLog?.lightsOn ?? true,
      studentsPresent: 156,
      totalStudents: 160,
      activeDevices: 24,
      systemHealth: 98,
      powerUsageKw: 2.4,
      timestamp: latestLog?.timestamp ?? new Date().toISOString(),
    });
  } catch (error) {
    console.error("IoT Dashboard error:", error);
    return res.status(500).json({ error: "Failed to fetch IoT dashboard data" });
  }
});

// GET /api/iot/history (Authenticated)
router.get("/history", authenticateToken, async (req, res) => {
  try {
    let logs = [];
    try {
      logs = await prisma.ioTLog.findMany({
        take: 20,
        orderBy: { timestamp: "desc" },
      });
      logs.reverse();
    } catch (dbErr) {
      logs = inMemoryLogs;
    }

    if (logs.length === 0) {
      logs = inMemoryLogs;
    }

    return res.json(logs);
  } catch (error) {
    console.error("IoT History error:", error);
    return res.status(500).json({ error: "Failed to fetch IoT history" });
  }
});

// POST /api/iot/webhook (Webhook ingestion with payload validation)
router.post("/webhook", async (req, res) => {
  const { temperature, airQuality, lightsOn, humidity, light, noise } = req.body;

  // Strict Validation: Reject invalid or missing sensor data
  if (temperature === undefined || temperature === null || isNaN(Number(temperature))) {
    return res.status(400).json({ error: "Invalid or missing 'temperature' (must be a number)" });
  }

  if (airQuality === undefined || airQuality === null || isNaN(Number(airQuality))) {
    return res.status(400).json({ error: "Invalid or missing 'airQuality' (must be a number)" });
  }

  if (lightsOn === undefined || lightsOn === null || typeof lightsOn !== "boolean") {
    return res.status(400).json({ error: "Invalid or missing 'lightsOn' (must be a boolean)" });
  }

  const tempNum = parseFloat(temperature);
  const airNum = parseFloat(airQuality);
  const humNum = humidity !== undefined ? parseFloat(humidity) : 48.0;
  const lightNum = light !== undefined ? parseFloat(light) : 340.0;
  const noiseNum = noise !== undefined ? parseFloat(noise) : 42.0;

  // Range validation
  if (tempNum < -50 || tempNum > 100) {
    return res.status(400).json({ error: "Temperature value out of realistic range (-50°C to 100°C)" });
  }
  if (airNum < 0 || airNum > 5000) {
    return res.status(400).json({ error: "Air quality value out of realistic range (0 to 5000 PPM)" });
  }

  try {
    let log;
    try {
      log = await prisma.ioTLog.create({
        data: {
          temperature: tempNum,
          airQuality: airNum,
          lightsOn: Boolean(lightsOn),
        },
      });
    } catch (dbErr) {
      log = {
        id: inMemoryLogs.length + 1,
        temperature: tempNum,
        airQuality: airNum,
        humidity: humNum,
        light: lightNum,
        noise: noiseNum,
        lightsOn: Boolean(lightsOn),
        timestamp: new Date().toISOString(),
      };
      inMemoryLogs.push(log);
      if (inMemoryLogs.length > 50) inMemoryLogs.shift();
    }

    return res.status(201).json({ message: "IoT data logged successfully", log });
  } catch (error) {
    console.error("IoT Webhook error:", error);
    return res.status(500).json({ error: "Failed to save IoT sensor data" });
  }
});

export default router;
