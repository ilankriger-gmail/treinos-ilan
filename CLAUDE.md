# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development

```bash
vercel dev                    # Start local dev server (port 3000)
vercel dev --listen 3001      # Alternate port
```

Requires Vercel CLI installed and authenticated. No build step, no bundler, no npm dependencies for frontend.

## Architecture

Single-file web app (`index.html`, ~6400 lines) with all HTML, CSS, and JS inline. **Never split this into separate files.**

### Stack
- **Frontend**: Vanilla HTML/CSS/JS in `index.html` — no framework
- **API**: `api/analyze.js` — Vercel Edge Function proxying to Anthropic Claude API (`claude-sonnet-4-5-20250929`)
- **Database**: Supabase PostgreSQL via REST API (direct fetch from frontend, anon key)
- **Language**: All UI text and code comments in PT-BR

### Views & Navigation
Three main views controlled by `showView(view)` using `tabMap {coach:0, calendar:1, workouts:2}`:
- **Coach** — AI chat interface ("Coach AI") with collapsible profile
- **Calendar** — Monthly calendar with daily activities
- **Workouts** — Exercise tracking with sub-tabs (Braço, Peito, Costas, Perna, Ombro, Cardio, Surf, Tenis, Fisio)

### Key Subsystems

**Set-by-Set Tracking**: Each exercise has `.sets-container` → `.set-row` elements. `toggleSet()` marks sets done and auto-copies weight/reps to next set. Progress bar counts done set-rows / total set-rows.

**AI Coach Chat**: Multi-turn conversation stored in `chatMessages[]`. System prompt built dynamically by `buildSystemPrompt()` with workout data from `buildDynamicWorkoutText()`. Commands `/ajuda`, `/treino`, `/relatorio`, `/reset` intercepted in `sendChatMessage()`. Suggestions use `<suggestion>` XML blocks parsed from responses.

**Cross-Device Sync**: 4 JSONB columns on `user_profile` (chat_history, workout_progress, exercise_configs, custom_exercises). Pattern: save to localStorage (cache) + fire-and-forget PATCH to Supabase. Load: try Supabase first → fallback localStorage.

**Exercise Images**: Local GIF files in `exercises/gifs/`, metadata in `exercises/data.json`. Loaded async after 1s delay. Dump script: `scripts/dump-exercisedb.js`.

### API Format
`POST /api/analyze` accepts either:
- Multi-turn: `{ messages: [...], system: "..." }`
- Legacy: `{ prompt: "..." }`

Returns: `{ content: "..." }`

### Database Tables (Supabase)
- `workout_logs` — individual exercise weight/reps
- `workout_sessions` — completed sessions (exercises_done JSONB, duration_minutes)
- `user_profile` — single row (id=1), profile + sync data + analysis history
- `calendar_activities` — daily activities by date (JSONB)
- `user_files` — uploaded files (base64 content)

All tables have RLS enabled with permissive policies (anonymous access).

### Init Sequence (DOMContentLoaded)
`loadCustomExercises()` → `initExerciseControls()` → `loadUploadedFiles()` → `loadProgress()` → `loadLastWeights()` → `migrateLocalDataToCloud()` → `selectDate()` → `Promise.all([loadActivities(), loadProfile()])` → `renderDashboardCards()` → delayed `loadExerciseImages()`

## Conventions

- CSS variables in `:root` — obsidian dark theme (#1e1e1e, #262626, #2e2e2e), accent #7f6df2
- Flat design only: no glassmorphism, no gradients, no box-shadows, no glow effects
- Accent color used ONLY in: progress bar, user chat bubble, CTA buttons, active timer
- `index.html` must be read in sections using offset/limit (too large for single read)
- `selectedDate` is shared state used by saveActivities — save/restore when modifying from suggestions
- `event.stopPropagation()` required on inputs inside collapsible profile header

## SQL Migrations
Migration files are in the root directory (`create-*.sql`, `add-*.sql`). Run against Supabase directly. Latest: `add-sync-columns.sql` adds JSONB sync columns to user_profile.
