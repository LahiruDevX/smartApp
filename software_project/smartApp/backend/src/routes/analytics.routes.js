import express from "express";
import pool from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

const router = express.Router();
router.use(requireAuth, requireRole("admin", "teacher"));

// GET /api/analytics -> real classroom figures for the Analytics screen:
// {
//   attendance: { students, todayRate, weekAvgRate,
//                 days: [{ date, rate, present }] }   (last 7 days, oldest first)
//   ai:         { questions, bySubject: [{ subject, questions }] }
//   quizzes:    { attempts, avgScore, bySubject: [{ subject, attempts, avgScore }] }
// }
// Rates and scores are percentages (0-100); avgScore is null with no attempts.
router.get("/", async (_req, res) => {
  try {
    const [students, days, ai, quizzes] = await Promise.all([
      pool.query(`SELECT COUNT(*)::int AS n FROM students`),
      // one row per day, counting each student once (present or late)
      pool.query(
        `SELECT to_char(d, 'YYYY-MM-DD') AS date,
                COUNT(DISTINCT a.student_id)::int AS present
         FROM generate_series(CURRENT_DATE - 6, CURRENT_DATE, interval '1 day') d
         LEFT JOIN attendance_records a ON a.session_date = d::date
         GROUP BY d ORDER BY d` // dates as plain YYYY-MM-DD, not UTC timestamps
      ),
      pool.query(
        `SELECT subject, COUNT(*)::int AS questions
         FROM chat_messages WHERE role = 'user'
         GROUP BY subject ORDER BY questions DESC`
      ),
      pool.query(
        `SELECT s.name AS subject,
                COUNT(*)::int AS attempts,
                ROUND(AVG(qa.score * 100.0 / NULLIF(qa.total, 0)))::int AS avg_score
         FROM quiz_attempts qa
         JOIN quizzes q ON q.id = qa.quiz_id
         LEFT JOIN subjects s ON s.id = q.subject_id
         GROUP BY s.name ORDER BY s.name`
      ),
    ]);

    const total = students.rows[0].n;
    const rate = (present) => (total ? Math.round((present * 100) / total) : 0);
    const dayRows = days.rows.map((r) => ({
      date: r.date,
      present: r.present,
      rate: rate(r.present),
    }));
    // average over days that had any attendance taken (skips weekends/no class)
    const taken = dayRows.filter((d) => d.present > 0);
    const weekAvgRate = taken.length
      ? Math.round(taken.reduce((a, d) => a + d.rate, 0) / taken.length)
      : 0;

    const attempts = quizzes.rows.reduce((a, r) => a + r.attempts, 0);
    const avgScore = attempts
      ? Math.round(
          quizzes.rows.reduce((a, r) => a + r.avg_score * r.attempts, 0) / attempts
        )
      : null;

    res.json({
      attendance: {
        students: total,
        todayRate: dayRows[dayRows.length - 1].rate,
        weekAvgRate,
        days: dayRows,
      },
      ai: {
        questions: ai.rows.reduce((a, r) => a + r.questions, 0),
        bySubject: ai.rows,
      },
      quizzes: {
        attempts,
        avgScore,
        bySubject: quizzes.rows.map((r) => ({
          subject: r.subject ?? "Unassigned",
          attempts: r.attempts,
          avgScore: r.avg_score,
        })),
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

export default router;
