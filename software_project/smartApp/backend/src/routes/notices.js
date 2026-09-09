import express from "express";
import { PrismaClient } from "@prisma/client";
import { authenticateToken, requireRole } from "../middleware/auth.js";

const router = express.Router();
const prisma = new PrismaClient();

// In-memory fallback
let inMemoryNotices = [
  {
    id: 1,
    title: "Midterm Physics Assessment Schedule",
    content: "The Midterm Physics test will take place this Thursday at 10:00 AM in Smart Lab 301. Please review Chapter 4-6 materials.",
    authorId: 2,
    author: { id: 2, email: "teacher@classroom.com", role: "teacher" },
    createdAt: new Date(Date.now() - 3600000 * 4).toISOString(),
  },
  {
    id: 2,
    title: "Smart Classroom IoT Maintenance",
    content: "Air quality sensors and automated light controls will undergo routine calibration this Friday between 4 PM and 6 PM.",
    authorId: 1,
    author: { id: 1, email: "admin@classroom.com", role: "admin" },
    createdAt: new Date(Date.now() - 3600000 * 24).toISOString(),
  },
  {
    id: 3,
    title: "Welcome to Smart Classroom 2026",
    content: "All students are encouraged to use the AI Teacher Assistant for 24/7 homework help and quiz preparation.",
    authorId: 2,
    author: { id: 2, email: "teacher@classroom.com", role: "teacher" },
    createdAt: new Date(Date.now() - 3600000 * 48).toISOString(),
  }
];

// GET /api/notices - All authenticated users (Students, Teachers, Admins)
// Sorted by createdAt desc (most recent first)
router.get("/", authenticateToken, async (req, res) => {
  try {
    try {
      const notices = await prisma.notice.findMany({
        orderBy: { createdAt: "desc" },
        include: {
          author: {
            select: { id: true, email: true, role: true }
          }
        }
      });
      return res.json({ notices });
    } catch (dbErr) {
      console.warn("[Notice Route] Database query fallback:", dbErr.message);
    }

    const sorted = [...inMemoryNotices].sort(
      (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
    return res.json({ notices: sorted });
  } catch (error) {
    console.error("Error fetching notices:", error);
    return res.status(500).json({ error: "Failed to retrieve notices" });
  }
});

// POST /api/notices - Teacher and Admin only
router.post("/", authenticateToken, requireRole(["teacher", "admin"]), async (req, res) => {
  try {
    const { title, content } = req.body;

    // Strict validation
    if (!title || typeof title !== "string" || title.trim().length === 0) {
      return res.status(400).json({ error: "Title is required and cannot be empty." });
    }

    if (!content || typeof content !== "string" || content.trim().length === 0) {
      return res.status(400).json({ error: "Notice content is required and cannot be empty." });
    }

    const trimmedTitle = title.trim();
    const trimmedContent = content.trim();

    try {
      const newNotice = await prisma.notice.create({
        data: {
          title: trimmedTitle,
          content: trimmedContent,
          authorId: req.user.id
        },
        include: {
          author: {
            select: { id: true, email: true, role: true }
          }
        }
      });
      return res.status(201).json({ message: "Notice posted successfully", notice: newNotice });
    } catch (dbErr) {
      console.warn("[Notice Route] Database create fallback:", dbErr.message);
    }

    const newNotice = {
      id: Date.now(),
      title: trimmedTitle,
      content: trimmedContent,
      authorId: req.user.id,
      author: { id: req.user.id, email: req.user.email, role: req.user.role },
      createdAt: new Date().toISOString()
    };
    inMemoryNotices.unshift(newNotice);

    return res.status(201).json({ message: "Notice posted successfully", notice: newNotice });
  } catch (error) {
    console.error("Error posting notice:", error);
    return res.status(500).json({ error: "Failed to post notice" });
  }
});

// DELETE /api/notices/:id - Teacher and Admin only
router.delete("/:id", authenticateToken, requireRole(["teacher", "admin"]), async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) {
      return res.status(400).json({ error: "Invalid notice ID." });
    }

    try {
      await prisma.notice.delete({ where: { id } });
      return res.json({ message: "Notice deleted successfully" });
    } catch (dbErr) {
      console.warn("[Notice Route] Database delete fallback:", dbErr.message);
    }

    inMemoryNotices = inMemoryNotices.filter((n) => n.id !== id);
    return res.json({ message: "Notice deleted successfully" });
  } catch (error) {
    console.error("Error deleting notice:", error);
    return res.status(500).json({ error: "Failed to delete notice" });
  }
});

export default router;
