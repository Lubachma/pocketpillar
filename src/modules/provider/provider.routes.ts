import type { FastifyInstance } from 'fastify';
import { authenticate } from '../../plugins/auth.js';
import { requirePremium } from '../subscription/premium.js';
import {
  listProvidersHandler,
  getProviderHandler,
  compareProductsHandler,
  bestMatchHandler,
} from './provider.handler.js';

export default async function providerRoutes(fastify: FastifyInstance) {
  // Public browsing (before signup); the scored best-match
  // is Premium (paywall option B).

  fastify.get(
    '/providers',
    { schema: { tags: ['provider'], description: 'List all pillar 3a providers' } },
    listProvidersHandler,
  );

  fastify.get(
    '/providers/compare',
    { schema: { tags: ['provider'], description: 'Compare products with filters and scoring' } },
    compareProductsHandler,
  );

  fastify.post<{ Body: unknown }>(
    '/providers/best-match',
    {
      preHandler: [authenticate, requirePremium],
      config: { rateLimit: { max: 30, timeWindow: '1 minute' } },
      schema: {
        tags: ['provider'],
        description: 'Find best matching products for your profile (Premium)',
      },
    },
    bestMatchHandler,
  );

  fastify.get(
    '/providers/:slug',
    {
      schema: {
        tags: ['provider'],
        description: 'Get provider details with products',
        params: {
          type: 'object',
          properties: {
            slug: { type: 'string', pattern: '^[a-z0-9-]+$', maxLength: 100 },
          },
          required: ['slug'],
        },
      },
    },
    getProviderHandler,
  );
}
