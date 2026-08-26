import { t } from '../../lib/i18n/index.js';
import type { Locale } from '../../lib/i18n/index.js';

/**
 * Pension score /100 — faithful port of `UserProfileStore.computeScore`
 * and `Benchmarks` from the archived iOS app (`archive/ios-swift`).
 *
 * Three additive criteria, total capped 0–100:
 * - replacement rate (0–40 pts): ≥ 80% → 40; 60–80 → 30 + (r−60)/2;
 *   < 60 → r/2 (truncation like Swift's `Int(...)`),
 * - pillar 3a (0–30 pts): 15 if an account exists + up to 15 based on the
 *   balance / age-bracket-average ratio,
 * - retirement horizon (0–30 pts): < 30 years → 30, < 40 → 25, < 50 → 20,
 *   otherwise 15.
 *
 * Deliberate divergence from iOS: the replacement rate is **not** recalculated
 * here — it comes from the backend calculator (`retirement-projection.ts`, 3a
 * excluded from retirement income, phase-1 assumptions), the single source of
 * truth. iOS used its local `OfflineCalculator` with its own constants.
 */

/** Swiss averages per age bracket (data from iOS `Benchmarks.swift`). */
export interface AgeBracketBenchmark {
  minAge: number;
  maxAge: number;
  averagePillar3aBalance: number; // centimes
  averageReplacementRate: number; // %
  averageBvgCapital: number; // centimes
}

export const AGE_BENCHMARKS: readonly AgeBracketBenchmark[] = [
  {
    minAge: 25,
    maxAge: 29,
    averagePillar3aBalance: 1_200_000,
    averageReplacementRate: 62,
    averageBvgCapital: 2_500_000,
  },
  {
    minAge: 30,
    maxAge: 34,
    averagePillar3aBalance: 2_800_000,
    averageReplacementRate: 60,
    averageBvgCapital: 6_500_000,
  },
  {
    minAge: 35,
    maxAge: 39,
    averagePillar3aBalance: 4_800_000,
    averageReplacementRate: 58,
    averageBvgCapital: 12_000_000,
  },
  {
    minAge: 40,
    maxAge: 44,
    averagePillar3aBalance: 7_200_000,
    averageReplacementRate: 57,
    averageBvgCapital: 19_500_000,
  },
  {
    minAge: 45,
    maxAge: 49,
    averagePillar3aBalance: 9_500_000,
    averageReplacementRate: 56,
    averageBvgCapital: 28_000_000,
  },
  {
    minAge: 50,
    maxAge: 54,
    averagePillar3aBalance: 12_000_000,
    averageReplacementRate: 55,
    averageBvgCapital: 38_000_000,
  },
  {
    minAge: 55,
    maxAge: 59,
    averagePillar3aBalance: 14_500_000,
    averageReplacementRate: 55,
    averageBvgCapital: 47_000_000,
  },
  {
    minAge: 60,
    maxAge: 65,
    averagePillar3aBalance: 16_000_000,
    averageReplacementRate: 54,
    averageBvgCapital: 54_000_000,
  },
] as const;

/** Fallback averages outside brackets (< 25 years or > 65 years) — iOS defaults. */
const FALLBACK_BENCHMARK = {
  averagePillar3aBalance: 5_000_000,
  averageReplacementRate: 57,
  averageBvgCapital: 15_000_000,
} as const;

export function getAgeBracket(age: number): AgeBracketBenchmark | null {
  return AGE_BENCHMARKS.find((b) => age >= b.minAge && age <= b.maxAge) ?? null;
}

/** Age-bracket 3a average (centimes), default CHF 50'000 outside bracket. */
export function averagePillar3aForAge(age: number): number {
  return getAgeBracket(age)?.averagePillar3aBalance ?? FALLBACK_BENCHMARK.averagePillar3aBalance;
}

