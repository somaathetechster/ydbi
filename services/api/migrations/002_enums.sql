-- 002_enums.sql
-- All domain enumerations in one place.
-- Adding values to an enum later requires ALTER TYPE ... ADD VALUE — do it here.

-- ── User & Auth ─────────────────────────────────────────────────────────────
CREATE TYPE user_status AS ENUM (
  'active',
  'suspended',
  'deleted'
);

CREATE TYPE auth_provider AS ENUM (
  'email',        -- email + password
  'google',
  'apple'
);

-- ── Billing & Tiers ──────────────────────────────────────────────────────────
CREATE TYPE subscription_tier AS ENUM (
  'free',
  'pro',          -- consumer paid
  'team',         -- B2B base
  'enterprise'    -- B2B custom
);

CREATE TYPE subscription_status AS ENUM (
  'active',
  'past_due',
  'cancelled',
  'trialing',
  'paused'
);

CREATE TYPE billing_interval AS ENUM (
  'monthly',
  'annual'
);

-- ── Organizations ─────────────────────────────────────────────────────────────
CREATE TYPE org_role AS ENUM (
  'owner',
  'admin',
  'member'
);

CREATE TYPE org_plan AS ENUM (
  'team',
  'enterprise'
);

-- ── Butler & Sessions ─────────────────────────────────────────────────────────
CREATE TYPE butler_state AS ENUM (
  'dormant',
  'ambient',
  'listening',
  'processing',
  'speaking',
  'confirming'
);

CREATE TYPE session_channel AS ENUM (
  'web',
  'ios',
  'android',
  'api'         -- direct API key access (B2B)
);

-- ── Memory ────────────────────────────────────────────────────────────────────
CREATE TYPE memory_tier AS ENUM (
  'session',       -- ephemeral, cleared on session end
  'episodic',      -- persistent key facts and events
  'behavioural'    -- usage patterns, silently updated
);

CREATE TYPE memory_status AS ENUM (
  'active',
  'archived',
  'deleted'
);

-- ── Tasks ─────────────────────────────────────────────────────────────────────
CREATE TYPE task_status AS ENUM (
  'pending',
  'in_progress',
  'completed',
  'cancelled'
);

CREATE TYPE task_priority AS ENUM (
  'low',
  'medium',
  'high',
  'urgent'
);

-- ── Voice ─────────────────────────────────────────────────────────────────────
CREATE TYPE voice_session_status AS ENUM (
  'active',
  'completed',
  'failed',
  'timed_out'
);

-- ── Usage / Metering ──────────────────────────────────────────────────────────
CREATE TYPE usage_metric AS ENUM (
  'ai_message',      -- one Claude API round-trip
  'voice_second'     -- one second of voice session (STT + TTS combined)
);

-- ── Integrations ──────────────────────────────────────────────────────────────
CREATE TYPE integration_provider AS ENUM (
  'google_calendar',
  'google_gmail',
  'slack',
  'webhook'         -- generic outbound webhook
);

CREATE TYPE integration_status AS ENUM (
  'active',
  'token_expired',
  'revoked',
  'error'
);

-- ── Audit ─────────────────────────────────────────────────────────────────────
CREATE TYPE audit_action AS ENUM (
  'user.created',
  'user.updated',
  'user.deleted',
  'user.login',
  'user.logout',
  'subscription.created',
  'subscription.upgraded',
  'subscription.cancelled',
  'org.created',
  'org.member_added',
  'org.member_removed',
  'api_key.created',
  'api_key.revoked',
  'integration.connected',
  'integration.revoked'
);