import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';
import type { PropertyPurchaseInput, PropertyPurchaseResult } from './calculator.types.js';

/** Domain error: the requested (or achievable) withdrawal is below the legal EPL minimum */
export class EplMinWithdrawalError extends Error {
  constructor() {
    super("Withdrawal below the EPL minimum of CHF 20'000");
    this.name = 'EplMinWithdrawalError';
  }
}

/** Calculate impact of EPL (property purchase) withdrawal on retirement */
export function calculatePropertyPurchaseImpact(
  input: PropertyPurchaseInput,
): PropertyPurchaseResult {
  const {
    age,
    retirementAge,
    currentBvgCapital,
    bvgCapitalAtAge50,
    withdrawalAmount,
    annualContribution,
    interestRate,
    conversionRate,
  } = input;

  const yearsToRetirement = retirementAge - age;

  // EPL withdrawal limits
  let maxWithdrawal: number;
  if (age < SWISS_PENSION.EPL_AGE_LIMIT) {
    // Before 50: can withdraw full vested benefits
    maxWithdrawal = currentBvgCapital;
  } else {
    // After 50: max of balance at 50 or 50% of current balance
    const halfCurrent = Math.round(currentBvgCapital / 2);
    maxWithdrawal = Math.max(bvgCapitalAtAge50 ?? halfCurrent, halfCurrent);
  }

  // A request below the legal EPL minimum is rejected, never silently raised.
  if (withdrawalAmount < SWISS_PENSION.EPL_MIN_WITHDRAWAL) {
    throw new EplMinWithdrawalError();
  }
  const effectiveWithdrawal = Math.min(withdrawalAmount, maxWithdrawal);
  if (effectiveWithdrawal < SWISS_PENSION.EPL_MIN_WITHDRAWAL) {
    // Capital too small to satisfy the legal minimum withdrawal.
    throw new EplMinWithdrawalError();
  }

  // Project capital WITHOUT withdrawal
  let capitalWithout = currentBvgCapital;
  for (let i = 0; i < yearsToRetirement; i++) {
    capitalWithout = Math.round(capitalWithout * (1 + interestRate / 100) + annualContribution);
  }

  // Project capital WITH withdrawal
  let capitalWith = currentBvgCapital - effectiveWithdrawal;
  for (let i = 0; i < yearsToRetirement; i++) {
    capitalWith = Math.round(capitalWith * (1 + interestRate / 100) + annualContribution);
  }

  const pensionWithout = Math.round((capitalWithout * conversionRate) / 100);
  const pensionWith = Math.round((capitalWith * conversionRate) / 100);
  const annualPensionLoss = pensionWithout - pensionWith;
  const capitalLostAtRetirement = capitalWithout - capitalWith;

  return {
    maxWithdrawal,
    effectiveWithdrawal,
    capitalAtRetirementWithout: capitalWithout,
    capitalAtRetirementWith: capitalWith,
    capitalLostAtRetirement,
    annualPensionWithout: pensionWithout,
    annualPensionWith: pensionWith,
    annualPensionLoss,
    monthlyPensionLoss: Math.round(annualPensionLoss / 12),
  };
}
