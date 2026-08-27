import { describe, it, expect } from 'vitest';
import {
  simulateCouple,
  estimateCoupleIncomeTax,
  planCoupleWithdrawals,
  isJointlyTaxed,
} from '../../../src/modules/calculator/couple-simulation.js';
import { SWISS_PENSION } from '../../../src/lib/constants/swiss-pension.js';
import type { RetirementProjectionInput } from '../../../src/modules/calculator/calculator.types.js';

/**
 * Couple simulation — hand-computed reference cases (all amounts in centimes).
 * Years derive from CURRENT_YEAR (YEAR below) so the cases stay valid over time.
 *
 * Tax building blocks (Zurich — official direct federal tax (IFD) 2026 brackets +
 * official FTA (Federal Tax Administration) 2026 sampled tables: simple tax ×
 * 95.01% steuerfuss, communal = simple × 119%
 * cantonal average) — hand-computed from official 2026 tariffs (RS ESTV
 * n° 215):
 *
 * Income tax (CHF):
 *   federal single 95'000 = 2'354.44 · single 60'000 = 671.44 · married 155'000
 *   = 6'030 (IFD 2026 — official schedule RS ESTV n° 215)
 *   ZH simple tax: single 95'000 → 5'720 · single 60'000 → 2'734 · married
 *   155'000 → 9'406 (cantonal = simple × 95.01%, communal = simple × 119%)
 *
 * Capital-withdrawal tax (official AFC 2026 tables sampled at the cantonal
 * capital, federal art. 38 LIFD included in the samples — the old ÷5/÷4
 * approximation is gone), married schedule: CHF 500'000 → 31'576,
 * 300'000 → 17'816, 200'000 → 10'936, 100'000 → 4'643, 1'100'000 → 96'725.
 * Single schedule: 500'000 → 35'068, 300'000 → 18'061, 200'000 → 11'141,
 * 100'000 → 4'817, 700'000 → 62'914.50, 400'000 → 24'981.
 */
const YEAR = SWISS_PENSION.CURRENT_YEAR;

function spouse(overrides: Partial<RetirementProjectionInput> = {}): RetirementProjectionInput {
  return {
    currentAge: 40,
    retirementAge: 65,
    grossAnnualIncome: 9_500_000,
    currentPillar2Capital: 15_000_000,
    annualPillar2Contribution: 800_000,
    pillar2InterestRate: 1.25,
    conversionRate: 6.0,
    currentPillar3aBalance: 1_000_000,
    annualPillar3aContribution: 725_800,
    pillar3aReturnRate: 3.0,
    estimatedAvsPension: 2_000_000,
    ...overrides,
  };
}

