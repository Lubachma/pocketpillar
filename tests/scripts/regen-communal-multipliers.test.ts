import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { describe, expect, it } from 'vitest';
import {
  atomicWriteFile,
  buildLookup,
  formatDiff,
  indexFactors,
  indexLocations,
  main,
  normalizeName,
  parseTable,
  planUpdates,
  renderFile,
  renderTable,
  TARGET_FILE,
} from '../../scripts/regen-communal-multipliers.mjs';
import type {
  CantonSection,
  FactorRecord,
  LocationRecord,
} from '../../scripts/regen-communal-multipliers.mjs';

/**
 * Tests for the annual communal-multipliers regeneration script —
 * local fixtures only, no network (fetch injected into `main`).
 */

const FAKE_BASE = 'fake://mirror';

const realSource = () => readFile(TARGET_FILE, 'utf8');

describe('parseTable on the real file', () => {
  it('finds the 26 cantons, the 100 municipalities and the tax year', async () => {
    const parsed = parseTable(await realSource());
    expect(parsed.taxYear).toBe(2026);
    expect(parsed.cantons).toHaveLength(26);
    expect(parsed.cantons.reduce((n, c) => n + c.entries.length, 0)).toBe(100);
    const zh = parsed.cantons.find((c) => c.code === 'ZH');
    expect(zh?.entries.find((e) => e.name === 'Zürich')).toEqual({
      name: 'Zürich',
      multiplier: 119,
      year: 2026,
    });
    const ge = parsed.cantons.find((c) => c.code === 'GE');
    expect(ge?.entries.find((e) => e.name === 'Genève')?.multiplier).toBe(45.49);
    // Cantons without a covered municipality are present, empty.
    for (const code of ['UR', 'OW', 'NW', 'AI', 'JU']) {
      expect(parsed.cantons.find((c) => c.code === code)?.entries).toEqual([]);
    }
  });

  it('round-trip: regenerating without change reproduces the file byte-for-byte', async () => {
    const source = await realSource();
    const parsed = parseTable(source);
    const out = renderFile(source, parsed.cantons, { year: 2026, fetchDate: '2026-08-06' });
    expect(out).toBe(source);
  });

  it('rejects a missing or malformed table', () => {
    expect(() => parseTable('export const X = 1;')).toThrow(/COMMUNAL_MULTIPLIERS/);
  });
});

describe('normalizeName', () => {
  it('is case-, accent- and separator-insensitive', () => {
    expect(normalizeName('Zürich')).toBe('zurich');
    expect(normalizeName('St. Gallen')).toBe('stgallen');
    expect(normalizeName('La Chaux-de-Fonds')).toBe('lachauxdefonds');
    expect(normalizeName('Küsnacht (ZH)')).toBe('kusnachtzh');
  });
});

describe('renderTable', () => {
  it('formats an empty canton, a single entry inline, and multiple entries multi-line', () => {
    const cantons: CantonSection[] = [
      { code: 'UR', entries: [] },
      { code: 'GL', entries: [{ name: 'Glarus Nord', multiplier: 63, year: 2027 }] },
      {
        code: 'BS',
        entries: [
          { name: 'Basel', multiplier: 0, year: 2027 },
          { name: 'Riehen', multiplier: 40, year: 2027 },
        ],
      },
    ];
    expect(renderTable(cantons)).toBe(
      '\n  UR: [],' +
        "\n  GL: [{ name: 'Glarus Nord', multiplier: 63, year: 2027 }]," +
        '\n  BS: [' +
        "\n    { name: 'Basel', multiplier: 0, year: 2027 }," +
        "\n    { name: 'Riehen', multiplier: 40, year: 2027 }," +
        '\n  ],',
    );
  });

  it('escapes apostrophes and switches to multi-line past 100 characters', () => {
    const cantons: CantonSection[] = [
      {
        code: 'VD',
        entries: [
          {
            name: "L'Isle-sur-la-Sarraz-et-ses-alentours-vraiment-lointains",
            multiplier: 74.5,
            year: 2027,
          },
        ],
      },
    ];
    expect(renderTable(cantons)).toBe(
      '\n  VD: [' +
        "\n    { name: 'L\\'Isle-sur-la-Sarraz-et-ses-alentours-vraiment-lointains', multiplier: 74.5, year: 2027 }," +
        '\n  ],',
    );
  });
});

