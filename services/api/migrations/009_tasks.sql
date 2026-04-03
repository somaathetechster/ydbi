-- 009_tasks.sql
-- Task management — the first core tool suite the Butler can create and manage.
-- Tasks can be standalone or linked to a calendar event via an integration.

CREATE TABLE tasks (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  org_id              UUID REFERENCES organizations (id) ON DELETE SET NULL,

  -- Content
  title               TEXT NOT NULL,
  description         TEXT,
  status              task_status NOT NULL DEFAULT 'pending',
  priority            task_priority NOT NULL DEFAULT 'medium',

  -- Assignment (B2B: tasks can be assigned to other org members)
  assigned_to         UUID REFERENCES users (id) ON DELETE SET NULL,

  -- Scheduling
  due_at              TIMESTAMPTZ,
  started_at          TIMESTAMPTZ,
  completed_at        TIMESTAMPTZ,
  cancelled_at        TIMESTAMPTZ,

  -- Recurrence (iCal RRULE format for simplicity)
  rrule               TEXT,                          -- e.g. "FREQ=WEEKLY;BYDAY=MO"
  parent_task_id      UUID REFERENCES tasks (id),    -- for recurring task instances

  -- External calendar sync
  calendar_event_id   TEXT,                          -- provider event ID
  integration_id      UUID,                          -- references user_integrations.id

  -- Butler context
  created_by_session  UUID REFERENCES butler_sessions (id) ON DELETE SET NULL,
  butler_notes        TEXT,                          -- Butler's internal reasoning about this task

  -- Metadata
  tags                TEXT[] NOT NULL DEFAULT '{}',
  metadata            JSONB NOT NULL DEFAULT '{}',

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ
);

CREATE INDEX idx_tasks_user_status    ON tasks (user_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_user_due       ON tasks (user_id, due_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_org_id         ON tasks (org_id) WHERE org_id IS NOT NULL;
CREATE INDEX idx_tasks_assigned_to    ON tasks (assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_tasks_parent         ON tasks (parent_task_id) WHERE parent_task_id IS NOT NULL;
-- Full-text search on title + description
CREATE INDEX idx_tasks_fts            ON tasks
  USING gin (to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- ── Task Comments ─────────────────────────────────────────────────────────────
CREATE TABLE task_comments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id             UUID NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
  user_id             UUID REFERENCES users (id) ON DELETE SET NULL,   -- NULL = Butler authored
  is_butler           BOOLEAN NOT NULL DEFAULT FALSE,

  content             TEXT NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ
);

CREATE INDEX idx_task_comments_task_id ON task_comments (task_id, created_at);