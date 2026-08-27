import { describe, it, expect, vi } from 'vitest';
import type { FastifyReply, FastifyRequest } from 'fastify';

// Minimal env so importing src/config (via the handler) does not exit the process.
vi.hoisted(() => {
  process.env.DATABASE_URL = 'postgresql://localhost:5432/test';
  process.env.REDIS_URL = 'redis://localhost:6379';
  process.env.SUPABASE_URL = 'https://test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
});

import { propertyPurchaseHandler } from '../../../src/modules/calculator/calculator.handler.js';
import { divorceImpactHandler } from '../../../src/modules/calculator/calculator.handler.js';
import { retirementProjectionHandler } from '../../../src/modules/calculator/calculator.handler.js';
import { coupleSimulationHandler } from '../../../src/modules/calculator/calculator.handler.js';

function createReply() {
  const reply = {
    statusCode: 200,
    payload: undefined as unknown,
    status(code: number) {
      reply.statusCode = code;
      return reply;
    },
    send(payload?: unknown) {
      reply.payload = payload;
      return reply;
    },
  };
  return reply as unknown as FastifyReply & { statusCode: number; payload: unknown };
}

function createRequest(body: unknown) {
  return { body, locale: 'fr' } as unknown as FastifyRequest<{ Body: unknown }>;
}

const validBody = {
  age: 45,
  retirementAge: 65,
  currentBvgCapital: 20_000_000,
  withdrawalAmount: 5_000_000,
  annualContribution: 800_000,
};

describe('propertyPurchaseHandler', () => {
  it('returns the impact projection for a valid request', async () => {
    const reply = createReply();

    await propertyPurchaseHandler(createRequest(validBody), reply);

    expect(reply.statusCode).toBe(200);
    expect(reply.payload).toMatchObject({ effectiveWithdrawal: 5_000_000 });
  });

  it("rejects a withdrawal below the CHF 20'000 EPL minimum with a localized 400", async () => {
    const reply = createReply();

    await propertyPurchaseHandler(
      createRequest({ ...validBody, withdrawalAmount: 1_000_000 }),
      reply,
    );

    expect(reply.statusCode).toBe(400);
    expect(reply.payload).toEqual({
      error: "Le retrait minimum pour l'achat immobilier est de CHF 20'000.",
    });
  });

  it('rejects retirementAge <= age at the schema level (400 validation)', async () => {
    const reply = createReply();

    await propertyPurchaseHandler(
      createRequest({ ...validBody, age: 65, retirementAge: 58 }),
      reply,
    );

    expect(reply.statusCode).toBe(400);
    expect(reply.payload).toMatchObject({ error: 'Erreur de validation' });
  });
});

describe('retirementProjectionHandler', () => {
  const validRetirement = {
    currentAge: 40,
    grossAnnualIncome: 9_500_000,
    currentPillar2Capital: 15_000_000,
    annualPillar2Contribution: 800_000,
  };

  it('estimates the AVS pension by income when estimatedAvsPension is omitted', async () => {
    // Simplified scale 44: income 95'000 ≥ 90'720 → ratio 1; years
    // projected to retirement min(65 − 20, 44) = 44 → max pension 30'240
    // (×12) → annualized ×13/12 (13th pension, retirement ≥ 2026) = CHF 32'760.
    const reply = createReply();

    await retirementProjectionHandler(createRequest(validRetirement), reply);

    expect(reply.statusCode).toBe(200);
    expect(reply.payload).toMatchObject({ estimatedAnnualAvsPension: 3_276_000 });
  });

  it('annualizes the caller-provided AVS pension over 13 monthly payments from 2026', async () => {
    // 25'000 (×12) × 13/12 = CHF 27'083.33 — 13th AVS pension (first payment
    // December 2026, retirement at 65 ≥ 2026).
    const reply = createReply();

    await retirementProjectionHandler(
      createRequest({ ...validRetirement, estimatedAvsPension: 2_500_000 }),
      reply,
    );

    expect(reply.statusCode).toBe(200);
    expect(reply.payload).toMatchObject({ estimatedAnnualAvsPension: 2_708_333 });
  });

  it('rejects a negative AVS pension (400 validation)', async () => {
    const reply = createReply();

    await retirementProjectionHandler(
      createRequest({ ...validRetirement, estimatedAvsPension: -1 }),
      reply,
    );

    expect(reply.statusCode).toBe(400);
    expect(reply.payload).toMatchObject({ error: 'Erreur de validation' });
  });
});

describe('divorceImpactHandler', () => {
  const validDivorce = {
    age: 50,
    bvgCapitalAtMarriage: 5_000_000,
    bvgCapitalNow: 20_000_000,
    spouseBvgCapitalAtMarriage: 1_000_000,
    spouseBvgCapitalNow: 10_000_000,
    yearsMarried: 15,
    annualContribution: 800_000,
  };

  it('returns 400 when a marriage capital exceeds the current capital (inversion)', async () => {
    const own = createReply();
    await divorceImpactHandler(
      createRequest({ ...validDivorce, bvgCapitalAtMarriage: 25_000_000 }),
      own,
    );
    expect(own.statusCode).toBe(400);
    expect(own.payload).toMatchObject({ error: 'Erreur de validation' });

    const spouse = createReply();
    await divorceImpactHandler(
      createRequest({ ...validDivorce, spouseBvgCapitalAtMarriage: 15_000_000 }),
      spouse,
    );
    expect(spouse.statusCode).toBe(400);
    expect(spouse.payload).toMatchObject({ error: 'Erreur de validation' });
  });

  it('accepts a valid payload (200)', async () => {
    const reply = createReply();

    await divorceImpactHandler(createRequest(validDivorce), reply);

    expect(reply.statusCode).toBe(200);
  });
});

