-- 004_organizations.sql
-- Organizations are optional add-ons for B2B.
-- A user can belong to multiple orgs with different roles.
-- An org has its own subscription, seat count, and usage pools.

CREATE TABLE organizations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL,
  slug                TEXT NOT NULL UNIQUE,         -- URL-safe identifier: "acme-corp"
  logo_url            TEXT,
  plan                org_plan NOT NULL DEFAULT 'team',

  -- Billing anchor — one org subscription separate from user subscriptions
  stripe_customer_id  TEXT UNIQUE,
  seat_limit          INTEGER NOT NULL DEFAULT 5,

  -- Settings
  allowed_domains     TEXT[],                       -- auto-join for matching email domains
  enforce_2fa         BOOLEAN NOT NULL DEFAULT FALSE,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ
);

CREATE INDEX idx_orgs_slug       ON organizations (slug);
CREATE INDEX idx_orgs_deleted_at ON organizations (deleted_at) WHERE deleted_at IS NULL;

-- ── Org Memberships ───────────────────────────────────────────────────────────
CREATE TABLE org_memberships (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id              UUID NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  role                org_role NOT NULL DEFAULT 'member',
  invited_by          UUID REFERENCES users (id),
  accepted_at         TIMESTAMPTZ,                  -- NULL = invite pending
  removed_at          TIMESTAMPTZ,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (org_id, user_id)
);

CREATE INDEX idx_org_memberships_org_id  ON org_memberships (org_id);
CREATE INDEX idx_org_memberships_user_id ON org_memberships (user_id);

-- ── Org Invitations ───────────────────────────────────────────────────────────
CREATE TABLE org_invitations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id              UUID NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
  invited_by          UUID NOT NULL REFERENCES users (id),

  email               TEXT NOT NULL,
  role                org_role NOT NULL DEFAULT 'member',
  token_hash          TEXT NOT NULL UNIQUE,
  expires_at          TIMESTAMPTZ NOT NULL,
  accepted_at         TIMESTAMPTZ,
  revoked_at          TIMESTAMPTZ,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_org_invitations_org_id     ON org_invitations (org_id);
CREATE INDEX idx_org_invitations_email      ON org_invitations (email);
CREATE INDEX idx_org_invitations_token_hash ON org_invitations (token_hash);