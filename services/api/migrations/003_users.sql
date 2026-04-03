-- 003_users.sql
-- Core user identity. Users are always independent; orgs are optional.
-- Auth identities are separate rows — one user can have multiple providers.

-- ── Users ─────────────────────────────────────────────────────────────────────
CREATE TABLE users (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  email               TEXT NOT NULL UNIQUE,
  display_name        TEXT,
  avatar_url          TEXT,
  timezone            TEXT NOT NULL DEFAULT 'UTC',
  locale              TEXT NOT NULL DEFAULT 'en',

  -- Status
  status              user_status NOT NULL DEFAULT 'active',
  email_verified_at   TIMESTAMPTZ,

  -- Butler persona preferences (stored here for fast access)
  butler_name         TEXT NOT NULL DEFAULT 'Butler',    -- user can rename their Butler
  butler_voice_id     TEXT,                              -- ElevenLabs voice ID override

  -- Timestamps
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ                        -- soft delete
);

CREATE INDEX idx_users_email         ON users (email);
CREATE INDEX idx_users_status        ON users (status) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created_at    ON users (created_at);

-- ── Auth Identities ───────────────────────────────────────────────────────────
-- Each row = one login method for a user.
-- email provider: password_hash is populated.
-- OAuth providers: provider_user_id + access_token populated.

CREATE TABLE auth_identities (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  provider            auth_provider NOT NULL,
  provider_user_id    TEXT,                         -- OAuth subject id
  email               TEXT,                         -- provider email (may differ)

  -- Email/password auth
  password_hash       TEXT,                         -- bcrypt, only for email provider

  -- OAuth tokens
  access_token        TEXT,                         -- encrypted at rest (app-level)
  refresh_token       TEXT,                         -- encrypted at rest
  token_expires_at    TIMESTAMPTZ,

  -- MFA
  totp_secret         TEXT,                         -- TOTP seed, encrypted
  totp_enabled        BOOLEAN NOT NULL DEFAULT FALSE,
  backup_codes        TEXT[],                       -- hashed backup codes

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (provider, provider_user_id),
  UNIQUE (user_id, provider)
);

CREATE INDEX idx_auth_identities_user_id  ON auth_identities (user_id);
CREATE INDEX idx_auth_identities_provider ON auth_identities (provider, provider_user_id);

-- ── API Keys (B2B direct access) ──────────────────────────────────────────────
CREATE TABLE api_keys (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  name                TEXT NOT NULL,                -- "Production key", "Dev key"
  key_prefix          TEXT NOT NULL,                -- first 8 chars, shown in UI: "ydbi_sk_AbCd..."
  key_hash            TEXT NOT NULL UNIQUE,         -- SHA-256 of the full key
  scopes              TEXT[] NOT NULL DEFAULT '{}', -- ["butler:read","tasks:write"] etc.

  last_used_at        TIMESTAMPTZ,
  expires_at          TIMESTAMPTZ,                  -- NULL = never expires
  revoked_at          TIMESTAMPTZ,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_api_keys_user_id   ON api_keys (user_id);
CREATE INDEX idx_api_keys_key_hash  ON api_keys (key_hash);

-- ── Password Reset Tokens ──────────────────────────────────────────────────────
CREATE TABLE password_reset_tokens (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  token_hash          TEXT NOT NULL UNIQUE,
  expires_at          TIMESTAMPTZ NOT NULL,
  used_at             TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_prt_token_hash ON password_reset_tokens (token_hash);
CREATE INDEX idx_prt_user_id    ON password_reset_tokens (user_id);

-- ── Email Verification Tokens ──────────────────────────────────────────────────
CREATE TABLE email_verification_tokens (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  email               TEXT NOT NULL,
  token_hash          TEXT NOT NULL UNIQUE,
  expires_at          TIMESTAMPTZ NOT NULL,
  used_at             TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_evt_token_hash ON email_verification_tokens (token_hash);

-- ── Refresh Token Store ────────────────────────────────────────────────────────
-- Server-side refresh token registry for revocation support.
CREATE TABLE refresh_tokens (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  token_hash          TEXT NOT NULL UNIQUE,
  session_channel     session_channel NOT NULL,
  device_fingerprint  TEXT,                         -- optional client-side fingerprint
  ip_address          INET,
  user_agent          TEXT,
  expires_at          TIMESTAMPTZ NOT NULL,
  revoked_at          TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rt_user_id    ON refresh_tokens (user_id);
CREATE INDEX idx_rt_token_hash ON refresh_tokens (token_hash);
CREATE INDEX idx_rt_expires_at ON refresh_tokens (expires_at);