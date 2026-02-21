-- Criar tabela para registros de treino
-- Rodar no Supabase Dashboard > SQL Editor

CREATE TABLE IF NOT EXISTS workout_logs (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  exercise_id TEXT NOT NULL,
  exercise_name TEXT,
  weight DECIMAL(5,1),
  reps INTEGER,
  notes TEXT
);

-- Permitir acesso anônimo
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous read" ON workout_logs FOR SELECT USING (true);
CREATE POLICY "Allow anonymous insert" ON workout_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anonymous update" ON workout_logs FOR UPDATE USING (true);
CREATE POLICY "Allow anonymous delete" ON workout_logs FOR DELETE USING (true);

-- Index para buscar por exercício
CREATE INDEX idx_workout_logs_exercise ON workout_logs(exercise_id);
CREATE INDEX idx_workout_logs_date ON workout_logs(created_at DESC);

COMMENT ON TABLE workout_logs IS 'Registro de pesos e treinos do Ilan';
