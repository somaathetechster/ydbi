// Voice session pipeline — coordinates STT → Butler → TTS.
// Full WebSocket implementation built in Phase 3.

export interface VoicePipelineConfig {
  userId: string
  sessionId: string
  voiceId?: string
}

export interface PipelineTurn {
  transcript: string
  response: string
  sttLatencyMs: number
  ttsLatencyMs: number
  totalLatencyMs: number
}

// Placeholder — full streaming pipeline implemented in Phase 3.
export async function processPipelineTurn(
  _audioBuffer: Buffer,
  _config: VoicePipelineConfig
): Promise<PipelineTurn> {
  throw new Error('Voice pipeline not yet implemented — Phase 3')
}