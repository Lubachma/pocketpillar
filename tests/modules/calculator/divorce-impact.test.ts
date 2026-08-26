import { describe, it, expect } from 'vitest';
import { calculateDivorceImpact } from '../../../src/modules/calculator/divorce-impact.js';

/**
 * Swiss divorce rule (art. 122/123 CC): the LPP capital accumulated *during the
 * marriage* by each spouse is split 50/50. The function also adds a simplified AVS
 * estimate: ~2% of the max AVS pension (CHF 30'240) per married year, split in two.
 * All amounts in centimes (CHF * 100).
 */
describe('calculateDivorceImpact', () => {
  it('splits the capital accumulated during marriage 50/50 (higher accumulator pays)', () => {
    // Case: 63-year-old, married 15 years, retires at 65.
    // Me: CHF 50'000 at marriage -> CHF 200'000 now (accumulated CHF 150'000).
    // Spouse: CHF 10'000 -> CHF 100'000 (accumulated CHF 90'000).
    // Total marriage capital CHF 240'000 -> my share CHF 120'000
    // -> I pay CHF 30'000 (negative transfer), ending at CHF 170'000.
    const result = calculateDivorceImpact({
      age: 63,
      retirementAge: 65,
      bvgCapitalAtMarriage: 5_000_000,
      bvgCapitalNow: 20_000_000,
      spouseBvgCapitalAtMarriage: 1_000_000,
      spouseBvgCapitalNow: 10_000_000,
      yearsMarried: 15,
      annualContribution: 800_000,
      interestRate: 1.25,
      conversionRate: 6.0,
    });

    expect(result.myAccumulatedDuringMarriage).toBe(15_000_000);
    expect(result.spouseAccumulatedDuringMarriage).toBe(9_000_000);
    expect(result.totalMarriageCapital).toBe(24_000_000);
    expect(result.transferAmount).toBe(-3_000_000);
    expect(result.capitalAfterDivorce).toBe(17_000_000);

    // Projection with CHF 8'000/year at 1.25% until 65:
    // with marriage 200'000 -> 221'311.25; after divorce 170'000 -> 190'376.56.
    expect(result.projectedCapitalWithMarriage).toBe(22_113_125);
    expect(result.projectedCapitalAfterDivorce).toBe(19_037_656);
    expect(result.annualPensionWithMarriage).toBe(1_326_788);
    expect(result.annualPensionAfterDivorce).toBe(1_142_259);
    expect(result.annualPensionDifference).toBe(184_529); // CHF 1'845.29/year less

    // AVS estimate: 2% * CHF 30'240 * 15 years / 2 = CHF 4'536/year.
    expect(result.estimatedAvsImpact).toBe(453_600);
  });

  it('transfers nothing when both spouses accumulated the same amount', () => {
    // Case: both started at 0 and now hold CHF 100'000 each after 10 married years.
    const result = calculateDivorceImpact({
      age: 64,
      retirementAge: 65,
      bvgCapitalAtMarriage: 0,
      bvgCapitalNow: 10_000_000,
      spouseBvgCapitalAtMarriage: 0,
      spouseBvgCapitalNow: 10_000_000,
      yearsMarried: 10,
      annualContribution: 0,
      interestRate: 1.25,
      conversionRate: 6.0,
    });

    expect(result.transferAmount).toBe(0);
    expect(result.capitalAfterDivorce).toBe(10_000_000);
    expect(result.annualPensionDifference).toBe(0);
    // The AVS estimate is independent of the capital split: 2% * 30'240 * 10 / 2 = CHF 3'024.
    expect(result.estimatedAvsImpact).toBe(302_400);
  });

  it('yields a positive transfer (and a pension gain) for the lower accumulator', () => {
    // Case: I accumulated CHF 50'000, my spouse CHF 200'000 -> total CHF 250'000,
    // my share CHF 125'000 -> I receive CHF 75'000, ending at CHF 125'000.
    // Note: annualPensionDifference is negative here — the divorce leaves me better off.
    // yearsMarried = 0 -> no AVS impact.
    const result = calculateDivorceImpact({
      age: 64,
      retirementAge: 65,
      bvgCapitalAtMarriage: 0,
      bvgCapitalNow: 5_000_000,
      spouseBvgCapitalAtMarriage: 0,
      spouseBvgCapitalNow: 20_000_000,
      yearsMarried: 0,
      annualContribution: 0,
      interestRate: 1.25,
      conversionRate: 6.0,
    });

    expect(result.transferAmount).toBe(7_500_000);
    expect(result.capitalAfterDivorce).toBe(12_500_000);
    expect(result.projectedCapitalAfterDivorce).toBe(12_656_250); // 125'000 * 1.0125
    expect(result.annualPensionDifference).toBe(-455_625);
    expect(result.estimatedAvsImpact).toBe(0);
  });

  it('keeps estimatedAvsImpact positive regardless of the transfer direction — documented simplification', () => {
    // The AVS figure is a rough "impact" estimate (child-rearing credits split), always
    // >= 0 and identical for both spouses; it is not a signed gain/loss. The code
    // documents it as a simplified estimate — frozen here for the 15-year case.
    const result = calculateDivorceImpact({
      age: 64,
      retirementAge: 65,
      bvgCapitalAtMarriage: 0,
      bvgCapitalNow: 5_000_000,
      spouseBvgCapitalAtMarriage: 0,
      spouseBvgCapitalNow: 20_000_000,
      yearsMarried: 15,
      annualContribution: 0,
      interestRate: 1.25,
      conversionRate: 6.0,
    });

    expect(result.transferAmount).toBeGreaterThan(0); // I receive LPP capital...
    expect(result.estimatedAvsImpact).toBe(453_600); // ...but the AVS "impact" is still positive
  });
});
