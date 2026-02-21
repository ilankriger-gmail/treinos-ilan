-- Criar tabela para atividades do calendário
-- Rodar no Supabase Dashboard > SQL Editor

CREATE TABLE calendar_activities (
  id SERIAL PRIMARY KEY,
  date DATE NOT NULL UNIQUE,
  activities JSONB DEFAULT '[]'
);

ALTER TABLE calendar_activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON calendar_activities FOR ALL USING (true);

CREATE INDEX idx_calendar_date ON calendar_activities(date);
