import { describe, it, expect, beforeAll, beforeEach, afterAll, vi } from 'vitest';
import type { FastifyInstance } from 'fastify';

// Minimal env so importing src/config (via the harness) does not exit the process.
const mocks = vi.hoisted(() => {
  process.env.DATABASE_URL = 'postgresql://localhost:5432/test';
  process.env.REDIS_URL = 'redis://localhost:6379';
  process.env.SUPABASE_URL = 'https://test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
  process.env.REVENUECAT_WEBHOOK_AUTH = 'rc-secret';
  return { getUser: vi.fn() };
});

vi.mock('../../../src/lib/supabase.js', () => ({
  supabaseAdmin: { auth: { getUser: mocks.getUser } },
}));

import { buildTestApp, createFakePrisma, createFakeRedis } from '../../helpers/test-app.js';

const TOKEN_SUB = '123e4567-e89b-42d3-a456-426614174000';
const LOCAL_USER_ID = '223e4567-e89b-42d3-a456-426614174111';
const LOCAL_USER = {
  id: LOCAL_USER_ID,
  email: 'user@example.ch',
  canton: 'VD',
  birthYear: 1995,
  replacementRateGoal: 70,
  municipality: null,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
};

const FUTURE = new Date(Date.now() + 30 * 24 * 3600 * 1000);
const PAST = new Date(Date.now() - 24 * 3600 * 1000);

const activeSubscription = {
  id: 'sub-1',
  userId: LOCAL_USER_ID,
  store: 'APP_STORE',
  productId: 'pp_premium_annual',
  environment: 'PRODUCTION',
  expiresAt: FUTURE,
  lastEventType: 'INITIAL_PURCHASE',
  lastEventAt: PAST,
  createdAt: PAST,
  updatedAt: PAST,
};

const authHeaders = { authorization: 'Bearer valid-token' };