describe('renderFile', () => {
  const miniSource = [
    '/**',
    ' * Source: ESTV data, tax year 2026, fetched on 2026-08-06',
    ' * via the mirror (data/parsed/2026/factors + locations.json).',
    ' */',
    'export const COMMUNAL_MULTIPLIERS_TAX_YEAR = 2026;',
    '',
    'export const COMMUNAL_MULTIPLIERS: Record<string, unknown> = {',
    "  ZH: [{ name: 'Zürich', multiplier: 119, year: 2026 }],",
    '  UR: [],',
    '};',
    '',
    'export function keep() {}',
    '',
  ].join('\n');

  it('updates the header, TAX_YEAR and the table, and preserves the rest', () => {
    const next: CantonSection[] = [
      { code: 'ZH', entries: [{ name: 'Zürich', multiplier: 121, year: 2027 }] },
      { code: 'UR', entries: [] },
    ];
    const out = renderFile(miniSource, next, { year: 2027, fetchDate: '2027-01-15' });
    expect(out).toContain('tax year 2027, fetched on 2027-01-15');
    expect(out).toContain('data/parsed/2027/factors');
    expect(out).toContain('COMMUNAL_MULTIPLIERS_TAX_YEAR = 2027;');
    expect(out).toContain("  ZH: [{ name: 'Zürich', multiplier: 121, year: 2027 }],");
    expect(out).toContain('  UR: [],');
    expect(out.endsWith('export function keep() {}\n')).toBe(true);
  });

  it('refuses to write when the header has drifted from the expected format', () => {
    const broken = miniSource.replace('tax year 2026', 'unknown year');
    expect(() =>
      renderFile(broken, [{ code: 'ZH', entries: [] }], { year: 2027, fetchDate: '2027-01-15' }),
    ).toThrow(/Unexpected header/);
  });
});

describe('indexLocations / indexFactors / buildLookup', () => {
  const locations: LocationRecord[] = [
    { TaxLocationID: 261000000, BfsID: 261, BfsName: 'Zürich', CantonID: 26, Canton: 'ZH' },
    { TaxLocationID: 100000, BfsID: 351, BfsName: 'Bern', CantonID: 4, Canton: 'BE' },
    // Orphan entry: no associated factors.
    { TaxLocationID: 200000, BfsID: 999, BfsName: 'Fantaisie', CantonID: 4, Canton: 'BE' },
  ];

  it('maps canton → cantonId and normalized name → BFS', () => {
    const { cantonIds, bfsByName } = indexLocations(locations);
    expect(cantonIds.get('ZH')).toBe(26);
    expect(bfsByName.get('ZH|zurich')).toBe(261);
  });

  it("rounds off the mirror's floating-point noise and ignores malformed entries", () => {
    const factors: FactorRecord[] = [
      { IncomeRateCity: 204.99999999999997, Location: { BfsID: 1 } },
      { IncomeRateCity: 45.49, Location: { BfsID: 2 } },
      { IncomeRateCity: '118', Location: { BfsID: 3 } },
      { Location: { BfsID: 4 } },
      { IncomeRateCity: 100 },
    ];
    const map = indexFactors(factors);
    expect(map.get(1)).toBe(205);
    expect(map.get(2)).toBe(45.49);
    expect(map.size).toBe(2);
  });

  it('resolves via the BFS id, returns null when the municipality or factor is missing', () => {
    const lookup = buildLookup(
      locations,
      new Map([['ZH', [{ IncomeRateCity: 121, Location: { BfsID: 261 } }]]]),
    );
    expect(lookup('ZH', 'zurich')).toBe(121);
    expect(lookup('ZH', 'Inconnue')).toBeNull();
    expect(lookup('BE', 'Bern')).toBeNull(); // canton with no factors provided
    expect(lookup('BE', 'Fantaisie')).toBeNull(); // BFS with no factor
  });
});

