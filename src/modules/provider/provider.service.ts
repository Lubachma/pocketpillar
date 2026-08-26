import type { PrismaClient } from '@prisma/client';
import type { FastifyBaseLogger } from 'fastify';
import type { Redis } from 'ioredis';
import type { ComparisonFilters } from './provider.types.js';

/**
 * Redis cache context for the provider catalog — fail-open like the JWT cache
 * in plugins/auth.ts: any Redis error falls back to Prisma, it never breaks
 * the endpoint.
 */
export interface CatalogCache {
  redis: Pick<Redis, 'get' | 'set'>;
  log: Pick<FastifyBaseLogger, 'warn'>;
}

const CATALOG_CACHE_PREFIX = 'catalog:';
/**
 * Catalog mutations happen only via prisma/seed.ts — a standalone script that
 * does not go through the server, so explicit invalidation is not possible.
 * The 10-minute TTL bounds the staleness instead.
 */
const CATALOG_CACHE_TTL_SECONDS = 600;

async function readCatalogCache<T>(
  cache: CatalogCache | undefined,
  key: string,
): Promise<T | null> {
  if (!cache) return null;
  try {
    const raw = await cache.redis.get(key);
    return raw ? (JSON.parse(raw) as T) : null;
  } catch (err) {
    cache.log.warn({ err }, 'Catalog cache read failed — falling back to Prisma');
    return null;
  }
}

async function writeCatalogCache(
  cache: CatalogCache | undefined,
  key: string,
  value: unknown,
): Promise<void> {
  if (!cache) return;
  try {
    await cache.redis.set(key, JSON.stringify(value), 'EX', CATALOG_CACHE_TTL_SECONDS);
  } catch (err) {
    cache.log.warn({ err }, 'Catalog cache write failed');
  }
}

/** Serve `key` from the cache when possible, otherwise fetch and store it. */
async function cachedCatalog<T>(
  cache: CatalogCache | undefined,
  key: string,
  fetch: () => Promise<T>,
): Promise<T> {
  const cached = await readCatalogCache<T>(cache, key);
  if (cached !== null) return cached;
  const value = await fetch();
  await writeCatalogCache(cache, key, value);
  return value;
}

export async function getAllProviders(
  prisma: PrismaClient,
  cache?: CatalogCache,
  activeOnly = true,
) {
  return cachedCatalog(
    cache,
    `${CATALOG_CACHE_PREFIX}providers:${activeOnly ? 'active' : 'all'}`,
    () =>
      prisma.pillar3aProvider.findMany({
        where: activeOnly ? { isActive: true } : undefined,
        include: {
          products: {
            where: activeOnly ? { isActive: true } : undefined,
            include: { fees: true },
            orderBy: { equityAllocation: 'desc' },
          },
        },
        orderBy: { name: 'asc' },
      }),
  );
}

export async function getProviderBySlug(prisma: PrismaClient, slug: string, cache?: CatalogCache) {
  const key = `${CATALOG_CACHE_PREFIX}provider:${slug}`;
  const cached = await readCatalogCache(cache, key);
  if (cached) return cached;
  const provider = await prisma.pillar3aProvider.findUnique({
    where: { slug },
    include: {
      products: {
        include: {
          fees: true,
          performanceHistory: { orderBy: { year: 'desc' }, take: 5 },
        },
        orderBy: { equityAllocation: 'desc' },
      },
    },
  });
  // Unknown slugs (404) are not cached.
  if (provider) await writeCatalogCache(cache, key, provider);
  return provider;
}

function compareCacheKey(filters: ComparisonFilters): string {
  return (
    `${CATALOG_CACHE_PREFIX}compare:` +
    [
      filters.riskLevel ?? '-',
      filters.sustainableOnly ? '1' : '0',
      filters.minEquityAllocation ?? '-',
      filters.maxEquityAllocation ?? '-',
      filters.maxFeePercent ?? '-',
    ].join(':')
  );
}

export async function getProductsForComparison(
  prisma: PrismaClient,
  filters: ComparisonFilters = {},
  cache?: CatalogCache,
) {
  return cachedCatalog(cache, compareCacheKey(filters), async () => {
    const products = await prisma.pillar3aProduct.findMany({
      where: {
        isActive: true,
        ...(filters.riskLevel && { riskLevel: filters.riskLevel }),
        ...(filters.sustainableOnly && { sustainableEsg: true }),
        ...(filters.minEquityAllocation !== undefined && {
          equityAllocation: { gte: filters.minEquityAllocation },
        }),
        ...(filters.maxEquityAllocation !== undefined && {
          equityAllocation: { lte: filters.maxEquityAllocation },
        }),
      },
      include: {
        provider: { select: { name: true, slug: true } },
        fees: true,
        performanceHistory: { orderBy: { year: 'desc' }, take: 5 },
      },
      orderBy: { name: 'asc' },
    });

    return products
      .filter((p) => {
        if (filters.maxFeePercent !== undefined && p.fees) {
          return p.fees.allInFeePercent <= filters.maxFeePercent;
        }
        return true;
      })
      .map((p) => {
        const returns = p.performanceHistory.map((ph) => ph.returnPercent);
        const avg3y =
          returns.length >= 3 ? returns.slice(0, 3).reduce((a, b) => a + b, 0) / 3 : null;
        const avg5y =
          returns.length >= 5 ? returns.slice(0, 5).reduce((a, b) => a + b, 0) / 5 : null;

        return {
          productId: p.id,
          providerName: p.provider.name,
          providerSlug: p.provider.slug,
          productName: p.name,
          productSlug: p.slug,
          riskLevel: p.riskLevel,
          equityAllocation: p.equityAllocation,
          allInFeePercent: p.fees?.allInFeePercent ?? 0,
          sustainableEsg: p.sustainableEsg,
          avgReturn3y: avg3y !== null ? Math.round(avg3y * 100) / 100 : null,
          avgReturn5y: avg5y !== null ? Math.round(avg5y * 100) / 100 : null,
        };
      });
  });
}

/**
 * Products feeding the recommendation engine. Products without a fee line are
 * excluded — a missing fee must never be treated as a free (0%) product in
 * the comparison rules.
 */
export async function getProductsForRecommendation(prisma: PrismaClient, cache?: CatalogCache) {
  return cachedCatalog(cache, `${CATALOG_CACHE_PREFIX}recommendations`, () =>
    prisma.pillar3aProduct.findMany({
      where: { isActive: true, fees: { isNot: null } },
      include: {
        fees: true,
        performanceHistory: { orderBy: { year: 'desc' }, take: 3 },
        provider: true,
      },
    }),
  );
}
