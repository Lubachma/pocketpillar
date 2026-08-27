import { describe, it, expect } from 'vitest';
import {
  calculateRetirementProjection,
  avsAnnualPension,
} from '../../../src/modules/calculator/retirement-projection.js';
import { SWISS_PENSION } from '../../../src/lib/constants/swiss-pension.js';

/**
 * Business rule: the pillar 3a is EXCLUDED from retirement income — it is withdrawn
 * as a lump sum (pillar3aAsLumpSum) and taxed separately, so it is never annualized
 * into totalAnnualRetirementIncome. Retirement income = AVS pension + pillar 2 pension.
 * Years are labelled from the dynamic CURRENT_YEAR. All amounts in centimes.
 *
 * 13th AVS pension (vote of 3.3.2024, first payment in December 2026): the AVS
 * pension is annualized over 13 monthly payments from the year 2026 (×13/12) — the
 * monthly pension does not change. `estimatedAvsPension` (input) is the classic
 * annual pension ×12 (scale 44: max CHF 30'240 = 12 × 2'520).
 *
 * Main case: 63-year-old, retires at 65, gross CHF 95'000,
 * pillar 2: CHF 150'000 at 1.25% + CHF 8'000/year,
 * pillar 3a: CHF 30'000 at 3% + CHF 7'258/year, estimated AVS CHF 25'000/year (×12).
 */
const YEAR = SWISS_PENSION.CURRENT_YEAR;

const baseInput = {
  currentAge: 63,
  retirementAge: 65,
  grossAnnualIncome: 9_500_000,
  currentPillar2Capital: 15_000_000,
  annualPillar2Contribution: 800_000,
  pillar2InterestRate: 1.25,
  conversionRate: 6.0,
  currentPillar3aBalance: 3_000_000,
  annualPillar3aContribution: 725_800,
  pillar3aReturnRate: 3.0,
  estimatedAvsPension: 2_500_000,
};

describe('calculateRetirementProjection', () => {
  it('projects pillar 2 and 3a year by year with per-year rounding', () => {
    // Pillar 2: 150'000*1.0125 + 8'000 = 159'875 (YEAR+1); *1.0125 + 8'000 = 169'873.44 (YEAR+2).
    // Pillar 3a: 30'000*1.03 + 7'258 = 38'158 (YEAR+1); *1.03 + 7'258 = 46'560.74 (YEAR+2).
    const result = calculateRetirementProjection(baseInput);

    expect(result.yearsToRetirement).toBe(2);
    expect(result.projectedPillar2Capital).toBe(16_987_344);
    expect(result.projectedPillar3aBalance).toBe(4_656_074);
    expect(result.yearByYearProjection).toEqual([
      // First projected year is CURRENT_YEAR + 1, at age currentAge + 1 (64).
      {
        year: YEAR + 1,
        age: 64,
        pillar2Capital: 15_987_500,
        pillar3aBalance: 3_815_800,
        totalCapital: 19_803_300,
      },
      {
        year: YEAR + 2,
        age: 65,
        pillar2Capital: 16_987_344,
        pillar3aBalance: 4_656_074,
        totalCapital: 21_643_418,
      },
    ]);
  });

  it('derives pensions, total income and replacement rate from the projections', () => {
    // Pillar 2 pension = 6% of CHF 169'873.44 = CHF 10'192.41.
    // Retirement in YEAR+2 (≥ 2026) → AVS annualized on 13 months:
    // 25'000 × 13/12 = CHF 27'083.33.
    // The 3a is NOT in the income: total = 27'083.33 + 10'192.41 = CHF 37'275.74
    // -> 39.24% of CHF 95'000. The 3a stays available as a lump sum of CHF 46'560.74.
    const result = calculateRetirementProjection(baseInput);

    expect(result.annualPillar2Pension).toBe(1_019_241);
    expect(result.estimatedAnnualAvsPension).toBe(2_708_333);
    expect(result.pillar3aAsLumpSum).toBe(4_656_074);
    expect(result.totalAnnualRetirementIncome).toBe(3_727_574);
    expect(result.replacementRate).toBe(39.24);
  });

  it('returns the current capitals and an empty projection when already at retirement age', () => {
    // Case: 65-year-old retiring now — zero compounding iterations, retirement
    // year = CURRENT_YEAR (≥ 2026 → 13 monthly AVS payments).
    // Pension = 6% of CHF 150'000 = CHF 9'000; total income = 27'083.33 + 9'000
    // = CHF 36'083.33.
    const result = calculateRetirementProjection({ ...baseInput, currentAge: 65 });

    expect(result.yearsToRetirement).toBe(0);
    expect(result.yearByYearProjection).toEqual([]);
    expect(result.projectedPillar2Capital).toBe(15_000_000);
    expect(result.projectedPillar3aBalance).toBe(3_000_000);
    expect(result.annualPillar2Pension).toBe(900_000);
    expect(result.totalAnnualRetirementIncome).toBe(3_608_333);
    expect(result.replacementRate).toBe(37.98);
  });

  it('works without a pillar 3a (zero balance and contribution)', () => {
    // Case: 64-year-old, no 3a; pillar 2 CHF 100'000 at 1.25%, no further contribution.
    // Projection: 100'000 * 1.0125 = CHF 101'250; pension = 6% = CHF 6'075.
    const result = calculateRetirementProjection({
      ...baseInput,
      currentAge: 64,
      currentPillar2Capital: 10_000_000,
      annualPillar2Contribution: 0,
      currentPillar3aBalance: 0,
      annualPillar3aContribution: 0,
    });

    expect(result.projectedPillar2Capital).toBe(10_125_000);
    expect(result.projectedPillar3aBalance).toBe(0);
    expect(result.pillar3aAsLumpSum).toBe(0);
    expect(result.annualPillar2Pension).toBe(607_500);
    expect(result.totalAnnualRetirementIncome).toBe(2_708_333 + 607_500);
    expect(result.replacementRate).toBe(34.9); // 33'158.33 / 95'000
  });

  it('ignores the 3a in the income even when it is the only capital (zero income guarded to 0)', () => {
    // Case: 3a of CHF 10'000 losing 20%/year (schema allows down to -20%), no other
    // income. Balance: 8'000 after year 1, 6'400 after year 2 — withdrawn as a lump
    // sum, so it contributes NOTHING to totalAnnualRetirementIncome (0 here).
    // grossAnnualIncome = 0 -> replacementRate is 0 (guard against division by zero).
    const result = calculateRetirementProjection({
      ...baseInput,
      grossAnnualIncome: 0,
      currentPillar2Capital: 0,
      annualPillar2Contribution: 0,
      currentPillar3aBalance: 1_000_000,
      annualPillar3aContribution: 0,
      pillar3aReturnRate: -20,
      estimatedAvsPension: 0,
    });

    expect(result.projectedPillar3aBalance).toBe(640_000);
    expect(result.pillar3aAsLumpSum).toBe(640_000);
    expect(result.totalAnnualRetirementIncome).toBe(0);
    expect(result.replacementRate).toBe(0);
  });
});

