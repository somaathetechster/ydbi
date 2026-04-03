-- 016_views.sql
-- Convenience views for the most common query patterns.
-- Views are security-definers are NOT used here — RLS on base tables is sufficient.

-- ── Active user subscription + tier limits (hot path) ─────────────────────────
CREATE VIEW v_user_subscription AS
SELECT
  u.id                          AS user_id,
  u.email,
  u.display_name,
  u.status                      AS user_status,
  s.id                          AS subscription_id,
  s.tier,
  s.status                      AS subscription_status,
  s.current_period_start,
  s.current_period_end,
  tl.ai_messages_limit,
  tl.voice_seconds_limit,
  tl.max_integrations,
  tl.max_tasks,
  tl.max_api_keys
FROM users u
LEFT JOIN subscriptions s
  ON s.user_id = u.id
  AND s.status IN ('active', 'trialing', 'past_due')
LEFT JOIN tier_limits tl ON tl.tier = COALESCE(s.tier, 'free')
WHERE u.deleted_at IS NULL;

-- ── Current period usage summary ──────────────────────────────────────────────
CREATE VIEW v_user_usage_summary AS
SELECT
  vs.user_id,
  vs.tier,
  vs.current_period_start,
  vs.current_period_end,
  vs.ai_messages_limit,
  vs.voice_seconds_limit,
  COALESCE(upt_ai.total, 0)                   AS ai_messages_used,
  COALESCE(upt_voice.total, 0)                AS voice_seconds_used,
  GREATEST(0, COALESCE(vs.ai_messages_limit, 0)    - COALESCE(upt_ai.total, 0))    AS ai_messages_remaining,
  GREATEST(0, COALESCE(vs.voice_seconds_limit, 0)  - COALESCE(upt_voice.total, 0)) AS voice_seconds_remaining,
  -- NULL limit = unlimited
  (vs.ai_messages_limit IS NULL)              AS ai_messages_unlimited,
  (vs.voice_seconds_limit IS NULL)            AS voice_seconds_unlimited
FROM v_user_subscription vs
LEFT JOIN usage_period_totals upt_ai
  ON upt_ai.user_id      = vs.user_id
  AND upt_ai.metric      = 'ai_message'
  AND upt_ai.period_start = vs.current_period_start
LEFT JOIN usage_period_totals upt_voice
  ON upt_voice.user_id      = vs.user_id
  AND upt_voice.metric      = 'voice_second'
  AND upt_voice.period_start = vs.current_period_start;

-- ── Active sessions (for WebSocket registry) ─────────────────────────────────
CREATE VIEW v_active_sessions AS
SELECT
  bs.id               AS session_id,
  bs.user_id,
  bs.channel,
  bs.butler_state,
  bs.turn_count,
  bs.last_active_at,
  bs.voice_session_id,
  u.display_name,
  u.butler_name
FROM butler_sessions bs
JOIN users u ON u.id = bs.user_id
WHERE bs.ended_at IS NULL
  AND u.deleted_at IS NULL;

-- ── Pending tasks due soon (Butler proactive alert source) ───────────────────
CREATE VIEW v_tasks_due_soon AS
SELECT
  t.id,
  t.user_id,
  t.title,
  t.priority,
  t.due_at,
  t.status,
  EXTRACT(EPOCH FROM (t.due_at - NOW())) / 3600 AS hours_until_due
FROM tasks t
WHERE t.status IN ('pending', 'in_progress')
  AND t.due_at IS NOT NULL
  AND t.due_at BETWEEN NOW() AND NOW() + INTERVAL '48 hours'
  AND t.deleted_at IS NULL
ORDER BY t.due_at ASC;

-- ── Memory retrieval context (for memory injection service) ──────────────────
CREATE VIEW v_active_episodic_memories AS
SELECT
  id,
  user_id,
  content,
  summary,
  category,
  embedding,
  importance,
  access_count,
  last_accessed_at,
  valid_from,
  valid_until
FROM episodic_memories
WHERE status = 'active'
  AND (valid_until IS NULL OR valid_until > NOW())
  AND superseded_by IS NULL;