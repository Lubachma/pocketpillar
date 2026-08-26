import { describe, it, expect } from 'vitest';
import { estimateAvsPension } from '../../src/lib/avs-pension-estimate.js';
import { SWISS_PENSION } from '../../src/lib/constants/swiss-pension.js';

/**
 * Documented simplified model (scale 44), all in centimes:
 *   incomeRatio   = clamp(income, 0, 90'720) / 90'720
 *   careerPension = 15'120 + (30'240 − 15'120) × incomeRatio
 *   pension       = round(careerPension × years / 44)
 * Years = `contributionYears` if provided, otherwise PROJECTED to retirement:
 * min((retirementAge ?? 65) − 20, 44) — the pension shown is the one paid
 * at retirement, assuming contributions continue until then.
 */
describe('estimateAvsPension', () => {
  it("maximum pension for an income ≥ CHF 90'720 and a full career (retirement at 65 → 44 projected years)", () => {
    // 65 − 20 = 45 projected years → clamped to 44; ratio 1 → 30'240 × 44/44.
    expect(estimateAvsPension({ grossAnnualIncome: 9_072_000, currentAge: 64 })).toBe(3_024_000);
    // Beyond the threshold, the ratio is capped at 1.
    expect(estimateAvsPension({ grossAnnualIncome: 15_000_000, currentAge: 64 })).toBe(3_024_000);
  });

  it('minimum pension for a zero income and a full career', () => {
    // ratio 0 → 15'120 × 44/44 (explicit contributionYears: the projection is ignored).
    expect(
      estimateAvsPension({ grossAnnualIncome: 0, currentAge: 30, contributionYears: 44 }),
    ).toBe(1_512_000);
  });

  it("interpolates proportionally between min and max (half-threshold → CHF 22'680)", () => {
    // Income 45'360 = 90'720 / 2 → 15'120 + 15'120 × 0.5 = 22'680, full career.
    expect(estimateAvsPension({ grossAnnualIncome: 4_536_000, currentAge: 64 })).toBe(2_268_000);
  });

  it('prorates the projected contribution years to retirement (retirement at 40 → 20/44)', () => {
    // 40 − 20 = 20 projected years; income ≥ threshold → 30'240 × 20/44 = 13'745.4545… → 13'745.45.
    expect(
      estimateAvsPension({ grossAnnualIncome: 9_500_000, currentAge: 35, retirementAge: 40 }),
    ).toBe(1_374_545);
    // A young worker has their career projected through to retirement: 30 years,
    // retiring at 65 → 45 projected years → clamped to 44 → max pension from CHF 90'720.
    expect(
      estimateAvsPension({ grossAnnualIncome: 9_500_000, currentAge: 30, retirementAge: 65 }),
    ).toBe(3_024_000);
  });

  it('rounds to the nearest centime, only once, on the final result', () => {
    // Income 50'000 → ratio 0.551146… → careerPension = 15'120 + 8'333.33… = 23'453.33…
    // Retiring at 45 → 25 years → 23'453.33… × 25/44 = 13'325.7575… → 13'325.76.
    expect(
      estimateAvsPension({ grossAnnualIncome: 5_000_000, currentAge: 40, retirementAge: 45 }),
    ).toBe(1_332_576);
  });

  it('uses contributionYears when provided, taking priority over the projection, clamped to 44', () => {
    // 44 explicit years despite being 30 → full career at the threshold → 30'240.
    expect(
      estimateAvsPension({ grossAnnualIncome: 9_072_000, currentAge: 30, contributionYears: 44 }),
    ).toBe(3_024_000);
    // Upper clamp: 50 years → 44.
    expect(
      estimateAvsPension({ grossAnnualIncome: 9_072_000, currentAge: 64, contributionYears: 50 }),
    ).toBe(3_024_000);
    // Lower clamp: negative → 0.
    expect(
      estimateAvsPension({ grossAnnualIncome: 9_072_000, currentAge: 64, contributionYears: -5 }),
    ).toBe(0);
  });

  it('bounds the projected years: 0 for retirement at 20 or before, 44 from retirement at 64 onward', () => {
    // Retiring at 20 → 20 − 20 = 0 years → 0 (assumption: career start simplified to age 20).
    expect(
      estimateAvsPension({ grossAnnualIncome: 9_500_000, currentAge: 18, retirementAge: 20 }),
    ).toBe(0);
    // Retiring at 64 → 44 years; at 70 → 50 → clamped to 44.
    expect(
      estimateAvsPension({ grossAnnualIncome: 9_072_000, currentAge: 60, retirementAge: 64 }),
    ).toBe(3_024_000);
    expect(
      estimateAvsPension({ grossAnnualIncome: 9_072_000, currentAge: 65, retirementAge: 70 }),
    ).toBe(3_024_000);
    // Current age no longer drives the years: an 18-year-old with retirement at 65 (default)
    // → 45 projected years → 44 → max pension at the threshold.
    expect(estimateAvsPension({ grossAnnualIncome: 9_500_000, currentAge: 18 })).toBe(3_024_000);
  });

  it("stays consistent with the legal constants (min CHF 15'120 / max CHF 30'240)", () => {
    expect(SWISS_PENSION.AVS_MIN_ANNUAL_PENSION).toBe(1_512_000);
    expect(SWISS_PENSION.AVS_MAX_ANNUAL_PENSION).toBe(3_024_000);
    expect(SWISS_PENSION.AVS_MAX_COUPLE_ANNUAL_PENSION).toBe(4_536_000);
    expect(SWISS_PENSION.AVS_MAX_PENSION_AVG_INCOME).toBe(9_072_000);
    expect(SWISS_PENSION.AVS_FULL_CONTRIBUTION_YEARS).toBe(44);
  });

  it('clamps a negative income to 0 (minimum pension for a full career)', () => {
    // Negative income → ratio 0 → minimum pension 15'120 (44 projected years, retiring at 65).
    expect(estimateAvsPension({ grossAnnualIncome: -500_000, currentAge: 64 })).toBe(1_512_000);
  });
});
