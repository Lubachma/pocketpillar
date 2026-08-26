import { describe, it, expect } from 'vitest';
import {
  calculatePropertyPurchaseImpact,
  EplMinWithdrawalError,
} from '../../../src/modules/calculator/property-purchase.js';

/**
 * EPL rules (src/lib/constants/swiss-pension.ts): minimum withdrawal CHF 20'000;
 * before age 50 the full vested benefits can be withdrawn, from 50 onwards the max is
 * the greater of the balance at age 50 and half the current balance.
 * All amounts in centimes (CHF * 100).
 */
describe('calculatePropertyPurchaseImpact', () => {
  it('allows the full capital before 50 and projects the pension loss to retirement', () => {
    // Case: 45-year-old, BVG capital CHF 200'000, withdraws CHF 50'000 for a home,
    // contributes CHF 8'000/year at 1.25% until 58, conversion 6.0%.
    // Without withdrawal: CHF 347'221.70 at 58; with: CHF 288'458.53.
    // The capital loss (CHF 58'763.17) exceeds the CHF 50'000 withdrawn because of
    // 13 years of foregone compound interest.
    const result = calculatePropertyPurchaseImpact({
      age: 45,
      retirementAge: 58,
      currentBvgCapital: 20_000_000,
      withdrawalAmount: 5_000_000,
      annualContribution: 800_000,
      interestRate: 1.25,
      conversionRate: 6.0,
    });

    expect(result.maxWithdrawal).toBe(20_000_000); // full vested benefits before 50
    expect(result.effectiveWithdrawal).toBe(5_000_000);
    expect(result.capitalAtRetirementWithout).toBe(34_722_170);
    expect(result.capitalAtRetirementWith).toBe(28_845_853);
    expect(result.capitalLostAtRetirement).toBe(5_876_317);
    expect(result.annualPensionWithout).toBe(2_083_330);
    expect(result.annualPensionWith).toBe(1_730_751);
    expect(result.annualPensionLoss).toBe(352_579); // CHF 3'525.79/year
    expect(result.monthlyPensionLoss).toBe(29_382); // CHF 293.82/month
  });

  it('limits the withdrawal after 50 to the balance at 50 when it exceeds half the current balance', () => {
    // Case: 52-year-old, capital CHF 300'000 (had CHF 250'000 at 50), requests CHF 300'000.
    // Max = max(250'000, 300'000 / 2) = CHF 250'000 -> the request is capped.
    const result = calculatePropertyPurchaseImpact({
      age: 52,
      retirementAge: 53,
      currentBvgCapital: 30_000_000,
      bvgCapitalAtAge50: 25_000_000,
      withdrawalAmount: 30_000_000,
      annualContribution: 0,
      interestRate: 1.25,
      conversionRate: 6.0,
    });

    expect(result.maxWithdrawal).toBe(25_000_000);
    expect(result.effectiveWithdrawal).toBe(25_000_000);
    // 300'000*1.0125 = 303'750 vs (300'000 - 250'000)*1.0125 = 50'625.
    expect(result.capitalAtRetirementWithout).toBe(30_375_000);
    expect(result.capitalAtRetirementWith).toBe(5_062_500);
    expect(result.annualPensionLoss).toBe(1_518_750);
    expect(result.monthlyPensionLoss).toBe(126_563); // round(1'518'750 / 12)
  });

  it('falls back to half the current balance after 50 when bvgCapitalAtAge50 is unknown', () => {
    // Case: same profile without the balance at 50 -> max = 300'000 / 2 = CHF 150'000.
    const result = calculatePropertyPurchaseImpact({
      age: 52,
      retirementAge: 53,
      currentBvgCapital: 30_000_000,
      withdrawalAmount: 10_000_000,
      annualContribution: 0,
      interestRate: 1.25,
      conversionRate: 6.0,
    });

    expect(result.maxWithdrawal).toBe(15_000_000);
    expect(result.effectiveWithdrawal).toBe(10_000_000);
    expect(result.capitalAtRetirementWith).toBe(20_250_000); // 200'000 * 1.0125
  });

  it("rejects a withdrawal below the CHF 20'000 EPL minimum with a domain error", () => {
    // Requesting CHF 10'000 (below the EPL minimum) is rejected — the function never
    // withdraws more (or less) than requested to satisfy the legal minimum.
    expect(() =>
      calculatePropertyPurchaseImpact({
        age: 63,
        retirementAge: 65,
        currentBvgCapital: 20_000_000,
        withdrawalAmount: 1_000_000,
        annualContribution: 800_000,
        interestRate: 1.25,
        conversionRate: 6.0,
      }),
    ).toThrow(EplMinWithdrawalError);
  });

  it('rejects the withdrawal when the capital is too small to reach the EPL minimum', () => {
    // Case: only CHF 15'000 of capital (< CHF 20'000 minimum). Requesting CHF 20'000
    // passes the request-level minimum, but the achievable withdrawal (capped at the
    // CHF 15'000 balance) falls below the legal minimum -> rejected, not silently
    // proceeded below it.
    expect(() =>
      calculatePropertyPurchaseImpact({
        age: 40,
        retirementAge: 41,
        currentBvgCapital: 1_500_000,
        withdrawalAmount: 2_000_000,
        annualContribution: 0,
        interestRate: 1.25,
        conversionRate: 6.0,
      }),
    ).toThrow(EplMinWithdrawalError);
  });

  it('computes the immediate pension impact when already at retirement age', () => {
    // Case: 65-year-old withdrawing CHF 50'000 at retirement — no compounding left.
    // Pension drops by 6% of 50'000 = CHF 3'000/year = CHF 250/month.
    const result = calculatePropertyPurchaseImpact({
      age: 65,
      retirementAge: 65,
      currentBvgCapital: 20_000_000,
      withdrawalAmount: 5_000_000,
      annualContribution: 800_000,
      interestRate: 1.25,
      conversionRate: 6.0,
    });

    expect(result.capitalAtRetirementWithout).toBe(20_000_000);
    expect(result.capitalAtRetirementWith).toBe(15_000_000);
    expect(result.annualPensionLoss).toBe(300_000);
    expect(result.monthlyPensionLoss).toBe(25_000);
  });
});
