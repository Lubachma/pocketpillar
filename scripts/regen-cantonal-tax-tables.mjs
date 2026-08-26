#!/usr/bin/env node
/**
 * Annual regeneration of the cantonal tax tables from the OFFICIAL
 * FTA (Federal Tax Administration) tax calculator (https://swisstaxcalculator.estv.admin.ch —
 * API delegate/ost-integration/v1/lg-proxy/operation/c3b67379_ESTV, POST JSON,
 * no auth, all values in WHOLE CHF).
 *
 * Two files produced (in CENTIMES, ×100 relative to the API):
 * - src/lib/constants/cantonal-income-tables.ts: SIMPLE cantonal tax
 *   (IncomeSimpleTaxCanton) sampled at each canton's capital over
 *   an income grid, for the single bracket (points, Relationship=1) and
 *   married bracket (pointsMarried, Relationship=2), plus cantonFuss (IncomeTaxCanton /
 *   IncomeSimpleTaxCanton at 100'000), churchFactor (IncomeTaxChurch /
 *   (IncomeTaxCanton + IncomeTaxCity) at 100'000, reformed confession) and
 *   averageCommunalMultiplier (carried over from canton-tax-rates.ts — reference
 *   cantonal average, not recomputed here).
 * - src/lib/constants/capital-withdrawal-tables.ts: tax on capital
 *   withdrawal (fed = TaxFed, rest = TaxCanton + TaxCity at the capital) by canton
 *   and marital status, plus refCanton500k / refCity500k (canton/
 *   municipality breakdown at the 500'000 single amount, for reference) and capitalMunicipality
 *   (BfsName of the capital in the capital response — basis for the communal ratio
 *   at runtime; an anomaly is flagged if this name is not covered by
 *   communal-multipliers.ts).
 *
 * Cantonal capitals resolved via API_searchLocation (exact match on
 * City/BfsName + canton code); capital tables via API_calculateManyCapitalTaxes
 * (TaxGroupID ≠ canton's BFS number — discovered by: for id 1..26, Capital 10'000,
 * read response[0].Location.Canton). Coverage of communal-multipliers.ts
 * is checked read-only (via parseTable from regen-communal-multipliers.mjs).
 *
 * Usage:
 *   node scripts/regen-cantonal-tax-tables.mjs           (writes both files)
 *   node scripts/regen-cantonal-tax-tables.mjs --check   (writes nothing: replays
 *                                                         the anchors, exit 1 on drift)
 *   node scripts/regen-cantonal-tax-tables.mjs --help
 *
 * Exit codes: 0 = OK · 1 = --check with drift · 2 = error (usage,
 * API unreachable after retries, invalid data, capital not found).
 *
 * Safeguards:
 * - Throttle ≤ 5 requests/s, retry ×3 with backoff (1s/2s/4s), hard failure =
 *   clear message (operation + context).
 * - ATOMIC write (temp file then rename) only once ALL
 *   data has been collected — never a partial file.
 * - Non-numeric/negative tax value, capital missing from a response:
 *   refuses to write, exit 2.
 *
 * After a regeneration: npm run typecheck && npm test.
 */
