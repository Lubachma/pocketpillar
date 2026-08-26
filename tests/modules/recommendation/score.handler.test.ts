import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { FastifyReply, FastifyRequest } from 'fastify';

// Minimal env so importing src/config (via the handler chain) does not exit.
vi.hoisted(() => {
  process.env.DATABASE_URL = 'postgresql://localhost:5432/test';
  process.env.REDIS_URL = 'redis://localhost:6379';
  process.env.SUPABASE_URL = 'https://test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
});

import { getScoreHandler } from '../../../src/modules/recommendation/score.handler.js';
import { SWISS_PENSION } from '../../../src/lib/constants/swiss-pension.js';

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

interface UserRow {
  canton: string | null;
  birthYear: number | null;
  financialProfile: { grossAnnualIncome: number } | null;
  pillar2Accounts: Array<{ currentCapital: number; annualBvgContribution: number | null }>;
  pillar3aAccounts: Array<{ currentBalance: number; annualContribution: number | null }>;
}

function createRequest(user: UserRow | null, locale = 'fr') {
  return {
    userId: 'user-local-id',
    locale,
    server: {
      prisma: { user: { findUnique: vi.fn().mockResolvedValue(user) } },
    },
  } as unknown as FastifyRequest;
}

const fullProfile: UserRow = {
  canton: 'VD',
  birthYear: SWISS_PENSION.CURRENT_YEAR - 64,
  financialProfile: { grossAnnualIncome: 9_500_000 },
  pillar2Accounts: [{ currentCapital: 12_000_000, annualBvgContribution: 700_000 }],
  pillar3aAccounts: [{ currentBalance: 4_800_000, annualContribution: 725_800 }],
};

describe('getScoreHandler (GET /score)', () => {
  beforeEach(() => vi.clearAllMocks());

  it.each([
    ['user not found', null],
    ['missing financial profile', { ...fullProfile, financialProfile: null }],
    ['missing canton', { ...fullProfile, canton: null }],
    ['missing birth year', { ...fullProfile, birthYear: null }],
  ])('422 when %s', async (_label, user) => {
    const reply = createReply();
    await getScoreHandler(createRequest(user), reply);

    expect(reply.statusCode).toBe(422);
    expect(reply.payload).toEqual({
      error: 'Profil incomplet. Renseignez canton, année de naissance et profil financier.',
    });
  });

  it('200: score consistent with the retirement calculator (hand-computed case)', async () => {
    const reply = createReply();
    await getScoreHandler(createRequest(fullProfile), reply);

    expect(reply.statusCode).toBe(200);
    const body = reply.payload as {
      score: number;
      breakdown: Array<{ criterion: string; points: number; maxPoints: number }>;
      benchmark: {
        bracket: { minAge: number; maxAge: number } | null;
        averagePillar3aBalance: number;
        userPillar3aBalance: number;
        userReplacementRate: number;
        userBvgCapital: number;
      };
      generatedAt: string;
    };

    // Projection at 64 (1 year): LPP 12'850'000 × 6.8 % = 873'800. AVS estimated
    // by income (batch 4): 95'000 ≥ 90'720 → ratio 1, years projected to
    // retirement min(65−20, 44) = 44 → max pension 30'240 (×12) → ×13/12 from 2026
    // (13th AVS pension) = 32'760. Total 3'276'000 + 873'800 = 4'149'800 /
    // 9'500'000 → rate 43.68 % → 21 pts; 3a 48'000/160'000 →
    // ratio 0.3 → 15 + 4 = 19 pts; age 64 → 15 pts. Total 55.
    expect(body.benchmark.userReplacementRate).toBe(43.68);
    expect(body.breakdown.map((b) => [b.criterion, b.points, b.maxPoints])).toEqual([
      ['REPLACEMENT_RATE', 21, 40],
      ['PILLAR_3A', 19, 30],
      ['AGE_AWARENESS', 15, 30],
    ]);
    expect(body.score).toBe(55);
    expect(body.benchmark.bracket).toEqual({ minAge: 60, maxAge: 65 });
    expect(body.benchmark.averagePillar3aBalance).toBe(16_000_000);
    expect(body.benchmark.userPillar3aBalance).toBe(4_800_000);
    expect(body.benchmark.userBvgCapital).toBe(12_000_000);
    expect(body.generatedAt).toEqual(expect.any(String));
  });

  it('aggregates multiple LPP and 3a accounts (sums)', async () => {
    const user: UserRow = {
      ...fullProfile,
      pillar2Accounts: [
        { currentCapital: 10_000_000, annualBvgContribution: 500_000 },
        { currentCapital: 2_000_000, annualBvgContribution: null }, // null → 0
      ],
      pillar3aAccounts: [
        { currentBalance: 4_000_000, annualContribution: 700_000 },
        { currentBalance: 800_000, annualContribution: null },
      ],
    };
    const reply = createReply();
    await getScoreHandler(createRequest(user), reply);

    const body = reply.payload as {
      benchmark: { userPillar3aBalance: number; userBvgCapital: number };
    };
    expect(body.benchmark.userPillar3aBalance).toBe(4_800_000);
    expect(body.benchmark.userBvgCapital).toBe(12_000_000);
  });

  it('no 3a account: 3a criterion at 0 point', async () => {
    const reply = createReply();
    await getScoreHandler(createRequest({ ...fullProfile, pillar3aAccounts: [] }), reply);

    const body = reply.payload as { breakdown: Array<{ criterion: string; points: number }> };
    expect(body.breakdown.find((b) => b.criterion === 'PILLAR_3A')?.points).toBe(0);
  });

  it('labels localized per request.locale (de)', async () => {
    const reply = createReply();
    await getScoreHandler(createRequest(fullProfile, 'de'), reply);

    const body = reply.payload as { breakdown: Array<{ label: string }> };
    expect(body.breakdown.map((b) => b.label)).toEqual([
      'Ersatzquote',
      'Säule-3a-Ersparnis',
      'Pensionshorizont',
    ]);
  });
});
