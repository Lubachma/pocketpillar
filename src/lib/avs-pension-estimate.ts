import { SWISS_PENSION } from './constants/swiss-pension.js';

/**
 * SIMPLIFIED estimate of the annual AVS pension (in-house model inspired by
 * scale 44) — used when the caller doesn't provide its own estimate
 * (`estimatedAvsPension`, `POST /calculator/retirement`) and by `GET /score`.
 * This is NOT an official calculation: the actual pension depends on the
 * individual account statement (actual contribution years, annual income,
 * bonuses, gaps).
 *
 * Model (all in centimes):
 *
 *   incomeRatio   = clamp(annualIncome, 0, 90'720) / 90'720
 *   careerPension = 15'120 + (30'240 − 15'120) × incomeRatio
 *   pension       = round(careerPension × years / 44)
 *
 * - Average annual income ≥ CHF 90'720 (`AVS_MAX_PENSION_AVG_INCOME`) →
 *   maximum pension CHF 30'240/year (full career); proportional interpolation
 *   between the minimum pension CHF 15'120/year (CHF 1'260/month) and the
 *   maximum.
 * - Contribution years: `contributionYears` if provided (clamped 0–44),
 *   otherwise **projected to retirement**: `min(retirementAge − 20, 44)` —
 *   the pension shown is the one paid AT retirement, assuming contributions
 *   continue until then (documented assumption: simplified career start at
 *   age 20, `AVS_CONTRIBUTION_START_AGE`). Projecting past years only would
 *   massively underestimate the pension of young workers.
 * - Rounding: nearest centime (`Math.round`), applied once on the final
 *   result.
 */
export interface AvsPensionEstimateInput {
  /** Gross annual income, in centimes (proxy for average annual income). */
  grossAnnualIncome: number;
  /** Current age — kept for caller compatibility (unused for the years
   * calculation when `retirementAge`/`contributionYears` drive the estimate). */
  currentAge: number;
  /** Retirement age (default 65) — drives the projection of contribution
   * years when `contributionYears` is not provided. */
  retirementAge?: number;
  /** Actual contribution years if known (clamped 0–44). */
  contributionYears?: number;
}

/** Estimates the annual AVS pension in centimes. Pure function. */
export function estimateAvsPension(input: AvsPensionEstimateInput): number {
  const incomeRatio =
    Math.min(Math.max(input.grossAnnualIncome, 0), SWISS_PENSION.AVS_MAX_PENSION_AVG_INCOME) /
    SWISS_PENSION.AVS_MAX_PENSION_AVG_INCOME;

  const careerPension =
    SWISS_PENSION.AVS_MIN_ANNUAL_PENSION +
    (SWISS_PENSION.AVS_MAX_ANNUAL_PENSION - SWISS_PENSION.AVS_MIN_ANNUAL_PENSION) * incomeRatio;

  const projectedYears = (input.retirementAge ?? 65) - SWISS_PENSION.AVS_CONTRIBUTION_START_AGE;
  const years = input.contributionYears ?? projectedYears;
  const yearsFactor =
    Math.min(Math.max(years, 0), SWISS_PENSION.AVS_FULL_CONTRIBUTION_YEARS) /
    SWISS_PENSION.AVS_FULL_CONTRIBUTION_YEARS;

  return Math.round(careerPension * yearsFactor);
}
