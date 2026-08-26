/** Type declarations for regen-communal-multipliers.mjs (zero-dependency ESM script). */

export interface CommunalEntry {
  name: string;
  multiplier: number;
  year: number;
}

export interface CantonSection {
  code: string;
  entries: CommunalEntry[];
}

export interface ParsedTable {
  taxYear: number;
  cantons: CantonSection[];
}

export type UpdateStatus = 'unchanged' | 'changed' | 'missing' | 'out-of-range';

export interface UpdateRow {
  canton: string;
  name: string;
  oldValue: number;
  oldYear: number;
  newValue: number | null;
  status: UpdateStatus;
}

export interface UpdatePlan {
  rows: UpdateRow[];
  nextCantons: CantonSection[];
  errors: string[];
}

/** Record from data/parsed/<year>/locations.json of the ESTV mirror. */
export interface LocationRecord {
  TaxLocationID: number;
  BfsID: number;
  BfsName: string;
  CantonID: number;
  Canton: string;
}

/** Record from data/parsed/<year>/factors/<cantonId>.json of the ESTV mirror. */
export interface FactorRecord {
  IncomeRateCity?: unknown;
  Location?: { BfsID?: unknown };
  [key: string]: unknown;
}

export type Lookup = (canton: string, name: string) => number | null;

export interface MainDeps {
  fetchImpl?: typeof fetch;
  readImpl?: (file: URL) => Promise<string>;
  writeImpl?: (file: URL, content: string) => Promise<unknown>;
  log?: (message: string) => void;
  error?: (message: string) => void;
  today?: () => string;
}

export const TARGET_FILE: URL;
export const SOURCE_BASE_URL: string;
export const MULTIPLIER_MIN: number;
export const MULTIPLIER_MAX: number;

export function normalizeName(name: string): string;
export function parseTable(source: string): ParsedTable;
export function indexLocations(locations: LocationRecord[]): {
  cantonIds: Map<string, number>;
  bfsByName: Map<string, number>;
};
export function indexFactors(factors: FactorRecord[]): Map<number, number>;
export function buildLookup(
  locations: LocationRecord[],
  factorsByCanton: Map<string, FactorRecord[]>,
): Lookup;
export function planUpdates(
  cantons: CantonSection[],
  lookup: Lookup,
  opts: { year: number },
): UpdatePlan;
export function formatDiff(rows: UpdateRow[]): string[];
export function renderTable(cantons: CantonSection[]): string;
export function renderFile(
  source: string,
  nextCantons: CantonSection[],
  opts: { year: number; fetchDate: string },
): string;
export function main(argv: string[], deps?: MainDeps): Promise<number>;
export function atomicWriteFile(file: URL, content: string): Promise<void>;