import { readFile, rename, writeFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import { parseTable } from './regen-communal-multipliers.mjs';

/** Sampled tax year (bump annually: regenerate then --check). */
export const TAX_YEAR = 2026;

/** FTA API base (operation appended to the path). */
export const API_BASE =
  'https://swisstaxcalculator.estv.admin.ch/delegate/ost-integration/v1/lg-proxy/operation/c3b67379_ESTV';

/** Regenerated files (paths resolved relative to this script). */
export const INCOME_TARGET_FILE = new URL(
  '../src/lib/constants/cantonal-income-tables.ts',
  import.meta.url,
);
export const CAPITAL_TARGET_FILE = new URL(
  '../src/lib/constants/capital-withdrawal-tables.ts',
  import.meta.url,
);

/** Communal coverage read for capitalMunicipality (read-only). */
export const COMMUNAL_MULTIPLIERS_FILE = new URL(
  '../src/lib/constants/communal-multipliers.ts',
  import.meta.url,
);

/** Cantons (order = Prisma Canton enum) and their capital (search name). */
export const CANTON_CAPITALS = [
  { code: 'ZH', name: 'Zürich' },
  { code: 'BE', name: 'Bern' },
  { code: 'LU', name: 'Luzern' },
  { code: 'UR', name: 'Altdorf' },
  { code: 'SZ', name: 'Schwyz' },
  { code: 'OW', name: 'Sarnen' },
  { code: 'NW', name: 'Stans' },
  { code: 'GL', name: 'Glarus' },
  { code: 'ZG', name: 'Zug' },
  { code: 'FR', name: 'Fribourg' },
  { code: 'SO', name: 'Solothurn' },
  { code: 'BS', name: 'Basel' },
  { code: 'BL', name: 'Liestal' },
  { code: 'SH', name: 'Schaffhausen' },
  { code: 'AR', name: 'Herisau' },
  { code: 'AI', name: 'Appenzell' },
  { code: 'SG', name: 'St. Gallen' },
  { code: 'GR', name: 'Chur' },
  { code: 'AG', name: 'Aarau' },
  { code: 'TG', name: 'Frauenfeld' },
  { code: 'TI', name: 'Bellinzona' },
  { code: 'VD', name: 'Lausanne' },
  { code: 'VS', name: 'Sion' },
  { code: 'NE', name: 'Neuchâtel' },
  { code: 'GE', name: 'Genève' },
  { code: 'JU', name: 'Delémont' },
];

/**
 * Cantonal averages of the communal multipliers (%), carried over from
 * canton-tax-rates.ts (communalMultiplier field) — the script does NOT recompute
 * an average: the capital's value is not representative of the canton.
 */
export const AVERAGE_COMMUNAL_MULTIPLIERS = {
  ZH: 119,
  BE: 150,
  LU: 110,
  UR: 100,
  SZ: 100,
  OW: 95,
  NW: 90,
  GL: 100,
  ZG: 60,
  FR: 85,
  SO: 115,
  BS: 0, // Basel-Stadt: unified tax (no separate communal rate)
  BL: 55,
  SH: 95,
  AR: 100,
  AI: 80,
  SG: 115,
  GR: 100,
  AG: 105,
  TG: 110,
  TI: 80,
  VD: 75,
  VS: 120,
  NE: 80,
  GE: 45,
  JU: 95,
};

/**
 * Income grid (CHF): 0, then 1'000→150'000 in steps of 1'000, then
 * 155'000→300'000 in steps of 5'000, then wide steps up to 5'000'000.
 */
export const INCOME_GRID = (() => {
  const grid = [0];
  for (let i = 1_000; i <= 150_000; i += 1_000) grid.push(i);
  for (let i = 155_000; i <= 300_000; i += 5_000) grid.push(i);
  grid.push(400_000, 500_000, 750_000, 1_000_000, 1_500_000, 2_000_000, 3_000_000, 5_000_000);
  return grid;
})();

/** Sampled capital withdrawal amounts (CHF). */
export const CAPITAL_AMOUNTS = [
  10_000, 25_000, 50_000, 75_000, 100_000, 150_000, 200_000, 300_000, 400_000, 500_000, 600_000,
  800_000, 1_000_000, 1_500_000, 2_000_000,
];

/** API contract constants. */
const REL_SINGLE = 1;
const REL_MARRIED = 2;
const CONFESSION_REFORMED = 1;
const CONFESSION_NONE = 4;
const LANGUAGE_FR = 2;

/** Reference income for cantonFuss / churchFactor / anchors (CHF). */
const REF_INCOME = 100_000;
/** Reference capital amount for refCanton500k / refCity500k and the ZH anchor. */
const REF_CAPITAL = 500_000;

/** --check anchors (contract validated on 2026-08-12). */
const ANCHOR_ZH_TAX_LOCATION_ID = 800_000_000; // Zürich (BfsID 261)
const ANCHOR_ZH_TAX_GROUP_ID = 26; // TaxGroupID ≠ canton's BFS number
const ANCHOR_ZH_BFS_ID = 261;
const ANCHOR_ZH_MARRIED_SIMPLE_100K = 4743; // married bracket (Relationship=2), sampled on 2026-08-12

/** Network timeout per request (the script is a batch tool, not a service). */
const FETCH_TIMEOUT_MS = 30_000;
/** Minimum interval between request starts: ≤ 5 req/s. */
const MIN_INTERVAL_MS = 200;
/** Retries after the 1st attempt (backoff 1s/2s/4s), then hard failure. */
const MAX_RETRIES = 3;
/** Progress display frequency (in successful requests). */
const PROGRESS_EVERY = 26;

/**
 * Normalization for municipality matching: case-insensitive, accent-insensitive,
 * and insensitive to any separator (same approach as regen-communal-multipliers).
 */
export function normalizeName(name) {
  return name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
}

/**
 * Picks the capital's entry in the API_searchLocation response:
 * exact match (normalized City or BfsName) within the right canton;
 * otherwise falls back to the canton's 1st entry (fallback: true — to be flagged).
 * → { entry, fallback } or null if the canton is absent from the response.
 */
export function resolveChefLieu(results, cantonCode, name) {
  const inCanton = (Array.isArray(results) ? results : []).filter((r) => r?.Canton === cantonCode);
  const wanted = normalizeName(name);
  const exact = inCanton.find(
    (r) =>
      normalizeName(String(r?.City ?? '')) === wanted ||
      normalizeName(String(r?.BfsName ?? '')) === wanted,
  );
  if (exact) return { entry: exact, fallback: false };
  if (inCanton.length > 0) return { entry: inCanton[0], fallback: true };
  return null;
}

/** API_calculateSimpleTaxes payload (same income for canton/federal, wealth 0). */
export function simpleTaxesPayload(taxLocationID, income, { relationship, confession } = {}) {
  return {
    SimKey: null,
    TaxYear: TAX_YEAR,
    TaxLocationID: taxLocationID,
    Relationship: relationship ?? REL_SINGLE,
    Confession1: confession ?? CONFESSION_NONE,
    Children: [],
    Confession2: 0,
    TaxableIncomeCanton: income,
    TaxableIncomeFed: income,
    TaxableFortune: 0,
  };
}

/** API_calculateManyCapitalTaxes payload (all municipalities of the canton). */
export function manyCapitalTaxesPayload(taxGroupID, relationship, capital) {
  return {
    TaxYear: TAX_YEAR,
    TaxGroupID: taxGroupID,
    Relationship: relationship,
    Confession1: CONFESSION_NONE,
    Capital: capital,
  };
}

/** API_searchLocation payload. */
export function searchLocationPayload(search) {
  return { Search: search, Language: LANGUAGE_FR, TaxYear: TAX_YEAR };
}

/** Validates a tax value from the API (finite number ≥ 0) or refuses to continue. */
function readTax(value, label) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) {
    throw new Error(`Invalid tax value — ${label}: ${JSON.stringify(value)}`);
  }
  return value;
}

