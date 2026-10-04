import express from "express";
import pool from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

const router = express.Router();

router.get("/esp32-control", async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, device_type, is_on, slider_value, manual_mode
       FROM devices
       WHERE id IN ('hvac', 'board_lights', 'door_lock', 'rfid')`
    );

    console.log("ESP32 CONTROL ROWS:", rows);

    const fan = rows.find((r) => r.id === "hvac");
    const light = rows.find((r) => r.id === "board_lights");
    const lock = rows.find((r) => r.id === "door_lock");
    const rfid = rows.find((r) => r.id === "rfid");

    res.json({
      fan: fan
        ? {
          manualMode: fan.manual_mode,
          isOn: fan.is_on,
          sliderValue: fan.slider_value,
        }
        : null,

      light: light
        ? {
          manualMode: light.manual_mode,
          isOn: light.is_on,
          sliderValue: light.slider_value,
        }
        : null,

      door: lock
        ? {
          manualMode: lock.manual_mode,
          unlock: lock.is_on,
        }
        : null,

      rfid: rfid
        ? {
          manualMode: rfid.manual_mode,
          isOn: rfid.is_on,
          sliderValue: rfid.slider_value,
        }
        : null,
    });
  } catch (err) {
    console.error("GET /api/devices/esp32-control ERROR:", err);

    res.status(500).json({
      message: "Could not load ESP32 control state",
    });
  }
});

router.post("/heartbeat", async (req, res) => {
  try {
    const { deviceIds } = req.body;

    if (!Array.isArray(deviceIds) || deviceIds.length === 0) {
      return res.status(400).json({
        message: "deviceIds must be a non-empty array",
      });
    }

    await pool.query(
      `UPDATE devices
       SET online = true,
           last_seen = now(),
           updated_at = now()
       WHERE id = ANY($1::text[])`,
      [deviceIds]
    );

    res.json({
      success: true,
      online: deviceIds,
      timestamp: new Date(),
    });
  } catch (err) {
    console.error("POST /api/devices/heartbeat ERROR:", err);

    res.status(500).json({
      message: "Could not update device heartbeat",
    });
  }
});

router.use(requireAuth);

const capabilitiesFor = (type) => {
  if (type === "fan") {
    return { control: "fan_speed", min: 1, max: 3, unit: "level" };
  }
  if (type === "bulb") {
    return { control: "brightness", min: 0, max: 100, unit: "%" };
  }
  if (type === "lock") {
    return {
      control: "door_lock",
      min: null,
      max: null,
      unit: null,
    };
  }

  if (type === "rfid") {
    return {
      control: "reader",
      min: null,
      max: null,
      unit: null,
    };
  }
  return { control: "monitor", min: null, max: null, unit: null };
};

const toDevice = (row) => ({
  id: row.id,
  title: row.title,
  type: row.device_type,
  isOn: row.is_on,
  sliderValue: row.slider_value,
  online: row.online,
  manualMode: row.manual_mode,
  updatedAt: row.updated_at,
  capabilities: capabilitiesFor(row.device_type),
});

router.get("/", async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, title, device_type, is_on, slider_value, online, manual_mode, updated_at
       FROM devices
       ORDER BY CASE device_type WHEN 'fan' THEN 1 WHEN 'bulb' THEN 2 ELSE 3 END`
    );
    res.json({ devices: rows.map(toDevice), updatedAt: new Date() });
  } catch (err) {
    console.error("GET /api/devices ERROR:", err);
    res.status(500).json({ message: "Could not load classroom devices" });
  }
});

router.patch("/:id", requireRole("admin", "teacher"), async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, title, device_type, is_on, slider_value, online, manual_mode, updated_at
       FROM devices WHERE id = $1`,
      [req.params.id]
    );
    if (!rows.length) {
      return res.status(404).json({ message: "Device not found" });
    }

    const current = rows[0];
    if (current.device_type === "rfid") {
      return res.status(400).json({ message: "RFID reader status is monitor-only" });
    }

    if (!current.online) {
      return res.status(409).json({ message: "Device is offline" });
    }

    const { isOn, manualMode, sliderValue } = req.body;
    if (isOn !== undefined && typeof isOn !== "boolean") {
      return res.status(400).json({ message: "isOn must be a boolean" });
    }
    if (manualMode !== undefined && typeof manualMode !== "boolean") {
      return res.status(400).json({ message: "manualMode must be a boolean" });
    }

    let nextSlider = current.slider_value;
    if (sliderValue !== undefined) {
      if (!Number.isInteger(sliderValue)) {
        return res.status(400).json({ message: "sliderValue must be an integer" });
      }
      const { min, max } = capabilitiesFor(current.device_type);
      if (sliderValue < min || sliderValue > max) {
        return res.status(400).json({
          message: `sliderValue must be between ${min} and ${max}`,
        });
      }
      nextSlider = sliderValue;
    }

    const updated = await pool.query(
      `UPDATE devices
       SET is_on = COALESCE($1, is_on), slider_value = $2, manual_mode = COALESCE($3, manual_mode), updated_at = now()
       WHERE id = $4
       RETURNING id, title, device_type, is_on, slider_value, online, manual_mode, updated_at`,
      [isOn, nextSlider, manualMode, req.params.id]
    );

    res.json({ device: toDevice(updated.rows[0]) });
  } catch (err) {
    console.error("PATCH /api/devices/:id ERROR:", err);
    res.status(500).json({ message: "Could not update device" });
  }
});

export default router;
