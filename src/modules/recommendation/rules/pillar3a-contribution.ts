import { pillar3aMaxContribution } from '../../../lib/pillar3a-max-contribution.js';
import { t } from '../../../lib/i18n/index.js';
import { calculatePillar3aTaxSavings } from '../../calculator/tax-savings.js';
import type { RecommendationRule } from '../recommendation.types.js';

const fmtChf = (centimes: number) => (centimes / 100).toLocaleString('fr-CH');

export const pillar3aContributionRule: RecommendationRule = (input) => {
  const {
    locale,
    pillar3aAccounts,
    hasSecondPillar,
    canton,
    municipality,
    taxableIncome,
    maritalStatus,
    churchTax,
  } = input;
  const yearsToRetirement = input.retirementAge - input.currentAge;

  // Without a 2nd pillar (self-employed, not affiliated): min(CHF 36'288, 20% of
  // taxable income, a proxy for net self-employment income — OPP3 art. 7).
  const maxContribution = pillar3aMaxContribution(hasSecondPillar, taxableIncome);

  // No 3a account at all
  if (pillar3aAccounts.length === 0) {
    const taxSavings = calculatePillar3aTaxSavings({
      canton,
      taxableIncome,
      contribution: maxContribution,
      municipality: municipality ?? undefined,
      maritalStatus,
      churchTax,
      hasSecondPillar,
    });

    return {
      type: 'OPEN_FIRST_3A',
      priority: 'HIGH',
      title: t(locale, 'rec.open_3a.title'),
      description: t(locale, 'rec.open_3a.description', {
        max: fmtChf(maxContribution),
        saving: fmtChf(taxSavings.totalTaxSaving),
      }),
      estimatedAnnualImpact: taxSavings.totalTaxSaving,
      estimatedLifetimeImpact: taxSavings.totalTaxSaving * yearsToRetirement,
      details: { maxContribution, taxSavings },
    };
  }

  // Has accounts but not maxing out
  const totalContribution = pillar3aAccounts.reduce(
    (sum, a) => sum + (a.annualContribution ?? 0),
    0,
  );

  if (totalContribution >= maxContribution) return null;

  const gap = maxContribution - totalContribution;

  const taxSavingsMax = calculatePillar3aTaxSavings({
    canton,
    taxableIncome,
    contribution: maxContribution,
    municipality: municipality ?? undefined,
    maritalStatus,
    churchTax,
    hasSecondPillar,
  });

  const taxSavingsCurrent = calculatePillar3aTaxSavings({
    canton,
    taxableIncome,
    contribution: totalContribution,
    municipality: municipality ?? undefined,
    maritalStatus,
    churchTax,
    hasSecondPillar,
  });

  const additionalSaving = taxSavingsMax.totalTaxSaving - taxSavingsCurrent.totalTaxSaving;

  return {
    type: 'MAX_3A_CONTRIBUTION',
    priority: 'HIGH',
    title: t(locale, 'rec.max_3a.title'),
    description: t(locale, 'rec.max_3a.description', {
      current: fmtChf(totalContribution),
      max: fmtChf(maxContribution),
      gap: fmtChf(gap),
      saving: fmtChf(additionalSaving),
    }),
    estimatedAnnualImpact: additionalSaving,
    estimatedLifetimeImpact: additionalSaving * yearsToRetirement,
    details: { currentContribution: totalContribution, maxContribution, gap, additionalSaving },
  };
};
