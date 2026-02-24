-- ==============================================
-- SETUP COMPLETO DO BANCO - Treino Ilan
-- Rodar no Supabase Dashboard > SQL Editor
-- Cria todas as tabelas do zero em um projeto novo
-- Suporte multi-usuário completo
-- ==============================================

-- ORDEM IMPORTANTE:
--   1. users e user_sessions (auth) — sem FK para outros
--   2. Tabelas de dados — com FK para users(id)

-- ==============================================
-- 1. AUTH - USERS
-- Tabela de autenticação: email/senha com hash+salt
-- Política: apenas service_role pode ler/escrever
-- ==============================================
CREATE TABLE users (
  id            SERIAL PRIMARY KEY,
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  salt          TEXT NOT NULL,
  nome          TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  last_login    TIMESTAMPTZ
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role only" ON users FOR ALL USING (auth.role() = 'service_role');
CREATE INDEX idx_users_email ON users(email);

-- ==============================================
-- 2. AUTH - USER SESSIONS
-- Tokens de sessão vinculados a um usuário
-- Política: apenas service_role
-- ==============================================
CREATE TABLE user_sessions (
  id         SERIAL PRIMARY KEY,
  user_id    INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  token      TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL
);

ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role only" ON user_sessions FOR ALL USING (auth.role() = 'service_role');
CREATE INDEX idx_user_sessions_token      ON user_sessions(token);
CREATE INDEX idx_user_sessions_user_id   ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_expires   ON user_sessions(expires_at);

-- ==============================================
-- 3. USER PROFILE
-- Um perfil por usuário: dados pessoais, onboarding,
-- histórico de análises e colunas de sync cross-device
-- ==============================================
CREATE TABLE user_profile (
  id                    SERIAL PRIMARY KEY,
  user_id               INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  updated_at            TIMESTAMPTZ DEFAULT NOW(),

  -- Dados pessoais
  nome                  TEXT,
  idade                 INTEGER,
  altura                INTEGER,
  sexo                  TEXT,

  -- Onboarding
  onboarding_completed  BOOLEAN DEFAULT FALSE,
  nivel_experiencia     TEXT,
  atividades_praticadas JSONB DEFAULT '[]',
  restricoes            TEXT,
  objetivo_treino       TEXT,
  objetivo_data         JSONB DEFAULT '{}',
  frequencia_semanal    INTEGER,

  -- Estado e objetivos legados
  objetivo              TEXT,
  dores                 TEXT,
  estado_hoje           TEXT,

  -- Análises do Coach AI
  ultima_analise        TEXT,
  ultima_analise_at     TIMESTAMPTZ,
  notas_medicas         TEXT DEFAULT '',
  historico_analises    JSONB DEFAULT '[]',

  -- Arquivos associados ao perfil (legado)
  arquivos              JSONB DEFAULT '[]',

  -- Sync cross-device (localStorage espelhado no Supabase)
  chat_history          JSONB DEFAULT '{}',
  workout_progress      JSONB DEFAULT '{}',
  exercise_configs      JSONB DEFAULT '{}',
  custom_exercises      JSONB DEFAULT '[]'
);

-- Um perfil por usuário
CREATE UNIQUE INDEX idx_profile_unique_user ON user_profile(user_id);
CREATE INDEX        idx_profile_user_id     ON user_profile(user_id);

ALTER TABLE user_profile ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON user_profile FOR ALL USING (true) WITH CHECK (true);

-- ==============================================
-- 4. WORKOUT LOGS
-- Registros individuais de exercício (peso/reps)
-- ==============================================
CREATE TABLE workout_logs (
  id            SERIAL PRIMARY KEY,
  user_id       INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  exercise_id   TEXT NOT NULL,
  exercise_name TEXT,
  weight        DECIMAL(5,1),
  reps          INTEGER,
  notes         TEXT
);

ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON workout_logs FOR ALL USING (true) WITH CHECK (true);
CREATE INDEX idx_workout_logs_exercise  ON workout_logs(exercise_id);
CREATE INDEX idx_workout_logs_user_id   ON workout_logs(user_id);
CREATE INDEX idx_workout_logs_user_date ON workout_logs(user_id, created_at DESC);

-- ==============================================
-- 5. WORKOUT SESSIONS
-- Sessões de treino completas com JSONB de exercícios
-- ==============================================
CREATE TABLE workout_sessions (
  id               SERIAL PRIMARY KEY,
  user_id          INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  date             DATE NOT NULL,
  workout_type     TEXT NOT NULL,
  exercises_done   JSONB DEFAULT '[]',
  duration_minutes INTEGER,
  notes            TEXT
);

ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON workout_sessions FOR ALL USING (true) WITH CHECK (true);
CREATE INDEX idx_sessions_user_id   ON workout_sessions(user_id);
CREATE INDEX idx_sessions_user_date ON workout_sessions(user_id, date DESC);

-- ==============================================
-- 6. CALENDAR ACTIVITIES
-- Atividades diárias no calendário (JSONB por dia)
-- Unique: (user_id, date) — cada usuário tem uma entrada por dia
-- ==============================================
CREATE TABLE calendar_activities (
  id         SERIAL PRIMARY KEY,
  user_id    INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  date       DATE NOT NULL,
  activities JSONB DEFAULT '[]'
);

-- Unique por usuário+data (não global)
CREATE UNIQUE INDEX idx_calendar_user_date ON calendar_activities(user_id, date);
CREATE INDEX        idx_calendar_user_id   ON calendar_activities(user_id);

ALTER TABLE calendar_activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON calendar_activities FOR ALL USING (true) WITH CHECK (true);

-- ==============================================
-- 7. USER FILES
-- Arquivos enviados pelo usuário (base64)
-- ==============================================
CREATE TABLE user_files (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL,
  content     TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_files ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON user_files FOR ALL USING (true) WITH CHECK (true);
CREATE INDEX idx_files_user_id ON user_files(user_id);
