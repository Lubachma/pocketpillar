import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createHash } from 'node:crypto';
import type { FastifyReply, FastifyRequest } from 'fastify';

// Minimal env so importing src/config (via the plugin) does not exit the process.
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

import { authenticate } from '../../src/plugins/auth.js';

const TOKEN = 'valid-token';
const TOKEN_SUB = '123e4567-e89b-42d3-a456-426614174000';
const TOKEN_EMAIL = 'user@example.ch';
const LOCAL_USER_ID = 'local-user-1';

function cacheKey(token: string): string {
  return 'auth:jwt:' + createHash('sha256').update(token).digest('hex');
}

function invalidCacheKey(token: string): string {
  return 'auth:jwt:invalid:' + createHash('sha256').update(token).digest('hex');
}

/** Unsigned test double of a JWT — only the exp claim matters to the cache TTL. */
function fakeJwt(exp: number): string {
  const b64 = (obj: unknown) => Buffer.from(JSON.stringify(obj)).toString('base64url');
  return `${b64({ alg: 'HS256', typ: 'JWT' })}.${b64({ sub: TOKEN_SUB, exp })}.signature`;
}

function createReply() {
  const reply = {
    statusCode: 200,
    payload: undefined as unknown,
    headers: {} as Record<string, string>,
    status(code: number) {
      reply.statusCode = code;
      return reply;
    },
    header(name: string, value: string) {
      reply.headers[name] = value;
      return reply;
    },
    send(payload?: unknown) {
      reply.payload = payload;
      return reply;
    },
  };
  return reply as unknown as FastifyReply & {
    statusCode: number;
    payload: unknown;
    headers: Record<string, string>;
  };
}

interface SetupOptions {
  /** null → no Authorization header at all */
  token?: string | null;
  /** Raw value returned by redis.get for the claims key (null → cache miss) */
  cached?: string | null;
  /** Raw value returned by redis.get for the invalid-marker key (null → no marker) */
  invalidCached?: string | null;
  /** Prisma user row returned by findUnique (null → deleted account) */
  prismaUser?: unknown;
}

function setup(options: SetupOptions = {}) {
  const {
    token = TOKEN,
    cached = null,
    invalidCached = null,
    prismaUser = { id: LOCAL_USER_ID },
  } = options;
  const redis = {
    get: vi.fn(async (key: string) =>
      key.startsWith('auth:jwt:invalid:') ? invalidCached : cached,
    ),
    set: vi.fn().mockResolvedValue('OK'),
  };
  const findUnique = vi.fn().mockResolvedValue(prismaUser);
  const warn = vi.fn();
  const request = {
    headers: token ? { authorization: `Bearer ${token}` } : {},
    locale: 'fr',
    userId: null as string | null,
    log: { warn },
    server: { redis, prisma: { user: { findUnique } } },
  } as unknown as FastifyRequest;
  return { request, redis, findUnique, warn, reply: createReply() };
}

function mockValidToken() {
  mocks.getUser.mockResolvedValue({
    data: { user: { id: TOKEN_SUB, email: TOKEN_EMAIL } },
    error: null,
  });
}

