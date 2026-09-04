import express from "express";
import pool from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

const router = express.Router();
router.use(requireAuth);

const staff = requireRole("admin", "teacher");

function toBooking(r) {
  return {
    id: r.id,
    title: r.title,
    teacher: r.teacher,
    room: r.room,
    weekday: r.weekday,
    startHour: r.start_hour,
    endHour: r.end_hour,
  };
}

// GET /api/schedule  -> { bookings: [...] }
router.get("/", async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT * FROM bookings ORDER BY weekday, start_hour`
    );
    res.json({ bookings: rows.map(toBooking) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// POST /api/schedule  { title, teacher, room?, weekday, startHour, endHour }
router.post("/", staff, async (req, res) => {
  try {
    const { title, teacher, weekday, startHour, endHour } = req.body;
    const room = (req.body.room || "Room 301").toString().trim() || "Room 301";
    if (!title || !teacher) {
      return res.status(400).json({ message: "title and teacher are required" });
    }
    const wd = Number(weekday);
    const sh = Number(startHour);
    const eh = Number(endHour);
    if (!(wd >= 1 && wd <= 5) || !(sh >= 0 && sh <= 23) || !(eh > sh && eh <= 24)) {
      return res.status(400).json({ message: "invalid day or time range" });
    }
    const { rows } = await pool.query(
      `INSERT INTO bookings (title, teacher, room, weekday, start_hour, end_hour)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [title.toString().trim(), teacher.toString().trim(), room, wd, sh, eh]
    );
    res.status(201).json({ booking: toBooking(rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// DELETE /api/schedule/:id
router.delete("/:id", staff, async (req, res) => {
  try {
    await pool.query(`DELETE FROM bookings WHERE id = $1`, [req.params.id]);
    res.json({ message: "Deleted" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

export default router;
