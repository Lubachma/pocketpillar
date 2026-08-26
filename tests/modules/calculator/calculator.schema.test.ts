import { describe, it, expect } from 'vitest';
import {
  lppGapRequestSchema,
  taxSavingsRequestSchema,
  pillar3aCatchupRequestSchema,
  propertyPurchaseRequestSchema,
  divorceImpactRequestSchema,
  staggeredWithdrawalRequestSchema,
  retirementProjectionRequestSchema,
  coupleSimulationRequestSchema,
} from '../../../src/modules/calculator/calculator.schema.js';
import { SWISS_PENSION } from '../../../src/lib/constants/swiss-pension.js';

// Valid minimal payloads per endpoint; amounts in centimes.
const validLppGap = {
  grossAnnualIncome: 8_000_000,
  age: 40,
  currentBvgCapital: 5_000_000,
  actualAnnualContribution: 700_000,
};
const validTaxSavings = { canton: 'ZH', taxableIncome: 10_000_000, contribution: 725_800 };
const validCatchup = { taxableIncome: 10_000_000 };
const validProperty = {
  age: 45,
  currentBvgCapital: 20_000_000,
  withdrawalAmount: 5_000_000,
  annualContribution: 800_000,
};
const validDivorce = {
  age: 50,
  bvgCapitalAtMarriage: 5_000_000,
  bvgCapitalNow: 20_000_000,
  spouseBvgCapitalAtMarriage: 1_000_000,
  spouseBvgCapitalNow: 10_000_000,
  yearsMarried: 15,
  annualContribution: 800_000,
};
const validStaggered = { canton: 'ZH', totalPillar3aBalance: 50_000_000, currentAge: 60 };
const validRetirement = {
  currentAge: 40,
  grossAnnualIncome: 9_500_000,
  currentPillar2Capital: 15_000_000,
  annualPillar2Contribution: 800_000,
};

describe('lppGapRequestSchema', () => {
  it('accepts a valid payload and applies the defaults (retirement 65, conversion 6.8)', () => {
    const parsed = lppGapRequestSchema.parse(validLppGap);
    expect(parsed).toEqual({ ...validLppGap, retirementAge: 65, conversionRate: 6.8 });
  });

  it('rejects zero or negative grossAnnualIncome (positive, not nonnegative)', () => {
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, grossAnnualIncome: 0 }).success).toBe(
      false,
    );
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, grossAnnualIncome: -1 }).success).toBe(
      false,
    );
  });

  it('enforces the age bounds 25-70 and retirementAge bounds 58-70', () => {
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, age: 24 }).success).toBe(false);
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, age: 25 }).success).toBe(true);
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, age: 71 }).success).toBe(false);
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, retirementAge: 57 }).success).toBe(
      false,
    );
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, retirementAge: 58 }).success).toBe(true);
  });

  it('requires retirementAge to be strictly greater than age', () => {
    // retirementAge <= age would project over zero or negative years.
    expect(
      lppGapRequestSchema.safeParse({ ...validLppGap, age: 58, retirementAge: 58 }).success,
    ).toBe(false);
    expect(
      lppGapRequestSchema.safeParse({ ...validLppGap, age: 70, retirementAge: 58 }).success,
    ).toBe(false);
    expect(
      lppGapRequestSchema.safeParse({ ...validLppGap, age: 69, retirementAge: 70 }).success,
    ).toBe(true);
    // With the default retirementAge (65), age 70 is no longer acceptable.
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, age: 70 }).success).toBe(false);
  });

  it('rejects non-integer, NaN, Infinity and string amounts', () => {
    expect(
      lppGapRequestSchema.safeParse({ ...validLppGap, grossAnnualIncome: 8_000_000.5 }).success,
    ).toBe(false);
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, grossAnnualIncome: NaN }).success).toBe(
      false,
    );
    expect(
      lppGapRequestSchema.safeParse({ ...validLppGap, grossAnnualIncome: Infinity }).success,
    ).toBe(false);
    expect(
      lppGapRequestSchema.safeParse({ ...validLppGap, grossAnnualIncome: '80000' }).success,
    ).toBe(false);
  });

  it('rejects missing required fields and negative capitals', () => {
    expect(lppGapRequestSchema.safeParse({ age: 40 }).success).toBe(false);
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, currentBvgCapital: -1 }).success).toBe(
      false,
    );
    // Zero capital/contribution is valid (nonnegative).
    expect(
      lppGapRequestSchema.safeParse({
        ...validLppGap,
        currentBvgCapital: 0,
        actualAnnualContribution: 0,
      }).success,
    ).toBe(true);
  });

  it('accepts conversionRate 0 and 100 but rejects 100.01', () => {
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, conversionRate: 0 }).success).toBe(true);
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, conversionRate: 100 }).success).toBe(
      true,
    );
    expect(lppGapRequestSchema.safeParse({ ...validLppGap, conversionRate: 100.01 }).success).toBe(
      false,
    );
  });
});

