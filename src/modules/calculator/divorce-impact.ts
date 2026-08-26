import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';
import type { DivorceImpactInput, DivorceImpactResult } from './calculator.types.js';

/** Calculate impact of divorce on pension (LPP splitting) */
export function calculateDivorceImpact(input: DivorceImpactInput): DivorceImpactResult {
  const {
    age,
    retirementAge,
    bvgCapitalAtMarriage,
    bvgCapitalNow,
    spouseBvgCapitalAtMarriage,
    spouseBvgCapitalNow,
    yearsMarried,
    annualContribution,
    interestRate,
    conversionRate,
  } = input;

  const yearsToRetirement = retirementAge - age;

  // LPP accumulated during marriage
  const myAccumulatedDuringMarriage = bvgCapitalNow - bvgCapitalAtMarriage;
  const spouseAccumulatedDuringMarriage = spouseBvgCapitalNow - spouseBvgCapitalAtMarriage;

  // 50/50 split of capital accumulated during marriage
  const totalMarriageCapital = myAccumulatedDuringMarriage + spouseAccumulatedDuringMarriage;
  const myShare = Math.round(totalMarriageCapital / 2);
  const transferAmount = myShare - myAccumulatedDuringMarriage;

  // Capital after divorce (positive transfer = I receive, negative = I pay)
  const capitalAfterDivorce = bvgCapitalNow + transferAmount;

  // AVS splitting: Erziehungsgutschriften are split. Simplified estimate.
  // Each married year generates an AVS credit that is split.
  const avsReductionEstimate = Math.round(
    (SWISS_PENSION.AVS_MAX_ANNUAL_PENSION * yearsMarried * 0.02) / // ~2% per married year
      2, // Split equally
  );

  // Project capital to retirement
  let projectedWithMarriage = bvgCapitalNow;
  let projectedAfterDivorce = capitalAfterDivorce;

  for (let i = 0; i < yearsToRetirement; i++) {
    projectedWithMarriage = Math.round(
      projectedWithMarriage * (1 + interestRate / 100) + annualContribution,
    );
    projectedAfterDivorce = Math.round(
      projectedAfterDivorce * (1 + interestRate / 100) + annualContribution,
    );
  }

  const pensionWithMarriage = Math.round((projectedWithMarriage * conversionRate) / 100);
  const pensionAfterDivorce = Math.round((projectedAfterDivorce * conversionRate) / 100);

  return {
    myAccumulatedDuringMarriage,
    spouseAccumulatedDuringMarriage,
    totalMarriageCapital,
    transferAmount,
    capitalAfterDivorce,
    projectedCapitalWithMarriage: projectedWithMarriage,
    projectedCapitalAfterDivorce: projectedAfterDivorce,
    annualPensionWithMarriage: pensionWithMarriage,
    annualPensionAfterDivorce: pensionAfterDivorce,
    annualPensionDifference: pensionWithMarriage - pensionAfterDivorce,
    estimatedAvsImpact: avsReductionEstimate,
  };
}
