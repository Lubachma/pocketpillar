import { describe, it, expect } from 'vitest';
import { calculatePillar3aTaxSavings } from '../../../src/modules/calculator/tax-savings.js';

/**
 * Reference constants:
 * - Pillar 3a max 2026: CHF 7'258 with a 2nd pillar; without a 2nd pillar,
 *   20% of taxable income (proxy for net earned income) capped at CHF 36'288
 *   (OPP3 art. 7).
 * - Federal brackets (federal-tax.ts): official direct federal tax (IFD) 2026
 *   tariff (art. 36 LIFD) — 0% up to CHF 15'200 (single) / CHF 29'700 (married).
 * - Cantonal/communal (cantonal-tax.ts): official FTA (Federal Tax Administration)
 *   2026 sampled tables —
 *   simple tax interpolated × cantonal steuerfuss (ZH 95.01%, VD 147.25%),
 *   communal = simple × real communal multiplier (cantonal average as
 *   fallback), church = (cantonal + communal) × cantonal factor.
 * All amounts in centimes (CHF * 100).
 *
 * Reference case used below: single in Zurich, taxable income CHF 100'000,
 * full 3a contribution CHF 7'258.
 * - Federal tax: CHF 2'684.44 before, CHF 2'205.41 after -> saving CHF 479.03
 * - ZH simple tax CHF 6'170 before -> cantonal 6'170 × 95.01% = CHF 5'862.12
 *   before, CHF 5'241.49 after -> saving CHF 620.63
 * - Communal (119% of the simple saving CHF 653.22): CHF 777.33
 */
const zurichSingle = {
  canton: 'ZH',
  taxableIncome: 10_000_000,
  contribution: 725_800,
  maritalStatus: 'SINGLE',
  churchTax: false,
  hasSecondPillar: true,
} as const;

