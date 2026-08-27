import type { Canton, MaritalStatus } from '@prisma/client';

// ─── LPP Gap Analysis ────────────────────────

export interface LppGapInput {
  grossAnnualIncome: number; // centimes
  age: number;
  retirementAge: number;
  currentBvgCapital: number; // centimes
  actualAnnualContribution: number; // centimes
  conversionRate: number; // %
}

export interface LppGapResult {
  coordinatedSalary: number; // centimes
  bvgMinContribution: number; // centimes/year
  contributionGap: number; // centimes/year (positive = underpaying)
  projectedBvgMinCapital: number; // centimes at retirement
  projectedActualCapital: number; // centimes at retirement
  capitalGap: number; // centimes
  projectedMinAnnualPension: number; // centimes/year
  projectedActualAnnualPension: number; // centimes/year
  pensionGap: number; // centimes/year
}

// ─── 3a Tax Savings ──────────────────────────

export interface TaxSavingsInput {
  canton: Canton;
  taxableIncome: number; // centimes
  contribution: number; // centimes
  maritalStatus: MaritalStatus;
  churchTax: boolean;
  hasSecondPillar: boolean;
  /** Commune de résidence — multiplicateur communal réel si couverte (2026),
   * sinon moyenne cantonale. */
  municipality?: string;
}

export interface TaxSavingsResult {
  federalTaxSaving: number; // centimes
  cantonalTaxSaving: number; // centimes
  communalTaxSaving: number; // centimes
  totalTaxSaving: number; // centimes
  effectiveReturnRate: number; // %
  maxContribution: number; // centimes
  isAtMax: boolean;
}

// ─── Retirement Projection ───────────────────

export interface RetirementProjectionInput {
  currentAge: number;
  retirementAge: number;
  grossAnnualIncome: number; // centimes
  currentPillar2Capital: number; // centimes
  annualPillar2Contribution: number; // centimes
  pillar2InterestRate: number; // %
  conversionRate: number; // %
  currentPillar3aBalance: number; // centimes
  annualPillar3aContribution: number; // centimes
  pillar3aReturnRate: number; // %
  /** Rente AVS annuelle sur 12 mensualités (échelle 44 : max CHF 30'240 =
   * 12 × 2'520) — la 13e rente (×13/12 dès 2026) est ajoutée par le moteur
   * selon l'année de retraite. */
  estimatedAvsPension: number; // centimes/year
  /** Optional — when provided, the result includes the estimated tax on the
   * 3a lump-sum withdrawal (official FTA 2026 tables per canton). */
  canton?: Canton;
  /** Withdrawal-tax schedule selector (joint for MARRIED/REGISTERED_PARTNERSHIP,
   * single otherwise). Defaults to SINGLE. */
  maritalStatus?: MaritalStatus;
  /** Municipality of residence — real communal multiplier if covered (2026),
   * otherwise cantonal average. */
  municipality?: string;
}

export interface YearProjection {
  year: number;
  age: number;
  pillar2Capital: number; // centimes
  pillar3aBalance: number; // centimes
  totalCapital: number; // centimes
}

// ─── Pillar 3a Catch-up ─────────────────

export interface Pillar3aCatchupInput {
  currentYear: number;
  yearsSinceFirstEligible: number;
  /** Map of year → actual contribution in centimes */
  pastContributions: Record<number, number>;
  hasSecondPillar: boolean;
  taxableIncome: number; // centimes
  /** Optionnels — pilotent le calcul réel de l'économie d'impôt. */
  canton?: Canton;
  maritalStatus?: MaritalStatus;
  municipality?: string;
}

export interface Pillar3aCatchupYearDetail {
  year: number;
  maxContribution: number; // centimes
  actualContribution: number; // centimes
  gap: number; // centimes
}

export interface Pillar3aCatchupResult {
  maxPerYear: number; // centimes
  eligibleYears: number;
  yearDetails: Pillar3aCatchupYearDetail[];
  totalCatchupPotential: number; // centimes
  currentYearGap: number; // centimes
  mustMaxCurrentYearFirst: boolean;
  estimatedTaxSavings: number; // centimes
  estimatedMarginalRate: number; // %
}

// ─── Property Purchase (EPL) ────────────

export interface PropertyPurchaseInput {
  age: number;
  retirementAge: number;
  currentBvgCapital: number; // centimes
  bvgCapitalAtAge50?: number; // centimes (needed if age > 50)
  withdrawalAmount: number; // centimes
  annualContribution: number; // centimes
  interestRate: number; // %
  conversionRate: number; // %
}

export interface PropertyPurchaseResult {
  maxWithdrawal: number; // centimes
  effectiveWithdrawal: number; // centimes
  capitalAtRetirementWithout: number; // centimes
  capitalAtRetirementWith: number; // centimes
  capitalLostAtRetirement: number; // centimes
  annualPensionWithout: number; // centimes/year
  annualPensionWith: number; // centimes/year
  annualPensionLoss: number; // centimes/year
  monthlyPensionLoss: number; // centimes/month
}

// ─── Divorce Impact ─────────────────────

export interface DivorceImpactInput {
  age: number;
  retirementAge: number;
  bvgCapitalAtMarriage: number; // centimes
  bvgCapitalNow: number; // centimes
  spouseBvgCapitalAtMarriage: number; // centimes
  spouseBvgCapitalNow: number; // centimes
  yearsMarried: number;
  annualContribution: number; // centimes
  interestRate: number; // %
  conversionRate: number; // %
}

export interface DivorceImpactResult {
  myAccumulatedDuringMarriage: number; // centimes
  spouseAccumulatedDuringMarriage: number; // centimes
  totalMarriageCapital: number; // centimes
  transferAmount: number; // centimes (positive = receive, negative = pay)
  capitalAfterDivorce: number; // centimes
  projectedCapitalWithMarriage: number; // centimes
  projectedCapitalAfterDivorce: number; // centimes
  annualPensionWithMarriage: number; // centimes/year
  annualPensionAfterDivorce: number; // centimes/year
  annualPensionDifference: number; // centimes/year
  estimatedAvsImpact: number; // centimes/year
}

// ─── Retirement Projection ──────────────

export interface RetirementProjectionResult {
  yearsToRetirement: number;
  projectedPillar2Capital: number; // centimes
  projectedPillar3aBalance: number; // centimes
  annualPillar2Pension: number; // centimes/year
  /** Rente AVS annuelle servie à la retraite — 13e rente incluse (×13/12)
   * dès 2026 (`AVS_13TH_PENSION_FIRST_YEAR`). */
  estimatedAnnualAvsPension: number; // centimes/year
  pillar3aAsLumpSum: number; // centimes
  totalAnnualRetirementIncome: number; // centimes/year
  replacementRate: number; // %
  yearByYearProjection: YearProjection[];
  /** Estimated tax on the 3a lump-sum withdrawal at retirement (official FTA
   * 2026 tables — the pillar 2 is annuitized in this model, so no capital
   * withdrawal tax applies to it here). Present only when the input carries a
   * canton (practitioner review 08.2026). */
  pillar3aWithdrawalTax?: number; // centimes
  /** pillar3aAsLumpSum − pillar3aWithdrawalTax. Present only with a canton. */
  pillar3aNetLumpSum?: number; // centimes
}
