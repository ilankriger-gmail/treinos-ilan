-- ==============================================
-- MIGRAÇÃO MULTI-USUÁRIO COMPLETA - Treino Ilan
-- Segura para rodar em bancos existentes (idempotente)
-- Consolida todas as mudanças necessárias para suporte multi-usuário
-- ==============================================

-- === PART 1: Adicionar user_id em todas as tabelas de dados ===
-- user_profile já tem user_id desde a migração 20260223020000

ALTER TABLE workout_logs
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE workout_sessions
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE calendar_activities
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE user_files
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

-- === PART 2: Atribuir dados existentes ao usuário 1 ===
UPDATE workout_logs      SET user_id = 1 WHERE user_id IS NULL;
UPDATE workout_sessions  SET user_id = 1 WHERE user_id IS NULL;
UPDATE calendar_activities SET user_id = 1 WHERE user_id IS NULL;
UPDATE user_files        SET user_id = 1 WHERE user_id IS NULL;

-- === PART 3: Corrigir constraint única em calendar_activities ===
-- Antes: UNIQUE(date) — global para todos os usuários
-- Depois: UNIQUE(user_id, date) — por usuário
ALTER TABLE calendar_activities DROP CONSTRAINT IF EXISTS calendar_activities_date_key;
DROP INDEX IF EXISTS idx_calendar_user_date;
CREATE UNIQUE INDEX idx_calendar_user_date ON calendar_activities(user_id, date);

-- === PART 4: Garantir todas as colunas do user_profile ===
-- Colunas de sync (cross-device)
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS chat_history      JSONB DEFAULT '{}';
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS workout_progress  JSONB DEFAULT '{}';
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS exercise_configs  JSONB DEFAULT '{}';
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS custom_exercises  JSONB DEFAULT '[]';

-- Colunas de onboarding
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS onboarding_completed    BOOLEAN DEFAULT FALSE;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS nivel_experiencia        TEXT;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS atividades_praticadas    JSONB DEFAULT '[]';
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS restricoes               TEXT;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS objetivo_treino          TEXT;
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS objetivo_data            JSONB DEFAULT '{}';
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS frequencia_semanal       INTEGER;

-- Coluna de vínculo com usuário
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

-- Atribuir perfil existente ao usuário 1
UPDATE user_profile SET user_id = 1 WHERE user_id IS NULL;

-- Corrigir sequência do serial (caso o INSERT explícito tenha travado em 1)
SELECT setval(pg_get_serial_sequence('user_profile', 'id'), COALESCE(MAX(id), 1)) FROM user_profile;

-- === PART 5: Índices de performance ===
CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id   ON workout_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_user_date ON workout_logs(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id       ON workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_date     ON workout_sessions(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_calendar_user_id       ON calendar_activities(user_id);

CREATE INDEX IF NOT EXISTS idx_files_user_id          ON user_files(user_id);

CREATE INDEX IF NOT EXISTS idx_profile_user_id        ON user_profile(user_id);

-- === PART 6: Constraint de unicidade no user_profile (um perfil por usuário) ===
CREATE UNIQUE INDEX IF NOT EXISTS idx_profile_unique_user ON user_profile(user_id);
