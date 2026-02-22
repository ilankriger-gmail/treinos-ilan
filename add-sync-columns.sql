-- Sync columns for cross-device data persistence
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS chat_history JSONB DEFAULT '{}';
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS workout_progress JSONB DEFAULT '{}';
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS exercise_configs JSONB DEFAULT '{}';
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS custom_exercises JSONB DEFAULT '[]';
