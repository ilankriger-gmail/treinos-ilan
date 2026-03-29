-- Add workout_history JSONB column to user_profile for storing workout backups
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS workout_history JSONB DEFAULT '[]'::jsonb;
