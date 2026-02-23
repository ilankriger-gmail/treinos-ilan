-- Add objetivo_data JSONB column to store structured goal info
-- { texto, data_alvo, resultado_esperado }
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS objetivo_data JSONB DEFAULT '{}';
