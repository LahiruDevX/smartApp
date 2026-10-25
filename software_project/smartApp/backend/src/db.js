/*import pkg from 'pg';
const { Pool } = pkg;

export const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

pool.on('connect', () => {
  console.log('✅ PostgreSQL connected');
});
*/
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

// SSL is for a real hosted Postgres (Render/Railway/etc.), not local dev —
// a local server usually has no SSL listener at all. Having DATABASE_URL set
// isn't itself a signal to use SSL (a local Postgres can be addressed by a
// connection string too), so this is a separate, explicit opt-in.
const useSsl = process.env.DB_SSL === 'true';

const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ...(useSsl ? { ssl: { rejectUnauthorized: false } } : {}),
    })
  : new Pool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      ...(useSsl ? { ssl: { rejectUnauthorized: false } } : {}),
    });

export default pool;