describe('taxSavingsRequestSchema', () => {
  it('accepts a valid payload and applies the defaults', () => {
    const parsed = taxSavingsRequestSchema.parse(validTaxSavings);
    expect(parsed).toEqual({
      ...validTaxSavings,
      maritalStatus: 'SINGLE',
      churchTax: false,
      hasSecondPillar: true,
    });
  });

  it('accepts all 26 Swiss cantons and rejects unknown or lowercase codes', () => {
    const cantons = [
      'ZH',
      'BE',
      'LU',
      'UR',
      'SZ',
      'OW',
      'NW',
      'GL',
      'ZG',
      'FR',
      'SO',
      'BS',
      'BL',
      'SH',
      'AR',
      'AI',
      'SG',
      'GR',
      'AG',
      'TG',
      'TI',
      'VD',
      'VS',
      'NE',
      'GE',
      'JU',
    ];
    for (const canton of cantons) {
      expect(taxSavingsRequestSchema.safeParse({ ...validTaxSavings, canton }).success).toBe(true);
    }
    expect(taxSavingsRequestSchema.safeParse({ ...validTaxSavings, canton: 'XX' }).success).toBe(
      false,
    );
    expect(taxSavingsRequestSchema.safeParse({ ...validTaxSavings, canton: 'zh' }).success).toBe(
      false,
    );
  });

  it('rejects zero contribution and zero/negative taxable income', () => {
    expect(taxSavingsRequestSchema.safeParse({ ...validTaxSavings, contribution: 0 }).success).toBe(
      false,
    );
    expect(
      taxSavingsRequestSchema.safeParse({ ...validTaxSavings, taxableIncome: 0 }).success,
    ).toBe(false);
    expect(
      taxSavingsRequestSchema.safeParse({ ...validTaxSavings, taxableIncome: -100 }).success,
    ).toBe(false);
  });

  it('accepts all five marital statuses', () => {
    for (const maritalStatus of [
      'SINGLE',
      'MARRIED',
      'REGISTERED_PARTNERSHIP',
      'DIVORCED',
      'WIDOWED',
    ]) {
      expect(taxSavingsRequestSchema.safeParse({ ...validTaxSavings, maritalStatus }).success).toBe(
        true,
      );
    }
    expect(
      taxSavingsRequestSchema.safeParse({ ...validTaxSavings, maritalStatus: 'single' }).success,
    ).toBe(false);
  });

  it('accepts an optional municipality but rejects an empty or overlong one', () => {
    expect(
      taxSavingsRequestSchema.safeParse({ ...validTaxSavings, municipality: 'Zürich' }).success,
    ).toBe(true);
    // Absent stays absent (no default injected).
    expect(taxSavingsRequestSchema.parse(validTaxSavings).municipality).toBeUndefined();
    expect(
      taxSavingsRequestSchema.safeParse({ ...validTaxSavings, municipality: '' }).success,
    ).toBe(false);
    expect(
      taxSavingsRequestSchema.safeParse({ ...validTaxSavings, municipality: 'x'.repeat(101) })
        .success,
    ).toBe(false);
    expect(
      taxSavingsRequestSchema.safeParse({ ...validTaxSavings, municipality: 123 }).success,
    ).toBe(false);
  });
});

