-- 007_sessions.sql
-- A session = one continuous interaction with the Butler.
-- Sessions have turns (user + assistant message pairs).
-- Session context is reconstructed from turns + injected memory at start of each API call.

CREATE TABLE butler_sessions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  org_id              UUID REFERENCES organizations (id) ON DELETE SET NULL,

  channel             session_channel NOT NULL,
  butler_state        butler_state NOT NULL DEFAULT 'ambient',

  -- Context window management
  turn_count          INTEGER NOT NULL DEFAULT 0,
  token_count         INTEGER NOT NULL DEFAULT 0,    -- approximate, updated each turn
  context_truncated   BOOLEAN NOT NULL DEFAULT FALSE, -- true if old turns were pruned

  -- Voice session link (null for text-only sessions)
  voice_session_id    UUID,                           -- references voice_sessions.id

  -- Timing
  started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_active_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at            TIMESTAMPTZ,

  -- Metadata
  device_fingerprint  TEXT,
  ip_address          INET,
  user_agent          TEXT
);

CREATE INDEX idx_sessions_user_id       ON butler_sessions (user_id);
CREATE INDEX idx_sessions_last_active   ON butler_sessions (last_active_at DESC);
CREATE INDEX idx_sessions_user_active   ON butler_sessions (user_id, ended_at)
  WHERE ended_at IS NULL;

-- ── Conversation Turns ─────────────────────────────────────────────────────────
-- Each row = one user message + one assistant response pair.
-- Raw messages stored for context reconstruction and memory extraction.

CREATE TABLE conversation_turns (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id          UUID NOT NULL REFERENCES butler_sessions (id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  turn_index          INTEGER NOT NULL,              -- ordering within session

  -- User message
  user_content        TEXT NOT NULL,
  user_content_type   TEXT NOT NULL DEFAULT 'text',  -- 'text' | 'voice_transcript'
  user_audio_url      TEXT,                          -- S3 key if voice input

  -- Assistant response
  assistant_content   TEXT,                          -- null while streaming
  assistant_audio_url TEXT,                          -- S3 key if TTS was generated
  butler_state        butler_state,                  -- state during this turn

  -- Tool use (function calls made during this turn)
  tool_calls          JSONB,                         -- [{name, input, output}]

  -- Model metadata
  model               TEXT,
  input_tokens        INTEGER,
  output_tokens       INTEGER,
  latency_ms          INTEGER,                       -- time to first token

  -- Memory flags
  flagged_for_memory  BOOLEAN NOT NULL DEFAULT FALSE, -- extracted into memory engine
  memory_extracted_at TIMESTAMPTZ,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (session_id, turn_index)
);

CREATE INDEX idx_turns_session_id   ON conversation_turns (session_id, turn_index);
CREATE INDEX idx_turns_user_id      ON conversation_turns (user_id);
CREATE INDEX idx_turns_memory_flag  ON conversation_turns (flagged_for_memory)
  WHERE flagged_for_memory = TRUE AND memory_extracted_at IS NULL;

-- Back-reference FK from butler_sessions to usage_events
-- (session_id in usage_events references butler_sessions.id)
ALTER TABLE usage_events
  ADD CONSTRAINT fk_usage_session
  FOREIGN KEY (session_id) REFERENCES butler_sessions (id) ON DELETE SET NULL;