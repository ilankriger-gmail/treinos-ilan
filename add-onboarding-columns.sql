ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS objetivo_treino TEXT;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS nivel_experiencia TEXT;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS atividades_praticadas JSONB DEFAULT '[]';
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS frequencia_semanal INTEGER;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS restricoes TEXT;