describe('pillar3aCatchupRequestSchema', () => {
  it('applies the defaults (current year, 1 retro year, empty contributions, with 2nd pillar)', () => {
    const parsed = pillar3aCatchupRequestSchema.parse(validCatchup);
    expect(parsed).toEqual({
      taxableIncome: 10_000_000,
      currentYear: SWISS_PENSION.CURRENT_YEAR,
      yearsSinceFirstEligible: 1,
      pastContributions: {},
      hasSecondPillar: true,
      maritalStatus: 'SINGLE',
    });
  });

  it('bounds yearsSinceFirstEligible to 0-10', () => {
    expect(
      pillar3aCatchupRequestSchema.safeParse({ ...validCatchup, yearsSinceFirstEligible: -1 })
        .success,
    ).toBe(false);
    expect(
      pillar3aCatchupRequestSchema.safeParse({ ...validCatchup, yearsSinceFirstEligible: 0 })
        .success,
    ).toBe(true);
    expect(
      pillar3aCatchupRequestSchema.safeParse({ ...validCatchup, yearsSinceFirstEligible: 10 })
        .success,
    ).toBe(true);
    expect(
      pillar3aCatchupRequestSchema.safeParse({ ...validCatchup, yearsSinceFirstEligible: 11 })
        .success,
    ).toBe(false);
  });

  it('coerces pastContributions record keys to numbers and rejects negative values', () => {
    const parsed = pillar3aCatchupRequestSchema.parse({
      ...validCatchup,
      pastContributions: { '2025': 400_000 },
    });
    expect(parsed.pastContributions).toEqual({ 2025: 400_000 });

    expect(
      pillar3aCatchupRequestSchema.safeParse({
        ...validCatchup,
        pastContributions: { '2025': -1 },
      }).success,
    ).toBe(false);
    expect(
      pillar3aCatchupRequestSchema.safeParse({
        ...validCatchup,
        pastContributions: { '2025': 400_000.5 },
      }).success,
    ).toBe(false);
  });
});

describe('propertyPurchaseRequestSchema', () => {
  it('accepts a valid payload and applies the defaults (interest 1.25%, conversion 6.8%)', () => {
    const parsed = propertyPurchaseRequestSchema.parse(validProperty);
    expect(parsed).toEqual({
      ...validProperty,
      retirementAge: 65,
      interestRate: 1.25,
      conversionRate: 6.8,
    });
    // bvgCapitalAtAge50 stays optional.
    expect(parsed.bvgCapitalAtAge50).toBeUndefined();
  });

  it('bounds age to 25-65 (stricter than the other schemas) and rejects zero withdrawal', () => {
    expect(propertyPurchaseRequestSchema.safeParse({ ...validProperty, age: 24 }).success).toBe(
      false,
    );
    expect(
      propertyPurchaseRequestSchema.safeParse({ ...validProperty, age: 65, retirementAge: 66 })
        .success,
    ).toBe(true);
    // Note: age 66+ is rejected here although lppGap/divorce allow up to 70.
    expect(propertyPurchaseRequestSchema.safeParse({ ...validProperty, age: 66 }).success).toBe(
      false,
    );
    expect(
      propertyPurchaseRequestSchema.safeParse({ ...validProperty, withdrawalAmount: 0 }).success,
    ).toBe(false);
  });

  it('requires retirementAge to be strictly greater than age', () => {
    expect(propertyPurchaseRequestSchema.safeParse({ ...validProperty, age: 65 }).success).toBe(
      false,
    ); // default retirementAge 65 is not > 65
    expect(
      propertyPurchaseRequestSchema.safeParse({ ...validProperty, age: 58, retirementAge: 58 })
        .success,
    ).toBe(false);
    expect(
      propertyPurchaseRequestSchema.safeParse({ ...validProperty, age: 57, retirementAge: 58 })
        .success,
    ).toBe(true);
  });

  it('bounds interestRate to 0-20', () => {
    expect(
      propertyPurchaseRequestSchema.safeParse({ ...validProperty, interestRate: -0.1 }).success,
    ).toBe(false);
    expect(
      propertyPurchaseRequestSchema.safeParse({ ...validProperty, interestRate: 0 }).success,
    ).toBe(true);
    expect(
      propertyPurchaseRequestSchema.safeParse({ ...validProperty, interestRate: 20 }).success,
    ).toBe(true);
    expect(
      propertyPurchaseRequestSchema.safeParse({ ...validProperty, interestRate: 20.1 }).success,
    ).toBe(false);
  });
});

