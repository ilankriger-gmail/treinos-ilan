-- Adicionar colunas de perfil na tabela user_profile
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS nome TEXT;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS idade INTEGER;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS altura INTEGER;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS sexo TEXT;
