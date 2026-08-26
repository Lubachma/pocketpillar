import { describe, it, expect } from 'vitest';
import {
  calculateStaggeredWithdrawal,
  calculateWithdrawalTax,
} from '../../../src/modules/calculator/staggered-withdrawal.js';
import { SWISS_PENSION } from '../../../src/lib/constants/swiss-pension.js';

/**
 * Capital-withdrawal tax model (see calculateWithdrawalTax): official AFC 2026
 * sampled tables per canton and marital status — the federal part (art. 38
 * LIFD) is included in the samples, the old federal/5 + cantonal/4
 * approximation is gone. Amounts are interpolated; the non-federal part is
 * rescaled by the ratio between the municipality multiplier and the cantonal
 * capital's multiplier (the tables are sampled at the capital city).
 * All amounts in centimes (CHF * 100). Years are computed from CURRENT_YEAR so
 * the cases stay valid over time (YEAR = current calendar year).
 *
 * Main case: Zurich, total 3a CHF 500'000, 3 accounts, retiring at 65 in 5 years.
 * Building blocks (single schedule, CHF): 500'000 → 35'068 · 250'000 → 14'601 ·
 * ~166'667 → 8'937 · 100'000 → 4'817.
 */
const YEAR = SWISS_PENSION.CURRENT_YEAR;

const baseInput = {
  canton: 'ZH',
  totalPillar3aBalance: 50_000_000,
  numberOfAccounts: 3,
  retirementAge: 65,
  currentAge: 60,
  maritalStatus: 'SINGLE',
  pillar2AsCapital: 0,
} as const;

