CREATE TABLE "devices" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "device_type" TEXT NOT NULL,
    "is_on" BOOLEAN NOT NULL DEFAULT false,
    "slider_value" INTEGER,
    "online" BOOLEAN NOT NULL DEFAULT true,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "devices_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "devices_type_check" CHECK ("device_type" IN ('fan', 'bulb', 'rfid')),
    CONSTRAINT "devices_value_check" CHECK (
        ("device_type" = 'fan' AND "slider_value" BETWEEN 1 AND 3) OR
        ("device_type" = 'bulb' AND "slider_value" BETWEEN 0 AND 100) OR
        ("device_type" = 'rfid' AND "slider_value" IS NULL)
    )
);

INSERT INTO "devices" ("id", "title", "device_type", "is_on", "slider_value", "online")
VALUES
    ('fan', 'Classroom Fan', 'fan', false, 2, true),
    ('bulb', 'Classroom Light', 'bulb', true, 80, true),
    ('rfid_reader', 'RFID Attendance Tracker', 'rfid', true, NULL, true);

CREATE TABLE "students" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "student_code" TEXT NOT NULL,
    "email" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "students_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "face_descriptors" (
    "id" SERIAL NOT NULL,
    "student_id" INTEGER NOT NULL,
    "descriptor" DOUBLE PRECISION[] NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "face_descriptors_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "attendance_records" (
    "id" SERIAL NOT NULL,
    "student_id" INTEGER NOT NULL,
    "method" TEXT NOT NULL DEFAULT 'facial',
    "status" TEXT NOT NULL DEFAULT 'present',
    "session_date" DATE NOT NULL DEFAULT CURRENT_DATE,
    "recorded_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "attendance_records_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "attendance_method_check" CHECK ("method" IN ('facial', 'rfid', 'manual')),
    CONSTRAINT "attendance_status_check" CHECK ("status" IN ('present', 'late'))
);

CREATE UNIQUE INDEX "students_student_code_key" ON "students"("student_code");
CREATE INDEX "face_descriptors_student" ON "face_descriptors"("student_id");
CREATE UNIQUE INDEX "attendance_records_student_id_session_date_key"
ON "attendance_records"("student_id", "session_date");
CREATE INDEX "attendance_records_date" ON "attendance_records"("session_date");

ALTER TABLE "face_descriptors"
ADD CONSTRAINT "face_descriptors_student_id_fkey"
FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "attendance_records"
ADD CONSTRAINT "attendance_records_student_id_fkey"
FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;
