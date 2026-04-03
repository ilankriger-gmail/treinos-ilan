-- Add badges_unlocked JSONB column to user_profile
-- Stores {badge_id: {date, timestamp}, ...}
-- Run in Supabase Dashboard > SQL Editor

ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS badges_unlocked JSONB DEFAULT '{}'::jsonb;
