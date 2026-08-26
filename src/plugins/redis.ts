import fp from 'fastify-plugin';
import type { FastifyInstance } from 'fastify';
import { redis } from '../lib/redis.js';

export default fp(async (fastify: FastifyInstance) => {
  await redis.connect();
  fastify.decorate('redis', redis);

  fastify.addHook('onClose', async () => {
    await redis.quit();
  });
});