describe('planUpdates', () => {
  const cantons: CantonSection[] = [
    {
      code: 'ZH',
      entries: [
        { name: 'Zürich', multiplier: 119, year: 2026 },
        { name: 'Adliswil', multiplier: 104, year: 2026 },
        { name: 'Kloten', multiplier: 100, year: 2026 },
      ],
    },
    { code: 'UR', entries: [] },
  ];

  const lookupFrom = (values: Map<string, number>) => {
    return (canton: string, name: string) => values.get(`${canton}|${normalizeName(name)}`) ?? null;
  };

  it('classifies changed / unchanged / missing and applies the new year', () => {
    const values = new Map([
      ['ZH|zurich', 121],
      ['ZH|adliswil', 104],
    ]);
    const plan = planUpdates(cantons, lookupFrom(values), { year: 2027 });
    expect(plan.errors).toEqual([]);
    expect(plan.rows.map((r) => r.status)).toEqual(['changed', 'unchanged', 'missing']);
    // Both the changed value AND the unchanged value move to the new year.
    expect(plan.nextCantons[0].entries[0]).toEqual({
      name: 'Zürich',
      multiplier: 121,
      year: 2027,
    });
    expect(plan.nextCantons[0].entries[1]).toEqual({
      name: 'Adliswil',
      multiplier: 104,
      year: 2027,
    });
    // Municipality gone: old value AND old year are both kept.
    expect(plan.nextCantons[0].entries[2]).toEqual({ name: 'Kloten', multiplier: 100, year: 2026 });
    expect(plan.nextCantons[1]).toEqual({ code: 'UR', entries: [] });
  });

  it('accepts the 0 and 1000 bounds, rejects implausible values', () => {
    const values = new Map([
      ['ZH|zurich', 0],
      ['ZH|adliswil', 1000],
      ['ZH|kloten', 1000.01],
    ]);
    const plan = planUpdates(cantons, lookupFrom(values), { year: 2027 });
    expect(plan.rows.map((r) => r.status)).toEqual(['changed', 'changed', 'out-of-range']);
    expect(plan.errors).toHaveLength(1);
    expect(plan.errors[0]).toMatch(/Kloten.*implausible/);
    // The outlier entry is kept as-is.
    expect(plan.nextCantons[0].entries[2]).toEqual({ name: 'Kloten', multiplier: 100, year: 2026 });

    const nonFinie = planUpdates(
      [{ code: 'ZH', entries: [{ name: 'Zürich', multiplier: 119, year: 2026 }] }],
      () => Number.POSITIVE_INFINITY,
      { year: 2027 },
    );
    expect(nonFinie.rows[0].status).toBe('out-of-range');
    expect(nonFinie.errors).toHaveLength(1);
  });
});

describe('formatDiff', () => {
  it('lists changes, disappearances and outliers — not the unchanged ones', () => {
    const plan = planUpdates(
      [
        {
          code: 'ZH',
          entries: [
            { name: 'Zürich', multiplier: 119, year: 2026 },
            { name: 'Kloten', multiplier: 100, year: 2026 },
            { name: 'Adliswil', multiplier: 104, year: 2026 },
          ],
        },
      ],
      (_canton, name) => (name === 'Zürich' ? 121 : name === 'Kloten' ? null : 104),
      { year: 2027 },
    );
    const lines = formatDiff(plan.rows);
    expect(lines).toHaveLength(2);
    expect(lines[0]).toBe('  ZH · Zürich : 119 → 121');
    expect(lines[1]).toMatch(/Kloten: missing from the source — value 100 \(year 2026\) kept/);
  });
});

