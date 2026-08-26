#!/usr/bin/env node
/**
 * Annual regeneration of the communal multipliers
 * (src/lib/constants/communal-multipliers.ts) from the GitHub mirror of
 * ESTV tax data: https://github.com/devbrains-com/swisstaxcalculator
 * (data/parsed/<year>/factors/<cantonId>.json — "IncomeRateCity" field by
 * BFS number — and data/parsed/<year>/locations.json for the mapping
 * municipality name → BFS number → cantonId).
 *
 * The script updates the VALUES of municipalities already covered — it does
 * not change the coverage perimeter (a decision, not an automatism).
 *
 * Usage:
 *   node scripts/regen-communal-multipliers.mjs --year 2027           (writes)
 *   node scripts/regen-communal-multipliers.mjs --year 2027 --check   (writes nothing)
 *   node scripts/regen-communal-multipliers.mjs --help
 *
 * Options:
 *   --year <YYYY>     Tax year of the data to fetch (required).
 *   --check           Modifies no file: exit 0 if the values
 *                     match the source, exit 1 if divergences exist
 *                     (usable as an annual task — deliberately outside CI:
 *                     the external source is not a build dependency).
 *   --base-url <url>  Alternative base (default: raw.githubusercontent.com,
 *                     master branch of the mirror).
 *
 * Exit codes: 0 = OK (check with no divergence / file written / nothing to
 * change) · 1 = --check with divergences · 2 = error (usage, source
 * unreachable or year not published, unexpected file header, implausible
 * value).
 *
 * Safeguards:
 * - Municipality gone from the source (merger…): warning + old value
 *   AND old year kept → the consistency test
 *   tests/lib/communal-multipliers.test.ts (year === TAX_YEAR) will fail until
 *   a human has made a decision.
 * - Implausible value (outside [0, 1000] or not finite): refuses to write, exit 2.
 * - File header not matching the expected format: refuses to write.
 *
 * After a regeneration: npm test && make check.
 */
import { readFile, rename, writeFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

/** Regenerated file (path resolved relative to this script). */
export const TARGET_FILE = new URL('../src/lib/constants/communal-multipliers.ts', import.meta.url);

/** raw.githubusercontent.com base of the mirror (without the year). */
export const SOURCE_BASE_URL =
  'https://raw.githubusercontent.com/devbrains-com/swisstaxcalculator/master/data/parsed';

/** Plausibility bounds for a communal multiplier (% of cantonal tax). */
export const MULTIPLIER_MIN = 0;
export const MULTIPLIER_MAX = 1000;

/** Project's Prettier printWidth — aligns generated formatting with `make check`. */
const PRINT_WIDTH = 100;

/**
 * Normalization identical to `normalizeMunicipalityName` from the target module:
 * case-insensitive, accent-insensitive, and insensitive to any separator.
 */
export function normalizeName(name) {
  return name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
}

/** Locates the COMMUNAL_MULTIPLIERS table in the TS source. */
function locateTable(source) {
  const tableStart = source.indexOf('export const COMMUNAL_MULTIPLIERS:');
  if (tableStart === -1) {
    throw new Error('Declaration "export const COMMUNAL_MULTIPLIERS:" not found.');
  }
  const openBrace = source.indexOf('{', tableStart);
  const tableEnd = source.indexOf('\n};', openBrace);
  if (openBrace === -1 || tableEnd === -1) {
    throw new Error('Bounds of the COMMUNAL_MULTIPLIERS table not found.');
  }
  return { openBrace, tableEnd };
}

const unescapeName = (name) => name.replace(/\\(.)/g, '$1');
const escapeName = (name) => name.replace(/\\/g, '\\\\').replace(/'/g, "\\'");

const ENTRY_RE = /^    \{ name: '((?:[^'\\]|\\.)*)', multiplier: (\d+(?:\.\d+)?), year: (\d+) \},$/;
const INLINE_RE =
  /^  ([A-Z]{2}): \[\{ name: '((?:[^'\\]|\\.)*)', multiplier: (\d+(?:\.\d+)?), year: (\d+) \}\],$/;

/**
 * Parses the table from the current TS file.
 * → { taxYear, cantons: [{ code, entries: [{ name, multiplier, year }] }] }
 * The order of cantons and municipalities is preserved (current sort order of the file).
 */
