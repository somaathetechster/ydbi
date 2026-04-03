-- 011_integrations.sql
-- Per-user OAuth integrations (Google Calendar, Gmail, Slack, webhooks).
-- Tokens are encrypted at the application layer before storage.
-- One row per provider per user — only one active connection per provider allowed.

CREATE TABLE user_integrations (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  provider              integration_provider NOT NULL,
  status                integration_status NOT NULL DEFAULT 'active',

  -- OAuth credentials (encrypted at application layer — stored as ciphertext)
  access_token_enc      TEXT,                         -- AES-256-GCM ciphertext
  refresh_token_enc     TEXT,
  token_expires_at      TIMESTAMPTZ,
  token_scope           TEXT[],                       -- granted OAuth scopes

  -- Provider-specific metadata
  provider_account_id   TEXT,                         -- e.g. Google account sub
  provider_account_email TEXT,
  provider_metadata     JSONB NOT NULL DEFAULT '{}',  -- calendar IDs, channel IDs, etc.

  -- Webhook-specific (for integration_provider='webhook')
  webhook_url           TEXT,
  webhook_secret_enc    TEXT,                         -- HMAC signing secret, encrypted

  -- Sync state
  last_synced_at        TIMESTAMPTZ,
  sync_cursor           TEXT,                         -- provider-specific pagination token

  -- Error tracking
  last_error            TEXT,
  error_count           INTEGER NOT NULL DEFAULT 0,
  last_error_at         TIMESTAMPTZ,

  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, provider)
);

CREATE INDEX idx_integrations_user_id    ON user_integrations (user_id);
CREATE INDEX idx_integrations_provider   ON user_integrations (provider, status);
CREATE INDEX idx_integrations_sync       ON user_integrations (last_synced_at)
  WHERE status = 'active';

-- Back-reference from tasks.integration_id
ALTER TABLE tasks
  ADD CONSTRAINT fk_tasks_integration
  FOREIGN KEY (integration_id) REFERENCES user_integrations (id) ON DELETE SET NULL;

-- ── Integration Sync Log ──────────────────────────────────────────────────────
CREATE TABLE integration_sync_log (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_id      UUID NOT NULL REFERENCES user_integrations (id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  sync_type           TEXT NOT NULL,                 -- 'full', 'incremental'
  records_synced      INTEGER NOT NULL DEFAULT 0,
  duration_ms         INTEGER,
  error               TEXT,

  started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at        TIMESTAMPTZ
);

CREATE INDEX idx_sync_log_integration ON integration_sync_log (integration_id, started_at DESC);