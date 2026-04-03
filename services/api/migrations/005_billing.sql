-- 005_billing.sql
-- Subscriptions belong to either a user (consumer) or an org (B2B).
-- Exactly one of user_id / org_id is non-null per row — enforced by check constraint.
-- Usage caps are derived from tier at query time via the tier_limits view below.

CREATE TABLE subscriptions (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Owner: user OR org, never both, never neither
  user_id                     UUID REFERENCES users (id) ON DELETE CASCADE,
  org_id                      UUID REFERENCES organizations (id) ON DELETE CASCADE,

  -- Tier & status
  tier                        subscription_tier NOT NULL DEFAULT 'free',
  status                      subscription_status NOT NULL DEFAULT 'active',
  billing_interval            billing_interval,             -- NULL for free tier

  -- Stripe
  stripe_subscription_id      TEXT UNIQUE,
  stripe_price_id             TEXT,
  stripe_customer_id          TEXT,

  -- Lifecycle dates
  trial_ends_at               TIMESTAMPTZ,
  current_period_start        TIMESTAMPTZ,
  current_period_end          TIMESTAMPTZ,
  cancelled_at                TIMESTAMPTZ,
  cancels_at                  TIMESTAMPTZ,                  -- scheduled cancellation

  -- Seat count (B2B)
  seat_count                  INTEGER NOT NULL DEFAULT 1,

  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT sub_owner_exclusive CHECK (
    (user_id IS NOT NULL AND org_id IS NULL)
    OR
    (user_id IS NULL AND org_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX idx_sub_user_id_active
  ON subscriptions (user_id)
  WHERE user_id IS NOT NULL AND status IN ('active', 'trialing', 'past_due');

CREATE UNIQUE INDEX idx_sub_org_id_active
  ON subscriptions (org_id)
  WHERE org_id IS NOT NULL AND status IN ('active', 'trialing', 'past_due');

CREATE INDEX idx_subscriptions_stripe_id ON subscriptions (stripe_subscription_id);
CREATE INDEX idx_subscriptions_status    ON subscriptions (status);

-- ── Tier Limits Reference ─────────────────────────────────────────────────────
-- Static lookup for caps per tier per rolling 30-day window.
-- ai_messages: number of Claude API round-trips.
-- voice_seconds: total STT+TTS seconds.
-- NULL = unlimited.

CREATE TABLE tier_limits (
  tier                subscription_tier PRIMARY KEY,
  ai_messages_limit   INTEGER,
  voice_seconds_limit INTEGER,
  max_integrations    INTEGER DEFAULT 1,
  max_tasks           INTEGER,
  max_api_keys        INTEGER DEFAULT 0,
  description         TEXT
);

INSERT INTO tier_limits
  (tier, ai_messages_limit, voice_seconds_limit, max_integrations, max_tasks, max_api_keys, description)
VALUES
  ('free',       100,   600,    1,    50,    0,    'Free — 100 messages, 10 voice min/month'),
  ('pro',        2000,  18000,  5,    NULL,  2,    'Pro — 2000 messages, 5 voice hrs/month'),
  ('team',       NULL,  NULL,   20,   NULL,  10,   'Team — unlimited messages and voice'),
  ('enterprise', NULL,  NULL,   NULL, NULL,  NULL, 'Enterprise — fully unlimited');

-- ── Stripe Webhook Events ─────────────────────────────────────────────────────
-- Idempotency store for incoming Stripe webhooks.
CREATE TABLE stripe_webhook_events (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_event_id     TEXT NOT NULL UNIQUE,         -- evt_xxx from Stripe
  event_type          TEXT NOT NULL,
  payload             JSONB NOT NULL,
  processed_at        TIMESTAMPTZ,
  error               TEXT,                         -- non-null if processing failed
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_stripe_events_event_id  ON stripe_webhook_events (stripe_event_id);
CREATE INDEX idx_stripe_events_type      ON stripe_webhook_events (event_type);
CREATE INDEX idx_stripe_events_processed ON stripe_webhook_events (processed_at) WHERE processed_at IS NULL;