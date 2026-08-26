import { describe, it, expect } from 'vitest';
import {
  computePensionScore,
  getAgeBracket,
  averagePillar3aForAge,
} from '../../../src/modules/recommendation/pension-score.js';
import type { PensionScoreInput } from '../../../src/modules/recommendation/pension-score.js';

/**
 * Rules ported from iOS (`UserProfileStore.computeScore` + `Benchmarks`):
 * replacement 0–40, 3a 0–30, retirement horizon 0–30, total clamped to 0–100.
 * Amounts in centimes.
 */
const baseInput: PensionScoreInput = {
  locale: 'fr',
  currentAge: 35,
  replacementRate: 65,
  hasPillar3a: true,
  pillar3aBalance: 4_800_000, // = average for the 35–39 bracket
  bvgCapital: 12_000_000,
};

describe('computePensionScore — replacement rate criterion (0–40)', () => {
  it.each([
    [85, 40],
    [80, 40],
    [79.9, 39], // 30 + 19.9/2 = 39.95, truncated like Swift's Int()
    [70, 35],
    [61, 30], // 30.5 truncated
    [60, 30],
    [59.9, 29],
    [50, 25],
    [0, 0],
  ])('rate %f → %i points', (rate, expected) => {
    const result = computePensionScore({ ...baseInput, replacementRate: rate });
    expect(result.breakdown[0].points).toBe(expected);
    expect(result.breakdown[0].maxPoints).toBe(40);
  });
});

describe('computePensionScore — pillar 3a criterion (0–30)', () => {
  it('no 3a account → 0 point', () => {
    const result = computePensionScore({ ...baseInput, hasPillar3a: false });
    expect(result.breakdown[1].points).toBe(0);
  });

  it('empty 3a account → 15 points (holding one is enough)', () => {
    const result = computePensionScore({ ...baseInput, pillar3aBalance: 0 });
    expect(result.breakdown[1].points).toBe(15);
  });

  it('balance = half the age-bracket average → 15 + 7 (ratio 0.5 truncated)', () => {
    const result = computePensionScore({ ...baseInput, pillar3aBalance: 2_400_000 });
    expect(result.breakdown[1].points).toBe(22);
  });

  it('balance = age-bracket average → 30 points', () => {
    const result = computePensionScore({ ...baseInput, pillar3aBalance: 4_800_000 });
    expect(result.breakdown[1].points).toBe(30);
  });

  it('balance well above the average → capped at 30', () => {
    const result = computePensionScore({ ...baseInput, pillar3aBalance: 50_000_000 });
    expect(result.breakdown[1].points).toBe(30);
  });
});

describe('computePensionScore — retirement horizon criterion (0–30)', () => {
  it.each([
    [18, 30],
    [29, 30],
    [30, 25],
    [39, 25],
    [40, 20],
    [49, 20],
    [50, 15],
    [65, 15],
    [70, 15],
  ])('age %i → %i points', (age, expected) => {
    const result = computePensionScore({ ...baseInput, currentAge: age });
    expect(result.breakdown[2].points).toBe(expected);
    expect(result.breakdown[2].maxPoints).toBe(30);
  });
});

describe('computePensionScore — full scores', () => {
  it('perfect score: rate ≥ 80%, 3a ≥ average, < 30 years old → 100', () => {
    const result = computePensionScore({
      ...baseInput,
      currentAge: 27,
      replacementRate: 82,
      pillar3aBalance: 2_000_000, // > average 25–29 (CHF 12'000)
    });
    expect(result.score).toBe(100);
    expect(result.breakdown.map((b) => b.points)).toEqual([40, 30, 30]);
  });

  it('empty profile: 0 rate, no 3a, 55 years old → 15 (horizon only)', () => {
    const result = computePensionScore({
      locale: 'fr',
      currentAge: 55,
      replacementRate: 0,
      hasPillar3a: false,
      pillar3aBalance: 0,
      bvgCapital: 0,
    });
    expect(result.score).toBe(15);
    expect(result.breakdown.map((b) => b.points)).toEqual([0, 0, 15]);
  });

  it('the score is the sum of the criteria, capped at 100', () => {
    const result = computePensionScore(baseInput);
    const sum = result.breakdown.reduce((s, b) => s + b.points, 0);
    expect(result.score).toBe(Math.min(100, sum));
    expect(result.score).toBe(32 + 30 + 25); // 65% → 32 pts (30 + 5/2 truncated)
  });
});

describe('benchmarks by age bracket (iOS data)', () => {
  it('covers the 8 brackets from 25 to 65 years old', () => {
    expect(getAgeBracket(25)).toMatchObject({
      minAge: 25,
      maxAge: 29,
      averagePillar3aBalance: 1_200_000,
      averageReplacementRate: 62,
      averageBvgCapital: 2_500_000,
    });
    expect(getAgeBracket(34)).toMatchObject({ minAge: 30, maxAge: 34 });
    expect(getAgeBracket(39)).toMatchObject({ minAge: 35, maxAge: 39 });
    expect(getAgeBracket(44)).toMatchObject({ minAge: 40, maxAge: 44 });
    expect(getAgeBracket(49)).toMatchObject({ minAge: 45, maxAge: 49 });
    expect(getAgeBracket(54)).toMatchObject({ minAge: 50, maxAge: 54 });
    expect(getAgeBracket(59)).toMatchObject({ minAge: 55, maxAge: 59 });
    expect(getAgeBracket(65)).toMatchObject({
      minAge: 60,
      maxAge: 65,
      averagePillar3aBalance: 16_000_000,
      averageReplacementRate: 54,
      averageBvgCapital: 54_000_000,
    });
  });

  it('outside the brackets (< 25 or > 65) → null + iOS fallback averages', () => {
    expect(getAgeBracket(24)).toBeNull();
    expect(getAgeBracket(66)).toBeNull();
    // iOS defaults: CHF 50'000 / 57 % / CHF 150'000.
    expect(averagePillar3aForAge(20)).toBe(5_000_000);

    const result = computePensionScore({ ...baseInput, currentAge: 20 });
    expect(result.benchmark.bracket).toBeNull();
    expect(result.benchmark.averagePillar3aBalance).toBe(5_000_000);
    expect(result.benchmark.averageReplacementRate).toBe(57);
    expect(result.benchmark.averageBvgCapital).toBe(15_000_000);
  });

  it('exposes the user values for comparison', () => {
    const result = computePensionScore(baseInput);
    expect(result.benchmark.bracket).toEqual({ minAge: 35, maxAge: 39 });
    expect(result.benchmark.userPillar3aBalance).toBe(4_800_000);
    expect(result.benchmark.userReplacementRate).toBe(65);
    expect(result.benchmark.userBvgCapital).toBe(12_000_000);
  });
});

describe('computePensionScore — label i18n', () => {
  it.each([
    ['fr', ['Taux de remplacement', 'Épargne 3a', 'Horizon retraite']],
    ['de', ['Ersatzquote', 'Säule-3a-Ersparnis', 'Pensionshorizont']],
    ['en', ['Replacement rate', 'Pillar 3a savings', 'Retirement horizon']],
  ] as const)('locale %s', (locale, labels) => {
    const result = computePensionScore({ ...baseInput, locale });
    expect(result.breakdown.map((b) => b.label)).toEqual(labels);
  });
});
