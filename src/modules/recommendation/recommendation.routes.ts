import type { FastifyInstance } from 'fastify';
import { authenticate } from '../../plugins/auth.js';
import { requirePremium } from '../subscription/premium.js';
import { getRecommendationsHandler } from './recommendation.handler.js';
import { getScoreHandler } from './score.handler.js';

export default async function recommendationRoutes(fastify: FastifyInstance) {
  fastify.addHook('preHandler', authenticate);

  fastify.get(
    '/recommendations',
    {
      // Premium — le score reste gratuit (dashboard), les recommandations
      // actionnables font partie de l'abonnement (paywall option B).
      preHandler: requirePremium,
      schema: {
        tags: ['recommendation'],
        description: "Recommandations personnalisees d'optimisation prevoyance (Premium)",
      },
    },
    getRecommendationsHandler,
  );

  fastify.get(
    '/score',
    {
      schema: {
        tags: ['recommendation'],
        description: 'Score de prevoyance /100 avec decomposition et benchmarks par age',
      },
    },
    getScoreHandler,
  );
}
