import express from "express";
import pool from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { euclidean, isValidDescriptor, MATCH_THRESHOLD } from "../face.js";

const router = express.Router();
router.use(requireAuth);

const staff = requireRole("admin", "teacher");

// A student scanned after this local hour is marked "late".
const LATE_AFTER_HOUR = 9;

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

async function summary(date) {
  const [{ rows: sc }, { rows: ac }] = await Promise.all([
    pool.query(`SELECT COUNT(*)::int AS n FROM students`),
    pool.query(
      `SELECT status, COUNT(*)::int AS n FROM attendance_records
       WHERE session_date = $1 GROUP BY status`,
      [date]
    ),
  ]);
  const present = ac.find((r) => r.status === "present")?.n ?? 0;
  const late = ac.find((r) => r.status === "late")?.n ?? 0;
  const total = sc[0].n;
  const marked = present + late;
  return {
    total,
    present,
    late,
    absent: Math.max(0, total - marked),
    rate: total ? Math.round((marked / total) * 100) : 0,
  };
}

// GET /api/attendance?date=YYYY-MM-DD
router.get("/", async (req, res) => {
  try {
    const date = req.query.date || todayISO();
    const { rows } = await pool.query(
      `SELECT s.student_code, s.name, a.method, a.status, a.recorded_at
       FROM attendance_records a
       JOIN students s ON s.id = a.student_id
       WHERE a.session_date = $1
       ORDER BY a.recorded_at DESC`,
      [date]
    );
    res.json({
      date,
      summary: await summary(date),
      records: rows.map((r) => ({
        studentCode: r.student_code,
        name: r.name,
        method: r.method,
        status: r.status,
        time: r.recorded_at,
      })),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// POST /api/attendance/recognize  { descriptor: number[128] }
router.post("/recognize", staff, async (req, res) => {
  try {
    const { descriptor } = req.body;
    if (!isValidDescriptor(descriptor)) {
      return res
        .status(400)
        .json({ message: "descriptor must be an array of 128 numbers" });
    }

    const { rows } = await pool.query(
      `SELECT f.student_id, f.descriptor, s.name, s.student_code
       FROM face_descriptors f JOIN students s ON s.id = f.student_id`
    );
    if (!rows.length) {
      return res.json({ matched: false, reason: "no enrolled faces" });
    }

    let best = { dist: Infinity, row: null };
    for (const row of rows) {
      const d = euclidean(descriptor, row.descriptor);
      if (d < best.dist) best = { dist: d, row };
    }

    if (best.dist > MATCH_THRESHOLD) {
      return res.json({
        matched: false,
        distance: Number(best.dist.toFixed(3)),
      });
    }

    const status =
      new Date().getHours() >= LATE_AFTER_HOUR ? "late" : "present";
    const date = todayISO();

    const upsert = await pool.query(
      `INSERT INTO attendance_records (student_id, method, status, session_date)
       VALUES ($1, 'facial', $2, $3)
       ON CONFLICT (student_id, session_date) DO NOTHING
       RETURNING id`,
      [best.row.student_id, status, date]
    );

    res.json({
      matched: true,
      alreadyMarked: upsert.rowCount === 0,
      distance: Number(best.dist.toFixed(3)),
      student: {
        studentCode: best.row.student_code,
        name: best.row.name,
      },
      status,
      summary: await summary(date),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// POST /api/attendance/manual  { studentId, status? }
router.post("/manual", staff, async (req, res) => {
  try {
    const { studentId, status } = req.body;
    if (!studentId) {
      return res.status(400).json({ message: "studentId is required" });
    }
    const s = status === "late" ? "late" : "present";
    const date = todayISO();
    await pool.query(
      `INSERT INTO attendance_records (student_id, method, status, session_date)
       VALUES ($1, 'manual', $2, $3)
       ON CONFLICT (student_id, session_date)
       DO UPDATE SET status = EXCLUDED.status, method = 'manual',
                     recorded_at = now()`,
      [studentId, s, date]
    );
    res.json({ message: "Marked", summary: await summary(date) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

export default router;
