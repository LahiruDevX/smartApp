-- The /api/devices routes (src/routes/device.routes.js) use a raw pg pool and
-- expect this table. It is NOT managed by Prisma. Run once against the smartapp DB:
--   psql -U postgres -d smartapp -f backend/sql/devices.sql

CREATE TABLE IF NOT EXISTS devices (
  id           TEXT PRIMARY KEY,
  title        TEXT NOT NULL,
  is_on        BOOLEAN NOT NULL DEFAULT false,
  slider_value INTEGER
);

-- device_type/online/updated_at were added later (src/routes/device.routes.js
-- reads/writes all three); guarded so re-running this file on an older table
-- backfills them instead of erroring.
ALTER TABLE devices ADD COLUMN IF NOT EXISTS device_type TEXT NOT NULL DEFAULT 'monitor';
ALTER TABLE devices ADD COLUMN IF NOT EXISTS online BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

INSERT INTO devices (id, title, is_on, slider_value, device_type) VALUES
  ('main_lights',      'Main Lights',      true,  80,   'bulb'),
  ('board_lights',     'Board Lights',     true,  100,  'bulb'),
  ('projector',        'Projector',        false, NULL, 'monitor'),
  ('hvac',             'HVAC System',      true,  22,   'fan'),
  ('audio',            'Audio System',     false, NULL, 'monitor'),
  ('emergency_lights', 'Emergency Lights', true,  50,   'bulb')
ON CONFLICT (id) DO UPDATE SET device_type = EXCLUDED.device_type;
