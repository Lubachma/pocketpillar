import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';
import type { LppGapInput, LppGapResult } from './calculator.types.js';

/** Get BVG contribution rate for a given age — past the last bracket, the last
 * rate (18%) still applies while working beyond the reference age */
function getBvgContributionRate(age: number): number {
  for (const bracket of SWISS_PENSION.BVG_CONTRIBUTION_RATES) {
    if (age >= bracket.ageFrom && age <= bracket.ageTo) {
      return bracket.rate;
    }
  }
  const lastBracket =
    SWISS_PENSION.BVG_CONTRIBUTION_RATES[SWISS_PENSION.BVG_CONTRIBUTION_RATES.length - 1];
  return age > lastBracket.ageTo ? lastBracket.rate : 0;
}

/** Project capital at retirement with annual contributions and compound interest */
function projectCapital(
  currentCapital: number,
  annualContribution: number,
  interestRate: number,
  years: number,
): number {
  let capital = currentCapital;
  for (let i = 0; i < years; i++) {
    capital = capital * (1 + interestRate / 100) + annualContribution;
  }
  return Math.round(capital);
}

/** Calculate LPP/BVG gap analysis */
export function calculateLppGap(input: LppGapInput): LppGapResult {
  const {
    grossAnnualIncome,
    age,
    retirementAge,
    currentBvgCapital,
    actualAnnualContribution,
    conversionRate,
  } = input;
  const yearsToRetirement = retirementAge - age;

  // Coordinated salary (law in force — the proportional 20% deduction was
  // part of the reform rejected in the vote of 22.09.2024):
  //   coordinated salary = gross salary − FIXED coordination deduction
  //   (CHF 26'460 = 7/8 of the max AVS pension), bounded between the legal
  //   minimum (CHF 3'780 — low part-time salaries) and the legal maximum
  //   (CHF 64'260 = 90'720 − 26'460).
  // Below the entry threshold (CHF 22'680), the salary is not LPP-insured.
  const coordinatedSalary =
    grossAnnualIncome < SWISS_PENSION.BVG_ENTRY_THRESHOLD
      ? 0
      : Math.min(
          Math.max(
            grossAnnualIncome - SWISS_PENSION.BVG_COORDINATION_DEDUCTION,
            SWISS_PENSION.BVG_MIN_COORDINATED_SALARY,
          ),
          SWISS_PENSION.BVG_MAX_COORDINATED_SALARY,
        );

  // BVG minimum contribution
  const rate = getBvgContributionRate(age);
  const bvgMinContribution = Math.round((coordinatedSalary * rate) / 100);
  const contributionGap = Math.max(bvgMinContribution - actualAnnualContribution, 0);

  // Project capital at retirement — both paths start from the current capital so the
  // comparison is symmetric; gaps are clamped at 0 (no "negative gap").
  const projectedBvgMinCapital = projectCapital(
    currentBvgCapital,
    bvgMinContribution,
    SWISS_PENSION.BVG_INTEREST_RATE_MIN,
    yearsToRetirement,
  );

  const projectedActualCapital = projectCapital(
    currentBvgCapital,
    actualAnnualContribution,
    SWISS_PENSION.BVG_INTEREST_RATE_MIN,
    yearsToRetirement,
  );

  const capitalGap = Math.max(projectedBvgMinCapital - projectedActualCapital, 0);

  // Pension projections
  const projectedMinAnnualPension = Math.round(
    (projectedBvgMinCapital * SWISS_PENSION.BVG_MIN_CONVERSION_RATE) / 100,
  );
  const projectedActualAnnualPension = Math.round((projectedActualCapital * conversionRate) / 100);
  const pensionGap = Math.max(projectedMinAnnualPension - projectedActualAnnualPension, 0);

  return {
    coordinatedSalary,
    bvgMinContribution,
    contributionGap,
    projectedBvgMinCapital,
    projectedActualCapital,
    capitalGap,
    projectedMinAnnualPension,
    projectedActualAnnualPension,
    pensionGap,
  };
}
