-- 015_rls.sql
-- Row Level Security policies.
-- These enforce data isolation at the database layer — not just application layer.
-- All policies follow the same pattern: users can only see their own data.
-- Org data is visible to org members with appropriate roles.
--
-- IMPORTANT: The API service connects as a dedicated role 'ydbi_api' (not superuser).
-- Service-level operations (webhooks, background jobs) use 'ydbi_service' role
-- which bypasses RLS via SECURITY DEFINER functions where needed.

-- ── Enable RLS on all user-scoped tables ──────────────────────────────────────
ALTER TABLE users                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_identities       ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys              ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_memory        ENABLE ROW LEVEL SECURITY;
ALTER TABLE episodic_memories     ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavioural_memory    ENABLE ROW LEVEL SECURITY;
ALTER TABLE butler_sessions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_turns    ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_sessions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_segments        ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_integrations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications         ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens           ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_events          ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_period_totals   ENABLE ROW LEVEL SECURITY;
ALTER TABLE memory_injections     ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens        ENABLE ROW LEVEL SECURITY;

-- ── Helper: current authenticated user ───────────────────────────────────────
-- The API sets this at the start of every transaction:
--   SET LOCAL app.current_user_id = '<uuid>';
-- RLS policies read it via this function.
CREATE OR REPLACE FUNCTION current_user_id()
RETURNS UUID AS $$
  SELECT NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID;
$$ LANGUAGE SQL STABLE;

-- ── Users ─────────────────────────────────────────────────────────────────────
CREATE POLICY users_self ON users
  FOR ALL USING (id = current_user_id());

-- ── Auth Identities ───────────────────────────────────────────────────────────
CREATE POLICY auth_identities_own ON auth_identities
  FOR ALL USING (user_id = current_user_id());

-- ── API Keys ──────────────────────────────────────────────────────────────────
CREATE POLICY api_keys_own ON api_keys
  FOR ALL USING (user_id = current_user_id());

-- ── Subscriptions ────────────────────────────────────────────────────────────
CREATE POLICY subscriptions_own ON subscriptions
  FOR ALL USING (
    user_id = current_user_id()
    OR org_id IN (
      SELECT org_id FROM org_memberships
      WHERE user_id = current_user_id()
        AND removed_at IS NULL
    )
  );

-- ── Sessions ──────────────────────────────────────────────────────────────────
CREATE POLICY butler_sessions_own ON butler_sessions
  FOR ALL USING (user_id = current_user_id());

CREATE POLICY conversation_turns_own ON conversation_turns
  FOR ALL USING (user_id = current_user_id());

CREATE POLICY voice_sessions_own ON voice_sessions
  FOR ALL USING (user_id = current_user_id());

CREATE POLICY voice_segments_own ON voice_segments
  FOR ALL USING (
    voice_session_id IN (
      SELECT id FROM voice_sessions WHERE user_id = current_user_id()
    )
  );

-- ── Memory ────────────────────────────────────────────────────────────────────
CREATE POLICY session_memory_own ON session_memory
  FOR ALL USING (user_id = current_user_id());

CREATE POLICY episodic_memories_own ON episodic_memories
  FOR ALL USING (user_id = current_user_id());

CREATE POLICY behavioural_memory_own ON behavioural_memory
  FOR ALL USING (user_id = current_user_id());

CREATE POLICY memory_injections_own ON memory_injections
  FOR ALL USING (user_id = current_user_id());

-- ── Tasks — own + org members ────────────────────────────────────────────────
CREATE POLICY tasks_own_or_org ON tasks
  FOR ALL USING (
    user_id = current_user_id()
    OR assigned_to = current_user_id()
    OR (
      org_id IS NOT NULL
      AND org_id IN (
        SELECT org_id FROM org_memberships
        WHERE user_id = current_user_id()
          AND removed_at IS NULL
      )
    )
  );

CREATE POLICY task_comments_own_task ON task_comments
  FOR ALL USING (
    task_id IN (
      SELECT id FROM tasks  -- uses tasks policy above transitively
      WHERE user_id = current_user_id()
         OR assigned_to = current_user_id()
    )
  );

-- ── Integrations, Notifications, Push Tokens ─────────────────────────────────
CREATE POLICY integrations_own ON user_integrations
  FOR ALL USING (user_id = current_user_id());

CREATE POLICY notifications_own ON notifications
  FOR ALL USING (user_id = current_user_id());

CREATE POLICY push_tokens_own ON push_tokens
  FOR ALL USING (user_id = current_user_id());

-- ── Usage ─────────────────────────────────────────────────────────────────────
CREATE POLICY usage_events_own ON usage_events
  FOR ALL USING (user_id = current_user_id());

CREATE POLICY usage_period_totals_own ON usage_period_totals
  FOR ALL USING (user_id = current_user_id());

-- ── Refresh Tokens ─────────────────────────────────────────────────────────────
CREATE POLICY refresh_tokens_own ON refresh_tokens
  FOR ALL USING (user_id = current_user_id());

-- ── Org Memberships — visible to all org members ──────────────────────────────
ALTER TABLE org_memberships ENABLE ROW LEVEL SECURITY;
CREATE POLICY org_memberships_visible ON org_memberships
  FOR SELECT USING (
    org_id IN (
      SELECT org_id FROM org_memberships m2
      WHERE m2.user_id = current_user_id()
        AND m2.removed_at IS NULL
    )
  );
CREATE POLICY org_memberships_self ON org_memberships
  FOR ALL USING (user_id = current_user_id());

-- ── Service bypass (ydbi_service role skips RLS for background jobs) ──────────
-- Grant ydbi_service BYPASSRLS in production:
--   ALTER ROLE ydbi_service BYPASSRLS;
-- This comment documents the intent; actual role creation is in infra provisioning scripts.