describe('estimateCoupleIncomeTax', () => {
  it('taxes the married couple jointly and the unmarried couple separately (ZH, 95k + 60k)', () => {
    // Married: combined CHF 155'000 → federal 6'030 (official 2026 schedule,
    // 7 %/8 % threshold at 130'500), cantonal 9'406 × 95.01% =
    // 8'936.64, communal 9'406 × 1.19 = 11'193.14 → CHF 26'159.78.
    // Unmarried: federal 2'354.44 + 671.44 = 3'025.88, cantonal 5'434.57 +
    // 2'597.57 = 8'032.14, communal 6'806.80 + 3'253.46 = 10'060.26
    // → CHF 21'118.28.
    // Two decent incomes → marriage penalty of CHF 5'041.50/year.
    const result = estimateCoupleIncomeTax('ZH', 9_500_000, 6_000_000);

    expect(result.married).toEqual({
      federalTax: 603_000,
      cantonalTax: 893_664,
      communalTax: 1_119_314,
      totalTax: 2_615_978,
    });
    expect(result.unmarried).toEqual({
      federalTax: 302_588,
      cantonalTax: 803_214,
      communalTax: 1_006_026,
      totalTax: 2_111_828,
    });
    expect(result.annualDifference).toBe(504_150);
    expect(result.cheaperStatus).toBe('CONCUBINAGE');
  });

  it('makes marriage cheaper for a single-earner couple (wider married schedules)', () => {
    // CHF 120'000 + 0: married federal 2'929 vs single 4'248.64 — and the
    // married cantonal schedule is softer too (6'026.48 vs 7'663.51): the
    // official FTA tables distinguish marital status on both levels (the old
    // simplified cantonal brackets did not).
    const result = estimateCoupleIncomeTax('ZH', 12_000_000, 0);

    expect(result.married.federalTax).toBe(292_900);
    expect(result.unmarried.federalTax).toBe(424_864);
    expect(result.married.cantonalTax).toBe(602_648);
    expect(result.unmarried.cantonalTax).toBe(766_351);
    expect(result.annualDifference).toBe(-500_704);
    expect(result.cheaperStatus).toBe('MARRIED');
  });

  it('reports EQUAL on zero incomes', () => {
    const result = estimateCoupleIncomeTax('ZH', 0, 0);

    expect(result.married.totalTax).toBe(0);
    expect(result.unmarried.totalTax).toBe(0);
    expect(result.annualDifference).toBe(0);
    expect(result.cheaperStatus).toBe('EQUAL');
  });

  it('uses the real communal multiplier of the municipality (Winterthur 125% vs ZH average 119%)', () => {
    // Same ZH 95k + 60k case, living in Winterthur (125%):
    // married communal = 9'406 × 1.25 = 11'757.50 (vs 11'193.14) → total
    // CHF 26'724.14 ; unmarried communal = (5'720 + 2'734) × 1.25 = 10'567.50
    // → CHF 21'625.52.
    const result = estimateCoupleIncomeTax('ZH', 9_500_000, 6_000_000, 'Winterthur');

    expect(result.married).toEqual({
      federalTax: 603_000,
      cantonalTax: 893_664,
      communalTax: 1_175_750,
      totalTax: 2_672_414,
    });
    expect(result.unmarried).toEqual({
      federalTax: 302_588,
      cantonalTax: 803_214,
      communalTax: 1_056_750,
      totalTax: 2_162_552,
    });
    expect(result.annualDifference).toBe(509_862);
  });
});

