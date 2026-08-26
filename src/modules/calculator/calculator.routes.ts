import type { FastifyInstance } from 'fastify';
import { authenticate } from '../../plugins/auth.js';
import { requirePremium } from '../subscription/premium.js';
import {
  lppGapHandler,
  taxSavingsHandler,
  retirementProjectionHandler,
  pillar3aCatchupHandler,
  propertyPurchaseHandler,
  divorceImpactHandler,
  staggeredWithdrawalHandler,
  coupleSimulationHandler,
  municipalitiesHandler,
} from './calculator.handler.js';

export default async function calculatorRoutes(fastify: FastifyInstance) {
  // Basic calculators: public (try-before-signup). Advanced scenarios:
  // authenticate + requirePremium (402 → paywall on the app side). The
  // 3a-catchup stays public with a free preview — premium detail is in the handler.

  fastify.get(
    '/calculator/municipalities',
    {
      config: { rateLimit: { max: 20, timeWindow: '1 minute' } },
      schema: {
        tags: ['calculator'],
        description:
          'Municipalities covered by real communal tax multipliers for a canton (picker data)',
      },
    },
    municipalitiesHandler,
  );

  fastify.post(
    '/calculator/lpp-gap',
    {
      config: { rateLimit: { max: 20, timeWindow: '1 minute' } },
      schema: {
        tags: ['calculator'],
        description: 'LPP/BVG gap analysis — compare actual vs minimum contributions and pension',
      },
    },
    lppGapHandler,
  );

  fastify.post(
    '/calculator/tax-savings',
    {
      config: { rateLimit: { max: 20, timeWindow: '1 minute' } },
      schema: {
        tags: ['calculator'],
        description: 'Pillar 3a tax savings calculator by canton',
      },
    },
    taxSavingsHandler,
  );

  fastify.post(
    '/calculator/retirement',
    {
      config: { rateLimit: { max: 20, timeWindow: '1 minute' } },
      schema: {
        tags: ['calculator'],
        description: 'Retirement projection with year-by-year breakdown',
      },
    },
    retirementProjectionHandler,
  );

  fastify.post(
    '/calculator/3a-catchup',
    {
      config: { rateLimit: { max: 20, timeWindow: '1 minute' } },
      schema: {
        tags: ['calculator'],
        description:
          'Pillar 3a catch-up calculator — how much can you contribute retroactively (2025+ reform)',
      },
    },
    pillar3aCatchupHandler,
  );

  fastify.post<{ Body: unknown }>(
    '/calculator/property-purchase',
    {
      preHandler: [authenticate, requirePremium],
      config: { rateLimit: { max: 20, timeWindow: '1 minute' } },
      schema: {
        tags: ['calculator'],
        description:
          'Property purchase (EPL) — impact of BVG withdrawal on retirement pension (Premium)',
      },
    },
    propertyPurchaseHandler,
  );

  fastify.post<{ Body: unknown }>(
    '/calculator/divorce-impact',
    {
      preHandler: [authenticate, requirePremium],
      config: { rateLimit: { max: 20, timeWindow: '1 minute' } },
      schema: {
        tags: ['calculator'],
        description: 'Divorce impact — LPP splitting and pension impact simulation (Premium)',
      },
    },
    divorceImpactHandler,
  );

  fastify.post<{ Body: unknown }>(
    '/calculator/staggered-withdrawal',
    {
      preHandler: [authenticate, requirePremium],
      config: { rateLimit: { max: 20, timeWindow: '1 minute' } },
      schema: {
        tags: ['calculator'],
        description:
          'Staggered withdrawal optimizer — compare tax on lump-sum vs staggered 3a/BVG withdrawal (Premium)',
      },
    },
    staggeredWithdrawalHandler,
  );

  fastify.post<{ Body: unknown }>(
    '/calculator/couple',
    {
      preHandler: [authenticate, requirePremium],
      config: { rateLimit: { max: 20, timeWindow: '1 minute' } },
      schema: {
        tags: ['calculator'],
        description:
          'Couple simulation — combined retirement income with AVS 150% cap, married vs unmarried tax estimate, coordinated withdrawal plan (Premium)',
      },
    },
    coupleSimulationHandler,
  );
}
