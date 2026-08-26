import type { FastifyRequest, FastifyReply } from 'fastify';
import { t } from '../../lib/i18n/index.js';
import { resolveAuth } from '../../plugins/auth.js';
import { isPremiumUser } from './subscription.service.js';

/**
 * preHandler — place AFTER `authenticate`: 402 Payment Required if
 * the user has no active subscription. The client maps 402 → paywall.
 */
export async function requirePremium(request: FastifyRequest, reply: FastifyReply) {
  const premium = await isPremiumUser(request.server, request.userId!);
  if (!premium) {
    return reply.status(402).send({ error: t(request.locale, 'sub.premium_required') });
  }
}

/**
 * Best-effort resolution for public endpoints with an enriched response
 * (free preview vs premium detail): never a 401 — anonymous, invalid token,
 * or an account without a subscription all resolve to `false`.
 */
export async function tryResolvePremium(request: FastifyRequest): Promise<boolean> {
  if (!request.headers.authorization) return false;
  const auth = await resolveAuth(request);
  if ('failure' in auth) return false;
  return isPremiumUser(request.server, auth.userId);
}