/** Validates a numeric identifier from the API (TaxLocationID, BfsID…). */
function readId(value, label) {
  if (typeof value !== 'number' || !Number.isInteger(value) || value < 0) {
    throw new Error(`Invalid identifier — ${label}: ${JSON.stringify(value)}`);
  }
  return value;
}

/** Ratio rounded to 4 decimals (0 if the denominator is zero — requested upstream). */
export function ratio4(numerator, denominator) {
  if (denominator === 0) return 0;
  return Math.round((numerator / denominator) * 10_000) / 10_000;
}

/** Canonical rendering of a ratio (String of a rounded Number — deterministic). */
const fmtRatio = (x) => String(x);

/** TS string literal in the project's Prettier format (single quotes, escaped). */
const tsString = (s) => `'${String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;

/**
 * API client: throttle (≤ 5 req/s between request starts), retry ×3 with
 * backoff, counter + progress. Hard failure = Error with operation + context.
 */
function createApi({ fetchImpl, sleepImpl, log, expectedTotal }) {
  let count = 0;
  let nextStartAt = 0;
  let lastContext = '';
  const startedAt = Date.now();

  async function call(operation, payload, context) {
    lastContext = context;
    let lastErr;
    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
      if (attempt > 0) await sleepImpl(1_000 * 2 ** (attempt - 1));
      const wait = nextStartAt - Date.now();
      if (wait > 0) await sleepImpl(wait);
      nextStartAt = Date.now() + MIN_INTERVAL_MS;
      try {
        const res = await fetchImpl(`${API_BASE}/${operation}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
          signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        if (data == null || typeof data !== 'object' || !('response' in data)) {
          throw new Error('JSON response with no "response" field');
        }
        count += 1;
        if (count % PROGRESS_EVERY === 0) {
          const elapsed = Math.round((Date.now() - startedAt) / 1000);
          log(`  progress: ${count}/${expectedTotal} requests (${elapsed}s) — ${lastContext}`);
        }
        return data;
      } catch (err) {
        lastErr = err;
      }
    }
    throw new Error(
      `Final failure after ${MAX_RETRIES + 1} attempts — ${operation} (${context}): ` +
        `${lastErr?.message ?? lastErr}`,
    );
  }

  return { call, getCount: () => count };
}