describe('divorceImpactRequestSchema', () => {
  it('accepts a valid payload and applies the defaults', () => {
    const parsed = divorceImpactRequestSchema.parse(validDivorce);
    expect(parsed).toEqual({
      ...validDivorce,
      retirementAge: 65,
      interestRate: 1.25,
      conversionRate: 6.8,
    });
  });

  it('bounds yearsMarried to 0-50', () => {
    expect(
      divorceImpactRequestSchema.safeParse({ ...validDivorce, yearsMarried: -1 }).success,
    ).toBe(false);
    expect(divorceImpactRequestSchema.safeParse({ ...validDivorce, yearsMarried: 0 }).success).toBe(
      true,
    );
    expect(
      divorceImpactRequestSchema.safeParse({ ...validDivorce, yearsMarried: 50 }).success,
    ).toBe(true);
    expect(
      divorceImpactRequestSchema.safeParse({ ...validDivorce, yearsMarried: 51 }).success,
    ).toBe(false);
  });

  it('rejects a missing spouse capital field', () => {
    expect(
      divorceImpactRequestSchema.safeParse({
        age: 50,
        bvgCapitalAtMarriage: 5_000_000,
        bvgCapitalNow: 20_000_000,
        spouseBvgCapitalAtMarriage: 1_000_000,
        // spouseBvgCapitalNow missing
        yearsMarried: 15,
        annualContribution: 800_000,
      }).success,
    ).toBe(false);
  });

  it('rejects a marriage capital above the current capital (negative acquisition)', () => {
    expect(
      divorceImpactRequestSchema.safeParse({
        ...validDivorce,
        bvgCapitalAtMarriage: 25_000_000, // > bvgCapitalNow 20'000'000
      }).success,
    ).toBe(false);
    expect(
      divorceImpactRequestSchema.safeParse({
        ...validDivorce,
        spouseBvgCapitalAtMarriage: 15_000_000, // > spouseBvgCapitalNow 10'000'000
      }).success,
    ).toBe(false);
    // Equality is valid (no capital acquired during the marriage).
    expect(
      divorceImpactRequestSchema.safeParse({
        ...validDivorce,
        bvgCapitalAtMarriage: validDivorce.bvgCapitalNow,
        spouseBvgCapitalAtMarriage: validDivorce.spouseBvgCapitalNow,
      }).success,
    ).toBe(true);
  });

  it('requires retirementAge to be strictly greater than age', () => {
    expect(
      divorceImpactRequestSchema.safeParse({ ...validDivorce, age: 65, retirementAge: 65 }).success,
    ).toBe(false);
    expect(
      divorceImpactRequestSchema.safeParse({ ...validDivorce, age: 70, retirementAge: 65 }).success,
    ).toBe(false);
    expect(
      divorceImpactRequestSchema.safeParse({ ...validDivorce, age: 64, retirementAge: 65 }).success,
    ).toBe(true);
  });
});

