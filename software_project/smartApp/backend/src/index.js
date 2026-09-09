import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import dotenv from "dotenv";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";

import materialsRouter from "./routes/materials.js";
import iotRouter from "./routes/iot.js";
import aiRouter from "./routes/ai.js";

dotenv.config();

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

const USERS = [
  // demo user: admin@classroom.com / password
  { id: 1, email: "admin@classroom.com", role: "admin", passwordHash: bcrypt.hashSync("password", 10) },
];

// middleware
function auth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ message: "Missing token" });

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ message: "Invalid token" });
  }
}

// login
app.post("/auth/login", async (req, res) => {
  const { email, password } = req.body;

  const u = USERS.find((x) => x.email === email);
  if (!u) return res.status(401).json({ message: "Invalid credentials" });

  const ok = await bcrypt.compare(password, u.passwordHash);
  if (!ok) return res.status(401).json({ message: "Invalid credentials" });

  const token = jwt.sign(
    { id: u.id, email: u.email, role: u.role },
    process.env.JWT_SECRET,
    { expiresIn: "7d" }
  );

  res.json({ token, user: { id: u.id, email: u.email, role: u.role } });
});
app.get("/", (req, res) => {
  res.send("SmartClassroom API is running ✅");
});

app.use("/materials", materialsRouter);
app.use("/iot", iotRouter);
app.use("/ai", aiRouter);

// example protected data for dashboard
app.get("/dashboard/summary", auth, (req, res) => {
  res.json({
    activeDevices: 24,
    studentsPresent: 156,
    systemHealth: 98,
    powerUsageKw: 2.4,
  });
});

app.get("/health", (req, res) => res.json({ ok: true }));

app.listen(process.env.PORT || 4000, () => {
  console.log(`API running on http://localhost:${process.env.PORT || 4000}`);
});
