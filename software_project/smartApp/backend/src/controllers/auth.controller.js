// backend/src/controllers/auth.controller.js
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const DEMO_USERS = [
  { email: "admin@classroom.com", password: "password", role: "admin" },
  { email: "teacher@classroom.com", password: "password", role: "teacher" },
  { email: "student@classroom.com", password: "password", role: "student" },
];

export async function register(req, res) {
  try {
    const { email, password, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "email and password are required" });
    }

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(409).json({ message: "Email already registered" });
    }

    const hashed = await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
      data: {
        email,
        password: hashed,
        role: role ?? "student",
      },
      select: { id: true, email: true, role: true, createdAt: true },
    });

    return res.status(201).json({ message: "User registered", user });
  } catch (err) {
    console.error("Register Error:", err);
    return res.status(500).json({ message: "Server error during registration" });
  }
}

export async function login(req, res) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "email and password are required" });
    }

    let user = null;
    try {
      user = await prisma.user.findUnique({ where: { email } });
    } catch (dbErr) {
      console.warn("DB findUnique warning:", dbErr.message);
    }

    // Auto-seed demo accounts if missing in database
    if (!user) {
      const demo = DEMO_USERS.find((u) => u.email === email);
      if (demo && demo.password === password) {
        try {
          const hashed = await bcrypt.hash(demo.password, 10);
          user = await prisma.user.create({
            data: {
              email: demo.email,
              password: hashed,
              role: demo.role,
            },
          });
        } catch (seedErr) {
          // In-memory fallback if DB write fails
          user = {
            id: demo.role === "admin" ? 1 : demo.role === "teacher" ? 2 : 3,
            email: demo.email,
            role: demo.role,
          };
        }
      }
    }

    if (!user) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // Check password if user has password hash
    if (user.password) {
      const ok = await bcrypt.compare(password, user.password);
      if (!ok) {
        return res.status(401).json({ message: "Invalid credentials" });
      }
    }

    const token = jwt.sign(
      { id: user.id, sub: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET || "super_secret_jwt_key_smart_classroom_2026",
      { expiresIn: "7d" }
    );

    return res.json({
      message: "Login success",
      token,
      user: { id: user.id, email: user.email, role: user.role },
    });
  } catch (err) {
    console.error("Login error:", err);
    return res.status(500).json({ message: "Server error during login" });
  }
}

export async function getMe(req, res) {
  try {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }

    try {
      const user = await prisma.user.findUnique({
        where: { id: req.user.id },
        select: { id: true, email: true, role: true, createdAt: true },
      });
      if (user) {
        return res.json({ user });
      }
    } catch (dbErr) {
      // Fallback
    }

    return res.json({ user: req.user });
  } catch (err) {
    console.error("getMe error:", err);
    return res.status(500).json({ message: "Server error fetching user" });
  }
}
