import { describe, it, expect } from 'vitest';
import { calculatePillar3aCatchup } from '../../../src/modules/calculator/pillar3a-catchup.js';

/**
 * 3a catch-up (in force since 2025): missed 3a contributions from 2025 onwards can be
 * paid retroactively (up to 10 years back), but only once the current year's
 * contribution is maxed.
 *
 * Two DISTINCT legal ceilings (OPP3):
 * - current year (ordinary contribution, art. 7): CHF 7'258 with a 2nd pillar;
 *   without, 20% of taxable income (proxy for net earned income) capped at
 *   CHF 36'288 — `maxPerYear` / `currentYearGap`;
 * - retroactive catch-up per missed year (art. 7b): the "petite cotisation"
 *   (CHF 7'258 in 2025 and 2026) for EVERYONE, self-employed included —
 *   `yearDetails[].maxContribution` / `totalCatchupPotential`.
 *   Source: bsv.admin.ch — The third pillar ("A buy-back … up to the
 *   'petite cotisation' (i.e. 7258 francs in 2026) will be allowed every year").
 * All amounts in centimes (CHF * 100).
 */
describe('calculatePillar3aCatchup', () => {
  it('computes the 2025 gap in the first catch-up year (2026)', () => {
    // Case: employee with a 2nd pillar, taxable CHF 100'000, contributed only CHF 4'000
    // in 2025. Even with 10 years since first eligibility, only 2025 is retro-eligible
    // in 2026 (2026 - 2025 = 1 year). Gap: 7'258 - 4'000 = CHF 3'258.
    // Marginal rate estimate: 30% (income > CHF 80'000) -> savings CHF 977.40.
    const result = calculatePillar3aCatchup({
      currentYear: 2026,
      yearsSinceFirstEligible: 10,
      pastContributions: { 2025: 400_000 },
      hasSecondPillar: true,
      taxableIncome: 10_000_000,
    });

    expect(result.maxPerYear).toBe(725_800);
    expect(result.eligibleYears).toBe(1);
    expect(result.yearDetails).toEqual([
      { year: 2025, maxContribution: 725_800, actualContribution: 400_000, gap: 325_800 },
    ]);
    expect(result.totalCatchupPotential).toBe(325_800);
    // Current year (2026) not contributed yet -> must be maxed before any catch-up.
    expect(result.currentYearGap).toBe(725_800);
    expect(result.mustMaxCurrentYearFirst).toBe(true);
    expect(result.estimatedMarginalRate).toBe(30);
    expect(result.estimatedTaxSavings).toBe(97_740);
  });

  it('skips fully-contributed years and looks back several years when eligible', () => {
    // Case: in 2030, 3 retro years (2029, 2028, 2027); 2029 was maxed (excluded),
    // 2028 contributed CHF 0, 2027 missing from the map (treated as 0).
    // Total potential = 2 * CHF 7'258 = CHF 14'516; income CHF 50'000 -> 25% rate.
    const result = calculatePillar3aCatchup({
      currentYear: 2030,
      yearsSinceFirstEligible: 3,
      pastContributions: { 2029: 725_800, 2028: 0 },
      hasSecondPillar: true,
      taxableIncome: 5_000_000,
    });

    expect(result.eligibleYears).toBe(3);
    expect(result.yearDetails).toEqual([
      { year: 2028, maxContribution: 725_800, actualContribution: 0, gap: 725_800 },
      { year: 2027, maxContribution: 725_800, actualContribution: 0, gap: 725_800 },
    ]);
    expect(result.totalCatchupPotential).toBe(1_451_600);
    expect(result.estimatedMarginalRate).toBe(25);
    expect(result.estimatedTaxSavings).toBe(362_900);
  });

  it("caps the retroactive catch-up at the small contribution (CHF 7'258) for a self-employed too", () => {
    // Case: self-employed, taxable CHF 200'000 -> ordinary max min(CHF 36'288,
    // 20% = CHF 40'000) = CHF 36'288 (current year, OPP3 art. 7). But the
    // retroactive catch-up of the missed 2025 year is capped at the "petite
    // cotisation" CHF 7'258 for EVERYONE (OPP3 art. 7b — bsv.admin.ch), NOT at
    // the self-employed ceiling. Income > CHF 150'000 -> 35% rate.
    const result = calculatePillar3aCatchup({
      currentYear: 2026,
      yearsSinceFirstEligible: 1,
      pastContributions: {},
      hasSecondPillar: false,
      taxableIncome: 20_000_000,
    });

    expect(result.maxPerYear).toBe(3_628_800); // ordinary current-year cap (art. 7)
    expect(result.yearDetails).toEqual([
      { year: 2025, maxContribution: 725_800, actualContribution: 0, gap: 725_800 },
    ]);
    expect(result.totalCatchupPotential).toBe(725_800); // catch-up: small contribution (art. 7b)
    expect(result.currentYearGap).toBe(3_628_800);
    expect(result.mustMaxCurrentYearFirst).toBe(true);
    expect(result.estimatedMarginalRate).toBe(35);
    expect(result.estimatedTaxSavings).toBe(254_030); // 7'258 × 35 %
  });

  it("caps the catch-up at CHF 7'258 even when the self-employed ordinary max is lower (20% rule)", () => {
    // Case: self-employed, taxable CHF 100'000 -> ordinary max = 20% = CHF 20'000
    // (< CHF 36'288) for the CURRENT year. The 2025 catch-up is still capped at
    // the small contribution CHF 7'258 (art. 7b) — same ceiling as an employee.
    // Income CHF 100'000 -> 30% rate -> savings 7'258 × 30% = CHF 2'177.40.
    const result = calculatePillar3aCatchup({
      currentYear: 2026,
      yearsSinceFirstEligible: 1,
      pastContributions: {},
      hasSecondPillar: false,
      taxableIncome: 10_000_000,
    });

    expect(result.maxPerYear).toBe(2_000_000); // ordinary current-year cap (art. 7)
    expect(result.yearDetails).toEqual([
      { year: 2025, maxContribution: 725_800, actualContribution: 0, gap: 725_800 },
    ]);
    expect(result.totalCatchupPotential).toBe(725_800);
    expect(result.currentYearGap).toBe(2_000_000);
    expect(result.mustMaxCurrentYearFirst).toBe(true);
    expect(result.estimatedMarginalRate).toBe(30);
    expect(result.estimatedTaxSavings).toBe(217_740);
  });

  it('reports no catch-up when past and current years are fully contributed', () => {
    // Case: 2025 and 2026 both maxed -> nothing to catch up, no need to max first.
    const result = calculatePillar3aCatchup({
      currentYear: 2026,
      yearsSinceFirstEligible: 1,
      pastContributions: { 2026: 725_800, 2025: 725_800 },
      hasSecondPillar: true,
      taxableIncome: 10_000_000,
    });

    expect(result.yearDetails).toEqual([]);
    expect(result.totalCatchupPotential).toBe(0);
    expect(result.currentYearGap).toBe(0);
    expect(result.mustMaxCurrentYearFirst).toBe(false);
    expect(result.estimatedTaxSavings).toBe(0);
  });

  it('returns no retro years when yearsSinceFirstEligible is 0, but still flags the current year', () => {
    // Case: first year of 3a eligibility — no catch-up possible, but the current
    // year's regular contribution is still tracked.
    const result = calculatePillar3aCatchup({
      currentYear: 2026,
      yearsSinceFirstEligible: 0,
      pastContributions: {},
      hasSecondPillar: true,
      taxableIncome: 10_000_000,
    });

    expect(result.eligibleYears).toBe(0);
    expect(result.yearDetails).toEqual([]);
    expect(result.totalCatchupPotential).toBe(0);
    expect(result.currentYearGap).toBe(725_800);
    expect(result.mustMaxCurrentYearFirst).toBe(true);
  });

  it('ignores past contributions above the max (gap floored at 0)', () => {
    // Case: CHF 8'000 recorded for 2025 (above the CHF 7'258 max — e.g. data error);
    // the gap is max(0, 7'258 - 8'000) = 0, so the year is excluded.
    const result = calculatePillar3aCatchup({
      currentYear: 2026,
      yearsSinceFirstEligible: 1,
      pastContributions: { 2025: 800_000 },
      hasSecondPillar: true,
      taxableIncome: 10_000_000,
    });

    expect(result.yearDetails).toEqual([]);
    expect(result.totalCatchupPotential).toBe(0);
  });

  it("applies the marginal rate thresholds at CHF 80'000 and CHF 150'000 of taxable income", () => {
    const rateAt = (taxableIncome: number) =>
      calculatePillar3aCatchup({
        currentYear: 2026,
        yearsSinceFirstEligible: 0,
        pastContributions: {},
        hasSecondPillar: true,
        taxableIncome,
      }).estimatedMarginalRate;

    // Boundaries are exclusive: exactly CHF 150'000 -> 30%, exactly CHF 80'000 -> 25%.
    expect(rateAt(15_000_001)).toBe(35);
    expect(rateAt(15_000_000)).toBe(30);
    expect(rateAt(8_000_001)).toBe(30);
    expect(rateAt(8_000_000)).toBe(25);
  });
});
