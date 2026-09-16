CREATE TABLE IF NOT EXISTS bookings (
  id          SERIAL PRIMARY KEY,
  title       TEXT NOT NULL,
  teacher     TEXT NOT NULL,
  room        TEXT NOT NULL DEFAULT 'Room 301',
  weekday     INT  NOT NULL CHECK (weekday BETWEEN 1 AND 5),
  start_hour  INT  NOT NULL CHECK (start_hour BETWEEN 0 AND 23),
  end_hour    INT  NOT NULL CHECK (end_hour BETWEEN 1 AND 24),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_hour > start_hour)
);

INSERT INTO bookings (title, teacher, room, weekday, start_hour, end_hour)
SELECT * FROM (VALUES
  ('Computer Science 301', 'Dr. Smith',    'Room 301', 1, 9, 11),
  ('Mathematics 201',      'Prof. Johnson','Room 301', 1, 11, 13),
  ('Physics Lab',          'Dr. Williams', 'Room 301', 3, 14, 16)
) AS seed(title, teacher, room, weekday, start_hour, end_hour)
WHERE NOT EXISTS (SELECT 1 FROM bookings);