export function parseTable(source) {
  const taxYearMatch = source.match(/export const COMMUNAL_MULTIPLIERS_TAX_YEAR = (\d+);/);
  if (!taxYearMatch) {
    throw new Error('"COMMUNAL_MULTIPLIERS_TAX_YEAR = <year>;" not found.');
  }
  const { openBrace, tableEnd } = locateTable(source);
  const body = source.slice(openBrace + 1, tableEnd);
  const cantons = [];
  let current = null;
  const lines = body.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.trim() === '') continue;
    let m = line.match(/^  ([A-Z]{2}): \[\],$/);
    if (m) {
      cantons.push({ code: m[1], entries: [] });
      continue;
    }
    m = line.match(/^  ([A-Z]{2}): \[$/);
    if (m) {
      current = { code: m[1], entries: [] };
      cantons.push(current);
      continue;
    }
    if (line === '  ],') {
      if (!current) throw new Error(`Table body, line ${i + 1}: orphan "],".`);
      current = null;
      continue;
    }
    m = line.match(INLINE_RE);
    if (m) {
      cantons.push({
        code: m[1],
        entries: [{ name: unescapeName(m[2]), multiplier: Number(m[3]), year: Number(m[4]) }],
      });
      continue;
    }
    m = line.match(ENTRY_RE);
    if (m) {
      if (!current) {
        throw new Error(`Table body, line ${i + 1}: entry outside canton section: ${line}`);
      }
      current.entries.push({ name: unescapeName(m[1]), multiplier: Number(m[2]), year: Number(m[3]) });
      continue;
    }
    throw new Error(`Table body, unexpected line ${i + 1}: ${line}`);
  }
  if (current) throw new Error(`Canton section "${current.code}" never closed.`);
  return { taxYear: Number(taxYearMatch[1]), cantons };
}

/**
 * Indexes locations.json from the mirror.
 * → { cantonIds: Map<canton → cantonId>, bfsByName: Map<"canton|normalized name" → bfsId> }
 */
export function indexLocations(locations) {
  const cantonIds = new Map();
  const bfsByName = new Map();
  for (const loc of locations) {
    cantonIds.set(loc.Canton, loc.CantonID);
    bfsByName.set(`${loc.Canton}|${normalizeName(loc.BfsName)}`, loc.BfsID);
  }
  return { cantonIds, bfsByName };
}

/**
 * Indexes a factors/<cantonId>.json file from the mirror.
 * → Map<bfsId → IncomeRateCity> (malformed entries ignored).
 * The mirror contains floating-point serialization noise
 * ("IncomeRateCity: 204.99999999999997" for 205); Steuerfüsse are
 * published with at most 2 decimals (Genève 45.49, Baar 47.53) → rounded to
 * 2 decimals on ingestion.
 */
export function indexFactors(factors) {
  const map = new Map();
  for (const f of factors) {
    const bfs = f?.Location?.BfsID;
    const rate = f?.IncomeRateCity;
    if (typeof bfs === 'number' && typeof rate === 'number') {
      map.set(bfs, Math.round(rate * 100) / 100);
    }
  }
  return map;
}

/**
 * Builds the lookup (canton, name) → source multiplier, or null if the
 * municipality is not found in locations.json / missing from the factors.
 */
export function buildLookup(locations, factorsByCanton) {
  const { bfsByName } = indexLocations(locations);
  const rateByCanton = new Map();
  for (const [canton, factors] of factorsByCanton) {
    rateByCanton.set(canton, indexFactors(factors));
  }
  return (canton, name) => {
    const bfs = bfsByName.get(`${canton}|${normalizeName(name)}`);
    if (bfs === undefined) return null;
    const rate = rateByCanton.get(canton)?.get(bfs);
    return rate === undefined ? null : rate;
  };
}

/**
 * Compares the current table to the source and plans the update.
 * lookup: (canton, name) → number | null (null = municipality gone from the source).
 * → { rows, nextCantons, errors }
 *   rows[].status: 'unchanged' | 'changed' | 'missing' | 'out-of-range'
 *   missing/out-of-range: old entry kept as-is (year included);
 *   out-of-range adds an error (refuses to write).
 */
export function planUpdates(cantons, lookup, { year }) {
  const rows = [];
  const errors = [];
  const nextCantons = cantons.map(({ code, entries }) => ({
    code,
    entries: entries.map((entry) => {
      const base = { canton: code, name: entry.name, oldValue: entry.multiplier, oldYear: entry.year };
      const found = lookup(code, entry.name);
      if (found === null) {
        rows.push({ ...base, newValue: null, status: 'missing' });
        return entry;
      }
      if (!Number.isFinite(found) || found < MULTIPLIER_MIN || found > MULTIPLIER_MAX) {
        rows.push({ ...base, newValue: found, status: 'out-of-range' });
        errors.push(
          `${code} · ${entry.name}: implausible source value (${found}) outside ` +
            `[${MULTIPLIER_MIN}, ${MULTIPLIER_MAX}] — write refused.`,
        );
        return entry;
      }
      rows.push({
        ...base,
        newValue: found,
        status: found === entry.multiplier ? 'unchanged' : 'changed',
      });
      return { name: entry.name, multiplier: found, year };
    }),
  }));
  return { rows, nextCantons, errors };
}

