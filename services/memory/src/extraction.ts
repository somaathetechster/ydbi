// Extracts episodic memories from conversation turns.
// Uses Claude to identify and structure memorable facts.
// Full implementation in Phase 7.

export interface ExtractedMemory {
  content: string
  summary: string
  category: 'preference' | 'fact' | 'event' | 'relationship'
  importance: 1 | 2 | 3 | 4 | 5
}

export async function extractMemoriesFromTurn(
  _userContent: string,
  _assistantContent: string
): Promise<ExtractedMemory[]> {
  // Claude-powered extraction implemented in Phase 7
  return []
}