describe('Subscription — RevenueCat webhook and premium gating', () => {
  let app: FastifyInstance;
  const prisma = createFakePrisma();
  const redis = createFakeRedis();

  beforeAll(async () => {
    app = await buildTestApp({ prisma, redis });
  });

  beforeEach(() => {
    vi.clearAllMocks();
    redis.store.clear();
    mocks.getUser.mockResolvedValue({ data: { user: { id: TOKEN_SUB } }, error: null });
    prisma.user.findUnique.mockImplementation(({ where }: { where: Record<string, string> }) => {
      if (where.supabaseId === TOKEN_SUB) return Promise.resolve(LOCAL_USER);
      if (where.id === LOCAL_USER_ID) return Promise.resolve(LOCAL_USER);
      return Promise.resolve(null);
    });
    prisma.subscription.findUnique.mockResolvedValue(null);
    prisma.subscription.upsert.mockResolvedValue(null);
    prisma.document.count.mockResolvedValue(0);
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /webhooks/revenuecat', () => {
    const event = (overrides: Record<string, unknown> = {}) => ({
      event: {
        type: 'INITIAL_PURCHASE',
        app_user_id: LOCAL_USER_ID,
        product_id: 'pp_premium_annual',
        store: 'APP_STORE',
        environment: 'PRODUCTION',
        expiration_at_ms: FUTURE.getTime(),
        event_timestamp_ms: Date.now(),
        ...overrides,
      },
    });

    it('401 without the correct Authorization header', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/webhooks/revenuecat',
        headers: { authorization: 'wrong' },
        payload: event(),
      });
      expect(res.statusCode).toBe(401);
      expect(prisma.subscription.upsert).not.toHaveBeenCalled();
    });

    it("accepts the raw value and the 'Bearer <value>' form", async () => {
      for (const authorization of ['rc-secret', 'Bearer rc-secret']) {
        const res = await app.inject({
          method: 'POST',
          url: '/webhooks/revenuecat',
          headers: { authorization },
          payload: event(),
        });
        expect(res.statusCode).toBe(200);
      }
    });

    it('400 on an invalid payload', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/webhooks/revenuecat',
        headers: { authorization: 'rc-secret' },
        payload: { nope: true },
      });
      expect(res.statusCode).toBe(400);
    });

    it('applies a purchase: upserts the expiry and invalidates the premium cache', async () => {
      redis.store.set(`premium:${LOCAL_USER_ID}`, '0');
      const res = await app.inject({
        method: 'POST',
        url: '/webhooks/revenuecat',
        headers: { authorization: 'rc-secret' },
        payload: event(),
      });
      expect(res.statusCode).toBe(200);
      expect(res.json()).toMatchObject({ received: true, action: 'applied' });
      expect(prisma.subscription.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userId: LOCAL_USER_ID },
          create: expect.objectContaining({
            userId: LOCAL_USER_ID,
            productId: 'pp_premium_annual',
            store: 'APP_STORE',
            expiresAt: new Date(FUTURE.getTime()),
            lastEventType: 'INITIAL_PURCHASE',
          }),
        }),
      );
      expect(redis.store.has(`premium:${LOCAL_USER_ID}`)).toBe(false);
    });

    it('resolves the user via aliases when app_user_id is a RevenueCat anonymous id', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/webhooks/revenuecat',
        headers: { authorization: 'rc-secret' },
        payload: event({ app_user_id: '$RCAnonymousID:abc123', aliases: [LOCAL_USER_ID] }),
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().action).toBe('applied');
    });

    it('200 unknown_user for an unknown user (no RevenueCat retry)', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/webhooks/revenuecat',
        headers: { authorization: 'rc-secret' },
        payload: event({ app_user_id: '999e4567-e89b-42d3-a456-426614174999', aliases: [] }),
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().action).toBe('unknown_user');
      expect(prisma.subscription.upsert).not.toHaveBeenCalled();
    });

    it('ignores a TEST event without touching the DB', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/webhooks/revenuecat',
        headers: { authorization: 'rc-secret' },
        payload: event({ type: 'TEST' }),
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().action).toBe('ignored_test');
      expect(prisma.subscription.upsert).not.toHaveBeenCalled();
    });

    it('ignores an event older than the last one applied (anti-reordering)', async () => {
      prisma.subscription.findUnique.mockResolvedValue({
        ...activeSubscription,
        lastEventAt: new Date('2026-08-10T12:00:00Z'),
      });
      const res = await app.inject({
        method: 'POST',
        url: '/webhooks/revenuecat',
        headers: { authorization: 'rc-secret' },
        payload: event({ event_timestamp_ms: new Date('2026-08-09T12:00:00Z').getTime() }),
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().action).toBe('stale_ignored');
      expect(prisma.subscription.upsert).not.toHaveBeenCalled();
    });

    it('an EXPIRATION revokes access: a past expiry makes premium inactive', async () => {
      prisma.subscription.findUnique.mockResolvedValue(activeSubscription);
      const res = await app.inject({
        method: 'POST',
        url: '/webhooks/revenuecat',
        headers: { authorization: 'rc-secret' },
        payload: event({ type: 'EXPIRATION', expiration_at_ms: PAST.getTime() }),
      });
      expect(res.statusCode).toBe(200);
      expect(prisma.subscription.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          update: expect.objectContaining({
            expiresAt: new Date(PAST.getTime()),
            lastEventType: 'EXPIRATION',
          }),
        }),
      );
    });
  });

  describe('Premium gating of the endpoints', () => {
    const person = {
      currentAge: 35,
      retirementAge: 65,
      grossAnnualIncome: 9_000_000,
      currentPillar2Capital: 5_000_000,
      annualPillar2Contribution: 700_000,
    };
    const coupleBody = {
      canton: 'VD',
      maritalStatus: 'MARRIED',
      person1: person,
      person2: { ...person, grossAnnualIncome: 8_000_000 },
    };

    it('402 on /calculator/couple without a subscription', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/calculator/couple',
        headers: authHeaders,
        payload: coupleBody,
      });
      expect(res.statusCode).toBe(402);
      expect(res.json().error).toBeTruthy();
    });

    it('401 on /calculator/couple without authentication', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/calculator/couple',
        payload: coupleBody,
      });
      expect(res.statusCode).toBe(401);
    });

    it('200 on /calculator/couple with an active subscription', async () => {
      prisma.subscription.findUnique.mockResolvedValue(activeSubscription);
      const res = await app.inject({
        method: 'POST',
        url: '/calculator/couple',
        headers: authHeaders,
        payload: coupleBody,
      });
      expect(res.statusCode).toBe(200);
    });

    it('402 on /recommendations without a subscription, /score stays accessible', async () => {
      const rec = await app.inject({
        method: 'GET',
        url: '/recommendations',
        headers: authHeaders,
      });
      expect(rec.statusCode).toBe(402);
    });

    it('3a-catchup anonymous: preview — totals visible, year-by-year plan hidden', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/calculator/3a-catchup',
        payload: { taxableIncome: 8_000_000, yearsSinceFirstEligible: 1 },
      });
      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(body.premiumRequired).toBe(true);
      expect(body.yearDetails).toEqual([]);
      expect(body.totalCatchupPotential).toBeGreaterThan(0);
      expect(body.estimatedTaxSavings).toBeGreaterThan(0);
    });

    it('3a-catchup premium: full year-by-year plan', async () => {
      prisma.subscription.findUnique.mockResolvedValue(activeSubscription);
      const res = await app.inject({
        method: 'POST',
        url: '/calculator/3a-catchup',
        headers: authHeaders,
        payload: { taxableIncome: 8_000_000, yearsSinceFirstEligible: 1 },
      });
      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(body.premiumRequired).toBe(false);
      expect(body.yearDetails.length).toBeGreaterThan(0);
    });

    it('an invalid token on 3a-catchup falls back to the preview (never 401)', async () => {
      mocks.getUser.mockResolvedValue({ data: { user: null }, error: { message: 'bad' } });
      const res = await app.inject({
        method: 'POST',
        url: '/calculator/3a-catchup',
        headers: authHeaders,
        payload: { taxableIncome: 8_000_000 },
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().premiumRequired).toBe(true);
    });
  });

  describe('GET /users/me — premium block', () => {
    it('exposes premium.active=false without a subscription', async () => {
      const res = await app.inject({ method: 'GET', url: '/users/me', headers: authHeaders });
      expect(res.statusCode).toBe(200);
      expect(res.json().premium).toEqual({ active: false, expiresAt: null });
    });

    it('exposes premium.active=true and the date with an active subscription', async () => {
      prisma.subscription.findUnique.mockResolvedValue(activeSubscription);
      const res = await app.inject({ method: 'GET', url: '/users/me', headers: authHeaders });
      expect(res.statusCode).toBe(200);
      expect(res.json().premium).toEqual({
        active: true,
        expiresAt: FUTURE.toISOString(),
      });
    });
  });
});
