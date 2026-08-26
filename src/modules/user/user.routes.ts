import type { FastifyInstance } from 'fastify';
import { authenticate } from '../../plugins/auth.js';
import { getMeHandler, updateMeHandler, deleteMeHandler } from './user.handler.js';

export default async function userRoutes(fastify: FastifyInstance) {
  fastify.addHook('preHandler', authenticate);

  fastify.get(
    '/users/me',
    {
      schema: {
        tags: ['user'],
        description: 'Get current user profile',
        response: {
          200: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              email: { type: 'string' },
              canton: { type: 'string', nullable: true },
              birthYear: { type: 'number', nullable: true },
              replacementRateGoal: { type: 'number' },
              municipality: { type: 'string', nullable: true },
              premium: {
                type: 'object',
                properties: {
                  active: { type: 'boolean' },
                  expiresAt: { type: 'string', nullable: true },
                },
              },
              createdAt: { type: 'string' },
            },
          },
        },
      },
    },
    getMeHandler,
  );

  fastify.patch(
    '/users/me',
    {
      schema: {
        tags: ['user'],
        description: 'Update current user profile',
        body: {
          type: 'object',
          properties: {
            canton: { type: 'string' },
            birthYear: { type: 'number' },
            replacementRateGoal: { type: 'number', minimum: 50, maximum: 100 },
          },
        },
      },
    },
    updateMeHandler,
  );

  fastify.delete(
    '/users/me',
    {
      schema: {
        tags: ['user'],
        description: 'Delete the current account (data and Supabase auth user)',
        response: {
          204: { type: 'null' },
        },
      },
    },
    deleteMeHandler,
  );
}
