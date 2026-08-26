import type { FastifyInstance } from 'fastify';
import { revenueCatWebhookHandler } from './subscription.handler.js';

export default async function subscriptionRoutes(fastify: FastifyInstance) {
  fastify.post(
    '/webhooks/revenuecat',
    {
      // RevenueCat batches its retries/renewals — a dedicated high ceiling.
      config: { rateLimit: { max: 300, timeWindow: '1 minute' } },
      schema: {
        tags: ['subscription'],
        description:
          "Webhook RevenueCat — met à jour l'abonnement premium (authentification par en-tête partagé)",
      },
    },
    revenueCatWebhookHandler,
  );
}
