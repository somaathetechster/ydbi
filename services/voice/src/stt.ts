import OpenAI from 'openai'

export interface TranscriptResult {
  text: string
  confidence?: number
  durationMs: number
}

// Transcribes audio buffer using OpenAI Whisper.
// Expanded in Phase 3 with streaming support.
export async function transcribeAudio(
  audioBuffer: Buffer,
  mimeType: string = 'audio/webm'
): Promise<TranscriptResult> {
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY })
  const start = Date.now()

  const file = new File([audioBuffer], `audio.${mimeType.split('/')[1]}`, { type: mimeType })

  const result = await client.audio.transcriptions.create({
    model: process.env.WHISPER_MODEL ?? 'whisper-1',
    file,
    response_format: 'json',
  })

  return {
    text: result.text,
    durationMs: Date.now() - start,
  }
}