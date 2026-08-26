import { timingSafeEqual } from 'node:crypto';
import type { FastifyRequest, FastifyReply } from 'fastify';
import { config } from '../../config/index.js';
import { revenueCatWebhookSchema } from './subscription.schema.js';
import { applyRevenueCatEvent } from './subscription.service.js';

/**
 * POST /webhooks/revenuecat — the caller is RevenueCat, not a user
 * (messages are not localized). RevenueCat retries on non-2xx: an unknown
 * user is therefore acknowledged with 200 (a retry wouldn't make it appear),
 * only configuration/authentication problems return an error.
 */
export async function revenueCatWebhookHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  if (!config.REVENUECAT_WEBHOOK_AUTH) {
    return reply.status(503).send({ error: 'RevenueCat webhook not configured' });
  }

  // The RevenueCat dashboard sends the configured value as-is in
  // Authorization — accept both the raw form and the `Bearer <value>` form.
  const header = request.headers.authorization ?? '';
  const expected = config.REVENUECAT_WEBHOOK_AUTH;
  const matches = (candidate: string): boolean => {
    const a = Buffer.from(candidate);
    const b = Buffer.from(expected);
    return a.length === b.length && timingSafeEqual(a, b);
  };
  if (!matches(header) && !matches(header.replace(/^Bearer /, ''))) {
    return reply.status(401).send({ error: 'Unauthorized' });
  }

  const parsed = revenueCatWebhookSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({ error: 'Invalid payload' });
  }

  const { event } = parsed.data;
  const action = await applyRevenueCatEvent(request.server, {
    type: event.type,
    appUserId: event.app_user_id,
    aliases: event.aliases,
    productId: event.product_id,
    store: event.store,
    environment: event.environment,
    expirationAtMs: event.expiration_at_ms,
    eventTimestampMs: event.event_timestamp_ms,
  });

  request.log.info(
    { action, eventType: event.type, environment: event.environment },
    'RevenueCat webhook processed',
  );
  return reply.send({ received: true, action });
}
