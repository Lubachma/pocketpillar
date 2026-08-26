import { describe, it, expect } from 'vitest';
import { providerSwitchRule } from '../../../src/modules/recommendation/rules/provider-switch.js';
import type { RecommendationInput } from '../../../src/modules/recommendation/recommendation.types.js';

/**
 * The account provider is free text typed by the user ("viac", "VIAC ", …) while
 * the catalogue stores a canonical casing ("VIAC"). The match must be
 * case-insensitive and ignore leading/trailing spaces.
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
  pillar3aAccounts: [
    {
      providerName: 'VIAC',
      accountType: 'BANK',
      currentBalance: 5_000_000,
      annualContribution: 700_000,
      interestRateOrReturn: null,
    },
  ],
  taxableIncome: 9_000_000,
  churchTax: false,
  hasSecondPillar: true,
  availableProducts: [
    {
      providerName: 'VIAC',
      productName: 'Global 100',
      allInFeePercent: 0.6,
      avgReturn3y: null,
      riskLevel: 'AGGRESSIVE',
    },
    {
      providerName: 'Finpension',
      productName: 'Global 100',
      allInFeePercent: 0.39,
      avgReturn3y: null,
      riskLevel: 'AGGRESSIVE',
    },
  ],
};

describe('providerSwitchRule — provider name matching', () => {
  it('emits PROVIDER_SWITCH when the names match exactly', () => {
    const rec = providerSwitchRule(baseInput);

    expect(rec?.type).toBe('PROVIDER_SWITCH');
    expect(rec?.details).toMatchObject({
      currentProvider: 'VIAC',
      suggestedProvider: 'Finpension',
    });
  });

  it('matches a lowercase free-text entry against the catalogue ("viac" ↔ "VIAC")', () => {
    const rec = providerSwitchRule({
      ...baseInput,
      pillar3aAccounts: [{ ...baseInput.pillar3aAccounts[0], providerName: 'viac' }],
    });

    expect(rec?.type).toBe('PROVIDER_SWITCH');
    expect(rec?.details).toMatchObject({ suggestedProvider: 'Finpension' });
  });

  it('ignores leading/trailing spaces and mixed case ("  Viac " ↔ "VIAC")', () => {
    const rec = providerSwitchRule({
      ...baseInput,
      pillar3aAccounts: [{ ...baseInput.pillar3aAccounts[0], providerName: '  Viac ' }],
    });

    expect(rec?.type).toBe('PROVIDER_SWITCH');
  });

  it('returns null when the provider is not in the catalogue (no invented fees)', () => {
    const rec = providerSwitchRule({
      ...baseInput,
      pillar3aAccounts: [{ ...baseInput.pillar3aAccounts[0], providerName: 'Unknown Bank' }],
    });

    expect(rec).toBeNull();
  });

  it('returns null when the fee gap is below the 0.15% threshold', () => {
    const rec = providerSwitchRule({
      ...baseInput,
      availableProducts: [
        { ...baseInput.availableProducts[0], allInFeePercent: 0.5 },
        baseInput.availableProducts[1], // 0.39 → delta 0.11 < 0.15
      ],
    });

    expect(rec).toBeNull();
  });
});
