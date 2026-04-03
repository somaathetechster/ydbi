-- 010_voice.sql
-- Voice sessions track the lifecycle of a real-time voice interaction.
-- One voice session can span multiple conversation turns.
-- Metering: duration_seconds feeds into usage_events on close.

CREATE TABLE voice_sessions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  butler_session_id   UUID NOT NULL REFERENCES butler_sessions (id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,

  status              voice_session_status NOT NULL DEFAULT 'active',

  -- Timing
  started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at            TIMESTAMPTZ,
  duration_seconds    INTEGER,                       -- computed on close

  -- Audio config
  stt_model           TEXT NOT NULL DEFAULT 'whisper-1',
  tts_voice_id        TEXT,                          -- ElevenLabs voice ID used
  tts_model           TEXT NOT NULL DEFAULT 'eleven_multilingual_v2',

  -- Quality metrics
  stt_word_error_rate FLOAT,                         -- populated post-session if available
  avg_latency_ms      INTEGER,

  -- Error
  error_code          TEXT,
  error_message       TEXT,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_voice_sessions_user_id ON voice_sessions (user_id);
CREATE INDEX idx_voice_sessions_session ON voice_sessions (butler_session_id);
CREATE INDEX idx_voice_sessions_status  ON voice_sessions (status)
  WHERE status = 'active';

-- ── Voice Segments ─────────────────────────────────────────────────────────────
-- Each STT/TTS round-trip within a voice session.
-- Granular records for debugging and billing accuracy.

CREATE TABLE voice_segments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  voice_session_id    UUID NOT NULL REFERENCES voice_sessions (id) ON DELETE CASCADE,
  turn_id             UUID REFERENCES conversation_turns (id) ON DELETE SET NULL,

  -- STT
  audio_input_url     TEXT,                          -- S3 key for raw user audio
  transcript          TEXT,                          -- Whisper output
  stt_latency_ms      INTEGER,
  stt_confidence      FLOAT,

  -- TTS
  tts_text            TEXT,                          -- text sent to ElevenLabs
  audio_output_url    TEXT,                          -- S3 key for Butler audio
  tts_latency_ms      INTEGER,
  tts_duration_ms     INTEGER,                       -- length of generated audio

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_voice_segments_session ON voice_segments (voice_session_id);

-- ── Back-reference: butler_sessions.voice_session_id FK ───────────────────────
ALTER TABLE butler_sessions
  ADD CONSTRAINT fk_butler_voice_session
  FOREIGN KEY (voice_session_id) REFERENCES voice_sessions (id) ON DELETE SET NULL
  DEFERRABLE INITIALLY DEFERRED;   -- deferred because sessions are created first