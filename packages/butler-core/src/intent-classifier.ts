import type { Intent } from './types.js'

// Stub — replaced with Claude-powered classification in Phase 3.
// Exported interface is stable; implementation will swap out.
export function classifyIntent(text: string): Intent {
  return {
    category: 'unknown',
    confidence: 0,
    entities: {},
    rawText: text,
  }
}