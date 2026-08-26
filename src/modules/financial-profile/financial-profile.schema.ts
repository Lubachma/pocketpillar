import { z } from 'zod';

const employmentStatusValues = ['EMPLOYED', 'SELF_EMPLOYED', 'UNEMPLOYED', 'RETIRED'] as const;
const maritalStatusValues = [
  'SINGLE',
  'MARRIED',
  'REGISTERED_PARTNERSHIP',
  'DIVORCED',
  'WIDOWED',
] as const;
const pillar3aAccountTypeValues = ['BANK', 'INSURANCE'] as const;

/** CHF 1 billion in centimes — upper bound rejecting absurd monetary inputs */
const MAX_MONEY_CENTIMES = 100_000_000_000;
const moneyAmount = () => z.number().int().nonnegative().max(MAX_MONEY_CENTIMES);

// ─── Financial Profile ────────────────────────

// Base shape WITHOUT defaults: .partial() over a schema that carries a .default()
// would keep injecting that default on partial updates (silently resetting fields).
const financialProfileFieldsSchema = z.object({
  employmentStatus: z.enum(employmentStatusValues),
  maritalStatus: z.enum(maritalStatusValues),
  numberOfChildren: z.number().int().min(0),
  grossAnnualIncome: moneyAmount(),
  netAnnualIncome: moneyAmount().optional(),
});

export const createFinancialProfileSchema = financialProfileFieldsSchema.extend({
  numberOfChildren: z.number().int().min(0).default(0),
});

export const updateFinancialProfileSchema = financialProfileFieldsSchema.partial();

// ─── Pillar 2 ─────────────────────────────────

// Same pattern: no defaults in the base shape reused for the update schema.
const pillar2AccountFieldsSchema = z.object({
  providerName: z.string().optional(),
  currentCapital: moneyAmount(),
  projectedCapitalAtRetirement: moneyAmount().optional(),
  conversionRate: z.number().min(0).max(100).optional(),
  insuredSalary: moneyAmount().optional(),
  coordinationDeduction: moneyAmount().optional(),
  annualBvgContribution: moneyAmount().optional(),
  annualSupraContribution: moneyAmount().optional(),
  isVestedBenefits: z.boolean(),
});

export const createPillar2AccountSchema = pillar2AccountFieldsSchema.extend({
  isVestedBenefits: z.boolean().default(false),
});

export const updatePillar2AccountSchema = pillar2AccountFieldsSchema.partial();

// ─── Pillar 3a ────────────────────────────────

export const createPillar3aAccountSchema = z.object({
  providerName: z.string().min(1),
  accountType: z.enum(pillar3aAccountTypeValues),
  currentBalance: moneyAmount(),
  annualContribution: moneyAmount().optional(),
  interestRateOrReturn: z.number().min(-50).max(100).optional(),
});

export const updatePillar3aAccountSchema = createPillar3aAccountSchema.partial();

// ─── Tax Situation ────────────────────────────

export const upsertTaxSituationSchema = z.object({
  taxableIncome: moneyAmount(),
  totalDeductions: moneyAmount().optional(),
  churchTax: z.boolean().default(false),
  taxableWealth: moneyAmount().optional(),
  municipality: z.string().optional(),
});

export type CreateFinancialProfileInput = z.infer<typeof createFinancialProfileSchema>;
export type CreatePillar2AccountInput = z.infer<typeof createPillar2AccountSchema>;
export type CreatePillar3aAccountInput = z.infer<typeof createPillar3aAccountSchema>;
export type UpsertTaxSituationInput = z.infer<typeof upsertTaxSituationSchema>;