export type ScoreCriterion = 'REPLACEMENT_RATE' | 'PILLAR_3A' | 'AGE_AWARENESS';

export interface ScoreBreakdownItem {
  criterion: ScoreCriterion;
  /** Localized label (Accept-Language). */
  label: string;
  points: number;
  maxPoints: number;
}

export interface PensionScoreInput {
  locale: Locale;
  currentAge: number;
  /** Replacement rate in % (backend calculator, 3a excluded from income). */
  replacementRate: number;
  hasPillar3a: boolean;
  /** Total 3a balance, in centimes. */
  pillar3aBalance: number;
  /** Current total LPP capital, in centimes (benchmark comparison). */
  bvgCapital: number;
}

export interface PensionScoreResult {
  score: number; // 0–100
  breakdown: ScoreBreakdownItem[];
  benchmark: {
    /** Age bracket found, null outside 25–65 years (fallback averages). */
    bracket: { minAge: number; maxAge: number } | null;
    averagePillar3aBalance: number; // centimes
    averageReplacementRate: number; // %
    averageBvgCapital: number; // centimes
    /** User values used in the calculation (comparison). */
    userPillar3aBalance: number;
    userReplacementRate: number;
    userBvgCapital: number;
  };
  generatedAt: string;
}

/** Calculates the pension score /100. Pure function. */
export function computePensionScore(input: PensionScoreInput): PensionScoreResult {
  const { locale, currentAge, replacementRate, hasPillar3a, pillar3aBalance, bvgCapital } = input;

  // ─── Replacement rate (0–40) ───
  let replacementPoints: number;
  if (replacementRate >= 80) {
    replacementPoints = 40;
  } else if (replacementRate >= 60) {
    replacementPoints = Math.floor(30 + (replacementRate - 60) / 2);
  } else {
    replacementPoints = Math.max(0, Math.floor(replacementRate / 2));
  }

  // ─── Pillar 3a (0–30) ───
  let pillar3aPoints = 0;
  if (hasPillar3a) {
    pillar3aPoints = 15;
    const benchmark = averagePillar3aForAge(currentAge);
    if (benchmark > 0) {
      const ratio = pillar3aBalance / benchmark;
      pillar3aPoints += Math.min(15, Math.floor(ratio * 15));
    }
  }

  // ─── Retirement horizon (0–30) ───
  const agePoints = currentAge < 30 ? 30 : currentAge < 40 ? 25 : currentAge < 50 ? 20 : 15;

  const score = Math.min(100, Math.max(0, replacementPoints + pillar3aPoints + agePoints));

  const bracket = getAgeBracket(currentAge);

  return {
    score,
    breakdown: [
      {
        criterion: 'REPLACEMENT_RATE',
        label: t(locale, 'score.criterion.replacement_rate'),
        points: replacementPoints,
        maxPoints: 40,
      },
      {
        criterion: 'PILLAR_3A',
        label: t(locale, 'score.criterion.pillar_3a'),
        points: pillar3aPoints,
        maxPoints: 30,
      },
      {
        criterion: 'AGE_AWARENESS',
        label: t(locale, 'score.criterion.age_awareness'),
        points: agePoints,
        maxPoints: 30,
      },
    ],
    benchmark: {
      bracket: bracket ? { minAge: bracket.minAge, maxAge: bracket.maxAge } : null,
      averagePillar3aBalance:
        bracket?.averagePillar3aBalance ?? FALLBACK_BENCHMARK.averagePillar3aBalance,
      averageReplacementRate:
        bracket?.averageReplacementRate ?? FALLBACK_BENCHMARK.averageReplacementRate,
      averageBvgCapital: bracket?.averageBvgCapital ?? FALLBACK_BENCHMARK.averageBvgCapital,
      userPillar3aBalance: pillar3aBalance,
      userReplacementRate: replacementRate,
      userBvgCapital: bvgCapital,
    },
    generatedAt: new Date().toISOString(),
  };
}
