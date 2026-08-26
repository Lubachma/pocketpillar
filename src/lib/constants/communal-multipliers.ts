import type { Canton } from '@prisma/client';
import { CANTONAL_INCOME_TABLES } from './cantonal-income-tables.js';

/**
 * Communal tax multipliers (Steuerfuss / communal tax coefficient) for the
 * ~100 most populous Swiss municipalities.
 *
 * Source: official tax data from the ESTV (Federal Tax Administration) tax
 * calculator, https://swisstaxcalculator.estv.admin.ch/#/taxdata —
 * "IncomeRateCity" field by municipality BFS number,
 * tax year 2026, fetched on 2026-08-06 via the mirror
 * https://github.com/devbrains-com/swisstaxcalculator
 * (data/parsed/2026/factors + locations.json).
 *
 * Spot cross-checks (2026): zh.ch (canton ZH Steuerfüsse),
 * lustat.ch (Luzern 1.45, Kriens 1.85, Emmen 2.15 units),
 * watson/FDP Winterthur (Winterthur 125%), abrechnungen.ch (Bern 154%).
 * Population ranking: Wikipedia "List of cities in Switzerland".
 *
 * Notes:
 * - The multiplier applies to the simplified base cantonal tax from
 *   `canton-tax-rates.ts` (like the average cantonal `communalMultiplier`).
 * - Basel (BS) = 0: communal tax merged with cantonal tax.
 * - Appenzell Ausserrhoden (Herisau 410%): very low cantonal base, high
 *   multipliers — actual values, not an error.
 * - Uncovered municipalities: fall back to the cantonal average
 *   (`resolveCommunalMultiplier`). Annual update required (TODO §6).
 */

/** Tax year for which the multipliers are valid. */
export const COMMUNAL_MULTIPLIERS_TAX_YEAR = 2026;

export interface CommunalMultiplierEntry {
  /** Official municipality name (BFS designation). */
  name: string;
  /** Communal multiplier as % of the base cantonal tax. */
  multiplier: number;
  /** Tax year for which this entry is valid. */
  year: number;
}

