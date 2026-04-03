export interface SynthesisResult {
  audioBuffer: Buffer
  durationMs: number
}

// Synthesises text to speech using ElevenLabs.
// Expanded in Phase 3 with streaming audio support.
export async function synthesiseSpeech(
  text: string,
  voiceId?: string
): Promise<SynthesisResult> {
  const start = Date.now()
  const key = process.env.ELEVENLABS_API_KEY
  const vid = voiceId ?? process.env.ELEVENLABS_DEFAULT_VOICE_ID ?? ''
  const model = process.env.ELEVENLABS_MODEL ?? 'eleven_multilingual_v2'

  const response = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${vid}`,
    {
      method: 'POST',
      headers: {
        'xi-api-key': key ?? '',
        'Content-Type': 'application/json',
        Accept: 'audio/mpeg',
      },
      body: JSON.stringify({
        text,
        model_id: model,
        voice_settings: { stability: 0.5, similarity_boost: 0.75 },
      }),
    }
  )

  if (!response.ok) {
    throw new Error(`ElevenLabs TTS failed: ${response.status} ${response.statusText}`)
  }

  const arrayBuffer = await response.arrayBuffer()
  return {
    audioBuffer: Buffer.from(arrayBuffer),
    durationMs: Date.now() - start,
  }
}