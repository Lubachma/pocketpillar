import type { Canton } from '@prisma/client';
import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';
import { incomeTaxBreakdown } from '../../lib/cantonal-tax.js';
import {
  calculateProgressiveTax,
  FEDERAL_TAX_BRACKETS_SINGLE,
  FEDERAL_TAX_BRACKETS_MARRIED,
} from '../../lib/constants/federal-tax.js';
import { calculateRetirementProjection, avsAnnualPension } from './retirement-projection.js';
import { calculateWithdrawalTax } from './staggered-withdrawal.js';
import type { RetirementProjectionInput, RetirementProjectionResult } from './calculator.types.js';

/**
 * Couple simulation — server-side port of the iOS `CoupleCalculator`, aligned
 * with the backend phase 1 rules where the iOS version diverged:
 *
 * - Retirement income per spouse: composed from
 *   `calculateRetirementProjection` (3a EXCLUDED from income — withdrawn as a
 *   lump sum and taxed separately, unlike the iOS `OfflineCalculator`).
 * - AVS couple cap 150% (CHF 45'360/year at ×12 — CHF 49'140/year once the
 *   13th pension is annualized from 2026, LAVS art. 35) applied **only to
 *   married couples / registered partnerships** — the iOS version also
 *   applied it to unmarried couples (concubinage), but the legal rule only
 *   targets married couples (registered partnerships have been treated the
 *   same since "marriage for all" in 2022).
 * - Couple taxation: joint taxation (married bracket on combined income) vs
 *   separate taxation (2 × single bracket). The cantonal tables distinguish
 *   marital status (single and married brackets sampled FTA (Federal Tax
 *   Administration) 2026). Gross income serves as a proxy for taxable income
 *   (deductions are unknown).
 * - Coordinated withdrawal plan: iOS anti-collision algorithm (3a at
 *   retirement − 1 year, LPP at retirement; on collision, step back a year
 *   as long as possible) + "push later" fallback added when stepping back is
 *   impossible (starting year already taken — the iOS version left the
 *   collision in that case). Tax per withdrawal via `calculateWithdrawalTax`
 *   — official FTA 2026 tables per canton (interpolation; the iOS version
 *   applied the income brackets on amount/5).
 * - Withdrawn capital is the **projected** capital at retirement (3a
 *   included — the iOS version used the current 3a balance, inconsistent
 *   with the projected LPP capital).
 * - "Simultaneous withdrawal" baseline: married → a single joint withdrawal
 *   (joint taxation, LIFD art. 38 — capital withdrawals from both spouses in
 *   the same year are added together); unmarried → sum of two individual
 *   withdrawals at the single bracket (separate taxation).
 */

/** Marital statuses relevant to the couple simulation (tax changes). */
export type CoupleMaritalStatus = 'MARRIED' | 'REGISTERED_PARTNERSHIP' | 'CONCUBINAGE';

export interface CoupleSimulationInput {
  canton: Canton;
  maritalStatus: CoupleMaritalStatus;
  person1: RetirementProjectionInput;
  person2: RetirementProjectionInput;
  /** Couple's municipality of residence — real communal multiplier if
   * covered (2026), otherwise cantonal average. */
  municipality?: string;
}

export interface CoupleTaxBreakdown {
  federalTax: number; // centimes/an
  cantonalTax: number; // centimes/an
  communalTax: number; // centimes/an
  totalTax: number; // centimes/an
}

export interface CoupleTaxEstimate {
  /** Joint taxation: combined income at the married bracket (direct federal tax (IFD)) + cantonal. */
  married: CoupleTaxBreakdown;
  /** Separate taxation: each spouse at the single bracket. */
  unmarried: CoupleTaxBreakdown;
  /** married.totalTax − unmarried.totalTax (> 0 = marriage costs more). */
  annualDifference: number;
  cheaperStatus: 'MARRIED' | 'CONCUBINAGE' | 'EQUAL';
}

export type CoupleWithdrawalSpouse = 'person1' | 'person2';
export type CoupleWithdrawalPillar = 'pillar3a' | 'pillar2';

export interface CoupleWithdrawalStep {
  year: number;
  spouse: CoupleWithdrawalSpouse;
  pillar: CoupleWithdrawalPillar;
  amount: number; // centimes
  estimatedTax: number; // centimes
}

export interface CoupleWithdrawalPlan {
  /** Anti-collision staggered withdrawals, sorted by year (at most 4). */
  steps: CoupleWithdrawalStep[];
  totalEstimatedTax: number; // centimes
  /** Tax if everything were withdrawn in the same year (jointly if married). */
  simultaneousEstimatedTax: number; // centimes
  taxSavingsVsSimultaneous: number; // centimes
}

