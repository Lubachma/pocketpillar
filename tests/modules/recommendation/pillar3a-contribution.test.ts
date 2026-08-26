import { describe, it, expect } from 'vitest';
import { pillar3aContributionRule } from '../../../src/modules/recommendation/rules/pillar3a-contribution.js';
import type { RecommendationInput } from '../../../src/modules/recommendation/recommendation.types.js';

/**
 * The rule must use the user's persisted municipality (real communal multiplier)
 * so that the recommended 3a tax saving matches what the calculator shows.
 * All amounts in centimes (CHF * 100).
 */
const baseInput: RecommendationInput = {
  locale: 'fr',
  canton: 'ZH',
  birthYear: 1990,
  currentAge: 36,
  retirementAge: 65,
  employmentStatus: 'EMPLOYED',
  maritalStatus: 'SINGLE',
  numberOfChildren: 0,
  grossAnnualIncome: 9_500_000,
  pillar2Accounts: [],
  pillar3aAccounts: [],
  taxableIncome: 9_000_000,
  churchTax: false,
  hasSecondPillar: true,
  availableProducts: [],
};

describe('pillar3aContributionRule — persisted municipality', () => {
  it('uses the real communal multiplier when the municipality is provided', () => {
    // Zürich city (119 %) vs Küsnacht (73 %): the same 3a saving at the cap
    // must differ via the communal multiplier.
    const zurich = pillar3aContributionRule({ ...baseInput, municipality: 'Zürich' });
    const kuesnacht = pillar3aContributionRule({ ...baseInput, municipality: 'Küsnacht' });

    expect(zurich?.type).toBe('OPEN_FIRST_3A');
    expect(kuesnacht?.type).toBe('OPEN_FIRST_3A');
    expect(zurich!.estimatedAnnualImpact).toBeGreaterThan(kuesnacht!.estimatedAnnualImpact!);
  });

  it('falls back to the cantonal average without a municipality (unchanged behavior)', () => {
    const without = pillar3aContributionRule(baseInput);
    const unknown = pillar3aContributionRule({ ...baseInput, municipality: 'Commune Inconnue' });

    expect(without!.estimatedAnnualImpact).toBe(unknown!.estimatedAnnualImpact);
  });
});

/**
 * 20 % rule (OPP3 art. 7): without a 2nd pillar, the 3a cap is
 * min(CHF 36'288, 20 % of taxable income). Reference case computed by
 * hand: self-employed ZH, single, taxable income CHF 100'000 → cap
 * CHF 20'000; tax saving at the cap = CHF 5'158.32 (federal 1'306.14
 * + cantonal 1'710.18 + communal 119 % × 1'800 = 2'142 — see
 * tests/modules/calculator/tax-savings.test.ts).
 */
describe('pillar3aContributionRule — self-employed without a 2nd pillar (20% rule)', () => {
  const selfEmployed: RecommendationInput = {
    ...baseInput,
    employmentStatus: 'SELF_EMPLOYED',
    hasSecondPillar: false,
    grossAnnualIncome: 10_000_000,
    taxableIncome: 10_000_000,
  };

  it("OPEN_FIRST_3A quantifies the cap at 20% of income (CHF 20'000), not 36'288", () => {
    const reco = pillar3aContributionRule(selfEmployed);

    expect(reco?.type).toBe('OPEN_FIRST_3A');
    expect(reco?.priority).toBe('HIGH');
    expect(reco?.details.maxContribution).toBe(2_000_000);
    expect(reco?.estimatedAnnualImpact).toBe(515_832);
    // 29 years before retirement (65 − 36): 515'832 × 29.
    expect(reco?.estimatedLifetimeImpact).toBe(14_959_128);
  });

  it('no recommendation when the contribution reaches the 20% cap', () => {
    // With the old flat cap (36'288), a CHF 20'000 contribution
    // would have triggered MAX_3A_CONTRIBUTION — that was wrong (not deductible).
    const reco = pillar3aContributionRule({
      ...selfEmployed,
      pillar3aAccounts: [
        {
          providerName: 'VIAC',
          accountType: 'BANK',
          currentBalance: 1_000_000,
          annualContribution: 2_000_000,
          interestRateOrReturn: null,
        },
      ],
    });

    expect(reco).toBeNull();
  });

  it('MAX_3A_CONTRIBUTION quantifies the gap up to the 20% cap', () => {
    // Contribution CHF 10'000 → gap CHF 10'000. Saving at 10'000: federal
    // 660 (2'684.44 − 2'024.44) + cantonal 855.09 + communal 1'071
    // (119 % × 900) = CHF 2'586.09 → additional gain
    // 5'158.32 − 2'586.09 = CHF 2'572.23.
    const reco = pillar3aContributionRule({
      ...selfEmployed,
      pillar3aAccounts: [
        {
          providerName: 'VIAC',
          accountType: 'BANK',
          currentBalance: 1_000_000,
          annualContribution: 1_000_000,
          interestRateOrReturn: null,
        },
      ],
    });

    expect(reco?.type).toBe('MAX_3A_CONTRIBUTION');
    expect(reco?.details.maxContribution).toBe(2_000_000);
    expect(reco?.details.gap).toBe(1_000_000);
    expect(reco?.estimatedAnnualImpact).toBe(257_223);
    expect(reco?.estimatedLifetimeImpact).toBe(7_459_467); // 257'223 × 29
  });

  it("the legal cap of CHF 36'288 applies as soon as 20% of income exceeds it", () => {
    // Taxable income CHF 300'000 → 20 % = CHF 60'000 > CHF 36'288.
    const reco = pillar3aContributionRule({
      ...selfEmployed,
      grossAnnualIncome: 30_000_000,
      taxableIncome: 30_000_000,
    });

    expect(reco?.type).toBe('OPEN_FIRST_3A');
    expect(reco?.details.maxContribution).toBe(3_628_800);
  });
});
