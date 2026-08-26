import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { PrismaClient } from '@prisma/client';
import {
  getAllProviders,
  getProviderBySlug,
  getProductsForComparison,
  getProductsForRecommendation,
  type CatalogCache,
} from '../../../src/modules/provider/provider.service.js';

/**
 * Catalog cache tests: fake Prisma delegates + an in-memory Redis (Map), so
 * the hit/miss/fail-open behavior is exercised without Docker or network.
 */

function createFakeRedis() {
  const store = new Map<string, string>();
  return {
    store,
    get: vi.fn(async (key: string) => store.get(key) ?? null),
    set: vi.fn(async (key: string, value: string) => {
      store.set(key, value);
      return 'OK';
    }),
  };
}

function createCache(redis = createFakeRedis()) {
  const cache: CatalogCache = { redis: redis as never, log: { warn: vi.fn() } };
  return { cache, redis, warn: cache.log.warn };
}

const PROVIDER_ROW = {
  id: 'provider-1',
  slug: 'viac',
  name: 'VIAC',
  products: [],
};

function createPrisma() {
  return {
    pillar3aProvider: {
      findMany: vi.fn().mockResolvedValue([PROVIDER_ROW]),
      findUnique: vi.fn().mockResolvedValue(PROVIDER_ROW),
    },
    pillar3aProduct: {
      findMany: vi.fn().mockResolvedValue([]),
    },
  };
}

describe('provider.service — catalog cache', () => {
  let prisma: ReturnType<typeof createPrisma>;

  beforeEach(() => {
    prisma = createPrisma();
  });

  it('serves the second getAllProviders call from the cache (Prisma not called again)', async () => {
    const { cache } = createCache();

    const first = await getAllProviders(prisma as unknown as PrismaClient, cache);
    const second = await getAllProviders(prisma as unknown as PrismaClient, cache);

    expect(prisma.pillar3aProvider.findMany).toHaveBeenCalledTimes(1);
    expect(second).toEqual(first);
    expect(cache.redis.set).toHaveBeenCalledWith(
      'catalog:providers:active',
      expect.any(String),
      'EX',
      600,
    );
  });

  it('serves a repeated getProviderBySlug from the cache, keyed by slug', async () => {
    const { cache, redis } = createCache();

    await getProviderBySlug(prisma as unknown as PrismaClient, 'viac', cache);
    await getProviderBySlug(prisma as unknown as PrismaClient, 'viac', cache);

    expect(prisma.pillar3aProvider.findUnique).toHaveBeenCalledTimes(1);
    expect(redis.store.has('catalog:provider:viac')).toBe(true);
  });

  it('does not cache an unknown slug (404 must keep hitting Prisma)', async () => {
    const { cache } = createCache();
    prisma.pillar3aProvider.findUnique.mockResolvedValue(null);

    await getProviderBySlug(prisma as unknown as PrismaClient, 'nope', cache);
    await getProviderBySlug(prisma as unknown as PrismaClient, 'nope', cache);

    expect(prisma.pillar3aProvider.findUnique).toHaveBeenCalledTimes(2);
  });

  it('bounds the performance history of a provider detail to 5 entries', async () => {
    await getProviderBySlug(prisma as unknown as PrismaClient, 'viac');

    expect(prisma.pillar3aProvider.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        include: expect.objectContaining({
          products: expect.objectContaining({
            include: expect.objectContaining({
              performanceHistory: { orderBy: { year: 'desc' }, take: 5 },
            }),
          }),
        }),
      }),
    );
  });

  it('caches comparison results per filter tuple', async () => {
    const { cache } = createCache();

    await getProductsForComparison(prisma as unknown as PrismaClient, {}, cache);
    await getProductsForComparison(prisma as unknown as PrismaClient, {}, cache);
    // A different filter tuple is a different cache entry.
    await getProductsForComparison(
      prisma as unknown as PrismaClient,
      { riskLevel: 'AGGRESSIVE' },
      cache,
    );

    expect(prisma.pillar3aProduct.findMany).toHaveBeenCalledTimes(2);
  });

  it('bounds the performance history of comparisons to 5 entries', async () => {
    await getProductsForComparison(prisma as unknown as PrismaClient);

    expect(prisma.pillar3aProduct.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        include: expect.objectContaining({
          performanceHistory: { orderBy: { year: 'desc' }, take: 5 },
        }),
      }),
    );
  });

  it('serves the second recommendation catalog call from the cache (take: 3 history)', async () => {
    const { cache, redis } = createCache();

    await getProductsForRecommendation(prisma as unknown as PrismaClient, cache);
    await getProductsForRecommendation(prisma as unknown as PrismaClient, cache);

    expect(prisma.pillar3aProduct.findMany).toHaveBeenCalledTimes(1);
    expect(prisma.pillar3aProduct.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        include: expect.objectContaining({
          performanceHistory: { orderBy: { year: 'desc' }, take: 3 },
        }),
      }),
    );
    expect(redis.store.has('catalog:recommendations')).toBe(true);
  });

  it('fail-open: a Redis read failure falls back to Prisma on every call', async () => {
    const { cache } = createCache();
    cache.redis.get = vi.fn().mockRejectedValue(new Error('redis down')) as never;

    const result = await getAllProviders(prisma as unknown as PrismaClient, cache);
    await getAllProviders(prisma as unknown as PrismaClient, cache);

    expect(result).toEqual([PROVIDER_ROW]);
    expect(prisma.pillar3aProvider.findMany).toHaveBeenCalledTimes(2);
    expect(cache.log.warn).toHaveBeenCalled();
  });

  it('fail-open: a Redis write failure still returns the Prisma result', async () => {
    const { cache } = createCache();
    cache.redis.set = vi.fn().mockRejectedValue(new Error('redis down')) as never;

    const result = await getAllProviders(prisma as unknown as PrismaClient, cache);

    expect(result).toEqual([PROVIDER_ROW]);
    expect(cache.log.warn).toHaveBeenCalled();
  });
});