export interface CoupleSimulationResult {
  person1: RetirementProjectionResult;
  person2: RetirementProjectionResult;
  /** Gross sum of both AVS pensions, before the cap (centimes/year). */
  combinedAvsAnnualRaw: number;
  /** Combined AVS pension after any couple cap (centimes/year). */
  combinedAvsAnnual: number;
  /** True if the 150% cap applies (married couple/partnership at the cap). */
  avsCapApplied: boolean;
  /** Reference legal cap (CHF 45'360/year at ×12 — annualized ×13/12 from
   * 2026 with the 13th pension, centimes) — exposed for client display;
   * only actually applied if married/registered partnership
   * (see `avsCapApplied`). */
  avsCapAnnual: number;
  /** Capped AVS + LPP pensions of both spouses (centimes/year). */
  combinedTotalAnnualIncome: number;
  combinedReplacementRate: number; // %
  taxEstimate: CoupleTaxEstimate;
  withdrawalPlan: CoupleWithdrawalPlan;
}

/** True if the couple is taxed jointly (marriage or registered partnership). */
export function isJointlyTaxed(maritalStatus: CoupleMaritalStatus): boolean {
  return maritalStatus === 'MARRIED' || maritalStatus === 'REGISTERED_PARTNERSHIP';
}

function taxBreakdown(
  income: number,
  canton: Canton,
  married: boolean,
  municipality?: string,
): CoupleTaxBreakdown {
  const federalBrackets = married ? FEDERAL_TAX_BRACKETS_MARRIED : FEDERAL_TAX_BRACKETS_SINGLE;
  const federalTax = calculateProgressiveTax(income, federalBrackets);
  const local = incomeTaxBreakdown(canton, income, { municipality, married });
  return {
    federalTax,
    cantonalTax: local.cantonal,
    communalTax: local.communal,
    totalTax: federalTax + local.cantonal + local.communal,
  };
}

function addBreakdowns(a: CoupleTaxBreakdown, b: CoupleTaxBreakdown): CoupleTaxBreakdown {
  return {
    federalTax: a.federalTax + b.federalTax,
    cantonalTax: a.cantonalTax + b.cantonalTax,
    communalTax: a.communalTax + b.communalTax,
    totalTax: a.totalTax + b.totalTax,
  };
}

/**
 * Annual tax estimate for the couple: marriage (joint taxation) vs
 * concubinage (separate taxation). Pure function.
 */
export function estimateCoupleIncomeTax(
  canton: Canton,
  grossIncome1: number,
  grossIncome2: number,
  municipality?: string,
): CoupleTaxEstimate {
  const combined = grossIncome1 + grossIncome2;
  const married = taxBreakdown(combined, canton, true, municipality);
  const unmarried = addBreakdowns(
    taxBreakdown(grossIncome1, canton, false, municipality),
    taxBreakdown(grossIncome2, canton, false, municipality),
  );
  const annualDifference = married.totalTax - unmarried.totalTax;
  return {
    married,
    unmarried,
    annualDifference,
    cheaperStatus:
      annualDifference > 0 ? 'CONCUBINAGE' : annualDifference < 0 ? 'MARRIED' : 'EQUAL',
  };
}

interface WithdrawalEvent {
  year: number;
  spouse: CoupleWithdrawalSpouse;
  pillar: CoupleWithdrawalPillar;
  amount: number;
}

/**
 * Coordinated withdrawal plan between spouses (tax-year anti-collision) —
 * algorithm from the iOS `CoupleCalculator.optimizeWithdrawalSchedule`,
 * with a "push later" fallback when stepping back is impossible.
 * Pure function.
 */
