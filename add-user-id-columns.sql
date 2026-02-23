-- Add user_id column to all data tables for per-user data isolation
-- Run in Supabase Dashboard > SQL Editor

-- Add user_id to user_profile
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id);

-- Add user_id to calendar_activities
ALTER TABLE calendar_activities ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id);

-- Add user_id to workout_logs
ALTER TABLE workout_logs ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id);

-- Add user_id to workout_sessions
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id);

-- Add user_id to user_files
ALTER TABLE user_files ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id);

-- Assign existing data to user 1 (the original user)
UPDATE user_profile SET user_id = 1 WHERE user_id IS NULL;
UPDATE calendar_activities SET user_id = 1 WHERE user_id IS NULL;
UPDATE workout_logs SET user_id = 1 WHERE user_id IS NULL;
UPDATE workout_sessions SET user_id = 1 WHERE user_id IS NULL;
UPDATE user_files SET user_id = 1 WHERE user_id IS NULL;

-- Fix calendar_activities unique constraint (was unique per date globally, now per user+date)
ALTER TABLE calendar_activities DROP CONSTRAINT IF EXISTS calendar_activities_date_key;
CREATE UNIQUE INDEX IF NOT EXISTS idx_calendar_user_date ON calendar_activities(user_id, date);

-- Create indexes for user_id filtering
CREATE INDEX IF NOT EXISTS idx_profile_user_id ON user_profile(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_user_id ON calendar_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id ON workout_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_files_user_id ON user_files(user_id);
