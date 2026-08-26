import { pillar3aMaxContribution } from '../../lib/pillar3a-max-contribution.js';
import { incomeTaxBreakdown } from '../../lib/cantonal-tax.js';
import {
  FEDERAL_TAX_BRACKETS_SINGLE,
  FEDERAL_TAX_BRACKETS_MARRIED,
  calculateProgressiveTax,
} from '../../lib/constants/federal-tax.js';
import type { TaxSavingsInput, TaxSavingsResult } from './calculator.types.js';

/** Calculate pillar 3a tax savings */
export function calculatePillar3aTaxSavings(input: TaxSavingsInput): TaxSavingsResult {
  const {
    canton,
    taxableIncome,
    contribution,
    maritalStatus,
    churchTax,
    hasSecondPillar,
    municipality,
  } = input;

  // Max contribution — without 2nd pillar: min(CHF 36'288, 20% of taxable
  // income, proxy for net earned income — OPP3 art. 7).
  const maxContribution = pillar3aMaxContribution(hasSecondPillar, taxableIncome);
  const effectiveContribution = Math.min(contribution, maxContribution);
  const incomeAfterDeduction = taxableIncome - effectiveContribution;

  // Federal tax savings (official direct federal tax (IFD) 2026 brackets, art. 36 LIFD)
  const isMarried = maritalStatus === 'MARRIED' || maritalStatus === 'REGISTERED_PARTNERSHIP';
  const federalBrackets = isMarried ? FEDERAL_TAX_BRACKETS_MARRIED : FEDERAL_TAX_BRACKETS_SINGLE;
  const federalTaxBefore = calculateProgressiveTax(taxableIncome, federalBrackets);
  const federalTaxAfter = calculateProgressiveTax(incomeAfterDeduction, federalBrackets);
  const federalTaxSaving = federalTaxBefore - federalTaxAfter;

  // Cantonal + communal (+ church): official FTA (Federal Tax Administration)
  // 2026 tables, interpolated (simple tax sampled per CHF 1'000 × cantonal
  // steuerfuss; real communal multiplier if the municipality is covered).
  const local = { municipality, churchTax, married: isMarried };
  const before = incomeTaxBreakdown(canton, taxableIncome, local);
  const after = incomeTaxBreakdown(canton, incomeAfterDeduction, local);
  const cantonalTaxSaving = before.cantonal + before.church - (after.cantonal + after.church);
  const communalTaxSaving = before.communal - after.communal;

  const totalTaxSaving = federalTaxSaving + cantonalTaxSaving + communalTaxSaving;
  const effectiveReturnRate =
    effectiveContribution > 0
      ? Math.round((totalTaxSaving / effectiveContribution) * 10000) / 100
      : 0;

  return {
    federalTaxSaving,
    cantonalTaxSaving,
    communalTaxSaving,
    totalTaxSaving,
    effectiveReturnRate,
    maxContribution,
    isAtMax: contribution >= maxContribution,
  };
}