describe('calculatePillar3aTaxSavings', () => {
  it('computes federal, cantonal and communal savings for a Zurich single at the 3a max', () => {
    const result = calculatePillar3aTaxSavings(zurichSingle);

    expect(result.federalTaxSaving).toBe(47_903);
    expect(result.cantonalTaxSaving).toBe(62_063);
    expect(result.communalTaxSaving).toBe(77_733);
    expect(result.totalTaxSaving).toBe(187_699); // CHF 1'876.99
    // 1'876.99 / 7'258 = 25.86% immediate "return" on the contribution.
    expect(result.effectiveReturnRate).toBe(25.86);
    expect(result.maxContribution).toBe(725_800);
    expect(result.isAtMax).toBe(true);
  });

  it('uses the married schedules for MARRIED status (lower federal and cantonal saving)', () => {
    // Same case but married: the married schedules are wider (federal 0% up to
    // CHF 29'700, and the official cantonal tables have a softer married
    // schedule — unlike the old simplified model, both levels now distinguish
    // marital status), so the deduction saves less on both.
    const result = calculatePillar3aTaxSavings({ ...zurichSingle, maritalStatus: 'MARRIED' });

    expect(result.federalTaxSaving).toBe(34_132);
    expect(result.cantonalTaxSaving).toBe(51_786);
    expect(result.communalTaxSaving).toBe(64_862);
    expect(result.totalTaxSaving).toBe(150_780);
    expect(result.effectiveReturnRate).toBe(20.77);
  });

  it('treats REGISTERED_PARTNERSHIP like MARRIED for the federal brackets', () => {
    const married = calculatePillar3aTaxSavings({ ...zurichSingle, maritalStatus: 'MARRIED' });
    const partnership = calculatePillar3aTaxSavings({
      ...zurichSingle,
      maritalStatus: 'REGISTERED_PARTNERSHIP',
    });

    expect(partnership).toEqual(married);
  });

  it('adds the church tax surcharge on top of the cantonal saving when churchTax is true', () => {
    // ZH church factor = 4.67% of (cantonal + communal): church CHF 616.65
    // before, CHF 551.36 after -> CHF 65.29 of extra saving on top of the
    // CHF 620.63 cantonal saving (the communal saving itself is unchanged).
    const result = calculatePillar3aTaxSavings({ ...zurichSingle, churchTax: true });

    expect(result.federalTaxSaving).toBe(47_903);
    expect(result.cantonalTaxSaving).toBe(62_063 + 6_529);
    expect(result.communalTaxSaving).toBe(77_733);
    expect(result.totalTaxSaving).toBe(194_228);
    expect(result.effectiveReturnRate).toBe(26.76);
  });

  it("caps the self-employed 3a at 20% of taxable income (CHF 20'000 at CHF 100'000)", () => {
    // Case: self-employed, taxable CHF 100'000, contributing CHF 20'000 to 3a.
    // Max = min(CHF 36'288, 20% * 100'000) = CHF 20'000 — contributing exactly the max.
    // Federal: 2'684.44 - 1'378.30 = CHF 1'306.14; ZH cantonal: simple saving
    // CHF 1'800 × 95.01% = CHF 1'710.18; communal: 119% × 1'800 = CHF 2'142.
    const result = calculatePillar3aTaxSavings({
      ...zurichSingle,
      hasSecondPillar: false,
      contribution: 2_000_000,
    });

    expect(result.maxContribution).toBe(2_000_000);
    expect(result.isAtMax).toBe(true);
    expect(result.federalTaxSaving).toBe(130_614);
    expect(result.cantonalTaxSaving).toBe(171_018);
    expect(result.communalTaxSaving).toBe(214_200);
    expect(result.totalTaxSaving).toBe(515_832);
    expect(result.effectiveReturnRate).toBe(25.79);
  });

  it("clamps a self-employed contribution to the 20%-of-income cap, not to CHF 36'288", () => {
    // Case: self-employed, taxable CHF 100'000, contributing CHF 36'288 — only
    // CHF 20'000 (20% of income) is deductible, so the savings equal the
    // CHF 20'000 case above.
    const result = calculatePillar3aTaxSavings({
      ...zurichSingle,
      hasSecondPillar: false,
      contribution: 3_628_800,
    });
    const atCap = calculatePillar3aTaxSavings({
      ...zurichSingle,
      hasSecondPillar: false,
      contribution: 2_000_000,
    });

    expect(result.maxContribution).toBe(2_000_000);
    expect(result.isAtMax).toBe(true);
    expect(result.totalTaxSaving).toBe(atCap.totalTaxSaving);
    expect(result.effectiveReturnRate).toBe(atCap.effectiveReturnRate);
  });

  it("allows the full CHF 36'288 for a self-employed once 20% of income exceeds it", () => {
    // Case: self-employed, taxable CHF 300'000 -> 20% = CHF 60'000 > CHF 36'288,
    // so the legal max applies. Contribution CHF 36'288.
    // Federal: 26'103.44 - 21'313.42 = CHF 4'790.02 (13.2% marginal bracket).
    // ZH cantonal: simple saving CHF 4'687.56 × 95.01% = CHF 4'453.65.
    // Communal: 119% × 4'687.56 = CHF 5'578.20.
    const result = calculatePillar3aTaxSavings({
      ...zurichSingle,
      hasSecondPillar: false,
      taxableIncome: 30_000_000,
      contribution: 3_628_800,
    });

    expect(result.maxContribution).toBe(3_628_800);
    expect(result.isAtMax).toBe(true);
    expect(result.federalTaxSaving).toBe(479_002);
    expect(result.cantonalTaxSaving).toBe(445_365);
    expect(result.communalTaxSaving).toBe(557_820);
    expect(result.totalTaxSaving).toBe(1_482_187);
    expect(result.effectiveReturnRate).toBe(40.85);
  });

  it('clamps a contribution above the max and reports isAtMax', () => {
    // Case: contributing CHF 10'000 with a 2nd pillar — only CHF 7'258 is deductible.
    const result = calculatePillar3aTaxSavings({ ...zurichSingle, contribution: 1_000_000 });
    const atMax = calculatePillar3aTaxSavings(zurichSingle);

    expect(result.isAtMax).toBe(true);
    expect(result.totalTaxSaving).toBe(atMax.totalTaxSaving);
    expect(result.effectiveReturnRate).toBe(atMax.effectiveReturnRate);
  });

  it('yields much lower savings in Zug than in Zurich for the same profile', () => {
    // Same case in ZG (low-tax canton): cantonal saving CHF 533.95, communal
    // CHF 410.78 -> total CHF 1'423.76 vs 1'876.99 in ZH.
    const result = calculatePillar3aTaxSavings({ ...zurichSingle, canton: 'ZG' });

    expect(result.cantonalTaxSaving).toBe(53_395);
    expect(result.communalTaxSaving).toBe(41_078);
    expect(result.totalTaxSaving).toBe(142_376);
    expect(result.effectiveReturnRate).toBe(19.62);
  });

  it('computes savings on a low income where the deduction crosses bracket thresholds', () => {
    // Case: taxable CHF 10'000, full CHF 7'258 contribution -> taxable drops to CHF 2'742.
    // Federal: CHF 0 both ways (0% bracket up to CHF 15'200).
    // ZH: simple CHF 60 at 10'000 (CHF 0 at 2'742) -> cantonal 60 × 95.01% =
    // CHF 57.01; communal: 119% × 60 = CHF 71.40.
    const result = calculatePillar3aTaxSavings({ ...zurichSingle, taxableIncome: 1_000_000 });

    expect(result.federalTaxSaving).toBe(0);
    expect(result.cantonalTaxSaving).toBe(5_701);
    expect(result.communalTaxSaving).toBe(7_140);
    expect(result.totalTaxSaving).toBe(12_841);
    expect(result.effectiveReturnRate).toBe(1.77);
  });

  it('returns zero savings when the whole income is below every taxed bracket', () => {
    // Case: taxable CHF 5'000 — ZH simple tax is 0 up to CHF 7'000 and the
    // federal 0% bracket runs to CHF 15'200. The CHF 7'258 deduction exceeds
    // the income; the negative remainder is taxed at CHF 0.
    const result = calculatePillar3aTaxSavings({ ...zurichSingle, taxableIncome: 500_000 });

    expect(result.federalTaxSaving).toBe(0);
    expect(result.cantonalTaxSaving).toBe(0);
    expect(result.communalTaxSaving).toBe(0);
    expect(result.totalTaxSaving).toBe(0);
    expect(result.effectiveReturnRate).toBe(0);
  });

  describe('municipality (real communal multipliers, tax year 2026)', () => {
    it('uses the real Lausanne multiplier (78.5%) instead of the VD average (75%) — hand-computed', () => {
      // Case: single in Lausanne, taxable CHF 100'000, full 3a CHF 7'258.
      // Federal saving: CHF 479.03 (same as the Zurich reference case).
      // VD cantonal: simple saving ≈ CHF 871 × 1.4725 (155% coefficient with
      // the 5% 2026 rebate) = CHF 1'282.49.
      // Communal: 78.5% × 871 ≈ CHF 683.71 (vs 75% × 871 ≈ CHF 653.22
      // with the VD average).
      const lausanne = calculatePillar3aTaxSavings({
        ...zurichSingle,
        canton: 'VD',
        municipality: 'Lausanne',
      });
      const vdAverage = calculatePillar3aTaxSavings({ ...zurichSingle, canton: 'VD' });

      expect(lausanne.federalTaxSaving).toBe(47_903);
      expect(lausanne.cantonalTaxSaving).toBe(128_249);
      expect(lausanne.communalTaxSaving).toBe(68_371);
      expect(lausanne.totalTaxSaving).toBe(244_523);
      expect(lausanne.effectiveReturnRate).toBe(33.69);

      expect(vdAverage.communalTaxSaving).toBe(65_322);
      expect(vdAverage.totalTaxSaving).toBe(241_474);
    });

    it('uses the Winterthur multiplier (125%) instead of the ZH average (119%)', () => {
      // Zurich reference case but living in Winterthur:
      // communal = 125% × 653.22 = CHF 816.52 (vs 777.33 at the cantonal average).
      const result = calculatePillar3aTaxSavings({ ...zurichSingle, municipality: 'Winterthur' });

      expect(result.cantonalTaxSaving).toBe(62_063);
      expect(result.communalTaxSaving).toBe(81_652);
      expect(result.totalTaxSaving).toBe(191_618);
    });

    it('keeps the same result for the city of Zurich (its 119% equals the ZH average)', () => {
      const zurichCity = calculatePillar3aTaxSavings({ ...zurichSingle, municipality: 'Zürich' });
      const average = calculatePillar3aTaxSavings(zurichSingle);

      expect(zurichCity).toEqual(average);
    });

    it('falls back to the cantonal average for an unknown municipality', () => {
      const unknown = calculatePillar3aTaxSavings({
        ...zurichSingle,
        municipality: 'Commune Inconnue',
      });
      const average = calculatePillar3aTaxSavings(zurichSingle);

      expect(unknown).toEqual(average);
    });
  });
});