const formatMultiplier = (m) => String(m);

/** Human-readable diff lines (changes, disappearances, implausible values). */
export function formatDiff(rows) {
  const lines = [];
  for (const r of rows) {
    if (r.status === 'changed') {
      lines.push(`  ${r.canton} · ${r.name} : ${formatMultiplier(r.oldValue)} → ${formatMultiplier(r.newValue)}`);
    } else if (r.status === 'missing') {
      lines.push(
        `  ${r.canton} · ${r.name}: missing from the source — value ${formatMultiplier(r.oldValue)} ` +
          `(year ${r.oldYear}) kept; to be resolved manually (municipality merger?), ` +
          'the consistency test will fail otherwise.',
      );
    } else if (r.status === 'out-of-range') {
      lines.push(
        `  ${r.canton} · ${r.name}: implausible source value ${formatMultiplier(r.newValue)} — refused, ` +
          `old value ${formatMultiplier(r.oldValue)} kept.`,
      );
    }
  }
  return lines;
}

/**
 * Generates the table body (between "= {" and "\n};"), in the Prettier format
 * of the current file: empty canton as `XX: [],`, single entry inline if
 * ≤ PRINT_WIDTH, otherwise multi-line.
 */
export function renderTable(cantons) {
  const lines = [];
  for (const { code, entries } of cantons) {
    if (entries.length === 0) {
      lines.push(`  ${code}: [],`);
      continue;
    }
    const rendered = entries.map(
      (e) =>
        `{ name: '${escapeName(e.name)}', multiplier: ${formatMultiplier(e.multiplier)}, year: ${e.year} }`,
    );
    if (entries.length === 1) {
      const inline = `  ${code}: [${rendered[0]}],`;
      if (inline.length <= PRINT_WIDTH) {
        lines.push(inline);
        continue;
      }
    }
    lines.push(`  ${code}: [`);
    for (const r of rendered) lines.push(`    ${r},`);
    lines.push(`  ],`);
  }
  return '\n' + lines.join('\n');
}

/** Replaces exactly one occurrence, otherwise refuses (drifted header → human). */
function replaceExactlyOnce(text, re, replacement, label) {
  const count = text.match(new RegExp(re.source, 'g'))?.length ?? 0;
  if (count !== 1) {
    throw new Error(
      `Unexpected header: "${label}" found ${count} times (expected 1) — ` +
        'the file drifted from the expected format, manual update required.',
    );
  }
  return text.replace(re, replacement);
}

/**
 * Produces the new file content: updated header (tax year,
 * fetch date, data/parsed/<year> path, COMMUNAL_MULTIPLIERS_TAX_YEAR)
 * + regenerated table. The rest of the file (interface, functions) is preserved.
 */
export function renderFile(source, nextCantons, { year, fetchDate }) {
  const { openBrace, tableEnd } = locateTable(source);
  let prefix = source.slice(0, openBrace + 1);
  const suffix = source.slice(tableEnd);
  prefix = replaceExactlyOnce(prefix, /tax year \d{4}/, `tax year ${year}`, 'tax year YYYY');
  prefix = replaceExactlyOnce(
    prefix,
    /fetched on \d{4}-\d{2}-\d{2}/,
    `fetched on ${fetchDate}`,
    'fetched on YYYY-MM-DD',
  );
  prefix = replaceExactlyOnce(
    prefix,
    /data\/parsed\/\d{4}\/factors/,
    `data/parsed/${year}/factors`,
    'data/parsed/YYYY/factors',
  );
  prefix = replaceExactlyOnce(
    prefix,
    /export const COMMUNAL_MULTIPLIERS_TAX_YEAR = \d+;/,
    `export const COMMUNAL_MULTIPLIERS_TAX_YEAR = ${year};`,
    'COMMUNAL_MULTIPLIERS_TAX_YEAR',
  );
  return prefix + renderTable(nextCantons) + suffix;
}

const USAGE = `Usage: node scripts/regen-communal-multipliers.mjs --year <YYYY> [--check] [--base-url <url>]

Regenerates the communal multipliers (src/lib/constants/communal-multipliers.ts)
from the ESTV mirror devbrains-com/swisstaxcalculator. --check: modifies nothing,
exit 1 if values diverge. Codes: 0 OK · 1 divergences (--check) · 2 error.`;

