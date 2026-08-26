import type {
  RecommendationInput,
  RecommendationResult,
  RecommendationRule,
} from './recommendation.types.js';
import {
  pillar3aContributionRule,
  providerSwitchRule,
  bvgRachatRule,
  openAdditional3aRule,
} from './rules/index.js';

const ALL_RULES: RecommendationRule[] = [
  pillar3aContributionRule,
  providerSwitchRule,
  bvgRachatRule,
  openAdditional3aRule,
];

const PRIORITY_ORDER = { HIGH: 0, MEDIUM: 1, LOW: 2 } as const;

function calculateCompleteness(input: RecommendationInput): number {
  let filled = 0;
  let total = 0;

  const check = (val: unknown) => {
    total++;
    if (val !== null && val !== undefined) filled++;
  };

  check(input.canton);
  check(input.birthYear);
  check(input.grossAnnualIncome);
  check(input.taxableIncome);
  check(input.pillar2Accounts.length > 0 ? true : null);
  check(input.pillar3aAccounts.length > 0 ? true : null);
  check(input.employmentStatus);
  check(input.maritalStatus);

  return Math.round((filled / total) * 100);
}

/** Generate personalized recommendations. Pure function. */
export function generateRecommendations(input: RecommendationInput): RecommendationResult {
  const recommendations = ALL_RULES.map((rule) => rule(input)).filter(
    (r): r is NonNullable<typeof r> => r !== null,
  );

  recommendations.sort((a, b) => {
    const pDiff = PRIORITY_ORDER[a.priority] - PRIORITY_ORDER[b.priority];
    if (pDiff !== 0) return pDiff;
    return b.estimatedAnnualImpact - a.estimatedAnnualImpact;
  });

  return {
    recommendations,
    profileCompleteness: calculateCompleteness(input),
    generatedAt: new Date().toISOString(),
  };
}