describe('staggeredWithdrawalRequestSchema', () => {
  it('accepts a valid payload and applies the defaults', () => {
    const parsed = staggeredWithdrawalRequestSchema.parse(validStaggered);
    expect(parsed).toEqual({
      ...validStaggered,
      numberOfAccounts: 1,
      retirementAge: 65,
      maritalStatus: 'SINGLE',
      pillar2AsCapital: 0,
    });
  });

  it('bounds numberOfAccounts to 1-5', () => {
    expect(
      staggeredWithdrawalRequestSchema.safeParse({ ...validStaggered, numberOfAccounts: 0 })
        .success,
    ).toBe(false);
    expect(
      staggeredWithdrawalRequestSchema.safeParse({ ...validStaggered, numberOfAccounts: 5 })
        .success,
    ).toBe(true);
    expect(
      staggeredWithdrawalRequestSchema.safeParse({ ...validStaggered, numberOfAccounts: 6 })
        .success,
    ).toBe(false);
  });

  it('accepts only SINGLE or MARRIED — REGISTERED_PARTNERSHIP is rejected here', () => {
    // Note: narrower than taxSavingsRequestSchema, which allows all five statuses.
    expect(
      staggeredWithdrawalRequestSchema.safeParse({ ...validStaggered, maritalStatus: 'MARRIED' })
        .success,
    ).toBe(true);
    expect(
      staggeredWithdrawalRequestSchema.safeParse({
        ...validStaggered,
        maritalStatus: 'REGISTERED_PARTNERSHIP',
      }).success,
    ).toBe(false);
  });

  it('accepts a zero 3a balance but rejects a negative one', () => {
    expect(
      staggeredWithdrawalRequestSchema.safeParse({ ...validStaggered, totalPillar3aBalance: 0 })
        .success,
    ).toBe(true);
    expect(
      staggeredWithdrawalRequestSchema.safeParse({ ...validStaggered, totalPillar3aBalance: -1 })
        .success,
    ).toBe(false);
  });

  it('requires retirementAge to be strictly greater than currentAge', () => {
    // Otherwise the lump sum would be dated in the past (negative projection window).
    expect(
      staggeredWithdrawalRequestSchema.safeParse({
        ...validStaggered,
        currentAge: 70,
        retirementAge: 58,
      }).success,
    ).toBe(false);
    expect(
      staggeredWithdrawalRequestSchema.safeParse({
        ...validStaggered,
        currentAge: 65,
        retirementAge: 65,
      }).success,
    ).toBe(false);
    expect(
      staggeredWithdrawalRequestSchema.safeParse({
        ...validStaggered,
        currentAge: 64,
        retirementAge: 65,
      }).success,
    ).toBe(true);
  });

  it('accepts an optional municipality (same rule as tax-savings)', () => {
    expect(
      staggeredWithdrawalRequestSchema.safeParse({ ...validStaggered, municipality: 'Winterthur' })
        .success,
    ).toBe(true);
    expect(
      staggeredWithdrawalRequestSchema.safeParse({ ...validStaggered, municipality: '' }).success,
    ).toBe(false);
  });
});

describe('retirementProjectionRequestSchema', () => {
  it('accepts a minimal payload and applies all defaults', () => {
    const parsed = retirementProjectionRequestSchema.parse(validRetirement);
    expect(parsed).toEqual({
      ...validRetirement,
      retirementAge: 65,
      pillar2InterestRate: 1.25,
      conversionRate: 6.8,
      currentPillar3aBalance: 0,
      annualPillar3aContribution: 0,
      pillar3aReturnRate: 3,
    });
    // No more flat default: the omission is resolved in the handler
    // (income-based estimate, simplified scale 44 — contract §7).
    expect(parsed.estimatedAvsPension).toBeUndefined();
  });

  it('keeps a caller-provided estimatedAvsPension (validation unchanged)', () => {
    const parsed = retirementProjectionRequestSchema.parse({
      ...validRetirement,
      estimatedAvsPension: 2_500_000,
    });
    expect(parsed.estimatedAvsPension).toBe(2_500_000);

    // Always validated: integer ≥ 0.
    expect(
      retirementProjectionRequestSchema.safeParse({ ...validRetirement, estimatedAvsPension: -1 })
        .success,
    ).toBe(false);
    expect(
      retirementProjectionRequestSchema.safeParse({
        ...validRetirement,
        estimatedAvsPension: 2_500_000.5,
      }).success,
    ).toBe(false);
  });

  it('allows currentAge from 18 (younger than the other endpoints)', () => {
    expect(
      retirementProjectionRequestSchema.safeParse({ ...validRetirement, currentAge: 17 }).success,
    ).toBe(false);
    expect(
      retirementProjectionRequestSchema.safeParse({ ...validRetirement, currentAge: 18 }).success,
    ).toBe(true);
  });

  it('allows a negative 3a return down to -20% but not beyond', () => {
    expect(
      retirementProjectionRequestSchema.safeParse({ ...validRetirement, pillar3aReturnRate: -20 })
        .success,
    ).toBe(true);
    expect(
      retirementProjectionRequestSchema.safeParse({ ...validRetirement, pillar3aReturnRate: -20.1 })
        .success,
    ).toBe(false);
    expect(
      retirementProjectionRequestSchema.safeParse({ ...validRetirement, pillar3aReturnRate: 20 })
        .success,
    ).toBe(true);
    expect(
      retirementProjectionRequestSchema.safeParse({ ...validRetirement, pillar3aReturnRate: 21 })
        .success,
    ).toBe(false);
  });

  it('rejects a missing grossAnnualIncome', () => {
    expect(
      retirementProjectionRequestSchema.safeParse({
        currentAge: 40,
        // grossAnnualIncome missing
        currentPillar2Capital: 15_000_000,
        annualPillar2Contribution: 800_000,
      }).success,
    ).toBe(false);
  });

  it('requires retirementAge to be strictly greater than currentAge', () => {
    expect(
      retirementProjectionRequestSchema.safeParse({
        ...validRetirement,
        currentAge: 65,
        retirementAge: 65,
      }).success,
    ).toBe(false);
    expect(
      retirementProjectionRequestSchema.safeParse({
        ...validRetirement,
        currentAge: 70,
        retirementAge: 58,
      }).success,
    ).toBe(false);
    expect(
      retirementProjectionRequestSchema.safeParse({
        ...validRetirement,
        currentAge: 64,
        retirementAge: 65,
      }).success,
    ).toBe(true);
  });
});

