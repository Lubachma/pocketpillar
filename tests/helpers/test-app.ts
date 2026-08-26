import { vi } from 'vitest';
import Fastify, { type FastifyInstance } from 'fastify';
import type { PrismaClient } from '@prisma/client';
import type { Redis } from 'ioredis';
import i18nPlugin from '../../src/plugins/i18n.js';
import errorHandlerPlugin from '../../src/plugins/error-handler.js';
import authPlugin from '../../src/plugins/auth.js';
import healthRoutes from '../../src/modules/health/health.routes.js';
import authRoutes from '../../src/modules/auth/auth.routes.js';
import userRoutes from '../../src/modules/user/user.routes.js';
import calculatorRoutes from '../../src/modules/calculator/calculator.routes.js';
import documentRoutes from '../../src/modules/document/document.routes.js';
import recommendationRoutes from '../../src/modules/recommendation/recommendation.routes.js';
import subscriptionRoutes from '../../src/modules/subscription/subscription.routes.js';

/**
 * Test harness for HTTP contract tests: a real Fastify instance with the
 * production plugins (i18n, error-handler, auth) and route modules, but with
 * Prisma and Redis replaced by in-memory fakes — no Docker, no network.
 *
 * Supabase is NOT faked here: each test file mocks `src/lib/supabase.js`
 * with `vi.mock` (hoisted), which intercepts the import across the whole
 * module graph, including the route handlers registered below.
 */

/** Prisma fake: vi.fn() delegates the tests can program per scenario. */
export function createFakePrisma() {
  return {
    user: {
      findUnique: vi.fn().mockResolvedValue(null),
      create: vi.fn().mockResolvedValue(null),
    },
    subscription: {
      findUnique: vi.fn().mockResolvedValue(null),
      upsert: vi.fn().mockResolvedValue(null),
    },
    document: {
      count: vi.fn().mockResolvedValue(0),
    },
  };
}
export type FakePrisma = ReturnType<typeof createFakePrisma>;

/** Redis fake: a real in-memory Map so the JWT cache behaves like production. */
export function createFakeRedis() {
  const store = new Map<string, string>();
  return {
    store,
    get: vi.fn(async (key: string) => store.get(key) ?? null),
    set: vi.fn(async (key: string, value: string) => {
      store.set(key, value);
      return 'OK';
    }),
    del: vi.fn(async (key: string) => {
      const existed = store.delete(key);
      return existed ? 1 : 0;
    }),
    ping: vi.fn(async () => 'PONG'),
    quit: vi.fn(async () => 'OK'),
  };
}
export type FakeRedis = ReturnType<typeof createFakeRedis>;

export interface TestAppFakes {
  prisma?: FakePrisma;
  redis?: FakeRedis;
}

export async function buildTestApp(fakes: TestAppFakes = {}): Promise<FastifyInstance> {
  const app = Fastify({ logger: false });

  app.decorate('prisma', (fakes.prisma ?? createFakePrisma()) as unknown as PrismaClient);
  app.decorate('redis', (fakes.redis ?? createFakeRedis()) as unknown as Redis);

  // Same cross-cutting plugins as src/app.ts (helmet/sensible/rate-limit are
  // transport concerns, not contract concerns — the error-handler test covers
  // the 429 mapping).
  await app.register(i18nPlugin);
  await app.register(errorHandlerPlugin);
  await app.register(authPlugin);

  // Sensitive routes: auth-protected, validated, or public calculators.
  await app.register(healthRoutes);
  await app.register(authRoutes);
  await app.register(userRoutes);
  await app.register(calculatorRoutes);
  await app.register(documentRoutes);
  await app.register(recommendationRoutes);
  await app.register(subscriptionRoutes);

  return app;
}
