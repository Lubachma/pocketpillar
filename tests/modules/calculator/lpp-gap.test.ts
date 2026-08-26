import { describe, it, expect } from 'vitest';
import { calculateLppGap } from '../../../src/modules/calculator/lpp-gap.js';

/**
 * Reference constants (src/lib/constants/swiss-pension.ts — law in force 2026):
 * - Entry threshold: CHF 22'680 (below this, the salary is not LPP-insured)
 * - Coordination deduction: FIXED, CHF 26'460 (7/8 of the max AVS pension)
 * - Coordinated salary: gross − 26'460, bounded between CHF 3'780 (legal floor)
 *   and CHF 64'260 (cap = 90'720 − 26'460)
 * - Credits: 7 % (25-34) / 10 % (35-44) / 15 % (45-54) / 18 % (55-65,
 *   extended beyond 65 as long as one keeps working)
 * - Min LPP interest: 1.25 % — min conversion rate: 6.8 %
 * Amounts in centimes (CHF × 100).
 */
describe('calculateLppGap', () => {
  it("computes the full analysis for a 63-year-old earning CHF 80'000, 2 years from retirement", () => {
    // Case: Zurich employee, 63, gross CHF 80'000, BVG capital CHF 200'000,
    // actual contribution CHF 4'000/year, retirement at 65, conversion 6.8%.
    // Deduction = fixed CHF 26'460 -> coordinated salary = 80'000 − 26'460 = CHF 53'540
    // (below the CHF 64'260 cap). Age 63 -> 18% rate -> BVG min contribution = CHF 9'637.20.
    const result = calculateLppGap({
      grossAnnualIncome: 8_000_000,
      age: 63,
      retirementAge: 65,
      currentBvgCapital: 20_000_000,
      actualAnnualContribution: 400_000,
      conversionRate: 6.8,
    });

    expect(result.coordinatedSalary).toBe(5_354_000);
    expect(result.bvgMinContribution).toBe(963_720);
    // Underpaying by CHF 5'637.20/year relative to the BVG minimum.
    expect(result.contributionGap).toBe(563_720);

    // Both projections start from the current CHF 200'000 capital (symmetric paths).
    // Min path (+ CHF 9'637.20/year at 1.25%): year 1 = 202'500 + 9'637.20 = 212'137.20;
    // year 2 = 212'137.20*1.0125 + 9'637.20 = 224'426.115 -> rounded once to 224'426.12.
    expect(result.projectedBvgMinCapital).toBe(22_442_612);
    // Actual path (+ CHF 4'000/year): year 1 = 202'500 + 4'000 = 206'500;
    // year 2 = 206'500*1.0125 + 4'000 = 213'081.25.
    expect(result.projectedActualCapital).toBe(21_308_125);

    // Gap = 224'426.12 − 213'081.25 = CHF 11'344.87 (contribution shortfall + compounding).
    expect(result.capitalGap).toBe(1_134_487);

    expect(result.projectedMinAnnualPension).toBe(1_526_098); // 6.8% of 224'426.12
    expect(result.projectedActualAnnualPension).toBe(1_448_953); // 6.8% of 213'081.25 (rounded)
    expect(result.pensionGap).toBe(1_526_098 - 1_448_953);
  });

  it('applies the 10% rate at 44 and the 15% rate at 45 (bracket boundary)', () => {
    // Case: same CHF 80'000 salary, early retirement at 58; only the age bracket changes.
    const base = {
      grossAnnualIncome: 8_000_000,
      retirementAge: 58,
      currentBvgCapital: 0,
      actualAnnualContribution: 0,
      conversionRate: 6.8,
    };
    const at44 = calculateLppGap({ ...base, age: 44 });
    const at45 = calculateLppGap({ ...base, age: 45 });

    // 10% of CHF 53'540 = CHF 5'354 vs 15% = CHF 8'031.
    expect(at44.bvgMinContribution).toBe(535_400);
    expect(at44.contributionGap).toBe(535_400);
    expect(at45.bvgMinContribution).toBe(803_100);
    expect(at45.contributionGap).toBe(803_100);
  });

  it('produces a zero gap when the actual contribution equals the LPP minimum (5-year annuity)', () => {
    // Case: 30-year-old, gross CHF 60'000 -> coordinated 60'000 − 26'460 = CHF 33'540,
    // 7% rate -> min contribution CHF 2'347.80/year, contributing exactly that, no current capital.
    // Projection over 5 years at 1.25%: 234'780 * (((1.0125)^5 − 1) / 0.0125) ~= CHF 12'036.17.
    const result = calculateLppGap({
      grossAnnualIncome: 6_000_000,
      age: 30,
      retirementAge: 35,
      currentBvgCapital: 0,
      actualAnnualContribution: 234_780,
      conversionRate: 6.8,
    });

    expect(result.coordinatedSalary).toBe(3_354_000);
    expect(result.bvgMinContribution).toBe(234_780);
    expect(result.contributionGap).toBe(0);
    expect(result.projectedBvgMinCapital).toBe(1_203_617);
    expect(result.projectedActualCapital).toBe(1_203_617);
    expect(result.capitalGap).toBe(0);
    expect(result.projectedMinAnnualPension).toBe(81_846);
    expect(result.pensionGap).toBe(0);
  });

  it("caps the coordinated salary at CHF 64'260 for any salary ≥ CHF 90'720", () => {
    // Case: gross CHF 90'720 (exactly the max insured salary) vs gross CHF 120'000.
    // The cap is fixed by law: max insured salary − fixed coordination deduction
    // = 90'720 − 26'460 = CHF 64'260. At CHF 120'000 the raw coordinated salary is
    // 120'000 − 26'460 = CHF 93'540 -> capped at CHF 64'260 too.
    const base = {
      age: 40,
      retirementAge: 65,
      currentBvgCapital: 0,
      actualAnnualContribution: 0,
      conversionRate: 6.8,
    };
    const atMax = calculateLppGap({ ...base, grossAnnualIncome: 9_072_000 });
    const above = calculateLppGap({ ...base, grossAnnualIncome: 12_000_000 });

    expect(atMax.coordinatedSalary).toBe(6_426_000); // CHF 64'260
    expect(above.coordinatedSalary).toBe(6_426_000); // fixed cap — does not shrink
  });

  it("returns a zero coordinated salary below the LPP entry threshold (CHF 22'680)", () => {
    // Case: gross CHF 4'000 — below the entry threshold, the salary is not LPP-insured
    // at all, so there is no coordinated salary and no BVG minimum contribution.
    const below = calculateLppGap({
      grossAnnualIncome: 400_000,
      age: 63,
      retirementAge: 65,
      currentBvgCapital: 0,
      actualAnnualContribution: 0,
      conversionRate: 6.8,
    });

    expect(below.coordinatedSalary).toBe(0);
    expect(below.bvgMinContribution).toBe(0);
    expect(below.contributionGap).toBe(0);

    // At exactly the threshold (CHF 22'680): 22'680 − 26'460 < 0 -> the legal minimum
    // coordinated salary CHF 3'780 applies (part-time floor). Same floor at CHF 23'000.
    const atThreshold = calculateLppGap({
      grossAnnualIncome: 2_268_000,
      age: 40,
      retirementAge: 65,
      currentBvgCapital: 0,
      actualAnnualContribution: 0,
      conversionRate: 6.8,
    });
    expect(atThreshold.coordinatedSalary).toBe(378_000);
    expect(
      calculateLppGap({
        grossAnnualIncome: 2_300_000,
        age: 40,
        retirementAge: 65,
        currentBvgCapital: 0,
        actualAnnualContribution: 0,
        conversionRate: 6.8,
      }).coordinatedSalary,
    ).toBe(378_000);
    // One centime below the threshold -> not insured.
    expect(
      calculateLppGap({
        grossAnnualIncome: 2_267_999,
        age: 40,
        retirementAge: 65,
        currentBvgCapital: 0,
        actualAnnualContribution: 0,
        conversionRate: 6.8,
      }).coordinatedSalary,
    ).toBe(0);
  });

  it('extends the 18% rate past 65 as long as one keeps working', () => {
    // Case: 66-year-old still working, retiring at 70, contributing CHF 5'000/year.
    // The last bracket rate (18%) applies past 65 -> BVG min = 18% of 53'540 = CHF 9'637.20.
    const result = calculateLppGap({
      grossAnnualIncome: 8_000_000,
      age: 66,
      retirementAge: 70,
      currentBvgCapital: 0,
      actualAnnualContribution: 500_000,
      conversionRate: 6.8,
    });

    expect(result.bvgMinContribution).toBe(963_720);
    expect(result.contributionGap).toBe(463_720); // 9'637.20 − 5'000
    // Min path over 4 years: 9'637.20 -> 19'394.87 -> 29'274.50 -> 39'277.63.
    expect(result.projectedBvgMinCapital).toBe(3_927_763);
    // Actual path: 5'000 -> 10'062.50 -> 15'188.28 -> 20'378.13.
    expect(result.projectedActualCapital).toBe(2_037_813);
    expect(result.capitalGap).toBe(1_889_950);
    expect(result.pensionGap).toBe(128_517); // 6.8% of each capital (rounded per path)
  });

  it('bounds the gaps at 0 when the actual situation exceeds the LPP minimum', () => {
    // Case: contributing CHF 10'000/year — more than the CHF 9'637.20 minimum.
    // Both paths start from the same CHF 200'000, so the gaps go negative in theory
    // and are clamped to 0 (there is no "negative gap").
    const result = calculateLppGap({
      grossAnnualIncome: 8_000_000,
      age: 63,
      retirementAge: 65,
      currentBvgCapital: 20_000_000,
      actualAnnualContribution: 1_000_000,
      conversionRate: 6.8,
    });

    expect(result.contributionGap).toBe(0);
    expect(result.capitalGap).toBe(0);
    expect(result.pensionGap).toBe(0);
  });

  it('returns the starting capitals when retirementAge equals age', () => {
    // Case: 65-year-old retiring immediately — zero compounding iterations, both
    // projections return the current capital.
    const result = calculateLppGap({
      grossAnnualIncome: 8_000_000,
      age: 65,
      retirementAge: 65,
      currentBvgCapital: 20_000_000,
      actualAnnualContribution: 400_000,
      conversionRate: 6.8,
    });

    expect(result.projectedBvgMinCapital).toBe(20_000_000);
    expect(result.projectedActualCapital).toBe(20_000_000);
    expect(result.capitalGap).toBe(0);
    expect(result.projectedMinAnnualPension).toBe(1_360_000); // 6.8% of CHF 200'000
    expect(result.projectedActualAnnualPension).toBe(1_360_000);
    expect(result.pensionGap).toBe(0);
  });
});
