import type { RiskLevel } from '@prisma/client';

export interface ProductComparison {
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
  score: number;
}

export interface ComparisonFilters {
  riskLevel?: RiskLevel;
  sustainableOnly?: boolean;
  maxFeePercent?: number;
  minEquityAllocation?: number;
  maxEquityAllocation?: number;
}

export interface ScoringWeights {
  fee: number;
  performance: number;
  riskMatch: number;
  esg: number;
}

export const DEFAULT_SCORING_WEIGHTS: ScoringWeights = {
  fee: 40,
  performance: 30,
  riskMatch: 20,
  esg: 10,
};
