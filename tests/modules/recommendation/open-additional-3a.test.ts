import { describe, it, expect } from 'vitest';
import { openAdditional3aRule } from '../../../src/modules/recommendation/rules/open-additional-3a.js';
import { calculateWithdrawalTax } from '../../../src/modules/calculator/staggered-withdrawal.js';
import type { RecommendationInput } from '../../../src/modules/recommendation/recommendation.types.js';

/**
 * Multi-account 3a strategy (batch 11). All amounts in centimes.
 *
 * Reference values (computed via `calculateWithdrawalTax`, official FTA
 * (Federal Tax Administration) 2026 sampled tables — federal art. 38 included):
 * - Case 1 account (ZH, SINGLE, CHF 100'000, 25 years): projected balance at 3 %/yr =
 *   CHF 209'377.79; single-withdrawal tax = CHF 11'789.94; staggered over
 *   2 years = CHF 10'200.04; saving = CHF 1'589.90 (158'990 centimes).
 * - Case 2 accounts (ZH, MARRIED, CHF 80'000, 20 years): projected balance =
 *   CHF 144'488.90; single-withdrawal tax = CHF 7'186.87; saving over
 *   3 years = CHF 888.77 (88'877 centimes).
 */
const account = (currentBalance: number) => ({
  providerName: 'Banque Test',
  accountType: 'BANK' as const,
  currentBalance,
  annualContribution: 700_000,
  interestRateOrReturn: 2.5,
});

const baseInput: RecommendationInput = {
  locale: 'fr',
  canton: 'ZH',
  birthYear: 1986,
  currentAge: 40,
  retirementAge: 65,
  employmentStatus: 'EMPLOYED',
  maritalStatus: 'SINGLE',
  numberOfChildren: 0,
  grossAnnualIncome: 9_500_000,
  pillar2Accounts: [],
  pillar3aAccounts: [account(10_000_000)], // CHF 100'000
  taxableIncome: 9_000_000,
  churchTax: false,
  hasSecondPillar: true,
  availableProducts: [],
};

describe('openAdditional3aRule — trigger', () => {
  it('1 account with a high balance → recommendation with a quantified impact', () => {
    const rec = openAdditional3aRule(baseInput);

    expect(rec).not.toBeNull();
    expect(rec!.type).toBe('OPEN_ADDITIONAL_3A');
    expect(rec!.priority).toBe('MEDIUM');
    expect(rec!.estimatedAnnualImpact).toBe(0);

    // Impact recomputed independently: projected balance 100'000 × 1.03^25,
    // single-withdrawal tax vs staggered over 2 years (= current accounts + 1).
    const projected = Math.round(10_000_000 * Math.pow(1.03, 25));
    const half = Math.round(projected / 2);
    const expectedSaving =
      calculateWithdrawalTax(projected, 'ZH', 'SINGLE') -
      (calculateWithdrawalTax(half, 'ZH', 'SINGLE') +
        calculateWithdrawalTax(projected - half, 'ZH', 'SINGLE'));

    expect(expectedSaving).toBe(158_990); // CHF 1'589.90 — reference value
    expect(rec!.estimatedLifetimeImpact).toBe(expectedSaving);
    expect(rec!.details.projectedBalance).toBe(20_937_779);
    expect(rec!.details.targetAccountCount).toBe(2);
    expect(rec!.details.bestStrategy).toBe('stagger_2_years');
  });

  it('2 married accounts → staggered over 3 years (married schedule)', () => {
    const rec = openAdditional3aRule({
      ...baseInput,
      currentAge: 45,
      maritalStatus: 'MARRIED',
      pillar3aAccounts: [account(4_000_000), account(4_000_000)], // CHF 80'000 total
    });

    expect(rec).not.toBeNull();
    expect(rec!.estimatedLifetimeImpact).toBe(88_877); // CHF 888.77 — reference value
    expect(rec!.details.targetAccountCount).toBe(3);
    expect(rec!.details.bestStrategy).toBe('stagger_3_years');
  });

  it('registered partnership = married schedule', () => {
    const input = {
      ...baseInput,
      currentAge: 45,
      pillar3aAccounts: [account(4_000_000), account(4_000_000)],
    };
    const married = openAdditional3aRule({ ...input, maritalStatus: 'MARRIED' });
    const partnership = openAdditional3aRule({
      ...input,
      maritalStatus: 'REGISTERED_PARTNERSHIP',
    });

    expect(partnership!.estimatedLifetimeImpact).toBe(married!.estimatedLifetimeImpact);
  });

  it('uses the real communal multiplier when the municipality is provided', () => {
    // Balance CHF 300'000 → projection CHF 628'133: beyond ~CHF 400'000 the
    // cantonal/communal portion of the ZH capital tables is no longer linear,
    // so the communal multiplier affects the staggering saving
    // (below that, this portion is a flat rate and the saving comes only from
    // the federal level — identical regardless of the municipality).
    const input = { ...baseInput, pillar3aAccounts: [account(30_000_000)] };
    const zurich = openAdditional3aRule({ ...input, municipality: 'Zürich' });
    const kuesnacht = openAdditional3aRule({ ...input, municipality: 'Küsnacht' });

    expect(zurich!.estimatedLifetimeImpact).toBe(1_442_035); // CHF 14'420.35
    expect(kuesnacht!.estimatedLifetimeImpact).toBe(988_827); // CHF 9'888.27
    expect(zurich!.estimatedLifetimeImpact).toBeGreaterThan(kuesnacht!.estimatedLifetimeImpact);
  });

  it('title and description are translated (keys resolved, variables interpolated)', () => {
    const rec = openAdditional3aRule(baseInput)!;

    expect(rec.title).not.toBe('rec.open_additional_3a.title');
    expect(rec.description).not.toContain('{{');
    // Amount formatted via toLocaleString('fr-CH') — separator varies by ICU.
    expect(rec.description).toContain((158_990 / 100).toLocaleString('fr-CH'));
  });
});

describe('openAdditional3aRule — exclusions', () => {
  it('0 accounts → null (OPEN_FIRST_3A takes over)', () => {
    expect(openAdditional3aRule({ ...baseInput, pillar3aAccounts: [] })).toBeNull();
  });

  it('3 accounts or more → null (staggering already possible)', () => {
    const three = [account(4_000_000), account(4_000_000), account(4_000_000)];
    expect(openAdditional3aRule({ ...baseInput, pillar3aAccounts: three })).toBeNull();
  });

  it('retirement in 5 years or less → null', () => {
    expect(openAdditional3aRule({ ...baseInput, currentAge: 60 })).toBeNull(); // 5 years
    expect(openAdditional3aRule({ ...baseInput, currentAge: 62 })).toBeNull(); // 3 years
  });

  it("total balance < CHF 50'000 → null", () => {
    expect(
      openAdditional3aRule({ ...baseInput, pillar3aAccounts: [account(4_999_999)] }),
    ).toBeNull();
  });

  it('balance split across 2 accounts: threshold evaluated on the total', () => {
    const rec = openAdditional3aRule({
      ...baseInput,
      pillar3aAccounts: [account(3_000_000), account(2_500_000)], // CHF 55'000 total
    });
    expect(rec).not.toBeNull();
    expect(rec!.details.totalBalance).toBe(5_500_000);
  });
});
