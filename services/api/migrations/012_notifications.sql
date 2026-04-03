-- 012_notifications.sql
-- Outbound notifications from Butler to user.
-- Covers push (mobile), in-app, and email channels.
-- Butler-generated proactive alerts are first-class notifications.

CREATE TABLE notifications (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  -- Content
  title               TEXT NOT NULL,
  body                TEXT NOT NULL,
  action_url          TEXT,                          -- deep link / URL on tap

  -- Source
  is_butler           BOOLEAN NOT NULL DEFAULT FALSE, -- true = Butler-initiated proactive alert
  source_session_id   UUID REFERENCES butler_sessions (id) ON DELETE SET NULL,
  source_task_id      UUID REFERENCES tasks (id) ON DELETE SET NULL,

  -- Delivery
  channel             TEXT NOT NULL DEFAULT 'in_app', -- 'in_app' | 'push' | 'email'
  sent_at             TIMESTAMPTZ,
  read_at             TIMESTAMPTZ,
  dismissed_at        TIMESTAMPTZ,

  -- Push-specific
  push_token_id       UUID,                          -- references push_tokens.id

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_unread
  ON notifications (user_id, created_at DESC)
  WHERE read_at IS NULL AND dismissed_at IS NULL;

CREATE INDEX idx_notifications_source_task
  ON notifications (source_task_id)
  WHERE source_task_id IS NOT NULL;

-- ── Device Push Tokens ─────────────────────────────────────────────────────────
CREATE TABLE push_tokens (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  token               TEXT NOT NULL UNIQUE,
  platform            TEXT NOT NULL,                 -- 'ios' | 'android'
  app_version         TEXT,
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,

  last_used_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_push_tokens_user_id ON push_tokens (user_id, is_active)
  WHERE is_active = TRUE;

-- Back-reference from notifications.push_token_id
ALTER TABLE notifications
  ADD CONSTRAINT fk_notifications_push_token
  FOREIGN KEY (push_token_id) REFERENCES push_tokens (id) ON DELETE SET NULL;