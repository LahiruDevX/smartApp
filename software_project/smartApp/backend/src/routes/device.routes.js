/*import { Router } from "express";

const router = Router();

// TEMP: no auth yet (we can add JWT middleware after)
router.get("/", async (req, res) => {
  res.json({
    devices: [
      { id: "main_lights", title: "Main Lights", isOn: true, sliderValue: 80 },
      { id: "board_lights", title: "Board Lights", isOn: true, sliderValue: 100 },
      { id: "projector", title: "Projector", isOn: false },
      { id: "hvac", title: "HVAC System", isOn: true, sliderValue: 22 },
      { id: "audio", title: "Audio System", isOn: false },
      { id: "emergency_lights", title: "Emergency Lights", isOn: true, sliderValue: 50 }
    ],
  });
});

router.patch("/:id", async (req, res) => {
  const { id } = req.params;
  const { isOn, sliderValue } = req.body;

  console.log("DEVICE UPDATE ✅", { id, isOn, sliderValue });

  // TEMP: just return success (later save in DB)
  res.json({ message: "Device updated", id, isOn, sliderValue });
});

export default router;
*/
import express from "express";
import pool from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

const router = express.Router();

// Every device endpoint requires a valid token.
router.use(requireAuth);

// GET /api/devices
router.get("/", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        id,
        title,
        is_on AS "isOn",
        slider_value AS "sliderValue"
      FROM devices
      ORDER BY id;
    `);

    res.json({ devices: result.rows });
  } catch (err) {
    console.error("GET /api/devices ERROR:", err);
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/devices/:id  — only staff may change device state
router.patch("/:id", requireRole("admin", "teacher"), async (req, res) => {
  try {
    const { id } = req.params;
    const { isOn, sliderValue } = req.body;

    const result = await pool.query(
      `
      UPDATE devices
      SET 
        is_on = COALESCE($1, is_on),
        slider_value = $2
      WHERE id = $3
      RETURNING 
        id,
        title,
        is_on AS "isOn",
        slider_value AS "sliderValue";
      `,
      [isOn, sliderValue ?? null, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Device not found" });
    }

    res.json({ device: result.rows[0] });
  } catch (err) {
    console.error("PATCH /api/devices/:id ERROR:", err);
    res.status(500).json({ message: err.message });
  }
});

export default router;
