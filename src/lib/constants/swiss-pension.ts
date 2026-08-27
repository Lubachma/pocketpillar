/**
 * Swiss pension system constants — law in force in 2026.
 *
 * ⚠️ The "LPP 2024 reform" (threshold 19'845, 20% deduction, bonuses
 * 9%/14%, conversion rate 6.0%) was REJECTED in the popular vote of
 * 22.09.2024 (~67% no) — it NEVER entered into force. This file reflects
 * the law actually applicable (LPP/OPP2 and LAVS, 2025-2026 values — AVS
 * pensions are not adjusted on 1.1.2026, next possible adjustment on
 * 1.1.2027; OFAS bulletin no. 167, 16.12.2025).
 *
 * All monetary values in centimes (CHF * 100).
 */
export const SWISS_PENSION = {
  // ─── AVS / AHV (1st pillar) — scale 44, 2025-2026 values ───
  /** CHF 30'240 (2'520/month) — max annual AVS pension (single), scale 44 */
  AVS_MAX_ANNUAL_PENSION: 3_024_000,
  /** CHF 15'120 (1'260/month) — min annual AVS pension, scale 44 */
  AVS_MIN_ANNUAL_PENSION: 1_512_000,
  /** CHF 90'720 — avg annual income from which the max AVS pension is reached
   * (scale 44; same figure as BVG_MAX_INSURED_SALARY, distinct meaning) */
  AVS_MAX_PENSION_AVG_INCOME: 9_072_000,
  /** CHF 45'360 — legal cap on the AVS pension of a married couple:
   * 150% of the maximum individual pension (LAVS art. 35). Does not apply
   * to unmarried cohabiting couples (individual taxation and pensions). */
  AVS_MAX_COUPLE_ANNUAL_PENSION: 4_536_000,
  /** 2026 — first year the 13th AVS pension payment is made (popular vote of
   * 3.3.2024; first payment in December 2026). From this year on, one
   * pension year counts 13 monthly payments (×13/12); the MONTHLY pension and
   * the 150% couple cap are unchanged. Source: sozialesicherheit.ch —
   * "Social insurance: what's changing in 2026". */
  AVS_13TH_PENSION_FIRST_YEAR: 2026,
  /** Full AVS contribution career (échelle 44) */
  AVS_FULL_CONTRIBUTION_YEARS: 44,
  /** Simplified career start age — estimated contribution years = age − 20 */
  AVS_CONTRIBUTION_START_AGE: 20,
  /** Employee AVS/AI/APG salary deduction (%): AVS 4.35 + AI 0.7 + APG 0.25
   * (excludes ALV 1.1% and family allowances). Informative — not used by the
   * calculation engines, which work from pensions, not contributions. */
  AVS_CONTRIBUTION_RATE_EMPLOYEE: 5.3,
  /** Employer share — same composition as the employee share (parity). */
  AVS_CONTRIBUTION_RATE_EMPLOYER: 5.3,

  // ─── LPP / BVG (2nd pillar) — law in force 2026 ───
  /** CHF 22'680 — entry threshold (art. 7 LPP / OPP2, since 1.1.2025) */
  BVG_ENTRY_THRESHOLD: 2_268_000,
  /** CHF 26'460 — coordination deduction: FIXED amount = 7/8 of the max AVS
   * pension (30'240 × 7/8). The proportional 20% deduction was part of
   * the reform rejected in the vote of 22.09.2024. */
  BVG_COORDINATION_DEDUCTION: 2_646_000,
  /** CHF 90'720 — maximum insured salary (art. 8 LPP; 3 × max AVS pension) */
  BVG_MAX_INSURED_SALARY: 9_072_000,
  /** CHF 3'780 — minimum coordinated salary (1/8 of the max AVS pension): applies
   * to low salaries above the entry threshold (part-time work). */
  BVG_MIN_COORDINATED_SALARY: 378_000,
  /** CHF 64'260 — maximum coordinated salary (90'720 − 26'460) */
  BVG_MAX_COORDINATED_SALARY: 6_426_000,

  /** BVG age-based contribution (bonification) rates — 4 brackets (art. 16 LPP) */
  BVG_CONTRIBUTION_RATES: [
    { ageFrom: 25, ageTo: 34, rate: 7.0 },
    { ageFrom: 35, ageTo: 44, rate: 10.0 },
    { ageFrom: 45, ageTo: 54, rate: 15.0 },
    { ageFrom: 55, ageTo: 65, rate: 18.0 },
  ] as const,

  /** Minimum BVG conversion rate: 6.8% (art. 14 LPP — the decrease to 6.0%
   * was part of the reform rejected on 22.09.2024) */
  BVG_MIN_CONVERSION_RATE: 6.8,
  /** Minimum interest rate on BVG capital (%, Federal Council decision of 5.11.2025 for 2026) */
  BVG_INTEREST_RATE_MIN: 1.25,

  // ─── Pillar 3a ──────────────────────────
  /** CHF 7'258 — max 3a contribution with 2nd pillar (unchanged in 2026) */
  PILLAR_3A_MAX_EMPLOYED: 725_800,
  /** CHF 36'288 — max 3a contribution without 2nd pillar */
  PILLAR_3A_MAX_SELF_EMPLOYED: 3_628_800,
  /** Max 3a as % of net earned income (self-employed without 2nd pillar) */
  PILLAR_3A_SELF_EMPLOYED_RATE: 20,
  /** First year eligible for 3a catch-up contributions (OPP3 art. 7a/7b) */
  PILLAR_3A_CATCHUP_START_YEAR: 2025,
  /** Max retroactive years for 3a catch-up */
  PILLAR_3A_CATCHUP_MAX_YEARS: 10,
  /** Default 3a return assumption (%) — single source for schema default + score handler */
  PILLAR_3A_DEFAULT_RETURN_RATE: 3.0,

  // ─── EPL / Property Purchase ────────────
  /** CHF 20'000 — minimum withdrawal for property purchase */
  EPL_MIN_WITHDRAWAL: 2_000_000,
  /** Age limit for full vested benefits withdrawal */
  EPL_AGE_LIMIT: 50,

  // ─── Retirement ─────────────────────────
  RETIREMENT_AGE_MEN: 65,
  /** 65 from 2028; AVS 21 transition for women born 1961-1963
   * (2026: 64 years and 6 months — women born in 1962). The app does not
   * model gender: target value kept, documented transitional gap ≤ 1 year. */
  RETIREMENT_AGE_WOMEN: 65,

  /** Current calendar year — computed at process start, never hardcoded */
  CURRENT_YEAR: new Date().getFullYear(),
} as const;
