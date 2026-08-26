import { describe, expect, it } from 'vitest';
import {
  DEMO_DOCUMENT,
  DEMO_FINANCIAL_PROFILE,
  DEMO_PILLAR2,
  DEMO_PILLAR3A,
  DEMO_TAX,
  DEMO_USER_PATCH,
  demoSubscriptionData,
} from '../../src/scripts/demo-fixtures.js';
import {
  createFinancialProfileSchema,
  createPillar2AccountSchema,
  createPillar3aAccountSchema,
  upsertTaxSituationSchema,
} from '../../src/modules/financial-profile/financial-profile.schema.js';
import { updateUserSchema } from '../../src/modules/user/user.schema.js';

describe('demo fixtures', () => {
  it('each payload passes the zod schema of the real endpoint', () => {
    expect(() => updateUserSchema.parse(DEMO_USER_PATCH)).not.toThrow();
    expect(() => createFinancialProfileSchema.parse(DEMO_FINANCIAL_PROFILE)).not.toThrow();
    expect(() => createPillar2AccountSchema.parse(DEMO_PILLAR2)).not.toThrow();
    expect(() => createPillar3aAccountSchema.parse(DEMO_PILLAR3A)).not.toThrow();
    expect(() => upsertTaxSituationSchema.parse(DEMO_TAX)).not.toThrow();
  });

  it('the profile tells the right story: visible gap and a relevant 3a catch-up', () => {
    // 35 y/o, VD — 3a contribution below the deductible max → the catch-up
    // preview and the recommendations have real substance.
    expect(DEMO_USER_PATCH.canton).toBe('VD');
    expect(DEMO_PILLAR3A.annualContribution).toBeLessThan(725_800); // 2026 max, in centimes
  });

  it('the sample PDF is a readable fictitious statement (not a blank page)', () => {
    const bytes = DEMO_DOCUMENT.bytes();
    const raw = new TextDecoder('latin1').decode(bytes);
    expect(raw.slice(0, 5)).toBe('%PDF-');
    // Real text content: Tj operators + correct xref table.
    expect(raw).toContain(' Tj');
    expect(raw).toContain('xref');
    expect(raw).toContain('startxref');
    // Explicit "fictitious" markers (never a real institution).
    expect(raw).toContain('Banque Exemple SA');
    expect(raw).toContain('monstration'); // tail of the French word for "demonstration" — its accented letter is octal-escaped in the PDF
    // Consistency with the demo profile: balance 24'000, interest 0.8 %.
    expect(raw).toContain("24'000.00");
    expect(raw).toContain('0.8');
    expect(bytes.length).toBeGreaterThan(1000);
    expect(DEMO_DOCUMENT.mimeType).toBe('application/pdf');
    expect(DEMO_DOCUMENT.type).toBe('PILLAR3A_STATEMENT');
  });

  it('the demo subscription is PROMOTIONAL and expires in ~400 days', () => {
    const now = new Date('2026-08-26T00:00:00Z');
    const sub = demoSubscriptionData(now);
    expect(sub.store).toBe('PROMOTIONAL');
    expect(sub.environment).toBe('PRODUCTION');
    const days = (sub.expiresAt.getTime() - now.getTime()) / (24 * 60 * 60 * 1000);
    expect(days).toBeCloseTo(400, 0);
    expect(sub.lastEventAt).toEqual(now);
  });
});
