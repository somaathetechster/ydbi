-- 008_memory.sql
-- Three-tier memory architecture.
-- All tiers share a common structure but differ in lifecycle and retrieval patterns.
-- pgvector powers semantic retrieval across episodic and behavioural tiers.

-- ── Session Memory ─────────────────────────────────────────────────────────────
-- Ephemeral working memory for the current session.
-- Cleared when session ends. Fast reads — no vector search needed.
-- Stored in Redis in production; this table is the durable fallback/restore source.

CREATE TABLE session_memory (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id          UUID NOT NULL REFERENCES butler_sessions (id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  key                 TEXT NOT NULL,                -- 'current_intent', 'last_entity', etc.
  value               JSONB NOT NULL,
  ttl_seconds         INTEGER,                      -- NULL = lives for full session

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (session_id, key)
);

CREATE INDEX idx_session_mem_session ON session_memory (session_id);

-- ── Episodic Memory ────────────────────────────────────────────────────────────
-- Persistent key facts, events, preferences extracted from conversations.
-- Examples: "User's partner is called Ife", "User dislikes morning meetings",
--           "User completed onboarding 2025-04-01".
-- Retrieved semantically (pgvector) + filtered by recency and importance.

CREATE TABLE episodic_memories (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  -- Content
  content             TEXT NOT NULL,                -- human-readable memory string
  summary             TEXT,                         -- shorter form for context injection
  category            TEXT,                         -- 'preference', 'fact', 'event', 'relationship'

  -- Vector embedding (text-embedding-3-small, 1536 dims)
  embedding           VECTOR(1536),

  -- Importance & lifecycle
  importance          SMALLINT NOT NULL DEFAULT 3 CHECK (importance BETWEEN 1 AND 5),
  status              memory_status NOT NULL DEFAULT 'active',
  access_count        INTEGER NOT NULL DEFAULT 0,
  last_accessed_at    TIMESTAMPTZ,

  -- Source
  source_session_id   UUID REFERENCES butler_sessions (id) ON DELETE SET NULL,
  source_turn_id      UUID REFERENCES conversation_turns (id) ON DELETE SET NULL,

  -- Temporal validity
  valid_from          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  valid_until         TIMESTAMPTZ,                  -- NULL = always valid
  superseded_by       UUID REFERENCES episodic_memories (id), -- for contradiction handling

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Semantic search index (ivfflat — good for 1M+ rows; use hnsw for <100k)
CREATE INDEX idx_episodic_embedding
  ON episodic_memories USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

CREATE INDEX idx_episodic_user_status
  ON episodic_memories (user_id, status, importance DESC)
  WHERE status = 'active';

CREATE INDEX idx_episodic_user_category
  ON episodic_memories (user_id, category)
  WHERE status = 'active';

-- ── Behavioural Memory ─────────────────────────────────────────────────────────
-- Usage patterns and inferred preferences. Updated silently in the background.
-- Examples: "User typically starts sessions at 8am", "User prefers short responses",
--           "User asks about tasks more than any other topic".
-- One row per signal type per user. Upserted, not appended.

CREATE TABLE behavioural_memory (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  -- Signal
  signal_key          TEXT NOT NULL,                -- 'preferred_session_time', 'avg_response_length_pref'
  signal_value        JSONB NOT NULL,               -- flexible: number, string, array, object
  confidence          FLOAT NOT NULL DEFAULT 0.5 CHECK (confidence BETWEEN 0 AND 1),

  -- Vector embedding of signal_key + signal_value summary (for semantic retrieval)
  embedding           VECTOR(1536),

  -- Lifecycle
  observation_count   INTEGER NOT NULL DEFAULT 1,   -- how many data points support this signal
  last_observed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status              memory_status NOT NULL DEFAULT 'active',

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, signal_key)
);

CREATE INDEX idx_behavioural_embedding
  ON behavioural_memory USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 50);

CREATE INDEX idx_behavioural_user
  ON behavioural_memory (user_id, signal_key)
  WHERE status = 'active';

-- ── Memory Injection Log ───────────────────────────────────────────────────────
-- Audit trail of what memories were injected into each session's context.
-- Critical for: debugging Butler responses, memory evaluation, bias detection.

CREATE TABLE memory_injections (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id          UUID NOT NULL REFERENCES butler_sessions (id) ON DELETE CASCADE,
  turn_id             UUID REFERENCES conversation_turns (id) ON DELETE SET NULL,
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  memory_tier         memory_tier NOT NULL,
  memory_id           UUID NOT NULL,                -- references episodic or behavioural id
  relevance_score     FLOAT,                        -- cosine similarity at injection time
  injected_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mem_injections_session ON memory_injections (session_id);
CREATE INDEX idx_mem_injections_memory  ON memory_injections (memory_id);