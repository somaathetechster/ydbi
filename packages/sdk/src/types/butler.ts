export type ButlerState =
  | 'dormant'
  | 'ambient'
  | 'listening'
  | 'processing'
  | 'speaking'
  | 'confirming'

export type SessionChannel = 'web' | 'ios' | 'android' | 'api'

export interface ButlerSession {
  id: string
  userId: string
  channel: SessionChannel
  butlerState: ButlerState
  turnCount: number
  startedAt: string
  lastActiveAt: string
}

export interface ConversationTurn {
  id: string
  sessionId: string
  turnIndex: number
  userContent: string
  userContentType: 'text' | 'voice_transcript'
  assistantContent: string | null
  butlerState: ButlerState | null
  createdAt: string
}