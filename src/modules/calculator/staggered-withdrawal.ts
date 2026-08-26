import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';
import { capitalWithdrawalTax } from '../../lib/cantonal-tax.js';
import type { Canton } from '@prisma/client';

export interface StaggeredWithdrawalInput {
  canton: Canton;
  totalPillar3aBalance: number; // centimes
  numberOfAccounts: number; // 1-5
  retirementAge: number;
  currentAge: number;
  maritalStatus: 'SINGLE' | 'MARRIED';
  pillar2AsCapital: number; // centimes — optional BVG capital withdrawal
  /** Municipality of residence — real communal multiplier if covered (2026),
   * otherwise cantonal average. */
  municipality?: string;
}

export interface WithdrawalStrategy {
  label: string;
  years: { year: number; amount: number }[];
  totalTax: number; // centimes
  effectiveTaxRate: number; // %
}

export interface StaggeredWithdrawalResult {
  strategies: WithdrawalStrategy[];
  bestStrategy: string;
  taxSavingsVsLumpSum: number; // centimes
}

/**
 * Tax on capital withdrawal — OFFICIAL FTA (Federal Tax Administration) 2026
 * tables per canton (`capitalWithdrawalTax`, interpolation of amounts
 * sampled at the cantonal capital, communal adjustment via multiplier
 * ratio). Covers federal (art. 38 LIFD — the ÷5 of the ordinary rate is
 * already included in the sampled tables), real cantonal and communal.
 */
export function calculateWithdrawalTax(
  amount: number,
  canton: Canton,
  maritalStatus: string,
  municipality?: string,
): number {
  return capitalWithdrawalTax(
    canton,
    amount,
    maritalStatus === 'MARRIED' || maritalStatus === 'REGISTERED_PARTNERSHIP'
      ? 'MARRIED'
      : 'SINGLE',
    municipality,
  );
}

export function calculateStaggeredWithdrawal(
  input: StaggeredWithdrawalInput,
): StaggeredWithdrawalResult {
  const {
    canton,
    totalPillar3aBalance,
    numberOfAccounts,
    retirementAge,
    currentAge,
    maritalStatus,
    pillar2AsCapital,
    municipality,
  } = input;

  const totalCapital = totalPillar3aBalance + pillar2AsCapital;
  const yearsBeforeRetirement = retirementAge - currentAge;
  const baseYear = SWISS_PENSION.CURRENT_YEAR;
  const strategies: WithdrawalStrategy[] = [];

  // Strategy 1: Everything at once (baseline)
  {
    const tax = calculateWithdrawalTax(totalCapital, canton, maritalStatus, municipality);
    strategies.push({
      label: 'lump_sum',
      years: [{ year: baseYear + yearsBeforeRetirement, amount: totalCapital }],
      totalTax: tax,
      effectiveTaxRate: totalCapital > 0 ? Math.round((tax / totalCapital) * 10000) / 100 : 0,
    });
  }

  // Strategy 2: Stagger over 2 years (last 2 years before retirement)
  if (yearsBeforeRetirement >= 2 && numberOfAccounts >= 2) {
    const half = Math.round(totalCapital / 2);
    const tax1 = calculateWithdrawalTax(half, canton, maritalStatus, municipality);
    const tax2 = calculateWithdrawalTax(totalCapital - half, canton, maritalStatus, municipality);
    const totalTax = tax1 + tax2;
    strategies.push({
      label: 'stagger_2_years',
      years: [
        { year: baseYear + yearsBeforeRetirement - 1, amount: half },
        { year: baseYear + yearsBeforeRetirement, amount: totalCapital - half },
      ],
      totalTax,
      effectiveTaxRate: totalCapital > 0 ? Math.round((totalTax / totalCapital) * 10000) / 100 : 0,
    });
  }

  // Strategy 3: Stagger over 3-5 years
  const maxStaggerYears = Math.min(numberOfAccounts, 5, yearsBeforeRetirement);
  if (maxStaggerYears >= 3) {
    const perYear = Math.round(totalCapital / maxStaggerYears);
    const years: { year: number; amount: number }[] = [];
    let totalTax = 0;
    let remaining = totalCapital;

    for (let i = 0; i < maxStaggerYears; i++) {
      const amount = i === maxStaggerYears - 1 ? remaining : perYear;
      remaining -= amount;
      const tax = calculateWithdrawalTax(amount, canton, maritalStatus, municipality);
      totalTax += tax;
      years.push({
        year: baseYear + yearsBeforeRetirement - (maxStaggerYears - 1 - i),
        amount,
      });
    }

    strategies.push({
      label: `stagger_${maxStaggerYears}_years`,
      years,
      totalTax,
      effectiveTaxRate: totalCapital > 0 ? Math.round((totalTax / totalCapital) * 10000) / 100 : 0,
    });
  }

  // Find best strategy — on a tax tie, keep the first (simplest) strategy
  const best = strategies.reduce((a, b) => (a.totalTax <= b.totalTax ? a : b));
  const lumpSumTax = strategies[0].totalTax;
  const taxSavings = lumpSumTax - best.totalTax;

  return {
    strategies,
    bestStrategy: best.label,
    taxSavingsVsLumpSum: taxSavings,
  };
}
