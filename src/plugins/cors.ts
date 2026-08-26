import fp from 'fastify-plugin';
import cors from '@fastify/cors';
import type { FastifyInstance } from 'fastify';
import { config } from '../config/index.js';

export default fp(async (fastify: FastifyInstance) => {
  const origin =
    config.NODE_ENV === 'production'
      ? config.CORS_ORIGIN.length > 0
        ? config.CORS_ORIGIN
        : false
      : [/^http:\/\/localhost(:\d+)?$/];

  await fastify.register(cors, {
    origin,
    credentials: true,
  });
});