/** Phase 1: resolving canton capitals → Map<code, { taxLocationID, bfsID }>. */
async function resolveAllChefLieux(api, anomalies) {
  const chefLieux = new Map();
  for (const { code, name } of CANTON_CAPITALS) {
    const data = await api.call(
      'API_searchLocation',
      searchLocationPayload(name),
      `searchLocation ${name} (${code})`,
    );
    const resolved = resolveChefLieu(data.response, code, name);
    if (!resolved) {
      throw new Error(`Capital not found via API_searchLocation: "${name}" (${code}).`);
    }
    const { entry, fallback } = resolved;
    const bfsID = readId(entry.BfsID, `BfsID ${name}`);
    const taxLocationID = readId(entry.TaxLocationID, `TaxLocationID ${name}`);
    if (fallback) {
      anomalies.push(
        `${code} · ${name}: no exact match — falling back to ` +
          `"${entry.City || entry.BfsName}" (BfsID ${bfsID}).`,
      );
    }
    chefLieux.set(code, { taxLocationID, bfsID });
  }
  return chefLieux;
}

/** Phase 2: discovering the canton → TaxGroupID mapping (1..26). */
async function discoverTaxGroupIds(api) {
  const groupIds = new Map();
  for (let id = 1; id <= CANTON_CAPITALS.length; id++) {
    const data = await api.call(
      'API_calculateManyCapitalTaxes',
      manyCapitalTaxesPayload(id, REL_SINGLE, 10_000),
      `TaxGroupID discovery ${id}`,
    );
    const canton = data.response?.[0]?.Location?.Canton;
    if (typeof canton !== 'string' || !/^[A-Z]{2}$/.test(canton)) {
      throw new Error(
        `TaxGroupID discovery ${id}: unreadable canton in response[0].Location.Canton.`,
      );
    }
    groupIds.set(canton, id);
  }
  const missing = CANTON_CAPITALS.filter((c) => !groupIds.has(c.code)).map((c) => c.code);
  if (missing.length > 0) {
    throw new Error(`TaxGroupID not found for: ${missing.join(', ')}.`);
  }
  return groupIds;
}

/** Phase 3: income sampling (single + married) + cantonFuss + churchFactor per canton. */
async function collectIncomeTables(api, chefLieux) {
  const tables = [];
  for (const { code } of CANTON_CAPITALS) {
    const { taxLocationID } = chefLieux.get(code);
    const points = [];
    const pointsMarried = [];
    let simpleAtRef = null;
    let effectiveAtRef = null;
    for (const income of INCOME_GRID) {
      const data = await api.call(
        'API_calculateSimpleTaxes',
        simpleTaxesPayload(taxLocationID, income),
        `income ${income} @ ${code}`,
      );
      const r = data.response ?? {};
      const simple = readTax(r.IncomeSimpleTaxCanton, `IncomeSimpleTaxCanton @ ${code}/${income}`);
      points.push({ i: income * 100, t: simple * 100 });
      if (income === REF_INCOME) {
        simpleAtRef = simple;
        effectiveAtRef = readTax(r.IncomeTaxCanton, `IncomeTaxCanton @ ${code}/${income}`);
      }
      const dataMarried = await api.call(
        'API_calculateSimpleTaxes',
        simpleTaxesPayload(taxLocationID, income, { relationship: REL_MARRIED }),
        `married income ${income} @ ${code}`,
      );
      const rm = dataMarried.response ?? {};
      const simpleMarried = readTax(
        rm.IncomeSimpleTaxCanton,
        `IncomeSimpleTaxCanton married @ ${code}/${income}`,
      );
      pointsMarried.push({ i: income * 100, t: simpleMarried * 100 });
    }
    const churchData = await api.call(
      'API_calculateSimpleTaxes',
      simpleTaxesPayload(taxLocationID, REF_INCOME, { confession: CONFESSION_REFORMED }),
      `reformed denomination @ ${code}`,
    );
    const cr = churchData.response ?? {};
    const church = readTax(cr.IncomeTaxChurch, `IncomeTaxChurch @ ${code}`);
    const churchCanton = readTax(cr.IncomeTaxCanton, `IncomeTaxCanton (ref.) @ ${code}`);
    const churchCity = readTax(cr.IncomeTaxCity, `IncomeTaxCity (ref.) @ ${code}`);
    tables.push({
      code,
      cantonFuss: ratio4(effectiveAtRef, simpleAtRef),
      churchFactor: ratio4(church, churchCanton + churchCity),
      averageCommunalMultiplier: AVERAGE_COMMUNAL_MULTIPLIERS[code],
      points,
      pointsMarried,
    });
  }
  return tables;
}