describe('calculateStaggeredWithdrawal', () => {
  it('compares lump sum vs 2-year vs 3-year staggered withdrawals', () => {
    const result = calculateStaggeredWithdrawal(baseInput);

    expect(result.strategies).toHaveLength(3);

    // Lump sum in YEAR+5: CHF 35'068 -> 7.01% of CHF 500'000.
    const lumpSum = result.strategies[0];
    expect(lumpSum.label).toBe('lump_sum');
    expect(lumpSum.years).toEqual([{ year: YEAR + 5, amount: 50_000_000 }]);
    expect(lumpSum.totalTax).toBe(3_506_800);
    expect(lumpSum.effectiveTaxRate).toBe(7.01);

    // Two withdrawals of CHF 250'000 in YEAR+4/YEAR+5: CHF 14'601 each,
    // CHF 29'202 total.
    const stagger2 = result.strategies[1];
    expect(stagger2.label).toBe('stagger_2_years');
    expect(stagger2.years).toEqual([
      { year: YEAR + 4, amount: 25_000_000 },
      { year: YEAR + 5, amount: 25_000_000 },
    ]);
    expect(stagger2.totalTax).toBe(2_920_200);
    expect(stagger2.effectiveTaxRate).toBe(5.84);

    // Three withdrawals of ~CHF 166'667 (last one gets the rounding
    // remainder): CHF 8'937 each, CHF 26'811 total.
    const stagger3 = result.strategies[2];
    expect(stagger3.label).toBe('stagger_3_years');
    expect(stagger3.years).toEqual([
      { year: YEAR + 3, amount: 16_666_667 },
      { year: YEAR + 4, amount: 16_666_667 },
      { year: YEAR + 5, amount: 16_666_666 },
    ]);
    expect(stagger3.totalTax).toBe(2_681_100);
    expect(stagger3.effectiveTaxRate).toBe(5.36);

    // Splitting across 3 years breaks the progression -> CHF 8'257 saved vs lump sum.
    expect(result.bestStrategy).toBe('stagger_3_years');
    expect(result.taxSavingsVsLumpSum).toBe(3_506_800 - 2_681_100);
  });

  it('offers only the lump sum with a single 3a account', () => {
    // Case: same profile but 1 account — staggering across accounts is impossible.
    const result = calculateStaggeredWithdrawal({ ...baseInput, numberOfAccounts: 1 });

    expect(result.strategies).toHaveLength(1);
    expect(result.bestStrategy).toBe('lump_sum');
    expect(result.taxSavingsVsLumpSum).toBe(0);
  });

  it('offers only the lump sum when retirement is less than 2 years away, and sums pillar 2 capital', () => {
    // Case: 64-year-old retiring at 65, 3a CHF 300'000 + BVG capital CHF 200'000
    // withdrawn the same year -> taxed on CHF 500'000 total (same as main case).
    const result = calculateStaggeredWithdrawal({
      ...baseInput,
      totalPillar3aBalance: 30_000_000,
      pillar2AsCapital: 20_000_000,
      numberOfAccounts: 2,
      currentAge: 64,
    });

    expect(result.strategies).toHaveLength(1);
    expect(result.strategies[0].years).toEqual([{ year: YEAR + 1, amount: 50_000_000 }]);
    expect(result.strategies[0].totalTax).toBe(3_506_800);
  });

  it('caps staggering at 5 years and splits evenly with 5 accounts', () => {
    // Case: 5 accounts, 5 years to retirement -> 5 withdrawals of CHF 100'000,
    // CHF 4'817 of tax each.
    const result = calculateStaggeredWithdrawal({ ...baseInput, numberOfAccounts: 5 });

    const stagger5 = result.strategies[2];
    expect(stagger5.label).toBe('stagger_5_years');
    expect(stagger5.years).toHaveLength(5);
    expect(stagger5.years.map((y) => y.year)).toEqual([
      YEAR + 1,
      YEAR + 2,
      YEAR + 3,
      YEAR + 4,
      YEAR + 5,
    ]);
    expect(stagger5.years.every((y) => y.amount === 10_000_000)).toBe(true);
    expect(stagger5.totalTax).toBe(5 * 481_700);
    expect(result.bestStrategy).toBe('stagger_5_years');
    expect(result.taxSavingsVsLumpSum).toBe(3_506_800 - 2_408_500);
  });

  it('taxes married couples on the married schedule (lower than single)', () => {
    // The married capital-withdrawal schedule is softer: CHF 31'576 vs
    // CHF 35'068 single on CHF 500'000 (official AFC tables).
    const single = calculateStaggeredWithdrawal(baseInput);
    const married = calculateStaggeredWithdrawal({ ...baseInput, maritalStatus: 'MARRIED' });

    expect(married.strategies[0].totalTax).toBe(3_157_600);
    expect(married.strategies[0].totalTax).toBeLessThan(single.strategies[0].totalTax);
    expect(married).not.toEqual(single);
  });

  it('uses the official AFC 2026 capital-withdrawal tables (federal part included)', () => {
    // No federal/5 + cantonal/4 decomposition anymore: the tables sample the
    // real capital-withdrawal tax (federal art. 38 LIFD included) at the
    // cantonal capital. Anchor verified against the AFC calculator: ZH single
    // CHF 500'000 → CHF 35'068.
    const result = calculateStaggeredWithdrawal({ ...baseInput, numberOfAccounts: 1 });

    expect(result.strategies[0].totalTax).toBe(calculateWithdrawalTax(50_000_000, 'ZH', 'SINGLE'));
    expect(result.strategies[0].totalTax).toBe(3_506_800);
  });

  it('zero balance: every strategy is tax-free, lump sum stays best (simplest)', () => {
    // Case: zero balance. A zero withdrawal costs zero tax — the origin point
    // (0 → 0) is added virtually to the sampled capital tables, which start
    // at CHF 10'000. All strategies tie at 0 → the first (simplest) wins:
    // covers the tax tie-break.
    const result = calculateStaggeredWithdrawal({ ...baseInput, totalPillar3aBalance: 0 });

    expect(result.strategies).toHaveLength(3);
    expect(result.strategies.every((s) => s.totalTax === 0)).toBe(true);
    expect(result.strategies.every((s) => s.effectiveTaxRate === 0)).toBe(true);
    expect(result.bestStrategy).toBe('lump_sum');
    expect(result.taxSavingsVsLumpSum).toBe(0);
  });

  it('applies the real communal multiplier of the municipality (Kriens 185% vs capital city Luzern 145%)', () => {
    // Case: same CHF 500'000 lump sum but canton LU, single. The tables are
    // sampled at the cantonal capital — Luzern (145%) — so the baseline
    // already reflects the capital city and living in Luzern changes nothing
    // (ratio 145/145). Kriens (185%) rescales the non-federal part by
    // 185/145: federal CHF 10'501 + 19'256 × 185/145 = CHF 35'069.
    const baseline = calculateStaggeredWithdrawal({
      ...baseInput,
      canton: 'LU',
      numberOfAccounts: 1,
    });
    const luzernCity = calculateStaggeredWithdrawal({
      ...baseInput,
      canton: 'LU',
      numberOfAccounts: 1,
      municipality: 'Luzern',
    });
    const kriens = calculateStaggeredWithdrawal({
      ...baseInput,
      canton: 'LU',
      numberOfAccounts: 1,
      municipality: 'Kriens',
    });

    expect(baseline.strategies[0].totalTax).toBe(2_975_700);
    expect(luzernCity.strategies[0].totalTax).toBe(2_975_700);
    expect(kriens.strategies[0].totalTax).toBe(3_506_900);
    // The whole difference comes from the non-federal part (federal unchanged).
    expect(kriens.strategies[0].totalTax - baseline.strategies[0].totalTax).toBe(531_200);
  });

  it('falls back to the cantonal average for an unknown municipality', () => {
    const unknown = calculateStaggeredWithdrawal({
      ...baseInput,
      numberOfAccounts: 1,
      municipality: 'Inexistante',
    });
    const average = calculateStaggeredWithdrawal({ ...baseInput, numberOfAccounts: 1 });

    expect(unknown).toEqual(average);
  });
});