/** Index by canton → covered municipalities, sorted alphabetically. */
export const COMMUNAL_MULTIPLIERS: Record<Canton, CommunalMultiplierEntry[]> = {
  ZH: [
    { name: 'Adliswil', multiplier: 104, year: 2026 },
    { name: 'Bülach', multiplier: 114, year: 2026 },
    { name: 'Dietikon', multiplier: 121, year: 2026 },
    { name: 'Dübendorf', multiplier: 92, year: 2026 },
    { name: 'Horgen', multiplier: 90, year: 2026 },
    { name: 'Illnau-Effretikon', multiplier: 113, year: 2026 },
    { name: 'Kloten', multiplier: 100, year: 2026 },
    { name: 'Küsnacht (ZH)', multiplier: 73, year: 2026 },
    { name: 'Meilen', multiplier: 79, year: 2026 },
    { name: 'Opfikon', multiplier: 94, year: 2026 },
    { name: 'Regensdorf', multiplier: 117, year: 2026 },
    { name: 'Richterswil', multiplier: 99, year: 2026 },
    { name: 'Schlieren', multiplier: 111, year: 2026 },
    { name: 'Stäfa', multiplier: 83, year: 2026 },
    { name: 'Thalwil', multiplier: 78, year: 2026 },
    { name: 'Uster', multiplier: 112, year: 2026 },
    { name: 'Volketswil', multiplier: 101, year: 2026 },
    { name: 'Wädenswil', multiplier: 102, year: 2026 },
    { name: 'Wallisellen', multiplier: 93, year: 2026 },
    { name: 'Wetzikon (ZH)', multiplier: 119, year: 2026 },
    { name: 'Winterthur', multiplier: 125, year: 2026 },
    { name: 'Zollikon', multiplier: 76, year: 2026 },
    { name: 'Zürich', multiplier: 119, year: 2026 },
  ],
  BE: [
    { name: 'Bern', multiplier: 154, year: 2026 },
    { name: 'Biel/Bienne', multiplier: 163, year: 2026 },
    { name: 'Burgdorf', multiplier: 163, year: 2026 },
    { name: 'Köniz', multiplier: 158, year: 2026 },
    { name: 'Langenthal', multiplier: 144, year: 2026 },
    { name: 'Lyss', multiplier: 160, year: 2026 },
    { name: 'Ostermundigen', multiplier: 169, year: 2026 },
    { name: 'Steffisburg', multiplier: 162, year: 2026 },
    { name: 'Thun', multiplier: 166, year: 2026 },
  ],
  LU: [
    { name: 'Ebikon', multiplier: 205, year: 2026 },
    { name: 'Emmen', multiplier: 215, year: 2026 },
    { name: 'Horw', multiplier: 140, year: 2026 },
    { name: 'Kriens', multiplier: 185, year: 2026 },
    { name: 'Luzern', multiplier: 145, year: 2026 },
  ],
  UR: [],
  SZ: [
    { name: 'Einsiedeln', multiplier: 170, year: 2026 },
    { name: 'Freienbach', multiplier: 64, year: 2026 },
    { name: 'Schwyz', multiplier: 175, year: 2026 },
  ],
  OW: [],
  NW: [],
  GL: [{ name: 'Glarus Nord', multiplier: 63, year: 2026 }],
  ZG: [
    { name: 'Baar', multiplier: 47.53, year: 2026 },
    { name: 'Cham', multiplier: 54, year: 2026 },
    { name: 'Zug', multiplier: 52, year: 2026 },
  ],
  FR: [
    { name: 'Bulle', multiplier: 74.3, year: 2026 },
    { name: 'Fribourg', multiplier: 80, year: 2026 },
  ],
  SO: [
    { name: 'Grenchen', multiplier: 114.9, year: 2026 },
    { name: 'Olten', multiplier: 108, year: 2026 },
    { name: 'Solothurn', multiplier: 107, year: 2026 },
  ],
  BS: [
    { name: 'Basel', multiplier: 0, year: 2026 },
    { name: 'Riehen', multiplier: 40, year: 2026 },
  ],
  BL: [
    { name: 'Allschwil', multiplier: 58, year: 2026 },
    { name: 'Binningen', multiplier: 49, year: 2026 },
    { name: 'Liestal', multiplier: 65, year: 2026 },
    { name: 'Muttenz', multiplier: 56, year: 2026 },
    { name: 'Pratteln', multiplier: 58.5, year: 2026 },
    { name: 'Reinach (BL)', multiplier: 54.5, year: 2026 },
  ],
  SH: [{ name: 'Schaffhausen', multiplier: 83, year: 2026 }],
  AR: [{ name: 'Herisau', multiplier: 410, year: 2026 }],
  AI: [],
  SG: [
    { name: 'Gossau (SG)', multiplier: 116, year: 2026 },
    { name: 'Rapperswil-Jona', multiplier: 74, year: 2026 },
    { name: 'St. Gallen', multiplier: 138, year: 2026 },
    { name: 'Uzwil', multiplier: 122, year: 2026 },
    { name: 'Wil (SG)', multiplier: 115, year: 2026 },
  ],
  GR: [{ name: 'Chur', multiplier: 88, year: 2026 }],
  AG: [
    { name: 'Aarau', multiplier: 96, year: 2026 },
    { name: 'Baden', multiplier: 92, year: 2026 },
    { name: 'Oftringen', multiplier: 113, year: 2026 },
    { name: 'Rheinfelden', multiplier: 90, year: 2026 },
    { name: 'Wettingen', multiplier: 95, year: 2026 },
    { name: 'Wohlen (AG)', multiplier: 116, year: 2026 },
  ],
  TG: [
    { name: 'Amriswil', multiplier: 158, year: 2026 },
    { name: 'Arbon', multiplier: 177, year: 2026 },
    { name: 'Frauenfeld', multiplier: 144, year: 2026 },
    { name: 'Kreuzlingen', multiplier: 136, year: 2026 },
  ],
  TI: [
    { name: 'Bellinzona', multiplier: 93, year: 2026 },
    { name: 'Locarno', multiplier: 90, year: 2026 },
    { name: 'Lugano', multiplier: 77, year: 2026 },
    { name: 'Mendrisio', multiplier: 77, year: 2026 },
  ],
  VD: [
    { name: 'Lausanne', multiplier: 78.5, year: 2026 },
    { name: 'Montreux', multiplier: 65, year: 2026 },
    { name: 'Morges', multiplier: 67, year: 2026 },
    { name: 'Nyon', multiplier: 61, year: 2026 },
    { name: 'Pully', multiplier: 61, year: 2026 },
    { name: 'Renens (VD)', multiplier: 77, year: 2026 },
    { name: 'Vevey', multiplier: 74.5, year: 2026 },
    { name: 'Yverdon-les-Bains', multiplier: 75, year: 2026 },
  ],
  VS: [
    { name: 'Martigny', multiplier: 110, year: 2026 },
    { name: 'Monthey', multiplier: 120, year: 2026 },
    { name: 'Sierre', multiplier: 120, year: 2026 },
    { name: 'Sion', multiplier: 110, year: 2026 },
  ],
  NE: [
    { name: 'La Chaux-de-Fonds', multiplier: 75, year: 2026 },
    { name: 'Neuchâtel', multiplier: 65, year: 2026 },
  ],
  GE: [
    { name: 'Carouge (GE)', multiplier: 40, year: 2026 },
    { name: 'Genève', multiplier: 45.49, year: 2026 },
    { name: 'Lancy', multiplier: 47, year: 2026 },
    { name: 'Meyrin', multiplier: 42, year: 2026 },
    { name: 'Onex', multiplier: 50.5, year: 2026 },
    { name: 'Thônex', multiplier: 44, year: 2026 },
    { name: 'Vernier', multiplier: 50, year: 2026 },
  ],
  JU: [],
};

