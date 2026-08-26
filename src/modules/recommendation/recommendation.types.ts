import type {
  Canton,
  EmploymentStatus,
  MaritalStatus,
  Pillar3aAccountType,
  RiskLevel,
} from '@prisma/client';
import type { Locale } from '../../lib/i18n/index.js';

export interface RecommendationInput {
  locale: Locale;
  canton: Canton;
  /** User's persisted municipality — refines the communal multiplier (otherwise cantonal average) */
  municipality?: string | null;
  birthYear: number;
  currentAge: number;
  retirementAge: number;

  employmentStatus: EmploymentStatus;
  maritalStatus: MaritalStatus;
  numberOfChildren: number;
  grossAnnualIncome: number;

  pillar2Accounts: Array<{
    currentCapital: number;
    conversionRate: number | null;
    annualBvgContribution: number | null;
    isVestedBenefits: boolean;
  }>;

  pillar3aAccounts: Array<{
    providerName: string;
    accountType: Pillar3aAccountType;
    currentBalance: number;
    annualContribution: number | null;
    interestRateOrReturn: number | null;
  }>;

  taxableIncome: number;
  churchTax: boolean;
  hasSecondPillar: boolean;

  availableProducts: Array<{
    providerName: string;
    productName: string;
    allInFeePercent: number;
    avgReturn3y: number | null;
    riskLevel: RiskLevel;
  }>;
}

export type RecommendationType =
  | 'OPEN_FIRST_3A'
  | 'MAX_3A_CONTRIBUTION'
  | 'PROVIDER_SWITCH'
  | 'BVG_VOLUNTARY_PURCHASE'
  | 'OPEN_ADDITIONAL_3A';

export type RecommendationPriority = 'HIGH' | 'MEDIUM' | 'LOW';

export interface Recommendation {
  type: RecommendationType;
  priority: RecommendationPriority;
  title: string;
  description: string;
  estimatedAnnualImpact: number; // centimes
  estimatedLifetimeImpact: number; // centimes
  details: Record<string, unknown>;
}

export type RecommendationRule = (input: RecommendationInput) => Recommendation | null;

export interface RecommendationResult {
  recommendations: Recommendation[];
  profileCompleteness: number; // 0-100
  generatedAt: string;
}
