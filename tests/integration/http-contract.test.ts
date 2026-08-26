import { describe, it, expect, beforeAll, beforeEach, afterAll, vi } from 'vitest';
import { createRequire } from 'node:module';
import type { FastifyInstance } from 'fastify';

// Minimal env so importing src/config (via the harness) does not exit the process.
const mocks = vi.hoisted(() => {
  process.env.DATABASE_URL = 'postgresql://localhost:5432/test';
  process.env.REDIS_URL = 'redis://localhost:6379';
  process.env.SUPABASE_URL = 'https://test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
  return { getUser: vi.fn() };
});

vi.mock('../../src/lib/supabase.js', () => ({
  supabaseAdmin: { auth: { getUser: mocks.getUser } },
}));

import { buildTestApp, createFakePrisma, createFakeRedis } from '../helpers/test-app.js';

const { version: APP_VERSION } = createRequire(import.meta.url)('../../package.json') as {
  version: string;
};

const TOKEN_SUB = '123e4567-e89b-42d3-a456-426614174000';
const TOKEN_EMAIL = 'user@example.ch';
const LOCAL_USER_ID = 'local-user-1';
const LOCAL_USER = {
  id: LOCAL_USER_ID,
  email: TOKEN_EMAIL,
  canton: 'ZH',
  birthYear: 1990,
  replacementRateGoal: 70,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
};

/**
 * HTTP contract tests: route → auth → validation → error format wiring,
 * verified through app.inject on a full app (real plugins, real route
 * modules, in-memory Prisma/Redis, mocked Supabase). Business logic is
 * covered elsewhere and intentionally not re-tested here.
 */
