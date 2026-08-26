import { t } from '../../../lib/i18n/index.js';
import { SWISS_PENSION } from '../../../lib/constants/swiss-pension.js';
import { calculateLppGap } from '../../calculator/lpp-gap.js';
import {
  calculateProgressiveTax,
  FEDERAL_TAX_BRACKETS_SINGLE,
  FEDERAL_TAX_BRACKETS_MARRIED,
} from '../../../lib/constants/federal-tax.js';
import { incomeTaxBreakdown } from '../../../lib/cantonal-tax.js';
import type { RecommendationRule } from '../recommendation.types.js';

const MIN_GAP_CENTIMES = 1_000_000;
const fmtChf = (centimes: number) => (centimes / 100).toLocaleString('fr-CH');

export const bvgRachatRule: RecommendationRule = (input) => {
  const {
    locale,
    pillar2Accounts,
    grossAnnualIncome,
    currentAge,
    retirementAge,
    canton,
    maritalStatus,
  } = input;
  const yearsToRetirement = retirementAge - currentAge;

  if (pillar2Accounts.length === 0) return null;

  const mainAccount = pillar2Accounts.find((a) => !a.isVestedBenefits) ?? pillar2Accounts[0];

  const gapResult = calculateLppGap({
    grossAnnualIncome,
    age: currentAge,
    retirementAge,
    currentBvgCapital: mainAccount.currentCapital,
    actualAnnualContribution: mainAccount.annualBvgContribution ?? 0,
    conversionRate: mainAccount.conversionRate ?? SWISS_PENSION.BVG_MIN_CONVERSION_RATE,
  });

  if (gapResult.capitalGap <= MIN_GAP_CENTIMES) return null;

  const suggestedRachat = Math.min(gapResult.capitalGap, grossAnnualIncome * 0.2);
  const isMarried = maritalStatus === 'MARRIED' || maritalStatus === 'REGISTERED_PARTNERSHIP';
  const federalBrackets = isMarried ? FEDERAL_TAX_BRACKETS_MARRIED : FEDERAL_TAX_BRACKETS_SINGLE;

  const federalBefore = calculateProgressiveTax(grossAnnualIncome, federalBrackets);
  const federalAfter = calculateProgressiveTax(
    grossAnnualIncome - suggestedRachat,
    federalBrackets,
  );
  const federalSaving = federalBefore - federalAfter;

  // Cantonal + communal: official FTA (Federal Tax Administration) 2026 tables
  // (cantonal average — this recommendation doesn't know the persisted municipality here).
  const before = incomeTaxBreakdown(canton, grossAnnualIncome, { married: isMarried });
  const after = incomeTaxBreakdown(canton, grossAnnualIncome - suggestedRachat, {
    married: isMarried,
  });
  const cantonalSaving = before.cantonal - after.cantonal;
  const communalSaving = before.communal - after.communal;

  const totalTaxSaving = federalSaving + cantonalSaving + communalSaving;

  return {
    type: 'BVG_VOLUNTARY_PURCHASE',
    priority: gapResult.capitalGap > 5_000_000 ? 'HIGH' : 'MEDIUM',
    title: t(locale, 'rec.bvg_rachat.title'),
    description: t(locale, 'rec.bvg_rachat.description', {
      gap: fmtChf(gapResult.capitalGap),
      rachat: fmtChf(suggestedRachat),
      saving: fmtChf(totalTaxSaving),
    }),
    estimatedAnnualImpact: totalTaxSaving,
    estimatedLifetimeImpact:
      totalTaxSaving + Math.round(suggestedRachat * yearsToRetirement * 0.0125),
    details: {
      capitalGap: gapResult.capitalGap,
      suggestedRachat,
      federalSaving,
      cantonalSaving,
      communalSaving,
    },
  };
};
