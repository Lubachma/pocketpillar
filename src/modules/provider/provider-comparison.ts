import type { RiskLevel } from '@prisma/client';
import type { ProductComparison, ScoringWeights } from './provider.types.js';
import { DEFAULT_SCORING_WEIGHTS } from './provider.types.js';

interface ProductForScoring {
  productId: string;
  providerName: string;
  providerSlug: string;
  productName: string;
  productSlug: string;
  riskLevel: RiskLevel;
  equityAllocation: number;
  allInFeePercent: number;
  sustainableEsg: boolean;
  avgReturn3y: number | null;
  avgReturn5y: number | null;
}

function normalize(value: number, min: number, max: number): number {
  if (max === min) return 50;
  return ((value - min) / (max - min)) * 100;
}

/** Score and rank products. Pure function. */
export function scoreProducts(
  products: ProductForScoring[],
  weights: ScoringWeights = DEFAULT_SCORING_WEIGHTS,
  preferredRiskLevel?: string,
): ProductComparison[] {
  if (products.length === 0) return [];

  const fees = products.map((p) => p.allInFeePercent);
  const minFee = Math.min(...fees);
  const maxFee = Math.max(...fees);

  const returns3y = products.map((p) => p.avgReturn3y ?? 0);
  const minReturn = Math.min(...returns3y);
  const maxReturn = Math.max(...returns3y);

  const totalWeight = weights.fee + weights.performance + weights.riskMatch + weights.esg;

  return products
    .map((p) => {
      // Lower fee = higher score
      const feeFactor = 100 - normalize(p.allInFeePercent, minFee, maxFee);
      const perfFactor = normalize(p.avgReturn3y ?? 0, minReturn, maxReturn);
      const riskFactor = !preferredRiskLevel || p.riskLevel === preferredRiskLevel ? 100 : 50;
      const esgFactor = p.sustainableEsg ? 100 : 0;

      const score = Math.round(
        (weights.fee * feeFactor +
          weights.performance * perfFactor +
          weights.riskMatch * riskFactor +
          weights.esg * esgFactor) /
          totalWeight,
      );

      return { ...p, score };
    })
    .sort((a, b) => b.score - a.score);
}
