import { z } from 'zod';
import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';
import { MAX_MONEY_CENTIMES } from '../../lib/constants/limits.js';

// Monetary inputs share the persisted int4 bound (contract §1) — the pure
// calculators don't hit Postgres, but one contract-wide rule beats two.
const money = () => z.number().int().nonnegative().max(MAX_MONEY_CENTIMES);
const positiveMoney = () => z.number().int().positive().max(MAX_MONEY_CENTIMES);

const cantonValues = [
  'ZH',
  'BE',
  'LU',
  'UR',
  'SZ',
  'OW',
  'NW',
  'GL',
  'ZG',
  'FR',
  'SO',
  'BS',
  'BL',
  'SH',
  'AR',
  'AI',
  'SG',
  'GR',
  'AG',
  'TG',
  'TI',
  'VD',
  'VS',
  'NE',
  'GE',
  'JU',
] as const;

export const municipalitiesQuerySchema = z.object({
  canton: z.enum(cantonValues),
});

const maritalStatusValues = [
  'SINGLE',
  'MARRIED',
  'REGISTERED_PARTNERSHIP',
  'DIVORCED',
  'WIDOWED',
] as const;

export const lppGapRequestSchema = z
  .object({
    grossAnnualIncome: positiveMoney(),
    age: z.number().int().min(25).max(70),
    retirementAge: z.number().int().min(58).max(70).default(65),
    currentBvgCapital: money(),
    actualAnnualContribution: money(),
    conversionRate: z.number().min(0).max(100).default(6.8),
  })
  .refine((d) => d.retirementAge > d.age, {
    message: 'retirementAge must be greater than age',
  });

export const taxSavingsRequestSchema = z.object({
  canton: z.enum(cantonValues),
  taxableIncome: positiveMoney(),
  contribution: positiveMoney(),
  maritalStatus: z.enum(maritalStatusValues).default('SINGLE'),
  churchTax: z.boolean().default(false),
  hasSecondPillar: z.boolean().default(true),
  // Municipality of residence (optional) — real communal multiplier if the
  // municipality is covered, otherwise falls back to the cantonal average.
  municipality: z.string().min(1).max(100).optional(),
});

export const pillar3aCatchupRequestSchema = z.object({
  currentYear: z.number().int().default(SWISS_PENSION.CURRENT_YEAR),
  yearsSinceFirstEligible: z.number().int().min(0).max(10).default(1),
  pastContributions: z.record(z.coerce.number(), money()).default({}),
  hasSecondPillar: z.boolean().default(true),
  taxableIncome: positiveMoney(),
  // Canton/marital status/municipality (optional): present → tax savings
  // calculated on the real FTA (Federal Tax Administration) 2026 brackets
  // (year by year); absent → flat historical estimate (marginal rate 25/30/35%).
  canton: z.enum(cantonValues).optional(),
  maritalStatus: z.enum(maritalStatusValues).default('SINGLE'),
  municipality: z.string().min(1).max(100).optional(),
});

export const propertyPurchaseRequestSchema = z
  .object({
    age: z.number().int().min(25).max(65),
    retirementAge: z.number().int().min(58).max(70).default(65),
    currentBvgCapital: money(),
    bvgCapitalAtAge50: money().optional(),
    withdrawalAmount: positiveMoney(),
    annualContribution: money(),
    interestRate: z.number().min(0).max(20).default(1.25),
    conversionRate: z.number().min(0).max(100).default(6.8),
  })
  .refine((d) => d.retirementAge > d.age, {
    message: 'retirementAge must be greater than age',
  });

export const divorceImpactRequestSchema = z
  .object({
    age: z.number().int().min(25).max(70),
    retirementAge: z.number().int().min(58).max(70).default(65),
    bvgCapitalAtMarriage: money(),
    bvgCapitalNow: money(),
    spouseBvgCapitalAtMarriage: money(),
    spouseBvgCapitalNow: money(),
    yearsMarried: z.number().int().min(0).max(50),
    annualContribution: money(),
    interestRate: z.number().min(0).max(20).default(1.25),
    conversionRate: z.number().min(0).max(100).default(6.8),
  })
  .refine((d) => d.retirementAge > d.age, {
    message: 'retirementAge must be greater than age',
  })
  // Capital acquired during the marriage cannot be negative.
  .refine((d) => d.bvgCapitalAtMarriage <= d.bvgCapitalNow, {
    message: 'bvgCapitalAtMarriage must not exceed bvgCapitalNow',
  })
  .refine((d) => d.spouseBvgCapitalAtMarriage <= d.spouseBvgCapitalNow, {
    message: 'spouseBvgCapitalAtMarriage must not exceed spouseBvgCapitalNow',
  });

export const staggeredWithdrawalRequestSchema = z
  .object({
    canton: z.enum(cantonValues),
    totalPillar3aBalance: money(),
    numberOfAccounts: z.number().int().min(1).max(5).default(1),
    retirementAge: z.number().int().min(58).max(70).default(65),
    currentAge: z.number().int().min(25).max(70),
    maritalStatus: z.enum(['SINGLE', 'MARRIED']).default('SINGLE'),
    pillar2AsCapital: money().default(0),
    // Municipality of residence (optional) — see tax-savings.
    municipality: z.string().min(1).max(100).optional(),
  })
  .refine((d) => d.retirementAge > d.currentAge, {
    message: 'retirementAge must be greater than currentAge',
  });

export const retirementProjectionRequestSchema = z
  .object({
    currentAge: z.number().int().min(18).max(70),
    retirementAge: z.number().int().min(58).max(70).default(65),
    grossAnnualIncome: positiveMoney(),
    currentPillar2Capital: money(),
    annualPillar2Contribution: money(),
    pillar2InterestRate: z.number().min(0).max(20).default(1.25),
    conversionRate: z.number().min(0).max(100).default(6.8),
    currentPillar3aBalance: money().default(0),
    annualPillar3aContribution: money().default(0),
    pillar3aReturnRate: z
      .number()
      .min(-20)
      .max(20)
      .default(SWISS_PENSION.PILLAR_3A_DEFAULT_RETURN_RATE),
    // No flat default: when the field is omitted, the handler estimates the
    // pension from income (simplified scale 44, `estimateAvsPension` — contract §7).
    estimatedAvsPension: money().optional(),
    // Canton/marital status/municipality (optional): present → the response
    // includes the estimated tax on the 3a lump-sum withdrawal (official FTA
    // 2026 tables — practitioner review 08.2026); absent → no tax fields.
    canton: z.enum(cantonValues).optional(),
    maritalStatus: z.enum(maritalStatusValues).optional(),
    municipality: z.string().min(1).max(100).optional(),
  })
  .refine((d) => d.retirementAge > d.currentAge, {
    message: 'retirementAge must be greater than currentAge',
  });

// Each spouse reuses exactly the inputs of an individual retirement
// projection (same bounds, same defaults, same refine).
export const coupleSimulationRequestSchema = z.object({
  canton: z.enum(cantonValues),
  // Marital statuses that change the couple's tax: marriage and registered
  // partnership = joint taxation; concubinage = 2 × single.
  maritalStatus: z.enum(['MARRIED', 'REGISTERED_PARTNERSHIP', 'CONCUBINAGE']),
  // Couple's municipality of residence (optional) — see tax-savings.
  municipality: z.string().min(1).max(100).optional(),
  person1: retirementProjectionRequestSchema,
  person2: retirementProjectionRequestSchema,
});
