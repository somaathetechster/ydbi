-- 006_usage.sql
-- Fine-grained usage ledger. Every AI message and every voice second is recorded.
-- Aggregation queries (monthly totals, cap checks) run against this table.
-- Partition by month in production once row count exceeds ~10M.

CREATE TABLE usage_events (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  org_id              UUID REFERENCES organizations (id) ON DELETE SET NULL,

  metric              usage_metric NOT NULL,
  quantity            INTEGER NOT NULL DEFAULT 1,   -- messages=1, voice=seconds elapsed

  -- Context (what generated this usage)
  session_id          UUID,                         -- references butler_sessions.id (added later)
  model               TEXT,                         -- claude-sonnet-4-... etc.

  -- Billing period snapshot (denormalised for fast cap queries)
  period_start        TIMESTAMPTZ NOT NULL,         -- truncated to billing period start
  period_end          TIMESTAMPTZ NOT NULL,

  recorded_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Fast monthly totals per user per metric
CREATE INDEX idx_usage_user_period
  ON usage_events (user_id, metric, period_start, period_end);

-- Fast monthly totals per org per metric
CREATE INDEX idx_usage_org_period
  ON usage_events (org_id, metric, period_start, period_end)
  WHERE org_id IS NOT NULL;

CREATE INDEX idx_usage_session_id
  ON usage_events (session_id)
  WHERE session_id IS NOT NULL;

-- ── Usage Aggregates (materialized, refreshed hourly) ──────────────────────────
-- Avoid full table scans on cap checks in the hot path.
CREATE TABLE usage_period_totals (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  org_id              UUID REFERENCES organizations (id) ON DELETE CASCADE,
  metric              usage_metric NOT NULL,
  period_start        TIMESTAMPTZ NOT NULL,
  period_end          TIMESTAMPTZ NOT NULL,
  total               BIGINT NOT NULL DEFAULT 0,
  last_refreshed_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, metric, period_start)
);

CREATE INDEX idx_upt_user_metric_period
  ON usage_period_totals (user_id, metric, period_start);