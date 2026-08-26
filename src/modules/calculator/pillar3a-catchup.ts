import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';
import { pillar3aMaxContribution } from '../../lib/pillar3a-max-contribution.js';
import { calculatePillar3aTaxSavings } from './tax-savings.js';
import type { Pillar3aCatchupInput, Pillar3aCatchupResult } from './calculator.types.js';

/** Calculate pillar 3a catch-up contribution potential and tax savings */
export function calculatePillar3aCatchup(input: Pillar3aCatchupInput): Pillar3aCatchupResult {
  const {
    currentYear,
    yearsSinceFirstEligible,
    pastContributions,
    hasSecondPillar,
    taxableIncome,
  } = input;

  // Cap on the ORDINARY contribution for the current year (OPP3 art. 7):
  // CHF 7'258 with a 2nd pillar; without one, min(CHF 36'288, 20% of taxable
  // income). Approximation: current taxable income is used as the base
  // (past income is not an input).
  const maxPerYear = pillar3aMaxContribution(hasSecondPillar, taxableIncome);

  // RETROACTIVE catch-up (OPP3 art. 7b — first buy-backs possible in 2026 for
  // 2025): each missed year is capped at the "petite cotisation", for
  // EVERYONE, self-employed without a 2nd pillar included — CHF 7'258 in
  // 2025 as in 2026. Source: bsv.admin.ch — The third pillar ("A buy-back …
  // up to the 'petite cotisation' (i.e. 7258 francs in 2026) will be
  // allowed every year").
  // Documented latent assumption: legally it's the petite cotisation OF THE
  // MISSED YEAR that applies — exact as long as 2025 = 2026 (CHF 7'258); to
  // be generalized at the next revaluation.
  const catchupMaxPerYear = SWISS_PENSION.PILLAR_3A_MAX_EMPLOYED;

  // Only years from 2025 onwards are eligible
  const firstEligibleYear = SWISS_PENSION.PILLAR_3A_CATCHUP_START_YEAR;
  const maxRetroYears = Math.min(
    yearsSinceFirstEligible,
    SWISS_PENSION.PILLAR_3A_CATCHUP_MAX_YEARS,
    currentYear - firstEligibleYear,
  );

  // Calculate gap per year — capped at the petite cotisation (art. 7b)
  const yearDetails: Pillar3aCatchupResult['yearDetails'] = [];
  let totalCatchupPotential = 0;

  for (let i = 0; i < maxRetroYears; i++) {
    const year = currentYear - 1 - i;
    if (year < firstEligibleYear) break;

    const contributed = pastContributions[year] ?? 0;
    const gap = Math.max(0, catchupMaxPerYear - contributed);

    if (gap > 0) {
      yearDetails.push({
        year,
        maxContribution: catchupMaxPerYear,
        actualContribution: contributed,
        gap,
      });
      totalCatchupPotential += gap;
    }
  }

  // Current year regular contribution must be maxed first
  const currentYearContribution = pastContributions[currentYear] ?? 0;
  const currentYearGap = Math.max(0, maxPerYear - currentYearContribution);

  // Estimated tax savings. With a canton: real year-by-year calculation via
  // the `tax-savings` engine (each buy-back is deducted in the year it is
  // paid — current taxable income is used as a proxy for future income,
  // a documented approximation). Without a canton: historical flat estimate
  // (marginal rate 25/30/35%).
  let estimatedTaxSavings: number;
  let estimatedMarginalRate: number;
  if (input.canton !== undefined) {
    estimatedTaxSavings = yearDetails.reduce(
      (sum, year) =>
        sum +
        calculatePillar3aTaxSavings({
          canton: input.canton!,
          taxableIncome,
          contribution: year.gap,
          maritalStatus: input.maritalStatus ?? 'SINGLE',
          churchTax: false,
          hasSecondPillar,
          municipality: input.municipality,
        }).totalTaxSaving,
      0,
    );
    estimatedMarginalRate =
      totalCatchupPotential > 0
        ? Math.round((estimatedTaxSavings / totalCatchupPotential) * 1000) / 10
        : 0;
  } else {
    estimatedMarginalRate = taxableIncome > 15_000_000 ? 35 : taxableIncome > 8_000_000 ? 30 : 25;
    estimatedTaxSavings = Math.round((totalCatchupPotential * estimatedMarginalRate) / 100);
  }

  return {
    maxPerYear,
    eligibleYears: maxRetroYears,
    yearDetails,
    totalCatchupPotential,
    currentYearGap,
    mustMaxCurrentYearFirst: currentYearGap > 0,
    estimatedTaxSavings,
    estimatedMarginalRate,
  };
}