/**
 * Normalizes a municipality name for lookup: case-, accent- and
 * separator-insensitive (spaces, hyphens, dots — "St. Gallen" and
 * "St.Gallen" both yield "stgallen").
 */
function normalizeMunicipalityName(name: string): string {
  return name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
}

/** Strips any BFS cantonal suffix ("Wetzikon (ZH)" → "Wetzikon"). */
function stripCantonSuffix(name: string): string {
  return name.replace(/\s*\([A-Z]{2}\)$/, '');
}

// Lookup index by canton: normalized official name + suffix-free alias
// (input "Wetzikon" for "Wetzikon (ZH)").
const LOOKUP = new Map<string, Map<string, number>>();
for (const [canton, entries] of Object.entries(COMMUNAL_MULTIPLIERS)) {
  const map = new Map<string, number>();
  for (const entry of entries) {
    map.set(normalizeMunicipalityName(entry.name), entry.multiplier);
  }
  for (const entry of entries) {
    const alias = normalizeMunicipalityName(stripCantonSuffix(entry.name));
    if (!map.has(alias)) {
      map.set(alias, entry.multiplier);
    }
  }
  LOOKUP.set(canton, map);
}

/**
 * Applicable communal multiplier: the municipality's if it's covered
 * (case-/accent-/separator-insensitive matching), otherwise the canton's
 * average multiplier (historical behavior). Fallback expected for any
 * uncovered or unspecified municipality.
 */
export function resolveCommunalMultiplier(canton: Canton, municipality?: string): number {
  const cantonAverage = CANTONAL_INCOME_TABLES[canton].averageCommunalMultiplier;
  if (!municipality) return cantonAverage;
  return LOOKUP.get(canton)?.get(normalizeMunicipalityName(municipality)) ?? cantonAverage;
}

/** Covered municipalities for a canton (client picker), sorted alphabetically. */
export function getMunicipalitiesForCanton(canton: Canton): { name: string; multiplier: number }[] {
  return COMMUNAL_MULTIPLIERS[canton].map(({ name, multiplier }) => ({ name, multiplier }));
}