describe('coupleSimulationHandler', () => {
  const spouse = {
    currentAge: 40,
    grossAnnualIncome: 9_500_000,
    currentPillar2Capital: 15_000_000,
    annualPillar2Contribution: 800_000,
  };
  const validCouple = {
    canton: 'ZH',
    maritalStatus: 'MARRIED',
    person1: spouse,
    person2: { ...spouse, currentAge: 38 },
  };

  it('returns the composed result for a valid request (AVS estimated per spouse)', async () => {
    // Simplified scale 44, income 95'000 ≥ 90'720: years projected to
    // retirement min(65 − 20, 44) = 44 for both spouses (the projection
    // targets the pension paid AT retirement, not the years already contributed) →
    // max pension CHF 30'240 (×12) each → ×13/12 from 2026 (13th pension)
    // = CHF 32'760.
    const reply = createReply();

    await coupleSimulationHandler(createRequest(validCouple), reply);

    expect(reply.statusCode).toBe(200);
    const payload = reply.payload as {
      person1: { estimatedAnnualAvsPension: number };
      person2: { estimatedAnnualAvsPension: number };
      combinedAvsAnnual: number;
      avsCapApplied: boolean;
      avsCapAnnual: number;
      taxEstimate: { cheaperStatus: string };
      withdrawalPlan: { steps: unknown[] };
    };
    expect(payload.person1.estimatedAnnualAvsPension).toBe(3_276_000);
    expect(payload.person2.estimatedAnnualAvsPension).toBe(3_276_000);
    // 65'520 combined > 49'140 → 150 % couple cap applied (married) —
    // monthly cap 3'780 paid 13 times from 2026 (45'360 × 13/12).
    expect(payload.combinedAvsAnnual).toBe(4_914_000);
    expect(payload.avsCapApplied).toBe(true);
    expect(payload.avsCapAnnual).toBe(4_914_000);
    expect(payload.taxEstimate.cheaperStatus).toBe('CONCUBINAGE');
    expect(payload.withdrawalPlan.steps.length).toBeGreaterThan(0);
  });

  it("propagates the couple's residence into each spouse projection (consistent 3a withdrawal tax)", async () => {
    // Review 08.2026: a person-level canton used to price the per-person 3a
    // withdrawal tax on the SINGLE schedule while the couple plan used the
    // MARRIED one — two different taxes for the same withdrawal in one
    // payload. The handler now overrides person-level residence with the
    // couple's (ZH married anchor: CHF 500'000 → 31'576).
    const reply = createReply();
    const with3a = {
      currentPillar3aBalance: 50_000_000,
      annualPillar3aContribution: 0,
      pillar3aReturnRate: 0,
    };

    await coupleSimulationHandler(
      createRequest({
        ...validCouple,
        person1: { ...spouse, ...with3a },
        // Person-level canton/maritalStatus must be IGNORED (couple wins).
        person2: {
          ...spouse,
          ...with3a,
          currentAge: 38,
          canton: 'VD',
          maritalStatus: 'SINGLE',
        },
      }),
      reply,
    );

    expect(reply.statusCode).toBe(200);
    const payload = reply.payload as {
      person1: { pillar3aWithdrawalTax?: number };
      person2: { pillar3aWithdrawalTax?: number };
    };
    expect(payload.person1.pillar3aWithdrawalTax).toBe(3_157_600);
    expect(payload.person2.pillar3aWithdrawalTax).toBe(3_157_600);
  });

  it('applies the 150% AVS cap for a married couple at the maximum', async () => {
    const reply = createReply();

    await coupleSimulationHandler(
      createRequest({
        ...validCouple,
        person1: { ...spouse, estimatedAvsPension: 2_940_000 },
        person2: { ...spouse, currentAge: 38, estimatedAvsPension: 2_940_000 },
      }),
      reply,
    );

    expect(reply.statusCode).toBe(200);
    expect(reply.payload).toMatchObject({
      combinedAvsAnnualRaw: 6_370_000,
      combinedAvsAnnual: 4_914_000,
      avsCapApplied: true,
    });
  });

  it('rejects an invalid marital status or spouse payload (400 validation)', async () => {
    const badStatus = createReply();
    await coupleSimulationHandler(
      createRequest({ ...validCouple, maritalStatus: 'SINGLE' }),
      badStatus,
    );
    expect(badStatus.statusCode).toBe(400);
    expect(badStatus.payload).toMatchObject({ error: 'Erreur de validation' });

    const badSpouse = createReply();
    await coupleSimulationHandler(
      createRequest({ ...validCouple, person2: { ...spouse, currentAge: 70 } }),
      badSpouse,
    );
    expect(badSpouse.statusCode).toBe(400);
    expect(badSpouse.payload).toMatchObject({ error: 'Erreur de validation' });
  });
});