describe('avsAnnualPension — 13th AVS pension from 2026', () => {
  // 13th AVS pension (vote of 3.3.2024): paid for the first time in
  // December 2026 — 13 monthly payments per year from 2026, 12 before. The
  // monthly pension (and the 150 % couple cap) does not change.
  // Source: sozialesicherheit.ch — "What's changing in 2026".
  it('keeps 12 monthly payments for pension years before 2026', () => {
    expect(avsAnnualPension(3_024_000, 2025)).toBe(3_024_000);
    expect(avsAnnualPension(3_024_000, 2020)).toBe(3_024_000);
  });

  it('annualizes on 13 monthly payments from 2026 onwards', () => {
    // Max pension CHF 30'240 (×12) → 30'240 × 13/12 = CHF 32'760 (×13).
    expect(avsAnnualPension(3_024_000, 2026)).toBe(3_276_000);
    expect(avsAnnualPension(3_024_000, 2027)).toBe(3_276_000);
    // Rounded to the nearest centime: 25'000 × 13/12 = 27'083.333…
    expect(avsAnnualPension(2_500_000, 2026)).toBe(2_708_333);
  });

  it('uses the named legal constant for the first year (2026)', () => {
    expect(SWISS_PENSION.AVS_13TH_PENSION_FIRST_YEAR).toBe(2026);
    expect(avsAnnualPension(3_024_000, SWISS_PENSION.AVS_13TH_PENSION_FIRST_YEAR)).toBe(3_276_000);
    expect(avsAnnualPension(3_024_000, SWISS_PENSION.AVS_13TH_PENSION_FIRST_YEAR - 1)).toBe(
      3_024_000,
    );
  });
});

describe('pillar 3a withdrawal tax estimate (practitioner review 08.2026)', () => {
  // In this model the pillar 2 is annuitized (conversion rate) — only the 3a
  // leaves as a lump sum, so the withdrawal tax estimate targets the 3a.
  // Anchors from the official FTA 2026 tables (see staggered-withdrawal tests):
  // ZH single CHF 500'000 → 35'068 (7.01%) · ZH married CHF 500'000 → 31'576.
  const frozen3aInput = {
    ...baseInput,
    currentPillar3aBalance: 50_000_000,
    annualPillar3aContribution: 0,
    pillar3aReturnRate: 0,
  };

  it('estimates the 3a lump-sum tax when a canton is provided (ZH, single schedule)', () => {
    const result = calculateRetirementProjection({
      ...frozen3aInput,
      canton: 'ZH',
      maritalStatus: 'SINGLE',
    });

    expect(result.projectedPillar3aBalance).toBe(50_000_000);
    expect(result.pillar3aWithdrawalTax).toBe(3_506_800);
    expect(result.pillar3aNetLumpSum).toBe(50_000_000 - 3_506_800);
  });

  it('uses the married schedule for MARRIED (and REGISTERED_PARTNERSHIP)', () => {
    const married = calculateRetirementProjection({
      ...frozen3aInput,
      canton: 'ZH',
      maritalStatus: 'MARRIED',
    });
    const partnership = calculateRetirementProjection({
      ...frozen3aInput,
      canton: 'ZH',
      maritalStatus: 'REGISTERED_PARTNERSHIP',
    });

    expect(married.pillar3aWithdrawalTax).toBe(3_157_600);
    expect(partnership.pillar3aWithdrawalTax).toBe(3_157_600);
    expect(married.pillar3aNetLumpSum).toBe(50_000_000 - 3_157_600);
  });

  it('omits the estimate when no canton is provided (fields absent from the response)', () => {
    const result = calculateRetirementProjection(frozen3aInput);

    expect(result.pillar3aWithdrawalTax).toBeUndefined();
    expect(result.pillar3aNetLumpSum).toBeUndefined();
  });
});
