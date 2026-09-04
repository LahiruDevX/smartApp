// Seed baseline accounts for local development / demos.
// Run with:  node prisma/seed.js
import bcrypt from "bcrypt";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const ACCOUNTS = [
  { email: "admin@classroom.com", password: "password", role: "admin" },
  { email: "teacher@classroom.com", password: "password", role: "teacher" },
  { email: "student@classroom.com", password: "password", role: "student" },
];

async function main() {
  for (const acc of ACCOUNTS) {
    const password = await bcrypt.hash(acc.password, 10);
    await prisma.user.upsert({
      where: { email: acc.email },
      update: { role: acc.role },
      create: { email: acc.email, password, role: acc.role },
    });
    console.log(`✔ ${acc.email} (${acc.role})`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
