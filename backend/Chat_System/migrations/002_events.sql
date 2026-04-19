CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Minimal events table required by chat_rooms.event_id foreign key.
-- This can later be replaced by a proper Events service sync strategy.
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(200) NOT NULL,
  cover_photo VARCHAR(500),
  starts_at TIMESTAMP,
  ends_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_created_at ON events(created_at DESC);
