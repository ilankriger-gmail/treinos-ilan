-- Tabela para armazenar arquivos do usuario (imagens, PDFs, TXTs)
-- Executar este SQL no Supabase Dashboard > SQL Editor

CREATE TABLE user_files (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all" ON user_files FOR ALL USING (true) WITH CHECK (true);
