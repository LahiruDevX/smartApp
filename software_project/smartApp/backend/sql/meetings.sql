CREATE TABLE IF NOT EXISTS meetings (
  id SERIAL PRIMARY KEY,
  subject_id INTEGER REFERENCES subjects(id),
  teacher_id INTEGER REFERENCES users(id),
  title VARCHAR(255) NOT NULL,
  scheduled_at TIMESTAMP NOT NULL,
  duration_minutes INT NOT NULL DEFAULT 45,
  jitsi_room_name TEXT UNIQUE NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'live', 'ended')),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS meeting_attendance (
  id SERIAL PRIMARY KEY,
  meeting_id INTEGER NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  student_id INTEGER NOT NULL REFERENCES users(id),
  joined_at TIMESTAMP,
  left_at TIMESTAMP,
  presence_checks_total INT NOT NULL DEFAULT 0,
  presence_checks_with_face INT NOT NULL DEFAULT 0,
  final_status VARCHAR(10) CHECK (final_status IN ('present', 'absent')),
  UNIQUE (meeting_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_meetings_subject ON meetings(subject_id);
CREATE INDEX IF NOT EXISTS idx_meetings_teacher ON meetings(teacher_id);
CREATE INDEX IF NOT EXISTS idx_meeting_attendance_meeting ON meeting_attendance(meeting_id);
CREATE INDEX IF NOT EXISTS idx_meeting_attendance_student ON meeting_attendance(student_id);