function parseArgs(argv) {
  const opts = { year: null, check: false, baseUrl: SOURCE_BASE_URL, help: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const eq = arg.indexOf('=');
    const flag = eq === -1 ? arg : arg.slice(0, eq);
    const inlineValue = eq === -1 ? undefined : arg.slice(eq + 1);
    const value = () => {
      if (inlineValue !== undefined) return inlineValue;
      i += 1;
      if (i >= argv.length) throw new Error(`Missing value for ${flag}`);
      return argv[i];
    };
    if (flag === '--year') opts.year = value();
    else if (flag === '--check') opts.check = true;
    else if (flag === '--base-url') opts.baseUrl = value();
    else if (flag === '--help' || flag === '-h') opts.help = true;
    else throw new Error(`Unknown option: ${arg}`);
  }
  return opts;
}

/** Network timeout per request (the script is a batch tool, not a service). */
const FETCH_TIMEOUT_MS = 30_000;

async function fetchJson(url, fetchImpl) {
  const res = await fetchImpl(url, { signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
  return res.json();
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
 * CLI entry point (injectable for tests: fetchImpl / readImpl /
 * writeImpl / log / error / today). Returns the exit code.
 */
export async function main(argv, deps = {}) {
  const {
    fetchImpl = fetch,
    readImpl = (file) => readFile(file, 'utf8'),
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
  if (!opts.year || !/^\d{4}$/.test(opts.year) || Number(opts.year) < 2020) {
    error(`--year <YYYY> required and plausible (≥ 2020).\n\n${USAGE}`);
    return 2;
  }
  const year = Number(opts.year);

  let source, parsed, locations, factorsByCanton;
  try {
    source = await readImpl(TARGET_FILE);
    parsed = parseTable(source);
    const base = opts.baseUrl.replace(/\/$/, '');
    locations = await fetchJson(`${base}/${year}/locations.json`, fetchImpl);
    const { cantonIds } = indexLocations(locations);
    const covered = parsed.cantons.filter((c) => c.entries.length > 0);
    const missingCanton = covered.find((c) => !cantonIds.has(c.code));
    if (missingCanton) {
      throw new Error(`Canton ${missingCanton.code} missing from the locations.json for ${year}.`);
    }
    const fetched = await Promise.all(
      covered.map(async (c) => [
        c.code,
        await fetchJson(`${base}/${year}/factors/${cantonIds.get(c.code)}.json`, fetchImpl),
      ]),
    );
    factorsByCanton = new Map(fetched);
  } catch (err) {
    error(
      `Failed to fetch ${year} data (year not yet published ` +
        `in the mirror? local file unreadable?): ${err.message}`,
    );
    return 2;
  }

  const lookup = buildLookup(locations, factorsByCanton);
  const plan = planUpdates(parsed.cantons, lookup, { year });

  log(`Communal multipliers — ESTV source (mirror devbrains-com/swisstaxcalculator), tax year ${year}.`);

  if (plan.errors.length > 0) {
    for (const errLine of plan.errors) error(errLine);
    error('Implausible values detected — nothing was written. Check the source.');
    return 2;
  }

  const changed = plan.rows.filter((r) => r.status === 'changed');
  const missing = plan.rows.filter((r) => r.status === 'missing');
  const unchanged = plan.rows.filter((r) => r.status === 'unchanged');
  const diff = formatDiff(plan.rows);
  if (diff.length > 0) {
    log('Diff:');
    for (const line of diff) log(line);
  }
  log(
    `Summary: ${unchanged.length} unchanged, ${changed.length} updated, ` +
      `${missing.length} missing from the source.`,
  );

  // In --check, a file stamped with a different year is a divergence:
  // regeneration is required even if the values are identical.
  const staleYear = year !== parsed.taxYear;
  if (staleYear) {
    log(
      `The file is stamped ${parsed.taxYear} — regeneration ${year} required ` +
        '(even if the values are identical).',
    );
  }

  if (opts.check) {
    if (changed.length > 0 || missing.length > 0 || staleYear) {
      log('Divergences detected — run without --check to regenerate.');
      return 1;
    }
    log(`Everything is up to date for ${year}.`);
    return 0;
  }

  if (changed.length === 0 && missing.length === 0 && !staleYear) {
    log(`Nothing to change — the file is already up to date for ${year}.`);
    return 0;
  }

  let nextSource;
  try {
    nextSource = renderFile(source, plan.nextCantons, { year, fetchDate: today() });
  } catch (err) {
    error(`${err.message} Nothing was written.`);
    return 2;
  }
  await writeImpl(TARGET_FILE, nextSource);
  log(
    `File ${TARGET_FILE.pathname} updated (year ${year}, fetched on ${today()}). ` +
      'Run: npm test && make check.',
  );
  if (missing.length > 0) {
    log(
      'Warning: municipalities missing from the source keep their old year — ' +
        "the consistency test (year === COMMUNAL_MULTIPLIERS_TAX_YEAR) will fail until this is resolved.",
    );
  }
  return 0;
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
