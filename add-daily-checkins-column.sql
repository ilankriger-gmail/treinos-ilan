-- Add daily_checkins JSONB column to user_profile
-- Stores array of {date, energia, sono, stress, dor, timestamp}
-- Run in Supabase Dashboard > SQL Editor

ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS daily_checkins JSONB DEFAULT '[]'::jsonb;
