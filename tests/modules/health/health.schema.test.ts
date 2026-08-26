import { describe, it, expect } from 'vitest';
import {
  healthResponseSchema,
  readinessResponseSchema,
} from '../../../src/modules/health/health.schema.js';

describe('healthResponseSchema', () => {
  it('accepts a valid health response', () => {
    expect(
      healthResponseSchema.safeParse({
        status: 'ok',
        timestamp: '2026-08-05T12:00:00.000Z',
        version: '0.1.0',
        uptime: 123.4,
      }).success,
    ).toBe(true);
  });

  it('requires the literal status "ok"', () => {
    expect(
      healthResponseSchema.safeParse({
        status: 'degraded',
        timestamp: '2026-08-05T12:00:00.000Z',
        version: '0.1.0',
        uptime: 0,
      }).success,
    ).toBe(false);
  });
});

describe('readinessResponseSchema', () => {
  it('accepts ok and degraded responses with optional latencies', () => {
    expect(
      readinessResponseSchema.safeParse({
        status: 'ok',
        timestamp: '2026-08-05T12:00:00.000Z',
        checks: {
          database: { status: 'ok', latencyMs: 3 },
          redis: { status: 'ok' },
        },
      }).success,
    ).toBe(true);
    expect(
      readinessResponseSchema.safeParse({
        status: 'degraded',
        timestamp: '2026-08-05T12:00:00.000Z',
        checks: { database: { status: 'error' }, redis: { status: 'ok', latencyMs: 1 } },
      }).success,
    ).toBe(true);
  });

  it('rejects an invalid check status or a missing check', () => {
    expect(
      readinessResponseSchema.safeParse({
        status: 'ok',
        timestamp: '2026-08-05T12:00:00.000Z',
        checks: { database: { status: 'unknown' }, redis: { status: 'ok' } },
      }).success,
    ).toBe(false);
    expect(
      readinessResponseSchema.safeParse({
        status: 'ok',
        timestamp: '2026-08-05T12:00:00.000Z',
        checks: { database: { status: 'ok' } },
      }).success,
    ).toBe(false);
  });
});