describe('coupleSimulationRequestSchema', () => {
  const validCouple = {
    canton: 'ZH',
    maritalStatus: 'MARRIED',
    person1: validRetirement,
    person2: { ...validRetirement, currentAge: 38 },
  };

  it('accepts a valid payload and applies the per-spouse retirement defaults', () => {
    const parsed = coupleSimulationRequestSchema.parse(validCouple);

    expect(parsed.canton).toBe('ZH');
    expect(parsed.maritalStatus).toBe('MARRIED');
    // Each spouse is a full retirement-projection input (defaults included).
    expect(parsed.person1).toEqual({
      ...validRetirement,
      retirementAge: 65,
      pillar2InterestRate: 1.25,
      conversionRate: 6.8,
      currentPillar3aBalance: 0,
      annualPillar3aContribution: 0,
      pillar3aReturnRate: 3,
    });
    expect(parsed.person1.estimatedAvsPension).toBeUndefined();
    expect(parsed.person2.currentAge).toBe(38);
  });

  it('accepts MARRIED, REGISTERED_PARTNERSHIP and CONCUBINAGE only', () => {
    for (const maritalStatus of ['MARRIED', 'REGISTERED_PARTNERSHIP', 'CONCUBINAGE']) {
      expect(
        coupleSimulationRequestSchema.safeParse({ ...validCouple, maritalStatus }).success,
      ).toBe(true);
    }
    // SINGLE / DIVORCED / WIDOWED are meaningless for a couple simulation.
    for (const maritalStatus of ['SINGLE', 'DIVORCED', 'WIDOWED', 'married']) {
      expect(
        coupleSimulationRequestSchema.safeParse({ ...validCouple, maritalStatus }).success,
      ).toBe(false);
    }
  });

  it('applies the per-spouse refine: retirementAge must exceed each spouse age', () => {
    expect(
      coupleSimulationRequestSchema.safeParse({
        ...validCouple,
        person2: { ...validRetirement, currentAge: 65 },
      }).success,
    ).toBe(false); // default retirementAge 65 is not > 65
    expect(
      coupleSimulationRequestSchema.safeParse({
        ...validCouple,
        person2: { ...validRetirement, currentAge: 64, retirementAge: 65 },
      }).success,
    ).toBe(true);
  });

  it('rejects a missing spouse or an unknown canton', () => {
    expect(
      coupleSimulationRequestSchema.safeParse({
        canton: validCouple.canton,
        maritalStatus: validCouple.maritalStatus,
        person1: validCouple.person1,
        // person2 missing
      }).success,
    ).toBe(false);
    expect(coupleSimulationRequestSchema.safeParse({ ...validCouple, canton: 'XX' }).success).toBe(
      false,
    );
  });

  it('accepts an optional municipality for the couple', () => {
    const parsed = coupleSimulationRequestSchema.parse({ ...validCouple, municipality: 'Zürich' });
    expect(parsed.municipality).toBe('Zürich');

    expect(coupleSimulationRequestSchema.parse(validCouple).municipality).toBeUndefined();
    expect(
      coupleSimulationRequestSchema.safeParse({ ...validCouple, municipality: '' }).success,
    ).toBe(false);
  });
});