describe('planCoupleWithdrawals', () => {
  const p1 = { retirementYear: YEAR + 25, pillar3aCapital: 20_000_000, pillar2Capital: 50_000_000 };
  const p2 = { retirementYear: YEAR + 25, pillar3aCapital: 10_000_000, pillar2Capital: 30_000_000 };

  it('spreads same-year retirements across 4 distinct years (anti-collision, married)', () => {
    // Events: 3a at retirement − 1 (YEAR+24), LPP at retirement (YEAR+25).
    // Greedy stagger (sorted by year, 3a first, person1 first): p1.3a keeps
    // YEAR+24, p2.3a falls back to YEAR+23, p1.LPP keeps YEAR+25, p2.LPP falls back
    // to YEAR+22 (YEAR+24 and YEAR+23 already taken).
    const plan = planCoupleWithdrawals('ZH', 'MARRIED', p1, p2);

    expect(plan.steps.map((s) => [s.year, s.spouse, s.pillar])).toEqual([
      [YEAR + 22, 'person2', 'pillar2'],
      [YEAR + 23, 'person2', 'pillar3a'],
      [YEAR + 24, 'person1', 'pillar3a'],
      [YEAR + 25, 'person1', 'pillar2'],
    ]);

    // Per-step tax on the married schedule (official AFC tables): 300k →
    // 1'781'600, 100k → 464'300, 200k → 1'093'600, 500k → 3'157'600 → total
    // CHF 64'971.
    expect(plan.steps.map((s) => s.estimatedTax)).toEqual([
      1_781_600, 464_300, 1_093_600, 3_157_600,
    ]);
    expect(plan.totalEstimatedTax).toBe(6_497_100);

    // Simultaneous baseline: married couples are taxed jointly — one
    // CHF 1'100'000 withdrawal → CHF 96'725. Savings CHF 31'754.
    expect(plan.simultaneousEstimatedTax).toBe(9_672_500);
    expect(plan.taxSavingsVsSimultaneous).toBe(9_672_500 - 6_497_100);
  });

  it('taxes concubins separately: single schedule per step and per-spouse baseline', () => {
    const married = planCoupleWithdrawals('ZH', 'MARRIED', p1, p2);
    const concubin = planCoupleWithdrawals('ZH', 'CONCUBINAGE', p1, p2);

    // Same anti-collision years, but the single schedule costs more per step:
    // 300k → 1'806'100, 100k → 481'700, 200k → 1'114'100, 500k → 3'506'800.
    expect(concubin.steps.map((s) => s.year)).toEqual(married.steps.map((s) => s.year));
    expect(concubin.steps.map((s) => s.estimatedTax)).toEqual([
      1_806_100, 481_700, 1_114_100, 3_506_800,
    ]);
    expect(concubin.totalEstimatedTax).toBe(6_908_700);

    // Baseline: each spouse taxed separately on their own total
    // (700k → 6'291'450, 400k → 2'498'100 → CHF 87'895.50).
    expect(concubin.simultaneousEstimatedTax).toBe(6_291_450 + 2_498_100);
    expect(concubin.taxSavingsVsSimultaneous).toBe(8_789_550 - 6_908_700);
  });

  it('keeps natural years when retirements are far apart (no collision)', () => {
    const plan = planCoupleWithdrawals(
      'ZH',
      'MARRIED',
      { retirementYear: YEAR + 25, pillar3aCapital: 20_000_000, pillar2Capital: 50_000_000 },
      { retirementYear: YEAR + 30, pillar3aCapital: 10_000_000, pillar2Capital: 30_000_000 },
    );

    expect(plan.steps.map((s) => s.year)).toEqual([YEAR + 24, YEAR + 25, YEAR + 29, YEAR + 30]);
    // Same amounts as the main case, one withdrawal per year either way →
    // identical total tax.
    expect(plan.totalEstimatedTax).toBe(6_497_100);
  });

  it('pushes later when backing up would reach the current year (iOS left the collision)', () => {
    // Both retire next year: 3a events target YEAR (cannot go earlier).
    const plan = planCoupleWithdrawals(
      'ZH',
      'MARRIED',
      { retirementYear: YEAR + 1, pillar3aCapital: 5_000_000, pillar2Capital: 10_000_000 },
      { retirementYear: YEAR + 1, pillar3aCapital: 4_000_000, pillar2Capital: 8_000_000 },
    );

    expect(plan.steps.map((s) => [s.year, s.spouse, s.pillar])).toEqual([
      [YEAR, 'person1', 'pillar3a'],
      [YEAR + 1, 'person2', 'pillar3a'],
      [YEAR + 2, 'person1', 'pillar2'],
      [YEAR + 3, 'person2', 'pillar2'],
    ]);
    // No two withdrawals in the same fiscal year — the invariant holds.
    expect(new Set(plan.steps.map((s) => s.year)).size).toBe(plan.steps.length);
  });

  it('returns an empty plan when neither spouse has capital', () => {
    const plan = planCoupleWithdrawals(
      'ZH',
      'MARRIED',
      { retirementYear: YEAR + 25, pillar3aCapital: 0, pillar2Capital: 0 },
      { retirementYear: YEAR + 25, pillar3aCapital: 0, pillar2Capital: 0 },
    );

    expect(plan.steps).toEqual([]);
    expect(plan.totalEstimatedTax).toBe(0);
    // Zero withdrawal → zero tax, including for the "simultaneous" baseline
    // (the origin (0 → 0) is virtually added to the sampled tables,
    // which start at CHF 10'000).
    expect(plan.simultaneousEstimatedTax).toBe(0);
    expect(plan.taxSavingsVsSimultaneous).toBe(0);
  });

  it('applies the real communal multiplier to the withdrawal taxes (Winterthur 125%)', () => {
    // Same 4-step plan as the main case, but in Winterthur: only the
    // non-federal part changes (rescaled by 125/119 against the Zürich
    // capital-city samples) — 300k → 1'846'339, 100k → 485'880, 200k →
    // 1'136'760, 500k → 3'265'499 ; simultaneous baseline 1'100k →
    // CHF 100'326.26.
    const plan = planCoupleWithdrawals('ZH', 'MARRIED', p1, p2, 'Winterthur');

    expect(plan.steps.map((s) => s.estimatedTax)).toEqual([
      1_846_339, 485_880, 1_136_760, 3_265_499,
    ]);
    expect(plan.totalEstimatedTax).toBe(6_734_478);
    expect(plan.simultaneousEstimatedTax).toBe(10_032_626);
    expect(plan.taxSavingsVsSimultaneous).toBe(10_032_626 - 6_734_478);
  });
});

