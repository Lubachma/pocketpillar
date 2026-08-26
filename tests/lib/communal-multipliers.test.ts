import { describe, it, expect } from 'vitest';
import {
  COMMUNAL_MULTIPLIERS,
  COMMUNAL_MULTIPLIERS_TAX_YEAR,
  resolveCommunalMultiplier,
  getMunicipalitiesForCanton,
} from '../../src/lib/constants/communal-multipliers.js';
import { CANTONAL_INCOME_TABLES } from '../../src/lib/constants/cantonal-income-tables.js';
import type { Canton } from '@prisma/client';

/**
 * Communal multipliers (Steuerfuss) — real per-municipality values, tax year
 * 2026, source ESTV tax calculator data (see the header of
 * src/lib/constants/communal-multipliers.ts). Reference values cross-checked
 * against cantonal sources: Zürich 119 %, Winterthur 125 % (zh.ch/watson),
 * Luzern 145 % (lustat.ch), Bern 154 %, Lausanne 78.5 %, Genève 45.49 %.
 */
describe('COMMUNAL_MULTIPLIERS data sanity', () => {
  it('covers ~100 municipalities across the 26 canton keys, all for the current tax year', () => {
    const all = Object.values(COMMUNAL_MULTIPLIERS).flat();
    expect(all).toHaveLength(100);
    expect(Object.keys(CANTONAL_INCOME_TABLES).sort()).toEqual(
      Object.keys(COMMUNAL_MULTIPLIERS).sort(),
    );
    for (const entry of all) {
      expect(entry.year).toBe(COMMUNAL_MULTIPLIERS_TAX_YEAR);
      expect(entry.multiplier).toBeGreaterThanOrEqual(0);
      expect(entry.name.length).toBeGreaterThan(0);
    }
  });

  it('has unique municipality names per canton, sorted alphabetically', () => {
    // Same normalization as the generator: diacritics stripped, lowercase.
    const key = (name: string) =>
      name
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase();
    for (const entries of Object.values(COMMUNAL_MULTIPLIERS)) {
      const names = entries.map((e) => e.name);
      expect(new Set(names).size).toBe(names.length);
      const sorted = [...names].sort((a, b) => (key(a) < key(b) ? -1 : key(a) > key(b) ? 1 : 0));
      expect(names).toEqual(sorted);
    }
  });

  it('matches the reference values of the largest cities (spot checks)', () => {
    expect(resolveCommunalMultiplier('ZH', 'Zürich')).toBe(119);
    expect(resolveCommunalMultiplier('GE', 'Genève')).toBe(45.49);
    expect(resolveCommunalMultiplier('VD', 'Lausanne')).toBe(78.5);
    expect(resolveCommunalMultiplier('BE', 'Bern')).toBe(154);
    expect(resolveCommunalMultiplier('ZH', 'Winterthur')).toBe(125);
    expect(resolveCommunalMultiplier('LU', 'Luzern')).toBe(145);
    // Basel-Stadt: merged cantonal/communal tax — no separate multiplier.
    expect(resolveCommunalMultiplier('BS', 'Basel')).toBe(0);
  });
});

describe('resolveCommunalMultiplier', () => {
  it('returns the real multiplier of a covered municipality', () => {
    expect(resolveCommunalMultiplier('VD', 'Lausanne')).toBe(78.5);
    expect(resolveCommunalMultiplier('ZH', 'Winterthur')).toBe(125);
  });

  it('matches case-insensitively and accent-insensitively', () => {
    expect(resolveCommunalMultiplier('VD', 'lausanne')).toBe(78.5);
    expect(resolveCommunalMultiplier('VD', 'LAUSANNE')).toBe(78.5);
    expect(resolveCommunalMultiplier('ZH', 'Zurich')).toBe(119); // no umlaut
    expect(resolveCommunalMultiplier('ZH', 'zürich')).toBe(119);
    expect(resolveCommunalMultiplier('GE', 'geneve')).toBe(45.49);
    expect(resolveCommunalMultiplier('BE', 'köniz')).toBe(158);
  });

  it('ignores spaces, hyphens and dots (St. Gallen / St.Gallen)', () => {
    expect(resolveCommunalMultiplier('SG', 'St. Gallen')).toBe(138);
    expect(resolveCommunalMultiplier('SG', 'St.Gallen')).toBe(138);
    expect(resolveCommunalMultiplier('SG', 'st gallen')).toBe(138);
    expect(resolveCommunalMultiplier('NE', 'La Chaux-de-Fonds')).toBe(75);
    expect(resolveCommunalMultiplier('NE', 'la chaux de fonds')).toBe(75);
  });

  it('accepts a municipality typed without its BFS canton suffix', () => {
    // Official name is « Wetzikon (ZH) » — plain « Wetzikon » must match.
    expect(resolveCommunalMultiplier('ZH', 'Wetzikon')).toBe(119);
    expect(resolveCommunalMultiplier('ZH', 'Wetzikon (ZH)')).toBe(119);
    expect(resolveCommunalMultiplier('VD', 'Renens')).toBe(77);
  });

  it('falls back to the cantonal average for an unknown municipality', () => {
    expect(resolveCommunalMultiplier('ZH', 'Nimportequoi')).toBe(
      CANTONAL_INCOME_TABLES.ZH.averageCommunalMultiplier,
    );
    expect(resolveCommunalMultiplier('GE', 'Inexistante')).toBe(
      CANTONAL_INCOME_TABLES.GE.averageCommunalMultiplier,
    );
  });

  it('falls back to the cantonal average when no municipality is given (current behavior)', () => {
    expect(resolveCommunalMultiplier('ZH')).toBe(
      CANTONAL_INCOME_TABLES.ZH.averageCommunalMultiplier,
    );
    expect(resolveCommunalMultiplier('ZH', undefined)).toBe(119);
    expect(resolveCommunalMultiplier('VD', '')).toBe(
      CANTONAL_INCOME_TABLES.VD.averageCommunalMultiplier,
    );
  });

  it('does not match a municipality of another canton', () => {
    // « Lausanne » exists in VD only — asking for it in ZH falls back.
    expect(resolveCommunalMultiplier('ZH', 'Lausanne')).toBe(
      CANTONAL_INCOME_TABLES.ZH.averageCommunalMultiplier,
    );
  });
});

describe('getMunicipalitiesForCanton', () => {
  it('returns the covered municipalities of a canton, sorted, without the year field', () => {
    const zh = getMunicipalitiesForCanton('ZH');

    expect(zh).toHaveLength(23);
    expect(zh[0]).toEqual({ name: 'Adliswil', multiplier: 104 });
    expect(zh).toContainEqual({ name: 'Zürich', multiplier: 119 });
    expect(zh.every((m) => !('year' in m))).toBe(true);
  });

  it('returns an empty list for a canton without covered municipality', () => {
    expect(getMunicipalitiesForCanton('JU')).toEqual([]);
    expect(getMunicipalitiesForCanton('UR')).toEqual([]);
  });

  it('covers every canton code of the Canton enum', () => {
    const cantons: Canton[] = Object.keys(CANTONAL_INCOME_TABLES) as Canton[];
    for (const canton of cantons) {
      expect(Array.isArray(getMunicipalitiesForCanton(canton))).toBe(true);
    }
  });
});
