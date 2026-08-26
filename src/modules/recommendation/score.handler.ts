import type { FastifyRequest, FastifyReply } from 'fastify';
import { t } from '../../lib/i18n/index.js';
import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';
import { estimateAvsPension } from '../../lib/avs-pension-estimate.js';
import { calculateRetirementProjection } from '../calculator/retirement-projection.js';
import { computePensionScore } from './pension-score.js';

/**
 * GET /score — pension score /100 + benchmarks for the age bracket.
 *
 * The replacement rate is calculated with the same assumptions used by the
 * Flutter client on `POST /calculator/retirement` (Zod schema defaults:
 * LPP interest 1.25%, conversion 6.8%, 3a return 3%, AVS pension estimated
 * from income — simplified scale 44, `estimateAvsPension`) — the score and
 * the dashboard summary card thus rely on the same figure.
 */
export async function getScoreHandler(request: FastifyRequest, reply: FastifyReply) {
  const user = await request.server.prisma.user.findUnique({
    where: { id: request.userId! },
    include: {
      financialProfile: true,
      pillar2Accounts: true,
      pillar3aAccounts: true,
    },
  });

  if (!user?.financialProfile || !user.canton || !user.birthYear) {
    return reply.status(422).send({
      error: t(request.locale, 'error.incomplete_profile'),
    });
  }

  const currentAge = SWISS_PENSION.CURRENT_YEAR - user.birthYear;
  const pillar2Capital = user.pillar2Accounts.reduce((sum, a) => sum + a.currentCapital, 0);
  const pillar3aBalance = user.pillar3aAccounts.reduce((sum, a) => sum + a.currentBalance, 0);

  const projection = calculateRetirementProjection({
    currentAge,
    retirementAge: SWISS_PENSION.RETIREMENT_AGE_MEN,
    grossAnnualIncome: user.financialProfile.grossAnnualIncome,
    currentPillar2Capital: pillar2Capital,
    annualPillar2Contribution: user.pillar2Accounts.reduce(
      (sum, a) => sum + (a.annualBvgContribution ?? 0),
      0,
    ),
    pillar2InterestRate: SWISS_PENSION.BVG_INTEREST_RATE_MIN,
    conversionRate: SWISS_PENSION.BVG_MIN_CONVERSION_RATE,
    currentPillar3aBalance: pillar3aBalance,
    annualPillar3aContribution: user.pillar3aAccounts.reduce(
      (sum, a) => sum + (a.annualContribution ?? 0),
      0,
    ),
    pillar3aReturnRate: SWISS_PENSION.PILLAR_3A_DEFAULT_RETURN_RATE,
    // Same dynamic estimate as the POST /calculator/retirement default.
    estimatedAvsPension: estimateAvsPension({
      grossAnnualIncome: user.financialProfile.grossAnnualIncome,
      currentAge,
    }),
  });

  const result = computePensionScore({
    locale: request.locale,
    currentAge,
    replacementRate: projection.replacementRate,
    hasPillar3a: user.pillar3aAccounts.length > 0,
    pillar3aBalance,
    bvgCapital: pillar2Capital,
  });

  return reply.send(result);
}
