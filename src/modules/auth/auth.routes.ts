import type { FastifyInstance } from 'fastify';
import { registerHandler } from './auth.handler.js';

export default async function authRoutes(fastify: FastifyInstance) {
  fastify.post(
    '/auth/register',
    {
      config: {
        rateLimit: { max: 3, timeWindow: '1 minute' },
      },
      schema: {
        tags: ['auth'],
        description:
          'Register / upsert a user after Supabase sign-up. Requires valid JWT. The email claim of the token is authoritative; the body email is optional and ignored.',
        body: {
          type: 'object',
          required: ['supabaseId'],
          properties: {
            email: { type: 'string', format: 'email' },
            supabaseId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              email: { type: 'string' },
              canton: { type: 'string', nullable: true },
              birthYear: { type: 'number', nullable: true },
              createdAt: { type: 'string' },
            },
          },
        },
      },
    },
    registerHandler,
  );
}