describe('HTTP contract — full app wiring', () => {
  let app: FastifyInstance;
  const prisma = createFakePrisma();
  const redis = createFakeRedis();

  beforeAll(async () => {
    // authenticate looks up by supabaseId, getMeHandler / registerHandler by id.
    prisma.user.findUnique.mockImplementation(
      ({ where }: { where: { supabaseId?: string; id?: string } }) => {
        if (where.supabaseId === TOKEN_SUB) return Promise.resolve(LOCAL_USER);
        if (where.id === LOCAL_USER_ID) return Promise.resolve(LOCAL_USER);
        return Promise.resolve(null);
      },
    );
    app = await buildTestApp({ prisma, redis });
  });

  beforeEach(() => {
    vi.clearAllMocks();
    // Premium gating caches `premium:<userId>` — clear it between tests
    // to prevent a premium test from contaminating the following ones.
    redis.store.clear();
    prisma.subscription.findUnique.mockResolvedValue(null);
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health → 200 with the dynamic version from package.json', async () => {
    const res = await app.inject({ method: 'GET', url: '/health' });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.status).toBe('ok');
    expect(body.version).toBe(APP_VERSION);
  });

  it('GET /users/me → 401 { error } without a token', async () => {
    const res = await app.inject({ method: 'GET', url: '/users/me' });

    expect(res.statusCode).toBe(401);
    expect(res.json()).toEqual({ error: "En-tête d'autorisation manquant ou invalide" });
  });

  it('GET /users/me → 200 with a valid token; the JWT cache avoids a second Supabase call', async () => {
    mocks.getUser.mockResolvedValue({
      data: { user: { id: TOKEN_SUB, email: TOKEN_EMAIL } },
      error: null,
    });
    const headers = { authorization: 'Bearer integration-token' };

    const first = await app.inject({ method: 'GET', url: '/users/me', headers });
    expect(first.statusCode).toBe(200);
    expect(first.json()).toMatchObject({ id: LOCAL_USER_ID, email: TOKEN_EMAIL });
    expect(mocks.getUser).toHaveBeenCalledTimes(1);

    // Second call, same token: served from the Redis cache (in-memory fake).
    const second = await app.inject({ method: 'GET', url: '/users/me', headers });
    expect(second.statusCode).toBe(200);
    expect(mocks.getUser).toHaveBeenCalledTimes(1);
  });

  it('POST /auth/register → 401 { error } without a token', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/auth/register',
      payload: { email: TOKEN_EMAIL, supabaseId: TOKEN_SUB },
    });

    expect(res.statusCode).toBe(401);
    expect(res.json()).toEqual({ error: "En-tête d'autorisation manquant ou invalide" });
  });

  it('POST /auth/register → 400 { error } on an invalid body (route schema validation)', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/auth/register',
      headers: { authorization: 'Bearer register-token' },
      payload: {},
    });

    expect(res.statusCode).toBe(400);
    const body = res.json();
    // Unified error shape — the native statusCode/message fields are gone.
    expect(typeof body.error).toBe('string');
    expect(body.statusCode).toBeUndefined();
    expect(body.message).toBeUndefined();
  });

  it('POST /auth/register → 200 with { supabaseId } alone (body email is optional)', async () => {
    mocks.getUser.mockResolvedValue({
      data: { user: { id: TOKEN_SUB, email: TOKEN_EMAIL } },
      error: null,
    });

    const res = await app.inject({
      method: 'POST',
      url: '/auth/register',
      headers: { authorization: 'Bearer register-valid-token' },
      payload: { supabaseId: TOKEN_SUB },
    });

    // Proves the route JSON-schema no longer requires `email` — the request
    // reaches the handler, which resolves the already-registered user.
    expect(res.statusCode).toBe(200);
    expect(res.json()).toMatchObject({ id: LOCAL_USER_ID, email: TOKEN_EMAIL });
    expect(prisma.user.create).not.toHaveBeenCalled();
  });

  it('GET /documents → 401 { error } without a token', async () => {
    const res = await app.inject({ method: 'GET', url: '/documents' });

    expect(res.statusCode).toBe(401);
    expect(res.json()).toEqual({ error: "En-tête d'autorisation manquant ou invalide" });
  });

  it('GET /score → 401 { error } without a token', async () => {
    const res = await app.inject({ method: 'GET', url: '/score' });

    expect(res.statusCode).toBe(401);
    expect(res.json()).toEqual({ error: "En-tête d'autorisation manquant ou invalide" });
  });

  // divorce-impact is a Premium scenario: authentication + active subscription.
  function primePremiumUser() {
    mocks.getUser.mockResolvedValue({
      data: { user: { id: TOKEN_SUB, email: TOKEN_EMAIL } },
      error: null,
    });
    prisma.subscription.findUnique.mockResolvedValue({
      expiresAt: new Date(Date.now() + 86_400_000),
      lastEventAt: new Date(0),
    });
  }

  it('POST /calculator/divorce-impact → 400 { error } on inverted capitals (Zod refine)', async () => {
    primePremiumUser();
    const res = await app.inject({
      method: 'POST',
      url: '/calculator/divorce-impact',
      headers: { authorization: 'Bearer premium-token' },
      payload: {
        age: 40,
        // Inversion: capital at marriage cannot exceed the current capital.
        bvgCapitalAtMarriage: 200_000,
        bvgCapitalNow: 100_000,
        spouseBvgCapitalAtMarriage: 50_000,
        spouseBvgCapitalNow: 150_000,
        yearsMarried: 10,
        annualContribution: 5_000,
      },
    });

    expect(res.statusCode).toBe(400);
    // NODE_ENV=test → no dev-only `details` field leaks into the payload.
    expect(res.json()).toEqual({ error: 'Erreur de validation' });
  });

  it('POST /calculator/divorce-impact → 402 { error } without a premium subscription', async () => {
    mocks.getUser.mockResolvedValue({
      data: { user: { id: TOKEN_SUB, email: TOKEN_EMAIL } },
      error: null,
    });
    const res = await app.inject({
      method: 'POST',
      url: '/calculator/divorce-impact',
      headers: { authorization: 'Bearer free-token' },
      payload: {},
    });

    expect(res.statusCode).toBe(402);
    expect(res.json()).toEqual({
      error: 'Cette fonctionnalité fait partie de PocketPillar Premium.',
    });
  });

  it('POST /calculator/divorce-impact → 200 on a valid payload (route → handler wiring)', async () => {
    primePremiumUser();
    const res = await app.inject({
      method: 'POST',
      url: '/calculator/divorce-impact',
      headers: { authorization: 'Bearer premium-token' },
      payload: {
        age: 40,
        bvgCapitalAtMarriage: 100_000,
        bvgCapitalNow: 200_000,
        spouseBvgCapitalAtMarriage: 50_000,
        spouseBvgCapitalNow: 150_000,
        yearsMarried: 10,
        annualContribution: 5_000,
      },
    });

    expect(res.statusCode).toBe(200);
    expect(typeof res.json().transferAmount).toBe('number');
  });

  it('GET /calculator/municipalities?canton=ZH → 200 with the sorted covered municipalities', async () => {
    const res = await app.inject({ method: 'GET', url: '/calculator/municipalities?canton=ZH' });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(Array.isArray(body)).toBe(true);
    expect(body.length).toBeGreaterThan(0);
    expect(body[0]).toEqual({ name: 'Adliswil', multiplier: 104 });
    expect(body).toContainEqual({ name: 'Zürich', multiplier: 119 });
    // Sorted by name (every entry has exactly { name, multiplier }).
    const names = body.map((m: { name: string }) => m.name);
    expect(names).toEqual([...names].sort((a: string, b: string) => a.localeCompare(b)));
    expect(Object.keys(body[0]).sort()).toEqual(['multiplier', 'name']);
  });

  it('GET /calculator/municipalities?canton=JU → 200 [] (canton without covered municipality)', async () => {
    const res = await app.inject({ method: 'GET', url: '/calculator/municipalities?canton=JU' });

    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual([]);
  });

  it('GET /calculator/municipalities → 400 { error } on an invalid or missing canton', async () => {
    const invalid = await app.inject({
      method: 'GET',
      url: '/calculator/municipalities?canton=XX',
    });
    expect(invalid.statusCode).toBe(400);
    expect(invalid.json()).toEqual({ error: 'Erreur de validation' });

    const missing = await app.inject({ method: 'GET', url: '/calculator/municipalities' });
    expect(missing.statusCode).toBe(400);
    expect(missing.json()).toEqual({ error: 'Erreur de validation' });
  });

  it('POST /calculator/tax-savings accepts an optional municipality (unknown → cantonal average)', async () => {
    const payload = { canton: 'ZH', taxableIncome: 10_000_000, contribution: 725_800 };

    const known = await app.inject({
      method: 'POST',
      url: '/calculator/tax-savings',
      payload: { ...payload, municipality: 'Winterthur' },
    });
    expect(known.statusCode).toBe(200);
    // Winterthur 125 % on the simple tax saving (FTA (Federal Tax Administration) 2026 tables:
    // simple(100'000) − simple(92'742) = 653.22 × 1.25 = 816.52).
    expect(known.json().communalTaxSaving).toBe(81_652);

    const unknown = await app.inject({
      method: 'POST',
      url: '/calculator/tax-savings',
      payload: { ...payload, municipality: 'Inexistante' },
    });
    expect(unknown.statusCode).toBe(200);
    // Fallback: ZH cantonal average 119 % → 653.22 × 1.19 = 777.33.
    expect(unknown.json().communalTaxSaving).toBe(77_733);
  });
});
