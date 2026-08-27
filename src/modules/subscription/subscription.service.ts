import type { FastifyInstance } from 'fastify';
import type { Subscription } from '@prisma/client';

/** Free plan: maximum number of documents stored. */
export const FREE_DOCUMENT_LIMIT = 1;

const PREMIUM_CACHE_PREFIX = 'premium:';
const PREMIUM_CACHE_TTL_SECONDS = 60;

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Premium is active as long as the entitlement end date is in the future (grace periods are already reflected by RevenueCat). */
export function isSubscriptionActive(sub: Pick<Subscription, 'expiresAt'> | null): boolean {
  return sub?.expiresAt != null && sub.expiresAt.getTime() > Date.now();
}

function premiumCacheKey(userId: string): string {
  return PREMIUM_CACHE_PREFIX + userId;
}

/**
 * A user's premium status — short Redis cache (60 s), invalidated by the
 * webhook. Fail-open to the DB: a Redis outage must neither block access nor
 * accidentally grant premium — the DB remains the source of truth.
 */
export async function isPremiumUser(app: FastifyInstance, userId: string): Promise<boolean> {
  const key = premiumCacheKey(userId);
  try {
    const cached = await app.redis.get(key);
    if (cached === '1') return true;
    if (cached === '0') return false;
  } catch {
    // fail-open to the DB
  }

  const sub = await app.prisma.subscription.findUnique({ where: { userId } });
  const active = isSubscriptionActive(sub);

  try {
    await app.redis.set(key, active ? '1' : '0', 'EX', PREMIUM_CACHE_TTL_SECONDS);
  } catch {
    // best-effort
  }
  return active;
}

async function invalidatePremiumCache(app: FastifyInstance, userId: string): Promise<void> {
  try {
    await app.redis.del(premiumCacheKey(userId));
  } catch {
    // best-effort — the 60 s TTL bounds the staleness
  }
}

/** Status exposed to the client on /users/me. */
export async function premiumStatus(
  app: FastifyInstance,
  userId: string,
): Promise<{ active: boolean; expiresAt: string | null }> {
  const sub = await app.prisma.subscription.findUnique({ where: { userId } });
  return {
    active: isSubscriptionActive(sub),
    expiresAt: sub?.expiresAt?.toISOString() ?? null,
  };
}

export interface RevenueCatEventInput {
  type: string;
  appUserId: string;
  aliases?: string[];
  productId?: string | null;
  store?: string | null;
  environment?: string | null;
  expirationAtMs?: number | null;
  eventTimestampMs?: number | null;
}

export type WebhookAction = 'applied' | 'ignored_test' | 'unknown_user' | 'stale_ignored';

/**
 * Applies a RevenueCat webhook event to the user's subscription row
 * (1 row per user, latest known state).
 *
 * - The mobile app calls `Purchases.logIn(<users.id>)` → `app_user_id` is our
 *   local uuid; RevenueCat's anonymous ids (`$RCAnonymousID:…`) are ignored
 *   in favor of `aliases`.
 * - Entitlement is read solely via `expiresAt`: CANCELLATION keeps access
 *   until the deadline, EXPIRATION carries a past deadline, BILLING_ISSUE
 *   is covered by the grace period that RevenueCat reflects in the deadline.
 * - Events can arrive out of order → an event older than the last one
 *   applied is ignored.
 */
export async function applyRevenueCatEvent(
  app: FastifyInstance,
  event: RevenueCatEventInput,
): Promise<WebhookAction> {
  if (event.type === 'TEST') return 'ignored_test';

  const candidates = [event.appUserId, ...(event.aliases ?? [])].filter((id) => UUID_RE.test(id));
  let userId: string | null = null;
  for (const id of candidates) {
    const user = await app.prisma.user.findUnique({ where: { id }, select: { id: true } });
    if (user) {
      userId = user.id;
      break;
    }
  }
  if (!userId) return 'unknown_user';

  const eventAt = event.eventTimestampMs != null ? new Date(event.eventTimestampMs) : new Date();
  // KNOWN LIMIT (review 08.2026): this check-then-upsert is not atomic — two
  // concurrent deliveries could let the older event win the upsert. The
  // window is milliseconds, RevenueCat redelivers, and the next event
  // self-corrects the row; an atomic conditional update needs a real
  // transaction (the test fake-prisma has none) — accepted for now.
  const existing = await app.prisma.subscription.findUnique({ where: { userId } });
  if (existing && existing.lastEventAt.getTime() > eventAt.getTime()) return 'stale_ignored';

  // An event without a deadline (rare: TRANSFER, informational events) must
  // not erase the current entitlement.
  const expiresAt =
    event.expirationAtMs != null ? new Date(event.expirationAtMs) : (existing?.expiresAt ?? null);

  const data = {
    store: event.store ?? existing?.store ?? 'UNKNOWN',
    environment: event.environment ?? existing?.environment ?? 'UNKNOWN',
    productId: event.productId ?? existing?.productId ?? 'unknown',
    expiresAt,
    lastEventType: event.type,
    lastEventAt: eventAt,
  };

  await app.prisma.subscription.upsert({
    where: { userId },
    create: { userId, ...data },
    update: data,
  });

  await invalidatePremiumCache(app, userId);
  return 'applied';
}
