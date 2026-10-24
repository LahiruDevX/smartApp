import express from "express";
import crypto from "crypto";
import pool from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

const router = express.Router();
router.use(requireAuth);

// A student "passes" the auto-attendance check if a face was detected in at
// least this fraction of their periodic presence checks during the call.
const PRESENCE_THRESHOLD = 0.6;

function toMeeting(r) {
  return {
    id: r.id,
    subjectId: r.subject_id,
    subjectName: r.subject_name ?? null,
    teacherId: r.teacher_id,
    title: r.title,
    scheduledAt: r.scheduled_at,
    durationMinutes: r.duration_minutes,
    jitsiRoomName: r.jitsi_room_name,
    status: r.status,
    createdAt: r.created_at,
  };
}

// POST /api/meetings (teacher only)  { subjectId, title, scheduledAt, durationMinutes }
router.post("/", requireRole("teacher"), async (req, res) => {
  try {
    const { subjectId, title, scheduledAt, durationMinutes } = req.body;
    if (!subjectId || !title || !scheduledAt) {
      return res.status(400).json({
        message: "subjectId, title, and scheduledAt are required",
      });
    }

    const roomName = `smartapp-${crypto.randomUUID()}`;
    const { rows } = await pool.query(
      `INSERT INTO meetings
         (subject_id, teacher_id, title, scheduled_at, duration_minutes, jitsi_room_name)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [
        subjectId,
        req.user.id,
        title,
        scheduledAt,
        durationMinutes || 45,
        roomName,
      ]
    );
    res.status(201).json({ meeting: toMeeting(rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// GET /api/meetings?subject_id=...
// Teachers see only meetings they created. There is no student/subject
// enrollment concept anywhere in this codebase (subjects are global, not
// per-student — see materials.routes.js / quizzes.routes.js, which list the
// same way), so students (and admins) see every meeting, optionally
// filtered by subject_id, exactly like those two routes already do.
router.get("/", async (req, res) => {
  try {
    const { subject_id } = req.query;
    const isTeacher = req.user.role === "teacher";
    const params = [];
    const where = [];

    if (isTeacher) {
      params.push(req.user.id);
      where.push(`m.teacher_id = $${params.length}`);
    }
    if (subject_id) {
      params.push(subject_id);
      where.push(`m.subject_id = $${params.length}`);
    }

    const { rows } = await pool.query(
      `SELECT m.*, s.name AS subject_name
       FROM meetings m
       LEFT JOIN subjects s ON s.id = m.subject_id
       ${where.length ? `WHERE ${where.join(" AND ")}` : ""}
       ORDER BY m.scheduled_at DESC`,
      params
    );
    res.json({ meetings: rows.map(toMeeting) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// GET /api/meetings/:id
router.get("/:id", async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT m.*, s.name AS subject_name
       FROM meetings m
       LEFT JOIN subjects s ON s.id = m.subject_id
       WHERE m.id = $1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ message: "Not found" });
    res.json({ meeting: toMeeting(rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// POST /api/meetings/:id/join (student only)
router.post("/:id/join", requireRole("student"), async (req, res) => {
  try {
    const meetingId = req.params.id;
    const { rows: meetingRows } = await pool.query(
      `SELECT status FROM meetings WHERE id = $1`,
      [meetingId]
    );
    if (!meetingRows.length) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    await pool.query(
      `INSERT INTO meeting_attendance (meeting_id, student_id, joined_at)
       VALUES ($1, $2, NOW())
       ON CONFLICT (meeting_id, student_id)
       DO UPDATE SET joined_at = NOW()`,
      [meetingId, req.user.id]
    );

    if (meetingRows[0].status === "scheduled") {
      await pool.query(`UPDATE meetings SET status = 'live' WHERE id = $1`, [
        meetingId,
      ]);
    }

    res.json({ message: "Joined" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// POST /api/meetings/:id/presence-check (student only)  { faceDetected: boolean }
// Never accepts or stores an image — boolean only.
router.post(
  "/:id/presence-check",
  requireRole("student"),
  async (req, res) => {
    try {
      const { faceDetected } = req.body;
      if (typeof faceDetected !== "boolean") {
        return res
          .status(400)
          .json({ message: "faceDetected must be a boolean" });
      }

      const { rowCount } = await pool.query(
        `UPDATE meeting_attendance
         SET presence_checks_total = presence_checks_total + 1,
             presence_checks_with_face = presence_checks_with_face
               + CASE WHEN $3 THEN 1 ELSE 0 END
         WHERE meeting_id = $1 AND student_id = $2`,
        [req.params.id, req.user.id, faceDetected]
      );
      if (!rowCount) {
        return res.status(404).json({
          message: "Join the meeting before sending presence checks",
        });
      }
      res.json({ message: "Recorded" });
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: "Server error" });
    }
  }
);

// POST /api/meetings/:id/leave (student only)
router.post("/:id/leave", requireRole("student"), async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT presence_checks_total, presence_checks_with_face
       FROM meeting_attendance WHERE meeting_id = $1 AND student_id = $2`,
      [req.params.id, req.user.id]
    );
    if (!rows.length) {
      return res
        .status(404)
        .json({ message: "You never joined this meeting" });
    }

    const total = rows[0].presence_checks_total;
    const withFace = rows[0].presence_checks_with_face;
    const finalStatus =
      total > 0 && withFace / total >= PRESENCE_THRESHOLD
        ? "present"
        : "absent";

    await pool.query(
      `UPDATE meeting_attendance
       SET left_at = NOW(), final_status = $3
       WHERE meeting_id = $1 AND student_id = $2`,
      [req.params.id, req.user.id, finalStatus]
    );
    res.json({ message: "Left", finalStatus });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// GET /api/meetings/:id/attendance (teacher only)
router.get("/:id/attendance", requireRole("teacher"), async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT a.id, a.student_id, u.email AS student_email,
              a.joined_at, a.left_at, a.final_status,
              a.presence_checks_total, a.presence_checks_with_face
       FROM meeting_attendance a
       JOIN "User" u ON u.id = a.student_id
       WHERE a.meeting_id = $1
       ORDER BY a.joined_at ASC NULLS LAST`,
      [req.params.id]
    );
    res.json({
      attendance: rows.map((r) => ({
        id: r.id,
        studentId: r.student_id,
        studentEmail: r.student_email,
        joinedAt: r.joined_at,
        leftAt: r.left_at,
        finalStatus: r.final_status,
        presenceChecksTotal: r.presence_checks_total,
        presenceChecksWithFace: r.presence_checks_with_face,
      })),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

export default router;
