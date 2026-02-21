-- Adicionar colunas para informações médicas e histórico de análises
-- Rodar no Supabase Dashboard > SQL Editor

ALTER TABLE user_profile 
ADD COLUMN IF NOT EXISTS notas_medicas TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS historico_analises JSONB DEFAULT '[]';
