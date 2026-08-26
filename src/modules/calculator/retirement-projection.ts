import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';
import type {
  RetirementProjectionInput,
  RetirementProjectionResult,
  YearProjection,
} from './calculator.types.js';

/**
 * Annualizes an AVS pension expressed as 12 monthly payments (scale 44: max
 * CHF 30'240 = 12 × 2'520) based on the year received: ×13/12 from 2026
 * (13th AVS pension, vote of 3.3.2024 — 1st payment in December 2026),
 * unchanged before that. The monthly pension itself doesn't change; only the
 * number of monthly payments made in the year goes from 12 to 13.
 * (`SWISS_PENSION.AVS_13TH_PENSION_FIRST_YEAR`)
 */
export function avsAnnualPension(annualPension12: number, year: number): number {
  return year >= SWISS_PENSION.AVS_13TH_PENSION_FIRST_YEAR
    ? Math.round((annualPension12 * 13) / 12)
    : annualPension12;
}

/** Calculate retirement projection with year-by-year detail */
export function calculateRetirementProjection(
  input: RetirementProjectionInput,
): RetirementProjectionResult {
  const {
    currentAge,
    retirementAge,
    grossAnnualIncome,
    currentPillar2Capital,
    annualPillar2Contribution,
    pillar2InterestRate,
    conversionRate,
    currentPillar3aBalance,
    annualPillar3aContribution,
    pillar3aReturnRate,
    estimatedAvsPension,
  } = input;

  const yearsToRetirement = retirementAge - currentAge;
  const yearByYearProjection: YearProjection[] = [];

  let pillar2 = currentPillar2Capital;
  let pillar3a = currentPillar3aBalance;

  for (let i = 0; i < yearsToRetirement; i++) {
    pillar2 = Math.round(pillar2 * (1 + pillar2InterestRate / 100) + annualPillar2Contribution);
    pillar3a = Math.round(pillar3a * (1 + pillar3aReturnRate / 100) + annualPillar3aContribution);

    yearByYearProjection.push({
      year: SWISS_PENSION.CURRENT_YEAR + i + 1,
      age: currentAge + i + 1,
      pillar2Capital: pillar2,
      pillar3aBalance: pillar3a,
      totalCapital: pillar2 + pillar3a,
    });
  }

  const projectedPillar2Capital = pillar2;
  const projectedPillar3aBalance = pillar3a;
  const annualPillar2Pension = Math.round((projectedPillar2Capital * conversionRate) / 100);

  // 13th AVS pension: the pension paid at retirement counts 13 monthly
  // payments per year from 2026 (×13/12) — `estimatedAvsPension` is the annual ×12 pension.
  const retirementYear = SWISS_PENSION.CURRENT_YEAR + yearsToRetirement;
  const annualAvsPension = avsAnnualPension(estimatedAvsPension, retirementYear);

  // Business rule: the 3a is EXCLUDED from retirement income — it is withdrawn as
  // a lump sum (pillar3aAsLumpSum) and taxed separately, not converted to an annuity.
  const totalAnnualRetirementIncome = annualAvsPension + annualPillar2Pension;
  const replacementRate =
    grossAnnualIncome > 0
      ? Math.round((totalAnnualRetirementIncome / grossAnnualIncome) * 10000) / 100
      : 0;

  return {
    yearsToRetirement,
    projectedPillar2Capital,
    projectedPillar3aBalance,
    annualPillar2Pension,
    estimatedAnnualAvsPension: annualAvsPension,
    pillar3aAsLumpSum: projectedPillar3aBalance,
    totalAnnualRetirementIncome,
    replacementRate,
    yearByYearProjection,
  };
}