/** Phase 4: capital withdrawals (single + married) at the capital, per canton. */
async function collectCapitalTables(api, chefLieux, groupIds) {
  const tables = [];
  for (const { code } of CANTON_CAPITALS) {
    const { bfsID } = chefLieux.get(code);
    const taxGroupID = groupIds.get(code);
    const perRelationship = new Map();
    let refCanton500k = null;
    let refCity500k = null;
    let capitalMunicipality = null;
    for (const relationship of [REL_SINGLE, REL_MARRIED]) {
      const points = [];
      for (const amount of CAPITAL_AMOUNTS) {
        const data = await api.call(
          'API_calculateManyCapitalTaxes',
          manyCapitalTaxesPayload(taxGroupID, relationship, amount),
          `capital ${amount} @ ${code} (${relationship === REL_SINGLE ? 'single' : 'married'})`,
        );
        const rows = Array.isArray(data.response) ? data.response : [];
        const line = rows.find((row) => row?.Location?.BfsID === bfsID);
        if (!line) {
          throw new Error(
            `Capital BfsID ${bfsID} missing from the capital response @ ${code} ` +
              `(amount ${amount}, relationship ${relationship}).`,
          );
        }
        if (capitalMunicipality === null) {
          capitalMunicipality = String(line.Location?.BfsName ?? '');
        }
        const fed = readTax(line.TaxFed, `TaxFed @ ${code}/${amount}`);
        const canton = readTax(line.TaxCanton, `TaxCanton @ ${code}/${amount}`);
        const city = readTax(line.TaxCity, `TaxCity @ ${code}/${amount}`);
        points.push({ a: amount * 100, fed: fed * 100, rest: (canton + city) * 100 });
        if (relationship === REL_SINGLE && amount === REF_CAPITAL) {
          refCanton500k = canton * 100;
          refCity500k = city * 100;
        }
      }
      perRelationship.set(relationship, points);
    }
    tables.push({
      code,
      single: perRelationship.get(REL_SINGLE),
      married: perRelationship.get(REL_MARRIED),
      refCanton500k,
      refCity500k,
      capitalMunicipality,
    });
  }
  return tables;
}

/**
 * Read-only check: flags canton capitals whose
 * capitalMunicipality is not covered by communal-multipliers.ts (the
 * runtime then falls back to the cantonal average for the communal ratio).
 */
async function reportCommunalCoverage(capitalTables, anomalies) {
  let parsed;
  try {
    parsed = parseTable(await readFile(COMMUNAL_MULTIPLIERS_FILE, 'utf8'));
  } catch (err) {
    anomalies.push(`communal coverage unreadable — check skipped: ${err.message}`);
    return;
  }
  const covered = new Map(
    parsed.cantons.map((c) => [c.code, new Set(c.entries.map((e) => normalizeName(e.name)))]),
  );
  for (const t of capitalTables) {
    const names = covered.get(t.code) ?? new Set();
    if (!names.has(normalizeName(t.capitalMunicipality))) {
      anomalies.push(
        `${t.code} · ${t.capitalMunicipality}: capital not covered by communal-multipliers.ts — ` +
          'the communal ratio for the capital withdrawal will use the cantonal average.',
      );
    }
  }
}

/** Common header of the generated files. */
function renderHeader(taxYear, fetchDate, unitLine) {
  return [
    `/**`,
    ` * GENERATED by scripts/regen-cantonal-tax-tables.mjs on ${fetchDate} — do not edit.`,
    ` * Source: official FTA (Federal Tax Administration) tax calculator (swisstaxcalculator.estv.admin.ch), tax year ${taxYear}.`,
    ` * ${unitLine}`,
    ` */`,
  ].join('\n');
}

