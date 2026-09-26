-- Weekly classes and their Smart Classroom IoT presets.
CREATE TABLE IF NOT EXISTS bookings (
  id                       SERIAL PRIMARY KEY,
  title                    TEXT NOT NULL,
  teacher                  TEXT NOT NULL,
  room                     TEXT NOT NULL DEFAULT 'Room 301',
  weekday                  INT NOT NULL CHECK (weekday BETWEEN 1 AND 5),
  start_minute             INT NOT NULL CHECK (start_minute BETWEEN 0 AND 1439),
  end_minute               INT NOT NULL CHECK (end_minute BETWEEN 1 AND 1440),
  enabled                  BOOLEAN NOT NULL DEFAULT true,
  automation_enabled       BOOLEAN NOT NULL DEFAULT true,
  fan_mode                 TEXT NOT NULL DEFAULT 'auto' CHECK (fan_mode IN ('off', 'on', 'auto')),
  fan_speed                INT NOT NULL DEFAULT 2 CHECK (fan_speed BETWEEN 1 AND 3),
  target_temperature       DOUBLE PRECISION NOT NULL DEFAULT 26 CHECK (target_temperature BETWEEN 16 AND 32),
  light_on                 BOOLEAN NOT NULL DEFAULT true,
  light_brightness         INT NOT NULL DEFAULT 80 CHECK (light_brightness BETWEEN 0 AND 100),
  attendance_enabled       BOOLEAN NOT NULL DEFAULT true,
  attendance_grace_minutes INT NOT NULL DEFAULT 10 CHECK (attendance_grace_minutes BETWEEN 0 AND 60),
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_minute > start_minute)
);

CREATE INDEX IF NOT EXISTS bookings_day_time
ON bookings (weekday, start_minute, end_minute);

CREATE TABLE IF NOT EXISTS schedule_automation_state (
  id                INT PRIMARY KEY CHECK (id = 1),
  active            BOOLEAN NOT NULL DEFAULT false,
  active_booking_id INT,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO schedule_automation_state (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS booking_id INT;
CREATE UNIQUE INDEX IF NOT EXISTS attendance_student_class_date_key
ON attendance_records (student_id, session_date, COALESCE(booking_id, 0));
