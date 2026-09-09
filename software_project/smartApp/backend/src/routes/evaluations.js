import express from "express";
import { PrismaClient } from "@prisma/client";
import { authenticateToken, requireRole } from "../middleware/auth.js";

const router = express.Router();
const prisma = new PrismaClient();

// All evaluation routes require authentication
router.use(authenticateToken);

// GET /api/evaluations - Fetch evaluations (Teachers see all, Students see their own)
router.get("/", async (req, res) => {
  try {
    let filter = {};
    
    // If student, only fetch their own evaluations
    if (req.user.role === "student") {
      filter = { studentId: req.user.id };
    }

    const evals = await prisma.evaluation.findMany({
      where: filter,
      include: { student: { select: { email: true } } },
      orderBy: { scheduledDate: "asc" },
    });
    res.json(evals);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch evaluations" });
  }
});

// POST /api/evaluations - Schedule a new evaluation (Teacher/Admin only)
router.post("/", requireRole("teacher", "admin"), async (req, res) => {
  const { title, subject, studentId, scheduledDate } = req.body;
  
  if (!studentId || !scheduledDate) {
    return res.status(400).json({ error: "Missing required fields (studentId, scheduledDate)" });
  }

  try {
    const evalRecord = await prisma.evaluation.create({
      data: {
        title: title || "Scheduled Quiz",
        subject: subject || "General",
        studentId: parseInt(studentId),
        scheduledDate: new Date(scheduledDate),
      },
    });
    res.status(201).json(evalRecord);
  } catch (error) {
    res.status(500).json({ error: "Failed to schedule evaluation" });
  }
});

export default router;