describe('atomicWriteFile', () => {
  it('writes via a temp file then renames (no leftover .tmp)', async () => {
    const dir = await mkdtemp(join(tmpdir(), 'regen-test-'));
    try {
      const target = pathToFileURL(join(dir, 'out.ts'));
      await atomicWriteFile(target, 'contenu écrit');
      expect(await readFile(target, 'utf8')).toBe('contenu écrit');
      expect(await readdir(dir)).toEqual(['out.ts']);
      // Overwriting an existing file: same atomic path.
      await atomicWriteFile(target, 'v2');
      expect(await readFile(target, 'utf8')).toBe('v2');
      expect(await readdir(dir)).toEqual(['out.ts']);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });
});

/** Builds a fake mirror (locations + factors) covering the municipalities of the real file. */
async function buildFakeMirror(year: number) {
  const { cantons } = parseTable(await realSource());
  const locations: LocationRecord[] = [];
  const pages: Record<string, unknown> = {};
  const cantonIds = new Map<string, number>();
  let nextBfs = 1;
  for (const { code, entries } of cantons) {
    if (entries.length === 0) continue;
    if (!cantonIds.has(code)) cantonIds.set(code, cantonIds.size + 1);
    const cantonId = cantonIds.get(code)!;
    const factors: FactorRecord[] = [];
    for (const e of entries) {
      const bfs = nextBfs++;
      locations.push({
        TaxLocationID: bfs * 1000,
        BfsID: bfs,
        BfsName: e.name,
        CantonID: cantonId,
        Canton: code,
      });
      factors.push({ IncomeRateCity: e.multiplier, Location: { BfsID: bfs } });
    }
    pages[`${FAKE_BASE}/${year}/factors/${cantonId}.json`] = factors;
  }
  pages[`${FAKE_BASE}/${year}/locations.json`] = locations;
  return { pages, locations };
}

const makeFetch = (pages: Record<string, unknown>) =>
  (async (input: unknown) => {
    const url = String(input);
    if (url in pages) {
      return { ok: true, status: 200, json: async () => pages[url] } as Response;
    }
    return { ok: false, status: 404, json: async () => null } as Response;
  }) as unknown as typeof fetch;

interface Harness {
  code: number;
  logs: string[];
  errors: string[];
  written: string | null;
}

async function runCli(argv: string[], pages: Record<string, unknown>): Promise<Harness> {
  const logs: string[] = [];
  const errors: string[] = [];
  let written: string | null = null;
  const code = await main(argv, {
    fetchImpl: makeFetch(pages),
    writeImpl: async (_file, content) => {
      written = content;
    },
    log: (m) => logs.push(m),
    error: (m) => errors.push(m),
    today: () => '2027-01-15',
  });
  return { code, logs, errors, written };
}

/** Overrides a municipality's value in the fake mirror (by exact BFS name). */
function overrideValue(
  pages: Record<string, unknown>,
  locations: LocationRecord[],
  year: number,
  name: string,
  value: number,
) {
  const loc = locations.find((l) => l.BfsName === name);
  if (!loc) throw new Error(`fixture inconnue : ${name}`);
  const key = `${FAKE_BASE}/${year}/factors/${loc.CantonID}.json`;
  const factors = pages[key] as FactorRecord[];
  const factor = factors.find((f) => (f.Location as { BfsID: number }).BfsID === loc.BfsID);
  if (!factor) throw new Error(`facteur manquant : ${name}`);
  factor.IncomeRateCity = value;
}

describe('main (CLI, injected fetch — no network)', () => {
  it('--check exits 0 when every value matches the source', async () => {
    const { pages } = await buildFakeMirror(2026);
    const h = await runCli(['--year', '2026', '--check', '--base-url', FAKE_BASE], pages);
    expect(h.code).toBe(0);
    expect(h.logs.join('\n')).toMatch(/100 unchanged, 0 updated, 0 missing from the source/);
    expect(h.logs.join('\n')).toMatch(/up to date for 2026/);
    expect(h.written).toBeNull();
  });

  it('--check exits 1 when the file is stamped with another year', async () => {
    const { pages } = await buildFakeMirror(2027);
    const h = await runCli(['--year', '2027', '--check', '--base-url', FAKE_BASE], pages);
    expect(h.code).toBe(1);
    expect(h.logs.join('\n')).toMatch(/stamped 2026 — regeneration 2027 required/);
    expect(h.written).toBeNull();
  });

  it('--check exits 1 with the diff when a value diverges, without writing', async () => {
    const { pages, locations } = await buildFakeMirror(2026);
    overrideValue(pages, locations, 2026, 'Zürich', 121);
    const h = await runCli(['--year', '2026', '--check', '--base-url', FAKE_BASE], pages);
    expect(h.code).toBe(1);
    expect(h.logs.join('\n')).toContain('ZH · Zürich : 119 → 121');
    expect(h.written).toBeNull();
  });

  it('writes the regenerated file (header, year, diff) in write mode', async () => {
    const { pages, locations } = await buildFakeMirror(2027);
    overrideValue(pages, locations, 2027, 'Zürich', 121);
    const h = await runCli(['--year', '2027', '--base-url', FAKE_BASE], pages);
    expect(h.code).toBe(0);
    expect(h.written).not.toBeNull();
    const out = h.written!;
    expect(out).toContain('tax year 2027, fetched on 2027-01-15');
    expect(out).toContain('data/parsed/2027/factors');
    expect(out).toContain('COMMUNAL_MULTIPLIERS_TAX_YEAR = 2027;');
    expect(out).toContain("{ name: 'Zürich', multiplier: 121, year: 2027 }");
    expect(out).toContain("{ name: 'Winterthur', multiplier: 125, year: 2027 }");
    // The written file re-parses cleanly (round-trip).
    expect(parseTable(out).cantons.reduce((n, c) => n + c.entries.length, 0)).toBe(100);
  });

  it('writes even when no value changed as long as the tax year advances', async () => {
    const { pages } = await buildFakeMirror(2027);
    const h = await runCli(['--year', '2027', '--base-url', FAKE_BASE], pages);
    expect(h.code).toBe(0);
    expect(h.written).not.toBeNull();
    expect(h.written!).toContain('COMMUNAL_MULTIPLIERS_TAX_YEAR = 2027;');
  });

  it('exits 2 and writes nothing on an implausible value', async () => {
    const { pages, locations } = await buildFakeMirror(2026);
    overrideValue(pages, locations, 2026, 'Genève', 1500);
    const h = await runCli(['--year', '2026', '--base-url', FAKE_BASE], pages);
    expect(h.code).toBe(2);
    expect(h.errors.join('\n')).toMatch(/Genève.*implausible/);
    expect(h.written).toBeNull();
  });

  it('municipality gone: warns, keeps the old value and year', async () => {
    const { pages, locations } = await buildFakeMirror(2027);
    pages[`${FAKE_BASE}/2027/locations.json`] = locations.filter((l) => l.BfsName !== 'Kloten');
    const write = await runCli(['--year', '2027', '--base-url', FAKE_BASE], pages);
    expect(write.code).toBe(0);
    expect(write.logs.join('\n')).toMatch(/Kloten: missing from the source/);
    expect(write.logs.join('\n')).toMatch(/1 missing from the source/);
    expect(write.written!).toContain("{ name: 'Kloten', multiplier: 100, year: 2026 }");

    const check = await runCli(['--year', '2027', '--check', '--base-url', FAKE_BASE], pages);
    expect(check.code).toBe(1);
  });

  it('exits 2 when the year is not published in the source (404)', async () => {
    const h = await runCli(['--year', '2099', '--base-url', FAKE_BASE], {});
    expect(h.code).toBe(2);
    expect(h.errors.join('\n')).toMatch(/HTTP 404/);
  });

  it('exits 2 without --year, exits 0 on --help', async () => {
    const noYear = await runCli([], {});
    expect(noYear.code).toBe(2);
    const help = await runCli(['--help'], {});
    expect(help.code).toBe(0);
    expect(help.logs.join('\n')).toMatch(/Usage/);
    const bad = await runCli(['--year', 'abc'], {});
    expect(bad.code).toBe(2);
  });
});
