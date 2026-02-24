-- Add coaching columns to user_profile
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS peso NUMERIC(5,1);
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS onboarding_at TIMESTAMPTZ;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS last_daily_message_date TEXT;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS last_weekly_review_date TEXT;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS daily_message_cache JSONB DEFAULT '{}';

-- Backfill onboarding_at for users who already completed onboarding
UPDATE user_profile SET onboarding_at = updated_at
WHERE onboarding_completed = TRUE AND onboarding_at IS NULL;
