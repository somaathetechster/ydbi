-- 014_functions_triggers.sql
-- Shared utility functions and triggers applied across all tables.

-- ── updated_at auto-maintenance ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to every table that has an updated_at column
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN
    SELECT table_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND column_name = 'updated_at'
      AND table_name IN (
        'users', 'auth_identities', 'organizations', 'org_memberships',
        'subscriptions', 'session_memory', 'episodic_memories',
        'behavioural_memory', 'tasks', 'task_comments',
        'user_integrations', 'notifications'
      )
  LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%s_updated_at
       BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
      t, t
    );
  END LOOP;
END;
$$;

-- ── Soft-delete guard ─────────────────────────────────────────────────────────
-- Prevent hard deletes on users table — use soft delete instead.
CREATE OR REPLACE FUNCTION prevent_hard_delete_users()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Hard deletes on users are not permitted. Set deleted_at instead.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_no_hard_delete
  BEFORE DELETE ON users
  FOR EACH ROW
  WHEN (OLD.deleted_at IS NULL)
  EXECUTE FUNCTION prevent_hard_delete_users();

-- ── Auto-create free subscription on user creation ────────────────────────────
CREATE OR REPLACE FUNCTION create_free_subscription()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO subscriptions (user_id, tier, status, current_period_start, current_period_end)
  VALUES (
    NEW.id,
    'free',
    'active',
    date_trunc('month', NOW()),
    date_trunc('month', NOW()) + INTERVAL '1 month'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_create_subscription
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION create_free_subscription();

-- ── Session turn counter ──────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION increment_session_turn_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE butler_sessions
  SET
    turn_count     = turn_count + 1,
    last_active_at = NOW()
  WHERE id = NEW.session_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_turns_increment_count
  AFTER INSERT ON conversation_turns
  FOR EACH ROW
  EXECUTE FUNCTION increment_session_turn_count();

-- ── Usage period boundary helper ──────────────────────────────────────────────
-- Returns the current billing period start for a given user.
-- Used by the usage recording service to stamp period_start/end on usage_events.
CREATE OR REPLACE FUNCTION get_billing_period(p_user_id UUID, OUT period_start TIMESTAMPTZ, OUT period_end TIMESTAMPTZ)
AS $$
BEGIN
  SELECT
    COALESCE(s.current_period_start, date_trunc('month', NOW())),
    COALESCE(s.current_period_end,   date_trunc('month', NOW()) + INTERVAL '1 month')
  INTO period_start, period_end
  FROM subscriptions s
  WHERE s.user_id = p_user_id
    AND s.status IN ('active', 'trialing', 'past_due')
  ORDER BY s.created_at DESC
  LIMIT 1;

  -- Fallback to calendar month if no subscription found
  IF period_start IS NULL THEN
    period_start := date_trunc('month', NOW());
    period_end   := date_trunc('month', NOW()) + INTERVAL '1 month';
  END IF;
END;
$$ LANGUAGE plpgsql STABLE;

-- ── Cap check function ─────────────────────────────────────────────────────────
-- Returns TRUE if user is within their tier limit for a given metric.
-- Called by the API gateway before serving any AI or voice request.
CREATE OR REPLACE FUNCTION check_usage_cap(
  p_user_id UUID,
  p_metric  usage_metric
)
RETURNS BOOLEAN AS $$
DECLARE
  v_tier          subscription_tier;
  v_limit         INTEGER;
  v_used          BIGINT;
  v_period_start  TIMESTAMPTZ;
  v_period_end    TIMESTAMPTZ;
BEGIN
  -- Get user's active tier
  SELECT tier INTO v_tier
  FROM subscriptions
  WHERE user_id = p_user_id
    AND status IN ('active', 'trialing', 'past_due')
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_tier IS NULL THEN
    v_tier := 'free';
  END IF;

  -- Get limit for this metric + tier
  SELECT
    CASE p_metric
      WHEN 'ai_message'   THEN ai_messages_limit
      WHEN 'voice_second' THEN voice_seconds_limit
    END
  INTO v_limit
  FROM tier_limits
  WHERE tier = v_tier;

  -- NULL limit = unlimited
  IF v_limit IS NULL THEN
    RETURN TRUE;
  END IF;

  -- Get billing period
  SELECT period_start, period_end
  INTO v_period_start, v_period_end
  FROM get_billing_period(p_user_id);

  -- Get current usage from aggregates (fast path)
  SELECT COALESCE(total, 0)
  INTO v_used
  FROM usage_period_totals
  WHERE user_id      = p_user_id
    AND metric       = p_metric
    AND period_start = v_period_start;

  RETURN v_used < v_limit;
END;
$$ LANGUAGE plpgsql STABLE;