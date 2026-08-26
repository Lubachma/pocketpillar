import type { Canton } from '@prisma/client';
import { CANTONAL_INCOME_TABLES } from './constants/cantonal-income-tables.js';
import { CAPITAL_WITHDRAWAL_TABLES } from './constants/capital-withdrawal-tables.js';
import { resolveCommunalMultiplier } from './constants/communal-multipliers.js';

/**
 * Cantonal/communal taxes — OFFICIAL tables sampled from the FTA (Federal Tax
 * Administration) tax calculator (swisstaxcalculator.estv.admin.ch), year
 * 2026, regenerable via `scripts/regen-cantonal-tax-tables.mjs`.
 *
 * Model (matches the actual structure of Swiss taxation):
 *   effective cantonal = interpolated simple tax × cantonal steuerfuss
 *   communal           = interpolated simple tax × communal multiplier
 *                        (actual per municipality, `communal-multipliers.ts`)
 *   church              = (cantonal + communal) × per-canton factor
 *
 * Linear interpolation on the CHF 1'000 grid bounds the error to a few
 * francs (continuous, piecewise-linear tariffs).
 */

interface Point {
  i: number;
  t: number;
}

/** Linear interpolation over points sorted by increasing `i`; extrapolation
 * beyond the last point using the final marginal slope. */
function interpolate(points: readonly Point[], x: number): number {
  const first = points[0];
  if (x <= first.i) return first.t;
  const last = points[points.length - 1];
  if (x >= last.i) {
    const prev = points[points.length - 2];
    const slope = (last.t - prev.t) / (last.i - prev.i);
    return Math.round(last.t + (x - last.i) * slope);
  }
  let lo = 0;
  let hi = points.length - 1;
  while (hi - lo > 1) {
    const mid = (lo + hi) >> 1;
    if (points[mid].i <= x) lo = mid;
    else hi = mid;
  }
  const a = points[lo];
  const b = points[hi];
  return Math.round(a.t + ((b.t - a.t) * (x - a.i)) / (b.i - a.i));
}

/** SIMPLE cantonal tax (legal base before multipliers), in centimes.
 * Single tariff — the married tariff goes through `incomeTaxBreakdown`. */
export function cantonalSimpleTax(canton: Canton, taxableIncome: number): number {
  return interpolate(CANTONAL_INCOME_TABLES[canton].points, taxableIncome);
}

export interface IncomeTaxOptions {
  /** Municipality of residence — actual communal multiplier if covered. */
  municipality?: string;
  /** Church tax included if true. */
  churchTax?: boolean;
  /** Married tariff (`pointsMarried` tables) if true — single otherwise. */
  married?: boolean;
}

export interface IncomeTaxBreakdown {
  /** Effective cantonal tax (cantonal steuerfuss and rebates included). */
  cantonal: number;
  /** Communal tax (actual municipality multiplier if covered). */
  communal: number;
  /** Church tax (0 if `churchTax` is false). */
  church: number;
  total: number;
}

/** Cantonal + communal (+ church) breakdown of income tax. */
export function incomeTaxBreakdown(
  canton: Canton,
  taxableIncome: number,
  options: IncomeTaxOptions = {},
): IncomeTaxBreakdown {
  const table = CANTONAL_INCOME_TABLES[canton];
  const points = options.married ? table.pointsMarried : table.points;
  const simple = interpolate(points, taxableIncome);
  const cantonal = Math.round(simple * table.cantonFuss);
  const communal = Math.round(
    (simple * resolveCommunalMultiplier(canton, options.municipality)) / 100,
  );
  const church = options.churchTax ? Math.round((cantonal + communal) * table.churchFactor) : 0;
  return { cantonal, communal, church, total: cantonal + communal + church };
}

/**
 * Tax on capital withdrawal (3a/LPP), in centimes — actual tables per canton
 * and marital status (the federal tariff of art. 38 LIFD is included in the
 * tables: sampled, not approximated via ÷ 5).
 *
 * Communal adjustment: the non-federal portion is weighted by the ratio
 * between the municipality's multiplier and the cantonal capital's
 * (documented approximation — capital tax steuerfüsse are close to income
 * tax ones in most cantons).
 */
export function capitalWithdrawalTax(
  canton: Canton,
  amount: number,
  maritalStatus: 'SINGLE' | 'MARRIED',
  municipality?: string,
): number {
  // The sampled grid starts at CHF 10'000: the origin (0 → 0) is added
  // virtually — otherwise any withdrawal under 10k would pay a fictitious
  // floor (and 0 must cost 0).
  if (amount <= 0) return 0;
  const table = CAPITAL_WITHDRAWAL_TABLES[canton];
  const points = maritalStatus === 'MARRIED' ? table.married : table.single;
  const withOrigin = [{ a: 0, fed: 0, rest: 0 }, ...points];
  const fed = interpolate(
    withOrigin.map((p) => ({ i: p.a, t: p.fed })),
    amount,
  );
  let rest = interpolate(
    withOrigin.map((p) => ({ i: p.a, t: p.rest })),
    amount,
  );
  if (municipality) {
    const capitalMultiplier = resolveCommunalMultiplier(canton, table.capitalMunicipality);
    const userMultiplier = resolveCommunalMultiplier(canton, municipality);
    if (capitalMultiplier > 0) {
      rest = Math.round((rest * userMultiplier) / capitalMultiplier);
    }
  }
  return fed + rest;
}
