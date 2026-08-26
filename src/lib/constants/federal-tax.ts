/**
 * Swiss direct federal tax (IFD) income brackets (art. 36 LIFD) — tariff in
 * force for tax year 2026 (DFF ordinance on cold progression compensation,
 * 10.09.2025; Rundschreiben ESTV n° 215, 11.09.2025; Fedlex DBG,
 * AS 2025 579).
 *
 * Single tariff: the maximum marginal rate of 13.2% drops to 11.5% beyond
 * the threshold where total tax reaches 11.5% of taxable income (legal cap).
 * Married tariff: maximum marginal rate of 13%, with a 941'300–941'400
 * micro-bracket at 12%, then the legal cap of 11.5% from 941'400.
 * All thresholds in centimes.
 */
export const FEDERAL_TAX_BRACKETS_SINGLE = [
  { from: 0, to: 1_520_000, rate: 0 },
  { from: 1_520_000, to: 3_320_000, rate: 0.77 },
  { from: 3_320_000, to: 4_350_000, rate: 0.88 },
  { from: 4_350_000, to: 5_800_000, rate: 2.64 },
  { from: 5_800_000, to: 7_620_000, rate: 2.97 },
  { from: 7_620_000, to: 8_210_000, rate: 5.94 },
  { from: 8_210_000, to: 10_890_000, rate: 6.6 },
  { from: 10_890_000, to: 14_150_000, rate: 8.8 },
  { from: 14_150_000, to: 18_510_000, rate: 11.0 },
  { from: 18_510_000, to: 79_390_000, rate: 13.2 },
  { from: 79_390_000, to: Infinity, rate: 11.5 },
] as const;

export const FEDERAL_TAX_BRACKETS_MARRIED = [
  { from: 0, to: 2_970_000, rate: 0 },
  { from: 2_970_000, to: 5_340_000, rate: 1.0 },
  { from: 5_340_000, to: 6_130_000, rate: 2.0 },
  { from: 6_130_000, to: 7_910_000, rate: 3.0 },
  { from: 7_910_000, to: 9_490_000, rate: 4.0 },
  { from: 9_490_000, to: 10_870_000, rate: 5.0 },
  { from: 10_870_000, to: 12_060_000, rate: 6.0 },
  // 7%/8% boundary at 130'500 (official cumulative anchor 3'658.00) — 2026
  // tariff, Rundschreiben ESTV n° 215 / Fedlex AS 2025 579.
  { from: 12_060_000, to: 13_050_000, rate: 7.0 },
  { from: 13_050_000, to: 13_840_000, rate: 8.0 },
  { from: 13_840_000, to: 14_430_000, rate: 9.0 },
  { from: 14_430_000, to: 14_830_000, rate: 10.0 },
  { from: 14_830_000, to: 15_040_000, rate: 11.0 },
  { from: 15_040_000, to: 15_240_000, rate: 12.0 },
  { from: 15_240_000, to: 94_130_000, rate: 13.0 },
  // Official 941'300–941'400 micro-bracket at 12% (cumulative anchor
  // 108'249.00 at 941'300): the legal cap of 11.5% kicks in at 941'400
  // (108'261.00 = 11.5% × 941'400 exactly).
  { from: 94_130_000, to: 94_140_000, rate: 12.0 },
  { from: 94_140_000, to: Infinity, rate: 11.5 },
] as const;

export type TaxBracket = { from: number; to: number; rate: number };

/** Calculate tax for a given income using progressive brackets */
export function calculateProgressiveTax(income: number, brackets: readonly TaxBracket[]): number {
  let tax = 0;
  for (const bracket of brackets) {
    if (income <= bracket.from) break;
    const taxableInBracket = Math.min(income, bracket.to) - bracket.from;
    tax += (taxableInBracket * bracket.rate) / 100;
  }
  return Math.round(tax);
}
