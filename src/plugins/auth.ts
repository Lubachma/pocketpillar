import fp from 'fastify-plugin';
import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { createHash } from 'node:crypto';
import { supabaseAdmin } from '../lib/supabase.js';
import { t } from '../lib/i18n/index.js';

export default fp(async (fastify: FastifyInstance) => {
  fastify.decorateRequest('userId', null);
});

/** Upper bound on the JWT validation cache lifetime (seconds). */
const JWT_CACHE_MAX_TTL_SECONDS = 300;
const JWT_CACHE_KEY_PREFIX = 'auth:jwt:';
/** Negative cache: rejected tokens are remembered briefly to absorb DoS amplification toward Supabase Auth. */
const JWT_INVALID_CACHE_TTL_SECONDS = 30;
const JWT_INVALID_CACHE_KEY_PREFIX = 'auth:jwt:invalid:';

/**
 * What the cache holds: the Supabase token validation outcome only — the
 * `sub`, and nothing else (no email: PII without a consumer here). The
 * Prisma user resolution is deliberately NOT cached — a deleted account
 * must stop authenticating immediately.
 */
interface CachedJwtClaims {
  userId: string; // Supabase `sub`
}

/** Cache key: sha256 of the token — the raw JWT is never stored in Redis. */
function jwtCacheKey(token: string): string {
  return JWT_CACHE_KEY_PREFIX + createHash('sha256').update(token).digest('hex');
}

/** Negative-cache key: distinct prefix, so a marker can never serve as claims. */
function jwtInvalidCacheKey(token: string): string {
  return JWT_INVALID_CACHE_KEY_PREFIX + createHash('sha256').update(token).digest('hex');
}

/**
 * Bounded TTL: never beyond the token's own `exp` claim, never beyond
 * JWT_CACHE_MAX_TTL_SECONDS. A value ≤ 0 means "do not cache".
 */
function jwtCacheTtl(token: string): number {
  let ttl = JWT_CACHE_MAX_TTL_SECONDS;
  try {
    const segment = token.split('.')[1];
    if (segment) {
      const { exp } = JSON.parse(Buffer.from(segment, 'base64url').toString('utf8')) as {
        exp?: unknown;
      };
      if (typeof exp === 'number') {
        ttl = Math.min(ttl, Math.floor(exp - Date.now() / 1000));
      }
    }
  } catch {
    // Undecodable token — the default TTL applies.
  }
  return ttl;
}

/** Cache read — fail-open: any Redis/parse error falls back to a Supabase call. */
async function readCachedClaims(
  request: FastifyRequest,
  key: string,
): Promise<CachedJwtClaims | null> {
  try {
    const raw = await request.server.redis.get(key);
    if (!raw) return null;
    const parsed: unknown = JSON.parse(raw);
    if (!parsed || typeof parsed !== 'object') return null;
    const { userId } = parsed as Record<string, unknown>;
    if (typeof userId !== 'string') return null;
    return { userId };
  } catch (err) {
    request.log.warn({ err }, 'JWT cache read failed — falling back to Supabase');
    return null;
  }
}

/** Cache write — fail-open: a Redis failure must never break authentication. */
async function writeCachedClaims(
  request: FastifyRequest,
  key: string,
  token: string,
  claims: CachedJwtClaims,
): Promise<void> {
  try {
    const ttl = jwtCacheTtl(token);
    if (ttl <= 0) return; // already expired — nothing worth caching
    await request.server.redis.set(key, JSON.stringify(claims), 'EX', ttl);
  } catch (err) {
    request.log.warn({ err }, 'JWT cache write failed');
  }
}

/** Negative-cache read — fail-open: any Redis error means "no marker", revalidate. */
async function readInvalidMarker(request: FastifyRequest, key: string): Promise<boolean> {
  try {
    return (await request.server.redis.get(key)) !== null;
  } catch (err) {
    request.log.warn({ err }, 'JWT negative cache read failed — falling back to Supabase');
    return false;
  }
}

/** Negative-cache write — fail-open, like the claims cache. */
async function writeInvalidMarker(request: FastifyRequest, key: string): Promise<void> {
  try {
    await request.server.redis.set(key, '1', 'EX', JWT_INVALID_CACHE_TTL_SECONDS);
  } catch (err) {
    request.log.warn({ err }, 'JWT negative cache write failed');
  }
}

export type AuthFailure = 'missing_header' | 'invalid_token' | 'user_not_found';

/**
 * Bearer resolution — Supabase JWT (including caches) then local user.
 * Never replies itself: `authenticate` turns it into a strict 401, the premium
 * gating of public endpoints (3a-catchup preview) into a best-effort resolution.
 */
export async function resolveAuth(
  request: FastifyRequest,
): Promise<{ userId: string } | { failure: AuthFailure }> {
  const authHeader = request.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return { failure: 'missing_header' };
  }

  const token = authHeader.slice(7);
  const invalidKey = jwtInvalidCacheKey(token);

  // Negative cache: a token rejected moments ago is rejected again immediately,
  // without another round-trip to Supabase Auth.
  if (await readInvalidMarker(request, invalidKey)) {
    return { failure: 'invalid_token' };
  }

  const cacheKey = jwtCacheKey(token);
  let claims = await readCachedClaims(request, cacheKey);

  if (!claims) {
    // A network/Supabase failure must surface as a clean 401, not an unhandled 500.
    try {
      const { data, error } = await supabaseAdmin.auth.getUser(token);
      if (error || !data.user) {
        // Cache the rejection briefly — a thrown network error is NOT cached:
        // it says nothing about the token's validity.
        await writeInvalidMarker(request, invalidKey);
        return { failure: 'invalid_token' };
      }
      claims = { userId: data.user.id };
    } catch {
      return { failure: 'invalid_token' };
    }
    await writeCachedClaims(request, cacheKey, token, claims);
  }

  const user = await request.server.prisma.user.findUnique({
    where: { supabaseId: claims.userId },
    select: { id: true },
  });

  if (!user) {
    return { failure: 'user_not_found' };
  }

  return { userId: user.id };
}

/** preHandler hook — extract and verify Supabase JWT, resolve local user */
export async function authenticate(request: FastifyRequest, reply: FastifyReply) {
  const auth = await resolveAuth(request);
  if ('failure' in auth) {
    const key =
      auth.failure === 'missing_header'
        ? 'auth.missing_header'
        : auth.failure === 'user_not_found'
          ? 'auth.user_not_found'
          : 'auth.invalid_token';
    return reply.status(401).send({ error: t(request.locale, key) });
  }
  request.userId = auth.userId;
}