/** Full content of cantonal-income-tables.ts (the project's Prettier format). */
export function renderIncomeTablesFile(tables, { taxYear, fetchDate }) {
  const lines = [];
  lines.push(`import type { Canton } from '@prisma/client';`);
  lines.push(``);
  lines.push(
    renderHeader(
      taxYear,
      fetchDate,
      'i/t in centimes. t = SIMPLE cantonal tax (statutory base before multipliers).',
    ),
  );
  lines.push(`export const CANTONAL_TAX_TABLES_TAX_YEAR = ${taxYear};`);
  lines.push(``);
  lines.push(`export interface CantonIncomePoint {`);
  lines.push(`  i: number;`);
  lines.push(`  t: number;`);
  lines.push(`}`);
  lines.push(``);
  lines.push(`export interface CantonIncomeTable {`);
  lines.push(
    `  cantonFuss: number; // IncomeTaxCanton / IncomeSimpleTaxCanton (cantonal steuerfuss, rebate included)`,
  );
  lines.push(
    `  churchFactor: number; // IncomeTaxChurch / (IncomeTaxCanton + IncomeTaxCity) at the cantonal capital, reformed denomination`,
  );
  lines.push(
    `  averageCommunalMultiplier: number; // carried over from canton-tax-rates.ts (communal fallback)`,
  );
  lines.push(`  points: CantonIncomePoint[];`);
  lines.push(`  pointsMarried: CantonIncomePoint[]; // married schedule (same table)`);
  lines.push(`}`);
  lines.push(``);
  lines.push(`export const CANTONAL_INCOME_TABLES: Record<Canton, CantonIncomeTable> = {`);
  for (const t of tables) {
    lines.push(`  ${t.code}: {`);
    lines.push(`    cantonFuss: ${fmtRatio(t.cantonFuss)},`);
    lines.push(`    churchFactor: ${fmtRatio(t.churchFactor)},`);
    lines.push(`    averageCommunalMultiplier: ${t.averageCommunalMultiplier},`);
    lines.push(`    points: [`);
    for (const p of t.points) lines.push(`      { i: ${p.i}, t: ${p.t} },`);
    lines.push(`    ],`);
    lines.push(`    pointsMarried: [`);
    for (const p of t.pointsMarried) lines.push(`      { i: ${p.i}, t: ${p.t} },`);
    lines.push(`    ],`);
    lines.push(`  },`);
  }
  lines.push(`};`);
  lines.push(``);
  return lines.join('\n');
}

/** Full content of capital-withdrawal-tables.ts (the project's Prettier format). */
export function renderCapitalTablesFile(tables, { taxYear, fetchDate }) {
  const lines = [];
  lines.push(`import type { Canton } from '@prisma/client';`);
  lines.push(``);
  lines.push(
    renderHeader(
      taxYear,
      fetchDate,
      'a/fed/rest in centimes. rest = cantonal + communal tax at the cantonal capital; fed = federal tax.',
    ),
  );
  lines.push(`export const CAPITAL_TAX_TABLES_TAX_YEAR = ${taxYear};`);
  lines.push(``);
  lines.push(`export interface CapitalTaxPoint {`);
  lines.push(`  a: number;`);
  lines.push(`  fed: number;`);
  lines.push(`  rest: number;`);
  lines.push(`}`);
  lines.push(``);
  lines.push(`export interface CantonCapitalTaxTable {`);
  lines.push(`  single: CapitalTaxPoint[];`);
  lines.push(`  married: CapitalTaxPoint[];`);
  lines.push(`  refCanton500k: number;`);
  lines.push(`  refCity500k: number;`);
  lines.push(`  capitalMunicipality: string; // BfsName of the cantonal capital (communal lookup)`);
  lines.push(`}`);
  lines.push(``);
  lines.push(`export const CAPITAL_WITHDRAWAL_TABLES: Record<Canton, CantonCapitalTaxTable> = {`);
  for (const t of tables) {
    lines.push(`  ${t.code}: {`);
    lines.push(`    single: [`);
    for (const p of t.single) lines.push(`      { a: ${p.a}, fed: ${p.fed}, rest: ${p.rest} },`);
    lines.push(`    ],`);
    lines.push(`    married: [`);
    for (const p of t.married) lines.push(`      { a: ${p.a}, fed: ${p.fed}, rest: ${p.rest} },`);
    lines.push(`    ],`);
    lines.push(`    refCanton500k: ${t.refCanton500k},`);
    lines.push(`    refCity500k: ${t.refCity500k},`);
    lines.push(`    capitalMunicipality: ${tsString(t.capitalMunicipality)},`);
    lines.push(`  },`);
  }
  lines.push(`};`);
  lines.push(``);
  return lines.join('\n');
}

