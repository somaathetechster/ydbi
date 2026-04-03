import type { ButlerState } from '@ydbi/sdk'

export type EmotionalRegister = 'operational' | 'exploratory' | 'stressed'

export type IntentCategory =
  | 'task.create'
  | 'task.update'
  | 'task.query'
  | 'calendar.check'
  | 'calendar.schedule'
  | 'voice.start'
  | 'voice.stop'
  | 'settings.update'
  | 'general.conversation'
  | 'unknown'

export interface Intent {
  category: IntentCategory
  confidence: number          // 0–1
  entities: Record<string, unknown>
  rawText: string
}

export interface ButlerContext {
  userId: string
  sessionId: string
  currentState: ButlerState
  emotionalRegister: EmotionalRegister
  conversationHistory: Array<{ role: 'user' | 'assistant'; content: string }>
  injectedMemories: string[]  // memory strings already in context
  turnIndex: number
}