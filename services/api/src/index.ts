import 'dotenv/config'
import Fastify from 'fastify'

const server = Fastify({
  logger: {
    level: process.env.NODE_ENV === 'production' ? 'warn' : 'info',
  },
})

server.get('/health', async () => {
  return { status: 'ok', service: '@ydbi/api', timestamp: new Date().toISOString() }
})

const start = async () => {
  try {
    const port = Number(process.env.PORT ?? 3001)
    await server.listen({ port, host: '0.0.0.0' })
    server.log.info(`YDBI API running on port ${port}`)
  } catch (err) {
    server.log.error(err)
    process.exit(1)
  }
}

start()