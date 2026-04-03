-- infra/postgres/init.sql
-- Runs once on first container start (before migrations).
-- Creates the two application roles YDBI needs.

-- ydbi_api: used by the API service for all user-facing queries.
-- RLS policies enforce data isolation per user via SET LOCAL app.current_user_id.
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ydbi_api') THEN
    CREATE ROLE ydbi_api LOGIN PASSWORD 'ydbi_api_password';
  END IF;
END
$$;

-- ydbi_service: used by background jobs (memory engine, usage aggregation, etc.)
-- This role bypasses RLS — must NEVER be used in the request path.
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ydbi_service') THEN
    CREATE ROLE ydbi_service LOGIN PASSWORD 'ydbi_service_password' BYPASSRLS;
  END IF;
END
$$;

-- Grant both roles access to the database
GRANT CONNECT ON DATABASE ydbi_dev TO ydbi_api;
GRANT CONNECT ON DATABASE ydbi_dev TO ydbi_service;

-- Schema usage (tables created during migrations will be granted separately)
GRANT USAGE ON SCHEMA public TO ydbi_api;
GRANT USAGE ON SCHEMA public TO ydbi_service;