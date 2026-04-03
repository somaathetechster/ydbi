import OpenAI from 'openai'

const EMBEDDING_MODEL = 'text-embedding-3-small'
const EMBEDDING_DIMS  = 1536

// Generates a vector embedding for a text string.
// Used by both retrieval and write-back paths.
export async function embed(text: string): Promise<number[]> {
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY })

  const result = await client.embeddings.create({
    model: EMBEDDING_MODEL,
    input: text,
    dimensions: EMBEDDING_DIMS,
  })

  const embedding = result.data[0]?.embedding
  if (!embedding) throw new Error('Embedding response missing data')
  return embedding
}

export { EMBEDDING_MODEL, EMBEDDING_DIMS }