export function planCoupleWithdrawals(
  canton: Canton,
  maritalStatus: CoupleMaritalStatus,
  person1: { retirementYear: number; pillar3aCapital: number; pillar2Capital: number },
  person2: { retirementYear: number; pillar3aCapital: number; pillar2Capital: number },
  municipality?: string,
): CoupleWithdrawalPlan {
  const baseYear = SWISS_PENSION.CURRENT_YEAR;
  const jointlyTaxed = isJointlyTaxed(maritalStatus);
  const withdrawalStatus = jointlyTaxed ? 'MARRIED' : 'SINGLE';

  // 3a the year before retirement, LPP capital at retirement (iOS parity).
  const events: WithdrawalEvent[] = [];
  const persons = [
    { spouse: 'person1' as const, ...person1 },
    { spouse: 'person2' as const, ...person2 },
  ];
  for (const person of persons) {
    if (person.pillar3aCapital > 0) {
      events.push({
        year: person.retirementYear - 1,
        spouse: person.spouse,
        pillar: 'pillar3a',
        amount: person.pillar3aCapital,
      });
    }
    if (person.pillar2Capital > 0) {
      events.push({
        year: person.retirementYear,
        spouse: person.spouse,
        pillar: 'pillar2',
        amount: person.pillar2Capital,
      });
    }
  }

  // Deterministic sort: year, then 3a before LPP, then spouse 1 before 2.
  events.sort((a, b) => {
    if (a.year !== b.year) return a.year - b.year;
    if (a.pillar !== b.pillar) return a.pillar === 'pillar3a' ? -1 : 1;
    return a.spouse < b.spouse ? -1 : 1;
  });

  // Anti-collision: never two withdrawals in the same tax year. We step back
  // a year as long as possible (not before the current year — iOS parity);
  // otherwise we push later (fallback added: the iOS version left the collision).
  const usedYears = new Set<number>();
  const scheduled: WithdrawalEvent[] = [];
  for (const event of events) {
    let year = event.year;
    while (usedYears.has(year) && year > baseYear) {
      year -= 1;
    }
    if (usedYears.has(year)) {
      year = event.year + 1;
      while (usedYears.has(year)) {
        year += 1;
      }
    }
    usedYears.add(year);
    scheduled.push({ ...event, year });
  }

  scheduled.sort((a, b) => {
    if (a.year !== b.year) return a.year - b.year;
    if (a.spouse !== b.spouse) return a.spouse < b.spouse ? -1 : 1;
    return a.pillar === 'pillar3a' ? -1 : 1;
  });

  const steps: CoupleWithdrawalStep[] = scheduled.map((event) => ({
    year: event.year,
    spouse: event.spouse,
    pillar: event.pillar,
    amount: event.amount,
    estimatedTax: calculateWithdrawalTax(event.amount, canton, withdrawalStatus, municipality),
  }));

  const totalEstimatedTax = steps.reduce((sum, step) => sum + step.estimatedTax, 0);

  // "Simultaneous withdrawal" baseline: married → everything at once (joint
  // taxation); unmarried → one withdrawal per spouse (separate taxation).
  const total1 = person1.pillar3aCapital + person1.pillar2Capital;
  const total2 = person2.pillar3aCapital + person2.pillar2Capital;
  const simultaneousEstimatedTax = jointlyTaxed
    ? calculateWithdrawalTax(total1 + total2, canton, 'MARRIED', municipality)
    : calculateWithdrawalTax(total1, canton, 'SINGLE', municipality) +
      calculateWithdrawalTax(total2, canton, 'SINGLE', municipality);

  return {
    steps,
    totalEstimatedTax,
    simultaneousEstimatedTax,
    taxSavingsVsSimultaneous: simultaneousEstimatedTax - totalEstimatedTax,
  };
}

/** Full couple simulation. Pure function. */
export function simulateCouple(input: CoupleSimulationInput): CoupleSimulationResult {
  const { canton, maritalStatus, municipality } = input;
  const jointlyTaxed = isJointlyTaxed(maritalStatus);

  const person1 = calculateRetirementProjection(input.person1);
  const person2 = calculateRetirementProjection(input.person2);

  // AVS couple cap 150% — married couples / registered partnerships only
  // (LAVS art. 35; unmarried couples keep two full pensions). The cap
  // targets the MONTHLY pension (3'780): the 13th pension also applies to
  // it — annual cap ×13/12 from 2026 (the individual pensions from
  // `person*.estimatedAnnualAvsPension` are already annualized on their
  // respective retirement years). Reference year: the later retirement
  // (combined income at cruising speed, both pensions paid).
  const combinedAvsAnnualRaw =
    person1.estimatedAnnualAvsPension + person2.estimatedAnnualAvsPension;
  const latestRetirementYear = Math.max(
    SWISS_PENSION.CURRENT_YEAR + person1.yearsToRetirement,
    SWISS_PENSION.CURRENT_YEAR + person2.yearsToRetirement,
  );
  const avsCapAnnual = avsAnnualPension(
    SWISS_PENSION.AVS_MAX_COUPLE_ANNUAL_PENSION,
    latestRetirementYear,
  );
  const avsCapApplied = jointlyTaxed && combinedAvsAnnualRaw > avsCapAnnual;
  const combinedAvsAnnual = avsCapApplied ? avsCapAnnual : combinedAvsAnnualRaw;

  const combinedTotalAnnualIncome =
    combinedAvsAnnual + person1.annualPillar2Pension + person2.annualPillar2Pension;
  const combinedGrossIncome = input.person1.grossAnnualIncome + input.person2.grossAnnualIncome;
  const combinedReplacementRate =
    combinedGrossIncome > 0
      ? Math.round((combinedTotalAnnualIncome / combinedGrossIncome) * 10000) / 100
      : 0;

  const taxEstimate = estimateCoupleIncomeTax(
    canton,
    input.person1.grossAnnualIncome,
    input.person2.grossAnnualIncome,
    municipality,
  );

  const withdrawalPlan = planCoupleWithdrawals(
    canton,
    maritalStatus,
    {
      retirementYear: SWISS_PENSION.CURRENT_YEAR + person1.yearsToRetirement,
      pillar3aCapital: person1.projectedPillar3aBalance,
      pillar2Capital: person1.projectedPillar2Capital,
    },
    {
      retirementYear: SWISS_PENSION.CURRENT_YEAR + person2.yearsToRetirement,
      pillar3aCapital: person2.projectedPillar3aBalance,
      pillar2Capital: person2.projectedPillar2Capital,
    },
    municipality,
  );

  return {
    person1,
    person2,
    combinedAvsAnnualRaw,
    combinedAvsAnnual,
    avsCapApplied,
    avsCapAnnual,
    combinedTotalAnnualIncome,
    combinedReplacementRate,
    taxEstimate,
    withdrawalPlan,
  };
}
