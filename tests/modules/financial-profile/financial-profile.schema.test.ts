import { describe, it, expect } from 'vitest';
import {
  createFinancialProfileSchema,
  updateFinancialProfileSchema,
  createPillar2AccountSchema,
  updatePillar2AccountSchema,
  createPillar3aAccountSchema,
  upsertTaxSituationSchema,
} from '../../../src/modules/financial-profile/financial-profile.schema.js';

// Amounts in centimes (CHF * 100).
const validProfile = {
  employmentStatus: 'EMPLOYED',
  maritalStatus: 'MARRIED',
  grossAnnualIncome: 9_500_000,
};

describe('createFinancialProfileSchema', () => {
  it('accepts a minimal profile and defaults numberOfChildren to 0', () => {
    expect(createFinancialProfileSchema.parse(validProfile)).toEqual({
      ...validProfile,
      numberOfChildren: 0,
    });
  });

  it('accepts all employment and marital statuses', () => {
    for (const employmentStatus of ['EMPLOYED', 'SELF_EMPLOYED', 'UNEMPLOYED', 'RETIRED']) {
      expect(
        createFinancialProfileSchema.safeParse({ ...validProfile, employmentStatus }).success,
      ).toBe(true);
    }
    for (const maritalStatus of [
      'SINGLE',
      'MARRIED',
      'REGISTERED_PARTNERSHIP',
      'DIVORCED',
      'WIDOWED',
    ]) {
      expect(
        createFinancialProfileSchema.safeParse({ ...validProfile, maritalStatus }).success,
      ).toBe(true);
    }
    expect(
      createFinancialProfileSchema.safeParse({ ...validProfile, employmentStatus: 'STUDENT' })
        .success,
    ).toBe(false);
  });

  it('rejects negative children, zero income is allowed (nonnegative)', () => {
    expect(
      createFinancialProfileSchema.safeParse({ ...validProfile, numberOfChildren: -1 }).success,
    ).toBe(false);
    expect(
      createFinancialProfileSchema.safeParse({ ...validProfile, grossAnnualIncome: 0 }).success,
    ).toBe(true);
    expect(
      createFinancialProfileSchema.safeParse({ ...validProfile, grossAnnualIncome: -1 }).success,
    ).toBe(false);
    expect(
      createFinancialProfileSchema.safeParse({ ...validProfile, grossAnnualIncome: 9_500_000.5 })
        .success,
    ).toBe(false);
  });

  it('bounds monetary amounts to CHF 1 billion (10^11 centimes)', () => {
    // Upper bound rejecting absurd inputs (10^15 and the like used to pass).
    expect(
      createFinancialProfileSchema.safeParse({
        ...validProfile,
        grossAnnualIncome: 100_000_000_000,
      }).success,
    ).toBe(true);
    expect(
      createFinancialProfileSchema.safeParse({
        ...validProfile,
        grossAnnualIncome: 100_000_000_001,
      }).success,
    ).toBe(false);
    expect(
      createPillar2AccountSchema.safeParse({ currentCapital: 999_999_999_999_999 }).success,
    ).toBe(false);
    expect(upsertTaxSituationSchema.safeParse({ taxableIncome: 100_000_000_001 }).success).toBe(
      false,
    );
  });
});

describe('updateFinancialProfileSchema', () => {
  it('accepts a partial update and injects NO defaults', () => {
    // The update schema is built from a default-free base shape, so parsing an empty
    // object yields {} — an update that omits numberOfChildren leaves the stored
    // value untouched instead of silently resetting it to 0.
    expect(updateFinancialProfileSchema.parse({})).toEqual({});
    expect(updateFinancialProfileSchema.parse({ grossAnnualIncome: 10_000_000 })).toEqual({
      grossAnnualIncome: 10_000_000,
    });
  });

  it('still validates the provided fields', () => {
    expect(updateFinancialProfileSchema.safeParse({ numberOfChildren: -1 }).success).toBe(false);
    expect(
      updateFinancialProfileSchema.safeParse({ maritalStatus: 'REGISTERED_PARTNERSHIP' }).success,
    ).toBe(true);
  });
});

describe('createPillar2AccountSchema', () => {
  it('accepts a minimal account and defaults isVestedBenefits to false', () => {
    expect(createPillar2AccountSchema.parse({ currentCapital: 25_000_000 })).toEqual({
      currentCapital: 25_000_000,
      isVestedBenefits: false,
    });
  });

  it('rejects a negative capital and bounds conversionRate to 0-100', () => {
    expect(createPillar2AccountSchema.safeParse({ currentCapital: -1 }).success).toBe(false);
    expect(
      createPillar2AccountSchema.safeParse({ currentCapital: 0, conversionRate: 100 }).success,
    ).toBe(true);
    expect(
      createPillar2AccountSchema.safeParse({ currentCapital: 0, conversionRate: 101 }).success,
    ).toBe(false);
  });

  it('update schema accepts any subset and injects NO defaults', () => {
    // Same default-free base shape as the profile schema: parsing {} yields {}, so a
    // pillar-2 update never resets isVestedBenefits (or any other omitted field).
    expect(updatePillar2AccountSchema.parse({})).toEqual({});
    expect(
      updatePillar2AccountSchema.parse({ annualBvgContribution: 896_000, isVestedBenefits: true }),
    ).toEqual({ annualBvgContribution: 896_000, isVestedBenefits: true });
  });
});

describe('createPillar3aAccountSchema', () => {
  const valid = { providerName: 'VIAC', accountType: 'BANK', currentBalance: 3_000_000 };

  it('accepts a valid BANK or INSURANCE account', () => {
    expect(createPillar3aAccountSchema.safeParse(valid).success).toBe(true);
    expect(
      createPillar3aAccountSchema.safeParse({ ...valid, accountType: 'INSURANCE' }).success,
    ).toBe(true);
    expect(
      createPillar3aAccountSchema.safeParse({ ...valid, accountType: 'FINTECH' }).success,
    ).toBe(false);
  });

  it('rejects an empty provider name and a missing balance', () => {
    expect(createPillar3aAccountSchema.safeParse({ ...valid, providerName: '' }).success).toBe(
      false,
    );
    expect(
      createPillar3aAccountSchema.safeParse({ providerName: 'VIAC', accountType: 'BANK' }).success,
    ).toBe(false);
  });

  it('allows a negative return down to -50% but not beyond', () => {
    expect(
      createPillar3aAccountSchema.safeParse({ ...valid, interestRateOrReturn: -50 }).success,
    ).toBe(true);
    expect(
      createPillar3aAccountSchema.safeParse({ ...valid, interestRateOrReturn: -50.1 }).success,
    ).toBe(false);
    expect(
      createPillar3aAccountSchema.safeParse({ ...valid, interestRateOrReturn: 100 }).success,
    ).toBe(true);
    expect(
      createPillar3aAccountSchema.safeParse({ ...valid, interestRateOrReturn: 101 }).success,
    ).toBe(false);
  });
});

describe('upsertTaxSituationSchema', () => {
  it('accepts a minimal payload and defaults churchTax to false', () => {
    expect(upsertTaxSituationSchema.parse({ taxableIncome: 8_000_000 })).toEqual({
      taxableIncome: 8_000_000,
      churchTax: false,
    });
  });

  it('rejects negative income or wealth', () => {
    expect(upsertTaxSituationSchema.safeParse({ taxableIncome: -1 }).success).toBe(false);
    expect(
      upsertTaxSituationSchema.safeParse({ taxableIncome: 8_000_000, taxableWealth: -1 }).success,
    ).toBe(false);
  });
});
