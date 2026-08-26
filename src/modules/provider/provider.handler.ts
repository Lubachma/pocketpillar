import type { FastifyRequest, FastifyReply } from 'fastify';
import { config } from '../../config/index.js';
import { t } from '../../lib/i18n/index.js';
import { compareQuerySchema, bestMatchSchema } from './provider.schema.js';
import {
  getAllProviders,
  getProviderBySlug,
  getProductsForComparison,
  type CatalogCache,
} from './provider.service.js';
import { scoreProducts } from './provider-comparison.js';
import { DEFAULT_SCORING_WEIGHTS } from './provider.types.js';

/** Redis-backed catalog cache context (fail-open — see provider.service.ts). */
function catalogCache(request: FastifyRequest): CatalogCache {
  return { redis: request.server.redis, log: request.log };
}

export async function listProvidersHandler(request: FastifyRequest, reply: FastifyReply) {
  const providers = await getAllProviders(request.server.prisma, catalogCache(request));
  return reply.send(providers);
}

export async function getProviderHandler(
  request: FastifyRequest<{ Params: { slug: string } }>,
  reply: FastifyReply,
) {
  const provider = await getProviderBySlug(
    request.server.prisma,
    request.params.slug,
    catalogCache(request),
  );
  if (!provider) {
    return reply.status(404).send({ error: t(request.locale, 'error.provider_not_found') });
  }
  return reply.send(provider);
}

export async function compareProductsHandler(
  request: FastifyRequest<{ Querystring: unknown }>,
  reply: FastifyReply,
) {
  const parsed = compareQuerySchema.safeParse(request.query);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const products = await getProductsForComparison(
    request.server.prisma,
    parsed.data,
    catalogCache(request),
  );
  const scored = scoreProducts(products, DEFAULT_SCORING_WEIGHTS, parsed.data.riskLevel);
  return reply.send(scored);
}

export async function bestMatchHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = bestMatchSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const { riskLevel, preferEsg, maxFeePercent } = parsed.data;

  const products = await getProductsForComparison(
    request.server.prisma,
    {
      riskLevel,
      sustainableOnly: preferEsg,
      maxFeePercent,
    },
    catalogCache(request),
  );

  const weights = {
    ...DEFAULT_SCORING_WEIGHTS,
    esg: preferEsg ? 20 : 0,
  };

  const scored = scoreProducts(products, weights, riskLevel);
  return reply.send(scored.slice(0, 3));
}
