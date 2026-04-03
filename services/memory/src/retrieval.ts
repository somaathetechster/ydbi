import { embed } from './embeddings.js'

export interface MemoryHit {
  id: string
  content: string
  summary: string | null
  category: string | null
  relevanceScore: number
  importance: number
}

// Retrieves episodic memories for a user semantically relevant to a query.
// Full implementation with pg pool in Phase 7.
export async function retrieveEpisodicMemories(
  _userId: string,
  query: string,
  limit: number = 10
): Promise<MemoryHit[]> {
  // Embedding generated — pg query built in Phase 7
  await embed(query)
  void limit
  return []
}