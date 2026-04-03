# YDBI — Your Digital Butler Intelligence

A Domani in-house product. An intelligent environment engine that surrounds, listens, and executes.

---

## Prerequisites

| Tool | Version |
|---|---|
| Node.js | ≥ 20.0.0 |
| pnpm | ≥ 10.0.0 |
| Docker + Docker Compose | latest |

Install pnpm if not already installed:
```bash
npm install -g pnpm
```

---

## First-time setup

### 1. Clone and install dependencies

```bash
git clone <repo-url> ydbi
cd ydbi
pnpm install
```

### 2. Configure environment

```bash
cp .env.example .env
```

Open `.env` and fill in:
- `JWT_SECRET` — generate with `openssl rand -base64 64`
- `TOKEN_ENCRYPTION_KEY` — generate with `openssl rand -hex 32`
- `ANTHROPIC_API_KEY` — from console.anthropic.com
- `OPENAI_API_KEY` — for Whisper STT
- `ELEVENLABS_API_KEY` — for Butler TTS voice

Everything else has working defaults for local dev.

### 3. Start infrastructure

```bash
pnpm docker:up
```

This starts:
- **PostgreSQL 16 + pgvector** on `localhost:5432`
- **Redis 7** on `localhost:6379`
- **MinIO** (S3-compatible storage) on `localhost:9000` — console at `localhost:9001`
- **Mailpit** (email dev server) on `localhost:1025` — UI at `localhost:8025`

Wait for Postgres to be healthy before running migrations (usually ~5 seconds).

### 4. Run migrations

```bash
pnpm migrate
```

This applies all 16 migrations in order against the local database. Safe to re-run — already-applied migrations are skipped.

### 5. Start development servers

```bash
pnpm dev
```

| Service | URL |
|---|---|
| Web app | http://localhost:3000 |
| API | http://localhost:3001 |
| API health | http://localhost:3001/health |

---

## Project structure

```
ydbi/
├── apps/
│   ├── web/              Next.js 15 — Butler web experience
│   ├── ios/              Swift + SwiftUI — native iOS
│   └── android/          Kotlin + Jetpack Compose — native Android
│
├── packages/
│   ├── sdk/              Shared types, API client, i18n
│   ├── butler-core/      Butler state machine, intent classifier, emotional register
│   └── ui-tokens/        Design tokens — colors, motion, spacing
│
├── services/
│   ├── api/              Fastify API gateway, auth, orchestration
│   │   ├── migrations/   16 Postgres migrations (Phase 1)
│   │   └── src/          Application source
│   ├── voice/            Whisper STT + ElevenLabs TTS pipeline
│   └── memory/           pgvector memory engine
│
└── infra/
    ├── docker/           docker-compose.yml for local dev
    └── postgres/         init.sql — DB roles
```

---

## Database

### Migration commands

```bash
# Apply all pending migrations
pnpm migrate

# Create a new migration file
pnpm migrate:create -- --name your_migration_name

# Roll back one migration
pnpm --filter @ydbi/api migrate:down

# Check migration status
pnpm --filter @ydbi/api migrate:status
```

### Connecting directly

```bash
# psql
psql postgresql://ydbi:ydbi_dev_password@localhost:5432/ydbi_dev

# Or via docker
docker exec -it ydbi_postgres psql -U ydbi -d ydbi_dev
```

### Reset everything (nuclear)

```bash
pnpm docker:reset   # destroys volumes, recreates containers
pnpm migrate        # re-applies all migrations from scratch
```

---

## Infrastructure services

### MinIO (object storage)
Console: http://localhost:9001
Credentials: `ydbi_dev` / `ydbi_dev_secret`
Buckets created automatically: `ydbi-audio`, `ydbi-attachments`

### Mailpit (email)
All outbound emails in development are captured here: http://localhost:8025
No emails actually leave your machine.

### Redis
```bash
docker exec -it ydbi_redis redis-cli
```

---

## Architecture phases

| Phase | Status | Description |
|---|---|---|
| 1 | ✅ Complete | Postgres schema — 29 tables, 16 migrations, RLS, views |
| 2 | Next | API gateway + auth (JWT, OAuth, refresh tokens) |
| 3 | Planned | Butler orchestration engine + Claude API voice loop |
| 4 | Planned | Web client — Butler Three.js core, all 7 presence states |
| 5 | Planned | iOS + Android native clients |
| 6 | Planned | Task + calendar service |
| 7 | Planned | Memory engine (pgvector, semantic retrieval) |
| 8 | Planned | Usage engine + Stripe billing |

---

## Tech stack

| Layer | Technology |
|---|---|
| Web | Next.js 15, Three.js / R3F, Framer Motion |
| iOS | Swift, SwiftUI |
| Android | Kotlin, Jetpack Compose |
| API | Node.js, Fastify |
| AI | Anthropic Claude API (streaming + tool use) |
| STT | OpenAI Whisper |
| TTS | ElevenLabs |
| Database | PostgreSQL 16 + pgvector |
| Cache | Redis 7 |
| Storage | S3-compatible (MinIO in dev) |
| Billing | Stripe |

---

## Environment variables

See `.env.example` for the full documented list with generation instructions for secrets.

---

*YDBI is a Domani in-house product. Not related to Infinitswap.*