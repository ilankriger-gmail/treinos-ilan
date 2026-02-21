-- Criar tabela para perfil e análises de IA
-- Rodar no Supabase Dashboard > SQL Editor

CREATE TABLE user_profile (
  id SERIAL PRIMARY KEY,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  objetivo TEXT,
  dores TEXT,
  estado_hoje TEXT,
  arquivos JSONB DEFAULT '[]',
  ultima_analise TEXT,
  ultima_analise_at TIMESTAMPTZ
);

-- Inserir registro inicial
INSERT INTO user_profile (id, objetivo, dores) VALUES (1, '', '');

ALTER TABLE user_profile ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON user_profile FOR ALL USING (true);
