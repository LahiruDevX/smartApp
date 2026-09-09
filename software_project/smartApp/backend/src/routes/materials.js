import express from "express";
import { PrismaClient } from "@prisma/client";
import { authenticateToken, requireRole } from "../middleware/auth.js";

const router = express.Router();
const prisma = new PrismaClient();

// In-memory fallback if database has not been migrated or is unavailable
let inMemoryMaterials = [
  {
    id: 1,
    title: "Introduction to Algebra",
    contentUrl: "https://classroom.internal/materials/algebra-intro.pdf",
    teacherId: 2,
    teacher: { email: "teacher@classroom.com" },
    createdAt: new Date().toISOString(),
  },
  {
    id: 2,
    title: "Python Programming Fundamentals",
    contentUrl: "https://classroom.internal/materials/python-basics.pdf",
    teacherId: 2,
    teacher: { email: "teacher@classroom.com" },
    createdAt: new Date().toISOString(),
  },
  {
    id: 3,
    title: "Newtonian Physics & Mechanics",
    contentUrl: "https://classroom.internal/materials/physics-newton.pdf",
    teacherId: 2,
    teacher: { email: "teacher@classroom.com" },
    createdAt: new Date().toISOString(),
  },
];

// GET /api/materials (Authenticated - Student, Teacher, Admin)
router.get("/", authenticateToken, async (req, res) => {
  try {
    const materials = await prisma.material.findMany({
      include: { teacher: { select: { email: true, id: true } } },
      orderBy: { createdAt: "desc" },
    });
    return res.json(materials);
  } catch (error) {
    console.warn("DB findMany materials failed, using memory fallback:", error.message);
    return res.json(inMemoryMaterials);
  }
});

// GET /api/materials/:id (Authenticated)
router.get("/:id", authenticateToken, async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) {
    return res.status(400).json({ error: "Invalid material ID" });
  }

  try {
    const material = await prisma.material.findUnique({
      where: { id },
      include: { teacher: { select: { email: true, id: true } } },
    });
    if (!material) {
      return res.status(404).json({ error: "Material not found" });
    }
    return res.json(material);
  } catch (error) {
    const found = inMemoryMaterials.find((m) => m.id === id);
    if (!found) return res.status(404).json({ error: "Material not found" });
    return res.json(found);
  }
});

// POST /api/materials (Protected - Teacher and Admin only)
router.post("/", authenticateToken, requireRole("teacher", "admin"), async (req, res) => {
  const { title, contentUrl } = req.body;
  const teacherId = req.user.id || parseInt(req.body.teacherId) || 1;

  if (!title || typeof title !== "string" || !title.trim()) {
    return res.status(400).json({ error: "Title is required and cannot be empty" });
  }

  if (!contentUrl || typeof contentUrl !== "string" || !contentUrl.trim()) {
    return res.status(400).json({ error: "Content URL is required and cannot be empty" });
  }

  try {
    const material = await prisma.material.create({
      data: {
        title: title.trim(),
        contentUrl: contentUrl.trim(),
        teacherId: teacherId,
      },
      include: { teacher: { select: { email: true, id: true } } },
    });
    return res.status(201).json(material);
  } catch (error) {
    console.warn("DB material.create failed, saving in memory fallback:", error.message);
    const newMaterial = {
      id: inMemoryMaterials.length > 0 ? Math.max(...inMemoryMaterials.map((m) => m.id)) + 1 : 1,
      title: title.trim(),
      contentUrl: contentUrl.trim(),
      teacherId: teacherId,
      teacher: { email: req.user.email || "teacher@classroom.com", id: teacherId },
      createdAt: new Date().toISOString(),
    };
    inMemoryMaterials.unshift(newMaterial);
    return res.status(201).json(newMaterial);
  }
});

// PUT /api/materials/:id (Protected - Teacher and Admin only)
router.put("/:id", authenticateToken, requireRole("teacher", "admin"), async (req, res) => {
  const id = parseInt(req.params.id);
  const { title, contentUrl } = req.body;

  if (isNaN(id)) {
    return res.status(400).json({ error: "Invalid material ID" });
  }

  if (!title || typeof title !== "string" || !title.trim()) {
    return res.status(400).json({ error: "Title cannot be empty" });
  }

  if (!contentUrl || typeof contentUrl !== "string" || !contentUrl.trim()) {
    return res.status(400).json({ error: "Content URL cannot be empty" });
  }

  try {
    const updated = await prisma.material.update({
      where: { id },
      data: {
        title: title.trim(),
        contentUrl: contentUrl.trim(),
      },
      include: { teacher: { select: { email: true, id: true } } },
    });
    return res.json(updated);
  } catch (error) {
    const idx = inMemoryMaterials.findIndex((m) => m.id === id);
    if (idx === -1) {
      return res.status(404).json({ error: "Material not found" });
    }
    inMemoryMaterials[idx] = {
      ...inMemoryMaterials[idx],
      title: title.trim(),
      contentUrl: contentUrl.trim(),
    };
    return res.json(inMemoryMaterials[idx]);
  }
});

// DELETE /api/materials/:id (Protected - Teacher and Admin only)
router.delete("/:id", authenticateToken, requireRole("teacher", "admin"), async (req, res) => {
  const id = parseInt(req.params.id);

  if (isNaN(id)) {
    return res.status(400).json({ error: "Invalid material ID" });
  }

  try {
    await prisma.material.delete({
      where: { id },
    });
    return res.json({ message: "Material deleted successfully", id });
  } catch (error) {
    const idx = inMemoryMaterials.findIndex((m) => m.id === id);
    if (idx === -1) {
      return res.status(404).json({ error: "Material not found" });
    }
    inMemoryMaterials.splice(idx, 1);
    return res.json({ message: "Material deleted successfully", id });
  }
});

export default router;