describe('authenticate — JWT Redis cache', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('rejects a missing Authorization header (401) without touching Redis or Supabase', async () => {
    const { request, reply, redis } = setup({ token: null });

    await authenticate(request, reply);

    expect(reply.statusCode).toBe(401);
    expect(reply.payload).toEqual({ error: "En-tête d'autorisation manquant ou invalide" });
    expect(redis.get).not.toHaveBeenCalled();
    expect(mocks.getUser).not.toHaveBeenCalled();
  });

  it('cache hit: validates from Redis without calling Supabase again', async () => {
    const { request, reply, redis, findUnique } = setup({
      cached: JSON.stringify({ userId: TOKEN_SUB }),
    });

    await authenticate(request, reply);

    expect(reply.statusCode).toBe(200);
    expect(request.userId).toBe(LOCAL_USER_ID);
    expect(redis.get).toHaveBeenCalledWith(cacheKey(TOKEN));
    expect(mocks.getUser).not.toHaveBeenCalled();
    expect(redis.set).not.toHaveBeenCalled();
    // The Prisma user resolution still runs on every request.
    expect(findUnique).toHaveBeenCalledWith({
      where: { supabaseId: TOKEN_SUB },
      select: { id: true },
    });
  });

  it('cache miss: validates with Supabase, then caches the claims with a bounded TTL', async () => {
    mockValidToken();
    const { request, reply, redis } = setup();

    await authenticate(request, reply);

    expect(reply.statusCode).toBe(200);
    expect(request.userId).toBe(LOCAL_USER_ID);
    expect(mocks.getUser).toHaveBeenCalledTimes(1);
    expect(redis.set).toHaveBeenCalledTimes(1);

    const [key, raw, ex, ttl] = redis.set.mock.calls[0] as [string, string, string, number];
    expect(key).toBe(cacheKey(TOKEN));
    // The raw token must never end up in Redis — only its hash.
    expect(key).not.toContain(TOKEN);
    expect(JSON.parse(raw)).toEqual({ userId: TOKEN_SUB });
    expect(ex).toBe('EX');
    expect(ttl).toBeGreaterThan(0);
    expect(ttl).toBeLessThanOrEqual(300);
  });

  it('fail-open: a Redis read failure falls back to the Supabase call', async () => {
    mockValidToken();
    const { request, reply, redis, warn } = setup();
    redis.get.mockRejectedValue(new Error('redis down'));

    await authenticate(request, reply);

    expect(mocks.getUser).toHaveBeenCalledTimes(1);
    expect(request.userId).toBe(LOCAL_USER_ID);
    expect(reply.statusCode).toBe(200);
    expect(warn).toHaveBeenCalled();
  });

  it('fail-open: a Redis write failure does not break authentication', async () => {
    mockValidToken();
    const { request, reply, redis, warn } = setup();
    redis.set.mockRejectedValue(new Error('redis down'));

    await authenticate(request, reply);

    expect(request.userId).toBe(LOCAL_USER_ID);
    expect(reply.statusCode).toBe(200);
    expect(warn).toHaveBeenCalled();
  });

  it('invalid token → 401 with a 30 s negative marker (distinct key, never the claims key)', async () => {
    mocks.getUser.mockResolvedValue({
      data: { user: null },
      error: Object.assign(new Error('bad token'), { name: 'AuthApiError', status: 403 }),
    });
    const { request, reply, redis } = setup();

    await authenticate(request, reply);

    expect(reply.statusCode).toBe(401);
    expect(reply.payload).toEqual({ error: 'Jeton invalide ou expiré' });
    expect(redis.set).toHaveBeenCalledTimes(1);
    const [key, value, ex, ttl] = redis.set.mock.calls[0] as [string, string, string, number];
    expect(key).toBe(invalidCacheKey(TOKEN));
    // The raw token must never end up in Redis — only its hash.
    expect(key).not.toContain(TOKEN);
    expect(value).toBe('1');
    expect(ex).toBe('EX');
    expect(ttl).toBe(30);
  });

  it('Supabase outage (retryable error) → 503, and the token is NOT negatively cached', async () => {
    // supabase-js RETURNS network failures instead of throwing:
    // AuthRetryableFetchError with status 0/5xx. Caching that as "invalid"
    // logged every valid user out for 30 s per flap (review 08.2026).
    mocks.getUser.mockResolvedValue({
      data: { user: null },
      error: Object.assign(new Error('fetch failed'), {
        name: 'AuthRetryableFetchError',
        status: 0,
      }),
    });
    const { request, reply, redis } = setup();

    await authenticate(request, reply);

    expect(reply.statusCode).toBe(503);
    expect(redis.set).not.toHaveBeenCalled();

    // Supabase back up: the SAME token authenticates again immediately
    // (fresh setup — the point is that NO negative marker was written).
    mockValidToken();
    const second = setup();
    await authenticate(second.request, second.reply);
    expect(second.reply.statusCode).toBe(200);
  });

  it('a 429 from Supabase Auth → 503 + Retry-After, valid tokens are NOT revoked', async () => {
    // Supabase rate-limits getUser PER IP — and one backend egress IP
    // serves every user. Classifying a burst 429 as "invalid token"
    // would mass-revoke valid sessions for 30 s (follow-up review).
    mocks.getUser.mockResolvedValue({
      data: { user: null },
      error: Object.assign(new Error('over_request_rate_limit'), {
        name: 'AuthApiError',
        status: 429,
      }),
    });
    const { request, reply, redis } = setup();

    await authenticate(request, reply);

    expect(reply.statusCode).toBe(503);
    expect(reply.headers['Retry-After']).toBe('30');
    expect(redis.set).not.toHaveBeenCalled();

    // Burst over: the SAME token authenticates immediately.
    mockValidToken();
    const second = setup();
    await authenticate(second.request, second.reply);
    expect(second.reply.statusCode).toBe(200);
  });

  it('a 503 from Supabase Auth → 503 (5xx statuses are availability, not validity)', async () => {
    mocks.getUser.mockResolvedValue({
      data: { user: null },
      error: Object.assign(new Error('upstream'), { status: 503 }),
    });
    const { request, reply, redis } = setup();

    await authenticate(request, reply);

    expect(reply.statusCode).toBe(503);
    expect(redis.set).not.toHaveBeenCalled();
  });

  it('a THROWN network error → 503, not a 401 (nothing cached either)', async () => {
    mocks.getUser.mockRejectedValue(new Error('socket hang up'));
    const { request, reply, redis } = setup();

    await authenticate(request, reply);

    expect(reply.statusCode).toBe(503);
    expect(redis.set).not.toHaveBeenCalled();
  });

  it('negative cache hit: an already-rejected token gets an immediate 401, no Supabase call', async () => {
    const { request, reply, redis, findUnique } = setup({ invalidCached: '1' });

    await authenticate(request, reply);

    expect(reply.statusCode).toBe(401);
    expect(reply.payload).toEqual({ error: 'Jeton invalide ou expiré' });
    expect(mocks.getUser).not.toHaveBeenCalled();
    expect(redis.set).not.toHaveBeenCalled();
    // The Prisma user resolution is never reached for a rejected token.
    expect(findUnique).not.toHaveBeenCalled();
  });

  it('two requests with the same invalid token → a single Supabase call', async () => {
    mocks.getUser.mockResolvedValue({
      data: { user: null },
      error: Object.assign(new Error('bad token'), { name: 'AuthApiError', status: 403 }),
    });
    // Stateful Redis fake: the marker written by the first request is seen by the second.
    const store = new Map<string, string>();
    const redis = {
      get: vi.fn(async (key: string) => store.get(key) ?? null),
      set: vi.fn(async (key: string, value: string) => {
        store.set(key, value);
        return 'OK';
      }),
    };
    const findUnique = vi.fn().mockResolvedValue({ id: LOCAL_USER_ID });
    const makeRequest = () =>
      ({
        headers: { authorization: `Bearer ${TOKEN}` },
        locale: 'fr',
        userId: null,
        log: { warn: vi.fn() },
        server: { redis, prisma: { user: { findUnique } } },
      }) as unknown as FastifyRequest;

    await authenticate(makeRequest(), createReply());
    const secondReply = createReply();
    await authenticate(makeRequest(), secondReply);

    expect(secondReply.statusCode).toBe(401);
    expect(mocks.getUser).toHaveBeenCalledTimes(1);
    expect(store.has(invalidCacheKey(TOKEN))).toBe(true);
  });

  it('revalidates with Supabase once the negative marker has expired', async () => {
    mocks.getUser.mockResolvedValue({
      data: { user: null },
      error: Object.assign(new Error('bad token'), { name: 'AuthApiError', status: 403 }),
    });
    const store = new Map<string, string>();
    const redis = {
      get: vi.fn(async (key: string) => store.get(key) ?? null),
      set: vi.fn(async (key: string, value: string) => {
        store.set(key, value);
        return 'OK';
      }),
    };
    const makeRequest = () =>
      ({
        headers: { authorization: `Bearer ${TOKEN}` },
        locale: 'fr',
        userId: null,
        log: { warn: vi.fn() },
        server: { redis, prisma: { user: { findUnique: vi.fn() } } },
      }) as unknown as FastifyRequest;

    await authenticate(makeRequest(), createReply());
    // TTL expiry is Redis' job (EX 30) — simulate it by evicting the marker.
    store.clear();
    await authenticate(makeRequest(), createReply());

    expect(mocks.getUser).toHaveBeenCalledTimes(2);
  });

  it('does not cache an already-expired token (TTL bounded by the exp claim)', async () => {
    mockValidToken();
    const expired = fakeJwt(Math.floor(Date.now() / 1000) - 10);
    const { request, reply, redis } = setup({ token: expired });

    await authenticate(request, reply);

    expect(request.userId).toBe(LOCAL_USER_ID);
    expect(redis.set).not.toHaveBeenCalled();
  });

  it('bounds the TTL to the remaining token lifetime when exp comes first', async () => {
    mockValidToken();
    const exp = Math.floor(Date.now() / 1000) + 120;
    const { request, reply, redis } = setup({ token: fakeJwt(exp) });

    await authenticate(request, reply);

    expect(redis.set).toHaveBeenCalledTimes(1);
    const [, , , ttl] = redis.set.mock.calls[0] as [string, string, string, number];
    expect(ttl).toBeGreaterThan(0);
    expect(ttl).toBeLessThanOrEqual(120);
  });

  it('ignores a malformed cache entry and revalidates with Supabase', async () => {
    mockValidToken();
    const { request, reply, redis } = setup({ cached: '{"unexpected":"shape"}' });

    await authenticate(request, reply);

    expect(mocks.getUser).toHaveBeenCalledTimes(1);
    expect(redis.set).toHaveBeenCalledTimes(1);
    expect(request.userId).toBe(LOCAL_USER_ID);
  });

  it('rejects a deleted Prisma user (401) even on a cache hit — existence is never cached', async () => {
    const { request, reply } = setup({
      cached: JSON.stringify({ userId: TOKEN_SUB }),
      prismaUser: null,
    });

    await authenticate(request, reply);

    expect(reply.statusCode).toBe(401);
    expect(reply.payload).toEqual({ error: 'Utilisateur non trouvé' });
    expect(mocks.getUser).not.toHaveBeenCalled();
  });
});
