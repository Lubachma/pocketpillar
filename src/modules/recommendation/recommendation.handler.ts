import type { FastifyRequest, FastifyReply } from 'fastify';
import { t } from '../../lib/i18n/index.js';
import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';
import { getProductsForRecommendation } from '../provider/provider.service.js';
import { generateRecommendations } from './recommendation.engine.js';
import type { RecommendationInput } from './recommendation.types.js';

export async function getRecommendationsHandler(request: FastifyRequest, reply: FastifyReply) {
  const user = await request.server.prisma.user.findUnique({
    where: { id: request.userId! },
    include: {
      financialProfile: true,
      pillar2Accounts: true,
      pillar3aAccounts: true,
      taxSituation: true,
    },
  });

  if (!user?.financialProfile || !user.canton || !user.birthYear) {
    return reply.status(422).send({
      error: t(request.locale, 'error.incomplete_profile'),
    });
  }

  // Cached catalog query (Redis, fail-open) — see provider.service.ts.
  const products = await getProductsForRecommendation(request.server.prisma, {
    redis: request.server.redis,
    log: request.log,
  });

  const currentAge = SWISS_PENSION.CURRENT_YEAR - user.birthYear;
  const hasSecondPillar =
    user.financialProfile.employmentStatus === 'EMPLOYED' || user.pillar2Accounts.length > 0;

  const input: RecommendationInput = {
    locale: request.locale,
    canton: user.canton,
    municipality: user.municipality,
    birthYear: user.birthYear,
    currentAge,
    retirementAge: SWISS_PENSION.RETIREMENT_AGE_MEN,
    employmentStatus: user.financialProfile.employmentStatus,
    maritalStatus: user.financialProfile.maritalStatus,
    numberOfChildren: user.financialProfile.numberOfChildren,
    grossAnnualIncome: user.financialProfile.grossAnnualIncome,
    pillar2Accounts: user.pillar2Accounts.map((a) => ({
      currentCapital: a.currentCapital,
      conversionRate: a.conversionRate,
      annualBvgContribution: a.annualBvgContribution,
      isVestedBenefits: a.isVestedBenefits,
    })),
    pillar3aAccounts: user.pillar3aAccounts.map((a) => ({
      providerName: a.providerName,
      accountType: a.accountType,
      currentBalance: a.currentBalance,
      annualContribution: a.annualContribution,
      interestRateOrReturn: a.interestRateOrReturn,
    })),
    taxableIncome: user.taxSituation?.taxableIncome ?? user.financialProfile.grossAnnualIncome,
    churchTax: user.taxSituation?.churchTax ?? false,
    hasSecondPillar,
    availableProducts: products.map((p) => {
      const returns = p.performanceHistory.map((ph) => ph.returnPercent);
      const avg3y = returns.length >= 3 ? returns.slice(0, 3).reduce((a, b) => a + b, 0) / 3 : null;
      return {
        providerName: p.provider.name,
        productName: p.name,
        allInFeePercent: p.fees?.allInFeePercent ?? 0,
        avgReturn3y: avg3y,
        riskLevel: p.riskLevel,
      };
    }),
  };

  const result = generateRecommendations(input);
  return reply.send(result);
}
