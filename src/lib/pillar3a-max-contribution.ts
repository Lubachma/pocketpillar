import { SWISS_PENSION } from './constants/swiss-pension.js';

/**
 * Applicable annual 3a ceiling, in centimes (OPP3 art. 7, 2026 values).
 *
 * - **With 2nd pillar** (affiliated to a pension fund, including voluntary
 *   LPP): CHF 7'258 — income has no effect.
 * - **Without 2nd pillar** (non-affiliated self-employed): **20% of
 *   income**, capped at CHF 36'288 — never negative.
 *
 * The legal basis is the *net income from gainful activity*; callers use the
 * best available proxy (taxable income on the calculator side, net or gross
 * income persisted on the profile side) — documented approximation in API
 * contract §7.
 *
 * The 20% is **truncated** to the nearest lower centime (`Math.floor`, parity
 * with the app-side Dart `~/` — batch 12 review): never rounds above the
 * legal deductible.
 */
export function pillar3aMaxContribution(hasSecondPillar: boolean, incomeCentimes: number): number {
  if (hasSecondPillar) return SWISS_PENSION.PILLAR_3A_MAX_EMPLOYED;
  const byIncome = Math.floor((incomeCentimes * SWISS_PENSION.PILLAR_3A_SELF_EMPLOYED_RATE) / 100);
  return Math.max(0, Math.min(SWISS_PENSION.PILLAR_3A_MAX_SELF_EMPLOYED, byIncome));
}
