import { describe, it, expect } from 'vitest';
import {
  FEDERAL_TAX_BRACKETS_SINGLE,
  FEDERAL_TAX_BRACKETS_MARRIED,
  calculateProgressiveTax,
} from '../../src/lib/constants/federal-tax.js';

/**
 * Direct federal tax (IFD) 2026 schedule (art. 36 LIFD) — threshold structure
 * pinned to the official tariff, bracket by bracket: Rundschreiben ESTV n° 215
 * (11.09.2025); Fedlex DBG, AS 2025 579; machine mirror
 * devbrains-com/swisstaxcalculator (`data/parsed/2026/tarifs/0.json`, table
 * BUND/EINKOMMENSSTEUER).
 *
 * The model applies the marginal rate to each bracket without rounded
 * cumulative anchors (documented residual gap: ≤ ~1 CHF on very high
 * incomes); the amounts below are the exact anchors of the official tariff.
 * Tax amounts in centimes.
 */
describe('FEDERAL_TAX_BRACKETS — official 2026 structure', () => {
  it('pins the 11 single brackets to the official 2026 thresholds', () => {
    const structure = FEDERAL_TAX_BRACKETS_SINGLE.map((b) => [b.from / 100, b.rate]);
    expect(structure).toEqual([
      [0, 0],
      [15_200, 0.77],
      [33_200, 0.88],
      [43_500, 2.64],
      [58_000, 2.97],
      [76_200, 5.94],
      [82_100, 6.6],
      [108_900, 8.8],
      [141_500, 11.0],
      [185_100, 13.2],
      [793_900, 11.5],
    ]);
  });

  it('pins the 16 married brackets to the official 2026 thresholds', () => {
    // Including the 7 %/8 % boundary at 130'500 (not 130'600) and the 11.5 %
    // cap kicking in at 941'400 after a micro-bracket 941'300–941'400 at
    // 12 % (official cumulative anchors: 3'658.00 at 130'500; 108'249.00 at
    // 941'300; 108'261.00 at 941'400).
    const structure = FEDERAL_TAX_BRACKETS_MARRIED.map((b) => [b.from / 100, b.rate]);
    expect(structure).toEqual([
      [0, 0],
      [29_700, 1.0],
      [53_400, 2.0],
      [61_300, 3.0],
      [79_100, 4.0],
      [94_900, 5.0],
      [108_700, 6.0],
      [120_600, 7.0],
      [130_500, 8.0],
      [138_400, 9.0],
      [144_300, 10.0],
      [148_300, 11.0],
      [150_400, 12.0],
      [152_400, 13.0],
      [941_300, 12.0],
      [941_400, 11.5],
    ]);
  });
});

describe('calculateProgressiveTax — official 2026 tariff anchors', () => {
  it('matches the official cumulative anchors on the married schedule', () => {
    // Official cumulative anchors (RS ESTV n° 215):
    // 130'500 → 3'658.00 · 152'400 → 5'692.00 · 941'300 → 108'249.00 ·
    // 941'400 → 108'261.00 (= 11.5 % × 941'400 exactly).
    expect(calculateProgressiveTax(13_050_000, FEDERAL_TAX_BRACKETS_MARRIED)).toBe(365_800);
    expect(calculateProgressiveTax(15_240_000, FEDERAL_TAX_BRACKETS_MARRIED)).toBe(569_200);
    expect(calculateProgressiveTax(94_130_000, FEDERAL_TAX_BRACKETS_MARRIED)).toBe(10_824_900);
    expect(calculateProgressiveTax(94_140_000, FEDERAL_TAX_BRACKETS_MARRIED)).toBe(10_826_100);
  });

  it('taxes married incomes exactly as the official 2026 tariff (boundary cases)', () => {
    // Married 155'000 → 5'692 + 13 % × 2'600 = 6'030.00 (the outdated threshold of
    // 130'600 gave 6'029.00, −1 CHF). Married 200'000 → 11'880.00.
    expect(calculateProgressiveTax(15_500_000, FEDERAL_TAX_BRACKETS_MARRIED)).toBe(603_000);
    expect(calculateProgressiveTax(20_000_000, FEDERAL_TAX_BRACKETS_MARRIED)).toBe(1_188_000);
    // Legal cap 11.5 %: married 1'000'000 → 115'000.00 exactly (the outdated
    // threshold of 940'900 gave 114'992.50, −7.50 CHF).
    expect(calculateProgressiveTax(100_000_000, FEDERAL_TAX_BRACKETS_MARRIED)).toBe(11_500_000);
  });

  it('matches the official single tariff on exact anchors (AFC 2026)', () => {
    // Single 100'000 → 2'684.44 (FTA (Federal Tax Administration)) · 120'000 → 4'248.64.
    expect(calculateProgressiveTax(10_000_000, FEDERAL_TAX_BRACKETS_SINGLE)).toBe(268_444);
    expect(calculateProgressiveTax(12_000_000, FEDERAL_TAX_BRACKETS_SINGLE)).toBe(424_864);
  });
});