/**
 * Atomic write: temp file next to the target then rename —
 * never a truncated target file if the process dies mid-write.
 */
export async function atomicWriteFile(file, content) {
  const tmp = new URL(`${file.href}.tmp-${process.pid}`);
  await writeFile(tmp, content, 'utf8');
  await rename(tmp, file);
}

/**
 * API contract anchors (--check): replays the values validated when
 * the script was introduced and flags any drift.
 * → list of { label, expected, actual, ok } (ok=false = drift).
 */
export async function runChecks(api) {
  const results = [];
  const record = (label, expected, actual, ok) => results.push({ label, expected, actual, ok });
  const eq = (label, actual, expected) => record(label, String(expected), String(actual), actual === expected);
  const within = (label, actual, expected, tolerance) =>
    record(
      label,
      `${expected} ±${tolerance}`,
      String(actual),
      typeof actual === 'number' && Math.abs(actual - expected) <= tolerance,
    );

  // ZH 2026 @100k (exact anchor from the validated contract).
  const zh = await api.call(
    'API_calculateSimpleTaxes',
    simpleTaxesPayload(ANCHOR_ZH_TAX_LOCATION_ID, REF_INCOME),
    'ZH anchor income 100k',
  );
  const zr = zh.response ?? {};
  eq('ZH @100k · simple cantonal tax', zr.IncomeSimpleTaxCanton, 6170);
  eq('ZH @100k · effective cantonal tax', zr.IncomeTaxCanton, 5862);
  eq('ZH @100k · federal tax', zr.IncomeTaxFed, 2684);

  // ZH married @100k (Relationship=2 bracket — covers the pointsMarried path).
  const zhMarried = await api.call(
    'API_calculateSimpleTaxes',
    simpleTaxesPayload(ANCHOR_ZH_TAX_LOCATION_ID, REF_INCOME, { relationship: REL_MARRIED }),
    'ZH anchor married income 100k',
  );
  eq(
    'ZH married @100k · simple cantonal tax',
    zhMarried.response?.IncomeSimpleTaxCanton,
    ANCHOR_ZH_MARRIED_SIMPLE_100K,
  );

  // ZH single capital 500k → Zürich row (BfsID 261), fed 10501 ±2.
  const cap = await api.call(
    'API_calculateManyCapitalTaxes',
    manyCapitalTaxesPayload(ANCHOR_ZH_TAX_GROUP_ID, REL_SINGLE, REF_CAPITAL),
    'ZH anchor capital 500k',
  );
  const zhLine = (Array.isArray(cap.response) ? cap.response : []).find(
    (row) => row?.Location?.BfsID === ANCHOR_ZH_BFS_ID,
  );
  within('ZH single capital 500k · federal tax', zhLine?.TaxFed, 10_501, 2);

  // GE / VD: simple tax @100k at the capital (±20).
  for (const { code, name, expected } of [
    { code: 'GE', name: 'Genève', expected: 10_177 },
    { code: 'VD', name: 'Lausanne', expected: 8_677 },
  ]) {
    const found = await api.call(
      'API_searchLocation',
      searchLocationPayload(name),
      `${code} anchor searchLocation`,
    );
    const resolved = resolveChefLieu(found.response, code, name);
    if (!resolved) {
      record(`${code} @100k · simple cantonal tax`, String(expected), 'capital not found', false);
      continue;
    }
    const data = await api.call(
      'API_calculateSimpleTaxes',
      simpleTaxesPayload(resolved.entry.TaxLocationID, REF_INCOME),
      `${code} anchor income 100k`,
    );
    within(`${code} @100k · simple cantonal tax`, data.response?.IncomeSimpleTaxCanton, expected, 20);
  }
  return results;
}

const USAGE = `Usage: node scripts/regen-cantonal-tax-tables.mjs [--check]

Regenerates the cantonal tax tables (src/lib/constants/cantonal-income-tables.ts
and capital-withdrawal-tables.ts) from the official FTA tax calculator.
--check: writes nothing, replays the contract anchors (ZH/GE/VD), exit 1 on drift.
Codes: 0 OK · 1 drift (--check) · 2 error.`;

