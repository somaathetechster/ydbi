-- 013_audit.sql
-- Immutable audit trail for security-sensitive actions.
-- Rows are never updated or deleted — append only.
-- Covers: auth events, subscription changes, org mutations, API key lifecycle, integrations.

CREATE TABLE audit_log (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Actor
  actor_user_id       UUID REFERENCES users (id) ON DELETE SET NULL,
  actor_api_key_id    UUID REFERENCES api_keys (id) ON DELETE SET NULL,
  actor_ip            INET,
  actor_user_agent    TEXT,

  -- Target
  action              audit_action NOT NULL,
  target_type         TEXT,                          -- 'user', 'org', 'subscription', etc.
  target_id           UUID,

  -- Org context
  org_id              UUID REFERENCES organizations (id) ON DELETE SET NULL,

  -- Payload — what changed
  before              JSONB,                         -- state before change (sanitised — no secrets)
  after               JSONB,                         -- state after change

  -- Additional context
  metadata            JSONB NOT NULL DEFAULT '{}',

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lookup by actor
CREATE INDEX idx_audit_actor_user    ON audit_log (actor_user_id, created_at DESC)
  WHERE actor_user_id IS NOT NULL;

-- Lookup by target entity
CREATE INDEX idx_audit_target        ON audit_log (target_type, target_id, created_at DESC)
  WHERE target_id IS NOT NULL;

-- Lookup by org
CREATE INDEX idx_audit_org           ON audit_log (org_id, created_at DESC)
  WHERE org_id IS NOT NULL;

-- Action filter
CREATE INDEX idx_audit_action        ON audit_log (action, created_at DESC);