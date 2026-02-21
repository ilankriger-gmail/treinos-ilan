# Treinos Ilan

App pessoal de acompanhamento de treinos de academia, atividades físicas e evolução corporal.

## Stack

- **Frontend**: HTML/CSS/JS puro em arquivo único (`index.html`) — sem framework, sem bundler
- **Backend**: Vercel Edge Function (`api/analyze.js`) — proxy para Gemini AI
- **Banco de dados**: Supabase (PostgreSQL) acessado diretamente via REST API do frontend
- **Deploy**: Vercel
- **Idioma**: Português brasileiro (PT-BR) em toda a interface e código

## Estrutura

```
index.html              # App inteiro (HTML + CSS + JS inline)
api/analyze.js          # Edge function — envia prompts para Gemini 1.5 Flash
create-table.sql        # Tabela workout_logs (registro de pesos/reps)
create-sessions-table.sql   # Tabela workout_sessions (sessões completadas)
create-profile-table.sql    # Tabela user_profile (perfil + análise IA)
create-calendar-table.sql   # Tabela calendar_activities (calendário)
add-columns.sql         # Migrations adicionais
add-profile-columns.sql # Migrations de perfil
```

## Banco de dados (Supabase)

### Tabelas

- **workout_logs**: Registros individuais de exercícios (exercise_id, weight, reps, notes)
- **workout_sessions**: Sessões de treino completas (date, workout_type, exercises_done JSONB, duration_minutes)
- **user_profile**: Perfil único (id=1) com objetivo, dores, estado_hoje, arquivos, ultima_analise
- **calendar_activities**: Atividades diárias no calendário (date, activities JSONB)

Todas as tabelas têm RLS habilitado com políticas permissivas (acesso anônimo).

## Funcionalidades

- Registro de treinos com peso/repetições por exercício
- Calendário de atividades (musculação, corrida, fisio, funcional, etc.)
- Perfil com objetivo, dores e estado diário
- Análise de IA (Gemini) baseada no histórico de treinos
- Histórico de sessões completadas

## Dev local

```bash
vercel dev
```

Roda na porta 3000 (ou especificar com `--listen <porta>`). Necessário Vercel CLI instalado e autenticado.

## Convenções

- Tudo em um arquivo (`index.html`): HTML, CSS e JS inline — manter essa estrutura
- CSS usa variáveis em `:root` com tema escuro (roxo/cinza)
- JS vanilla, sem dependências npm no frontend
- Supabase é acessado direto via fetch no frontend (REST API)
- A API de análise (`/api/analyze`) é um proxy para Gemini — recebe `{ prompt }` e retorna `{ content }`
