-- 001_extensions.sql
-- Enable required Postgres extensions before any schema objects.
-- Run once on a fresh database. Safe to re-run (IF NOT EXISTS).

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";        -- gen_random_uuid(), crypt()
CREATE EXTENSION IF NOT EXISTS "vector";          -- pgvector — semantic memory
CREATE EXTENSION IF NOT EXISTS "pg_trgm";         -- trigram indexes for fuzzy search