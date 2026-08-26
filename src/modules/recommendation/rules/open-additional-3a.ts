import { SWISS_PENSION } from '../../../lib/constants/swiss-pension.js';
import { t } from '../../../lib/i18n/index.js';
import { calculateStaggeredWithdrawal } from '../../calculator/staggered-withdrawal.js';
import type { RecommendationRule } from '../recommendation.types.js';

/** Minimum total 3a balance (centimes = CHF 50'000): below this, the capital
 * tax saving is too small to justify one more account. */
const MIN_TOTAL_BALANCE_CENTIMES = 5_000_000;
/** Minimum horizon: staggering withdrawals is only worthwhile if retirement
 * is strictly more than 5 years away (time is needed to fund the additional
 * account, and a 3a withdrawal is only possible starting 5 years before
 * retirement age). */
const MIN_YEARS_TO_RETIREMENT = 5;
/** Beyond 2 open accounts (3+), staggering is already possible and the
 * marginal gain of one more account becomes small relative to the management
 * complexity — usual practice in Switzerland is 3 to 5 accounts total. */
const MAX_ACCOUNTS_FOR_RECOMMENDATION = 3;

const fmtChf = (centimes: number) => (centimes / 100).toLocaleString('fr-CH');

/**
 * Multi-account 3a strategy: with 1 or 2 accounts and significant capital,
 * recommend opening an additional account to stagger withdrawals and smooth
 * out the progressivity of the capital tax.
 *
 * Impact = tax difference between a lump-sum withdrawal and a withdrawal
 * staggered over (accounts + 1) years of the **balance projected at
 * retirement**. Assumptions (documented in the API contract §8):
 * - projected balance = current balance compounded at the default 3a return
 *   (`SWISS_PENSION.PILLAR_3A_DEFAULT_RETURN_RATE`, 3%/year), with no future
 *   contributions — a conservative assumption: future contributions would
 *   increase the saving;
 * - tax on the capital withdrawal calculated from the **official FTA
 *   (Federal Tax Administration) 2026 tables per canton**
 *   (`calculateStaggeredWithdrawal` → `capitalWithdrawalTax` — federal
 *   art. 38 LIFD included, communal adjustment via multiplier ratio),
 *   consistent with the simulator;
 * - married couples / registered partnership: married tax scale.
 */
export const openAdditional3aRule: RecommendationRule = (input) => {
  const {
    locale,
    canton,
    municipality,
    maritalStatus,
    pillar3aAccounts,
    currentAge,
    retirementAge,
  } = input;
  const yearsToRetirement = retirementAge - currentAge;

  const accountCount = pillar3aAccounts.length;
  // 0 accounts → OPEN_FIRST_3A applies instead; ≥ 3 accounts → staggering is already possible.
  if (accountCount < 1 || accountCount >= MAX_ACCOUNTS_FOR_RECOMMENDATION) return null;
  if (yearsToRetirement <= MIN_YEARS_TO_RETIREMENT) return null;

  const totalBalance = pillar3aAccounts.reduce((sum, a) => sum + a.currentBalance, 0);
  if (totalBalance < MIN_TOTAL_BALANCE_CENTIMES) return null;

  const projectedBalance = Math.round(
    totalBalance *
      Math.pow(1 + SWISS_PENSION.PILLAR_3A_DEFAULT_RETURN_RATE / 100, yearsToRetirement),
  );
  const targetAccountCount = accountCount + 1;

  const staggered = calculateStaggeredWithdrawal({
    canton,
    totalPillar3aBalance: projectedBalance,
    numberOfAccounts: targetAccountCount,
    retirementAge,
    currentAge,
    maritalStatus:
      maritalStatus === 'MARRIED' || maritalStatus === 'REGISTERED_PARTNERSHIP'
        ? 'MARRIED'
        : 'SINGLE',
    pillar2AsCapital: 0,
    municipality: municipality ?? undefined,
  });

  const lumpSumTax = staggered.strategies[0].totalTax;
  const saving = staggered.taxSavingsVsLumpSum;

  return {
    type: 'OPEN_ADDITIONAL_3A',
    priority: 'MEDIUM',
    title: t(locale, 'rec.open_additional_3a.title'),
    description: t(locale, 'rec.open_additional_3a.description', {
      count: accountCount,
      target: targetAccountCount,
      balance: fmtChf(projectedBalance),
      saving: fmtChf(saving),
    }),
    estimatedAnnualImpact: 0,
    estimatedLifetimeImpact: saving,
    details: {
      currentAccountCount: accountCount,
      targetAccountCount,
      totalBalance,
      projectedBalance,
      yearsToRetirement,
      returnRatePercent: SWISS_PENSION.PILLAR_3A_DEFAULT_RETURN_RATE,
      estimatedLumpSumTax: lumpSumTax,
      estimatedStaggeredTax: lumpSumTax - saving,
      bestStrategy: staggered.bestStrategy,
    },
  };
};