function parseArgs(argv) {
  const opts = { check: false, help: false };
  for (const arg of argv) {
    if (arg === '--check') opts.check = true;
    else if (arg === '--help' || arg === '-h') opts.help = true;
    else throw new Error(`Unknown option: ${arg}`);
  }
  return opts;
}

/** Total number of calls for a full regeneration (for the progress display). */
const EXPECTED_CALLS =
  CANTON_CAPITALS.length * 2 + // canton capitals + TaxGroupID discovery
  CANTON_CAPITALS.length * (INCOME_GRID.length * 2 + 1) + // single+married income + confession
  CANTON_CAPITALS.length * 2 * CAPITAL_AMOUNTS.length; // capital single+married

/**
 * CLI entry point (injectable for tests: fetchImpl / sleepImpl /
 * writeImpl / log / error / today). Returns the exit code.
 */
export async function main(argv, deps = {}) {
  const {
    fetchImpl = fetch,
    sleepImpl = (ms) => new Promise((resolve) => setTimeout(resolve, ms)),
    writeImpl = atomicWriteFile,
    log = (message) => console.log(message),
    error = (message) => console.error(message),
    today = () => new Date().toISOString().slice(0, 10),
  } = deps;

  let opts;
  try {
    opts = parseArgs(argv);
  } catch (err) {
    error(`${err.message}\n\n${USAGE}`);
    return 2;
  }
  if (opts.help) {
    log(USAGE);
    return 0;
  }

  const startedAt = Date.now();
  const api = createApi({ fetchImpl, sleepImpl, log, expectedTotal: EXPECTED_CALLS });

  if (opts.check) {
    let results;
    try {
      results = await runChecks(api);
    } catch (err) {
      error(`--check interrupted: ${err.message}`);
      return 2;
    }
    for (const r of results) {
      log(`${r.ok ? 'OK  ' : 'DRIFT'} · ${r.label}: expected ${r.expected}, got ${r.actual}`);
    }
    const failures = results.filter((r) => !r.ok);
    if (failures.length > 0) {
      log(`${failures.length}/${results.length} anchor(s) drifted — the API changed, regeneration needs manual validation.`);
      return 1;
    }
    log(`${results.length}/${results.length} anchors conform — API contract stable for ${TAX_YEAR}.`);
    return 0;
  }

  log(
    `Cantonal tax tables — FTA source (swisstaxcalculator.estv.admin.ch), ` +
      `tax year ${TAX_YEAR}. ~${EXPECTED_CALLS} requests planned (≤ 5 req/s).`,
  );
  try {
    const anomalies = [];
    const chefLieux = await resolveAllChefLieux(api, anomalies);
    const groupIds = await discoverTaxGroupIds(api);
    const incomeTables = await collectIncomeTables(api, chefLieux);
    const capitalTables = await collectCapitalTables(api, chefLieux, groupIds);
    await reportCommunalCoverage(capitalTables, anomalies);

    const fetchDate = today();
    await writeImpl(
      INCOME_TARGET_FILE,
      renderIncomeTablesFile(incomeTables, { taxYear: TAX_YEAR, fetchDate }),
    );
    await writeImpl(
      CAPITAL_TARGET_FILE,
      renderCapitalTablesFile(capitalTables, { taxYear: TAX_YEAR, fetchDate }),
    );

    const elapsed = Math.round((Date.now() - startedAt) / 1000);
    log(
      `Done: ${api.getCount()} API calls in ${elapsed}s. Files written:\n` +
        `  ${INCOME_TARGET_FILE.pathname}\n  ${CAPITAL_TARGET_FILE.pathname}`,
    );
    if (anomalies.length > 0) {
      log('Anomalies:');
      for (const a of anomalies) log(`  ${a}`);
    } else {
      log('No anomalies (26 capitals resolved via exact match).');
    }
    log('Run: npm run typecheck && npm test.');
    return 0;
  } catch (err) {
    error(`${err.message} Nothing was written (${api.getCount()} calls made).`);
    return 2;
  }
}

const isDirectRun = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isDirectRun) {
  main(process.argv.slice(2)).then(
    (code) => process.exit(code),
    (err) => {
      console.error(err);
      process.exit(2);
    },
  );
}
