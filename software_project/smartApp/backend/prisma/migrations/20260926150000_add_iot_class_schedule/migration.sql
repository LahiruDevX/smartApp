CREATE TABLE IF NOT EXISTS "bookings" (
    "id" SERIAL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "teacher" TEXT NOT NULL,
    "room" TEXT NOT NULL DEFAULT 'Room 301',
    "weekday" INTEGER NOT NULL,
    "start_minute" INTEGER,
    "end_minute" INTEGER,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "start_minute" INTEGER;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "end_minute" INTEGER;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='bookings' AND column_name='start_hour'
  ) THEN
    UPDATE "bookings"
    SET "start_minute" = COALESCE("start_minute", "start_hour" * 60),
        "end_minute" = COALESCE("end_minute", "end_hour" * 60);
    ALTER TABLE "bookings" DROP COLUMN "start_hour" CASCADE;
    ALTER TABLE "bookings" DROP COLUMN "end_hour" CASCADE;
  END IF;
END $$;

UPDATE "bookings" SET "start_minute"=540 WHERE "start_minute" IS NULL;
UPDATE "bookings" SET "end_minute"=600 WHERE "end_minute" IS NULL;
ALTER TABLE "bookings" ALTER COLUMN "start_minute" SET NOT NULL;
ALTER TABLE "bookings" ALTER COLUMN "end_minute" SET NOT NULL;

ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "enabled" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "automation_enabled" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "fan_mode" TEXT NOT NULL DEFAULT 'auto';
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "fan_speed" INTEGER NOT NULL DEFAULT 2;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "target_temperature" DOUBLE PRECISION NOT NULL DEFAULT 26;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "light_on" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "light_brightness" INTEGER NOT NULL DEFAULT 80;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "attendance_enabled" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "attendance_grace_minutes" INTEGER NOT NULL DEFAULT 10;

ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "bookings_weekday_check";
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "bookings_start_minute_check";
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "bookings_end_minute_check";
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "bookings_time_check";
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "bookings_fan_mode_check";
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "bookings_fan_speed_check";
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "bookings_temperature_check";
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "bookings_brightness_check";
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "bookings_grace_check";

ALTER TABLE "bookings" ADD CONSTRAINT "bookings_weekday_check" CHECK ("weekday" BETWEEN 1 AND 5);
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_start_minute_check" CHECK ("start_minute" BETWEEN 0 AND 1439);
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_end_minute_check" CHECK ("end_minute" BETWEEN 1 AND 1440);
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_time_check" CHECK ("end_minute" > "start_minute");
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_fan_mode_check" CHECK ("fan_mode" IN ('off', 'on', 'auto'));
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_fan_speed_check" CHECK ("fan_speed" BETWEEN 1 AND 3);
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_temperature_check" CHECK ("target_temperature" BETWEEN 16 AND 32);
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_brightness_check" CHECK ("light_brightness" BETWEEN 0 AND 100);
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_grace_check" CHECK ("attendance_grace_minutes" BETWEEN 0 AND 60);

CREATE INDEX IF NOT EXISTS "bookings_day_time"
ON "bookings" ("weekday", "start_minute", "end_minute");

CREATE TABLE IF NOT EXISTS "schedule_automation_state" (
    "id" INTEGER PRIMARY KEY CHECK ("id" = 1),
    "active" BOOLEAN NOT NULL DEFAULT false,
    "active_booking_id" INTEGER,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO "schedule_automation_state" ("id") VALUES (1)
ON CONFLICT ("id") DO NOTHING;

ALTER TABLE "attendance_records" ADD COLUMN IF NOT EXISTS "booking_id" INTEGER;
ALTER TABLE "attendance_records"
DROP CONSTRAINT IF EXISTS "attendance_records_student_id_session_date_key";
DROP INDEX IF EXISTS "attendance_records_student_id_session_date_key";
CREATE UNIQUE INDEX IF NOT EXISTS "attendance_student_class_date_key"
ON "attendance_records" ("student_id", "session_date", COALESCE("booking_id", 0));
ALTER TABLE "attendance_records"
DROP CONSTRAINT IF EXISTS "attendance_records_booking_id_fkey";
ALTER TABLE "attendance_records"
ADD CONSTRAINT "attendance_records_booking_id_fkey"
FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE;
