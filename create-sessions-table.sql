-- Criar tabela para sessões de treino completadas
-- Rodar no Supabase Dashboard > SQL Editor

CREATE TABLE workout_sessions (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  date DATE NOT NULL,
  workout_type TEXT NOT NULL,
  exercises_done JSONB DEFAULT '[]',
  duration_minutes INTEGER,
  notes TEXT
);

ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON workout_sessions FOR ALL USING (true);

CREATE INDEX idx_sessions_date ON workout_sessions(date DESC);