describe('simulateCouple', () => {
  it("caps the combined AVS pension at 150% for married couples (CHF 49'140/yr from 2026)", () => {
    // Both spouses at the individual AVS maximum CHF 30'240 (×12) → ×13/12 from
    // 2026 (13th pension) = CHF 32'760 each → raw 65'520, capped at 150 % of the
    // max monthly pension paid 13 times: 45'360 × 13/12 = CHF 49'140.
    // Combined income = 49'140 + LPP pensions.
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'MARRIED',
      person1: spouse({ estimatedAvsPension: 3_024_000 }),
      person2: spouse({ currentAge: 38, estimatedAvsPension: 3_024_000 }),
    });

    expect(result.combinedAvsAnnualRaw).toBe(6_552_000);
    expect(result.avsCapAnnual).toBe(4_914_000);
    expect(result.avsCapApplied).toBe(true);
    expect(result.combinedAvsAnnual).toBe(4_914_000);
    expect(result.combinedTotalAnnualIncome).toBe(
      4_914_000 + result.person1.annualPillar2Pension + result.person2.annualPillar2Pension,
    );
  });

  it('does NOT cap the AVS pensions of concubins (LAVS art. 35 targets married couples)', () => {
    // Divergence from the iOS CoupleCalculator, which applied the cap to
    // every couple: concubins keep two full individual pensions.
    // CHF 29'400 (×12) → ×13/12 = CHF 31'850 each from 2026 → 63'700 combined.
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'CONCUBINAGE',
      person1: spouse({ estimatedAvsPension: 2_940_000 }),
      person2: spouse({ currentAge: 38, estimatedAvsPension: 2_940_000 }),
    });

    expect(result.combinedAvsAnnualRaw).toBe(6_370_000);
    expect(result.avsCapApplied).toBe(false);
    expect(result.combinedAvsAnnual).toBe(6_370_000);
  });

  it('treats REGISTERED_PARTNERSHIP like MARRIED (assimilation since 2022)', () => {
    expect(isJointlyTaxed('REGISTERED_PARTNERSHIP')).toBe(true);

    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'REGISTERED_PARTNERSHIP',
      person1: spouse({ estimatedAvsPension: 2_940_000 }),
      person2: spouse({ currentAge: 38, estimatedAvsPension: 2_940_000 }),
    });

    expect(result.avsCapApplied).toBe(true);
    expect(result.combinedAvsAnnual).toBe(4_914_000);
  });

  it('composes both retirement projections and the combined replacement rate', () => {
    // Spouses 10 years apart (no withdrawal collision): per-spouse income
    // = AVS 20'000 ×13/12 = 21'666.67 + LPP pension ; combined rate =
    // combined / 190'000.
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'MARRIED',
      person1: spouse(),
      person2: spouse({ currentAge: 30 }),
    });

    expect(result.person1.totalAnnualRetirementIncome).toBe(
      2_166_667 + result.person1.annualPillar2Pension,
    );
    expect(result.combinedAvsAnnualRaw).toBe(4_333_334);
    expect(result.avsCapApplied).toBe(false);
    const expectedTotal =
      4_333_334 + result.person1.annualPillar2Pension + result.person2.annualPillar2Pension;
    expect(result.combinedTotalAnnualIncome).toBe(expectedTotal);
    expect(result.combinedReplacementRate).toBe(
      Math.round((expectedTotal / 19_000_000) * 10000) / 100,
    );

    // Withdrawal plan is built on the PROJECTED capitals (3a included —
    // the iOS used the current 3a balance, inconsistent with projected LPP).
    expect(result.withdrawalPlan.steps.map((s) => [s.spouse, s.pillar, s.amount])).toEqual([
      ['person1', 'pillar3a', result.person1.projectedPillar3aBalance],
      ['person1', 'pillar2', result.person1.projectedPillar2Capital],
      ['person2', 'pillar3a', result.person2.projectedPillar3aBalance],
      ['person2', 'pillar2', result.person2.projectedPillar2Capital],
    ]);
  });

  it('always exposes the tax estimate (comparison married vs concubinage)', () => {
    // The comparison is status-independent: even a married couple sees what
    // concubinage would cost (and conversely).
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'CONCUBINAGE',
      person1: spouse(),
      person2: spouse({ grossAnnualIncome: 6_000_000 }),
    });

    expect(result.taxEstimate.married.totalTax).toBe(2_615_978);
    expect(result.taxEstimate.unmarried.totalTax).toBe(2_111_828);
    expect(result.taxEstimate.cheaperStatus).toBe('CONCUBINAGE');
  });

  it("allocates the capped AVS per spouse: CHF 2'047.50/month each at two max pensions (practitioner review 08.2026)", () => {
    // Two max pensions (CHF 30'240 ×12 each → 32'760 with the 13th): raw
    // combined 65'520 > cap 49'140 → each spouse displays 24'570/year
    // = CHF 2'047.50/month (the practitioner's exact number).
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'MARRIED',
      person1: spouse({ estimatedAvsPension: 3_024_000 }),
      person2: spouse({ currentAge: 38, estimatedAvsPension: 3_024_000 }),
    });

    expect(result.person1Income.avsAnnual).toBe(2_457_000);
    expect(result.person2Income.avsAnnual).toBe(2_457_000);
    expect(result.person1Income.avsAnnual + result.person2Income.avsAnnual).toBe(
      result.combinedAvsAnnual,
    );
    expect(result.person1Income.pillar2Annual).toBe(result.person1.annualPillar2Pension);
    expect(result.person1Income.totalAnnual).toBe(2_457_000 + result.person1.annualPillar2Pension);
    // Per-spouse replacement rate vs their OWN gross income (95'000 here).
    expect(result.person1Income.replacementRate).toBe(
      Math.round(((2_457_000 + result.person1.annualPillar2Pension) / 9_500_000) * 10000) / 100,
    );
    // The per-spouse view always sums back to the combined (capped) income.
    expect(result.person1Income.totalAnnual + result.person2Income.totalAnnual).toBe(
      result.combinedTotalAnnualIncome,
    );
  });

  it('allocates the cap pro rata when the two pensions differ (LAVS art. 35 al. 3)', () => {
    // p1 = 32'760/year (13th incl.), p2 = 20'000/year → raw 52'760 > cap 49'140.
    // p1 share = round(49'140 × 32'760/52'760) = 30'512.25 ; p2 gets the rest
    // (18'627.75) so the two shares sum exactly to the cap.
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'MARRIED',
      person1: spouse({ estimatedAvsPension: 3_024_000 }),
      person2: spouse({ currentAge: 38, estimatedAvsPension: 1_846_154 }),
    });

    expect(result.combinedAvsAnnualRaw).toBe(5_276_000);
    expect(result.avsCapApplied).toBe(true);
    expect(result.person1Income.avsAnnual).toBe(3_051_225);
    expect(result.person2Income.avsAnnual).toBe(1_862_775);
    expect(result.person1Income.avsAnnual + result.person2Income.avsAnnual).toBe(4_914_000);
  });

  it('exposes a single-phase timeline when both spouses retire the same year', () => {
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'MARRIED',
      person1: spouse({ estimatedAvsPension: 3_024_000 }),
      person2: spouse({ estimatedAvsPension: 3_024_000 }),
    });

    expect(result.timeline).toHaveLength(1);
    const [phase] = result.timeline;
    expect(phase.startYear).toBe(YEAR + 25);
    expect(phase.endYear).toBeNull();
    expect(phase.person1Age).toBe(65);
    expect(phase.person2Age).toBe(65);
    expect(phase.person1Retired).toBe(true);
    expect(phase.person2Retired).toBe(true);
    expect(phase.avsCapApplied).toBe(true);
    // The cruising phase IS the existing headline: same capped shares,
    // same combined income.
    expect(phase.person1AvsAnnual).toBe(2_457_000);
    expect(phase.person2AvsAnnual).toBe(2_457_000);
    expect(phase.combinedAnnual).toBe(result.combinedTotalAnnualIncome);
  });

  it("phases the timeline on an age gap: full pension until the younger retires, then the cap (practitioner's own case)", () => {
    // p1 is 40, p2 is 38 → p1 retires at YEAR+25, p2 at YEAR+27. Between the
    // two retirements the elder draws a FULL pension (LAVS art. 35 caps only
    // once both pensions are running) — the exact nuance the practitioner
    // flagged ("rente pleine ~1 an puis plafonné").
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'MARRIED',
      person1: spouse({ estimatedAvsPension: 3_024_000 }),
      person2: spouse({ currentAge: 38, estimatedAvsPension: 3_024_000 }),
    });

    expect(result.timeline).toHaveLength(2);
    const [first, cruising] = result.timeline;

    // Phase 1 — only p1 retired: full individual pension, no cap.
    expect(first.startYear).toBe(YEAR + 25);
    expect(first.endYear).toBe(YEAR + 27);
    expect(first.person1Age).toBe(65);
    expect(first.person2Age).toBe(63);
    expect(first.person1Retired).toBe(true);
    expect(first.person2Retired).toBe(false);
    expect(first.avsCapApplied).toBe(false);
    expect(first.person1AvsAnnual).toBe(3_276_000); // full, ×13/12
    expect(first.person2AvsAnnual).toBe(0);
    expect(first.person2Pillar2Annual).toBe(0);
    expect(first.person1TotalAnnual).toBe(3_276_000 + result.person1.annualPillar2Pension);
    expect(first.combinedAnnual).toBe(first.person1TotalAnnual);

    // Phase 2 — both retired: pro-rata capped shares, headline figures.
    expect(cruising.startYear).toBe(YEAR + 27);
    expect(cruising.endYear).toBeNull();
    expect(cruising.person1Age).toBe(67);
    expect(cruising.person2Age).toBe(65);
    expect(cruising.person2Retired).toBe(true);
    expect(cruising.avsCapApplied).toBe(true);
    expect(cruising.person1AvsAnnual).toBe(2_457_000);
    expect(cruising.person2AvsAnnual).toBe(2_457_000);
    expect(cruising.combinedAnnual).toBe(result.combinedTotalAnnualIncome);
  });

  it('never caps the timeline of unmarried couples, in either phase', () => {
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'CONCUBINAGE',
      person1: spouse({ estimatedAvsPension: 3_024_000 }),
      person2: spouse({ currentAge: 38, estimatedAvsPension: 3_024_000 }),
    });

    expect(result.timeline).toHaveLength(2);
    expect(result.timeline[0].avsCapApplied).toBe(false);
    expect(result.timeline[1].avsCapApplied).toBe(false);
    // Both keep their full pensions once retired.
    expect(result.timeline[1].person1AvsAnnual).toBe(3_276_000);
    expect(result.timeline[1].person2AvsAnnual).toBe(3_276_000);
  });

  it('orders the phases correctly when the PARTNER retires first', () => {
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'MARRIED',
      person1: spouse({ currentAge: 38, estimatedAvsPension: 3_024_000 }),
      person2: spouse({ estimatedAvsPension: 3_024_000 }),
    });

    const [first] = result.timeline;
    expect(first.person1Retired).toBe(false);
    expect(first.person2Retired).toBe(true);
    expect(first.person1AvsAnnual).toBe(0);
    expect(first.person2AvsAnnual).toBe(3_276_000);
    expect(first.combinedAnnual).toBe(3_276_000 + result.person2.annualPillar2Pension);
  });

  it('keeps the uncapped pensions per spouse when no cap applies (concubinage)', () => {
    const result = simulateCouple({
      canton: 'ZH',
      maritalStatus: 'CONCUBINAGE',
      person1: spouse({ estimatedAvsPension: 3_024_000 }),
      person2: spouse({ currentAge: 38, estimatedAvsPension: 3_024_000 }),
    });

    expect(result.avsCapApplied).toBe(false);
    expect(result.person1Income.avsAnnual).toBe(3_276_000);
    expect(result.person2Income.avsAnnual).toBe(3_276_000);
    // Same numbers as the raw projection — the per-spouse view only differs
    // when the couple cap bites.
    expect(result.person1Income.totalAnnual).toBe(result.person1.totalAnnualRetirementIncome);
    expect(result.person1Income.replacementRate).toBe(result.person1.replacementRate);
  });
});
