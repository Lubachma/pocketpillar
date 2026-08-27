import type { FastifyRequest, FastifyReply } from 'fastify';
import { config } from '../../config/index.js';
import { t } from '../../lib/i18n/index.js';
import {
  lppGapRequestSchema,
  taxSavingsRequestSchema,
  retirementProjectionRequestSchema,
  pillar3aCatchupRequestSchema,
  propertyPurchaseRequestSchema,
  divorceImpactRequestSchema,
  staggeredWithdrawalRequestSchema,
  coupleSimulationRequestSchema,
  municipalitiesQuerySchema,
} from './calculator.schema.js';
import { tryResolvePremium } from '../subscription/premium.js';
import { calculateLppGap } from './lpp-gap.js';
import { calculatePillar3aTaxSavings } from './tax-savings.js';
import { calculateRetirementProjection } from './retirement-projection.js';
import { calculatePillar3aCatchup } from './pillar3a-catchup.js';
import { calculatePropertyPurchaseImpact, EplMinWithdrawalError } from './property-purchase.js';
import { calculateDivorceImpact } from './divorce-impact.js';
import { calculateStaggeredWithdrawal } from './staggered-withdrawal.js';
import { simulateCouple } from './couple-simulation.js';
import { estimateAvsPension } from '../../lib/avs-pension-estimate.js';
import { getMunicipalitiesForCanton } from '../../lib/constants/communal-multipliers.js';
import type { z } from 'zod';
import type { MaritalStatus } from '@prisma/client';

export async function lppGapHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = lppGapRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const result = calculateLppGap(parsed.data);
  return reply.send(result);
}

export async function taxSavingsHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = taxSavingsRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const result = calculatePillar3aTaxSavings(parsed.data);
  return reply.send(result);
}

type RetirementProjectionData = z.infer<typeof retirementProjectionRequestSchema>;

// AVS pension not provided → estimated from income (simplified scale 44)
// instead of the old flat default of CHF 14'700 (contract §7). Shared by
// retirementProjectionHandler and coupleSimulationHandler (a single place
// for the AVS default — no possible divergence).
function withEstimatedAvsPension(data: RetirementProjectionData) {
  return {
    ...data,
    estimatedAvsPension:
      data.estimatedAvsPension ??
      estimateAvsPension({
        grossAnnualIncome: data.grossAnnualIncome,
        currentAge: data.currentAge,
        retirementAge: data.retirementAge,
      }),
  };
}

export async function retirementProjectionHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = retirementProjectionRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const result = calculateRetirementProjection(withEstimatedAvsPension(parsed.data));
  return reply.send(result);
}

export async function pillar3aCatchupHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = pillar3aCatchupRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const result = calculatePillar3aCatchup(parsed.data);

  // Free preview (paywall option B): totals visible to everyone — catch-up
  // amount and estimated tax savings; the year-by-year plan is reserved for
  // Premium. Public endpoint: best-effort premium resolution.
  const premium = await tryResolvePremium(request);
  if (!premium) {
    return reply.send({ ...result, yearDetails: [], premiumRequired: true });
  }
  return reply.send({ ...result, premiumRequired: false });
}

export async function propertyPurchaseHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = propertyPurchaseRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  try {
    const result = calculatePropertyPurchaseImpact(parsed.data);
    return reply.send(result);
  } catch (err) {
    if (err instanceof EplMinWithdrawalError) {
      return reply.status(400).send({ error: t(request.locale, 'calc.property.min_withdrawal') });
    }
    throw err;
  }
}

export async function divorceImpactHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = divorceImpactRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const result = calculateDivorceImpact(parsed.data);
  return reply.send(result);
}

export async function staggeredWithdrawalHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = staggeredWithdrawalRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const result = calculateStaggeredWithdrawal(parsed.data);
  return reply.send(result);
}

export async function coupleSimulationHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = coupleSimulationRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  // The couple's residence and tax status win over any person-level values:
  // otherwise a person-level canton priced the per-person 3a withdrawal tax
  // on the SINGLE schedule while the couple plan used the MARRIED one — two
  // different taxes for the same withdrawal in one payload (review 08.2026).
  const withdrawalStatus = parsed.data.maritalStatus === 'CONCUBINAGE' ? 'SINGLE' : 'MARRIED';
  const withCoupleResidence = (person: RetirementProjectionData) => ({
    ...withEstimatedAvsPension(person),
    canton: parsed.data.canton,
    maritalStatus: withdrawalStatus as MaritalStatus,
    municipality: parsed.data.municipality,
  });

  const result = simulateCouple({
    canton: parsed.data.canton,
    maritalStatus: parsed.data.maritalStatus,
    municipality: parsed.data.municipality,
    person1: withCoupleResidence(parsed.data.person1),
    person2: withCoupleResidence(parsed.data.person2),
  });
  return reply.send(result);
}

export async function municipalitiesHandler(
  request: FastifyRequest<{ Querystring: unknown }>,
  reply: FastifyReply,
) {
  const parsed = municipalitiesQuerySchema.safeParse(request.query);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  // Communal multipliers change once a year — safe to cache for a day.
  return reply
    .header('Cache-Control', 'public, max-age=86400')
    .send(getMunicipalitiesForCanton(parsed.data.canton));
}
