import { describe, it, expect } from 'vitest';
import {
  compareQuerySchema,
  bestMatchSchema,
} from '../../../src/modules/provider/provider.schema.js';

describe('compareQuerySchema', () => {
  it('accepts an empty query (all fields optional)', () => {
    expect(compareQuerySchema.parse({})).toEqual({});
  });

  it('accepts all risk levels and rejects unknown ones', () => {
    for (const riskLevel of ['CONSERVATIVE', 'MODERATE', 'BALANCED', 'GROWTH', 'AGGRESSIVE']) {
      expect(compareQuerySchema.safeParse({ riskLevel }).success).toBe(true);
    }
    expect(compareQuerySchema.safeParse({ riskLevel: 'YOLO' }).success).toBe(false);
  });

  it('transforms the sustainableOnly string flag to a boolean', () => {
    expect(compareQuerySchema.parse({ sustainableOnly: 'true' }).sustainableOnly).toBe(true);
    expect(compareQuerySchema.parse({ sustainableOnly: 'false' }).sustainableOnly).toBe(false);
    // Any string other than 'true' maps to false.
    expect(compareQuerySchema.parse({ sustainableOnly: 'yes' }).sustainableOnly).toBe(false);
  });

  it('coerces numeric query strings and bounds maxFeePercent to 0-5', () => {
    expect(compareQuerySchema.parse({ maxFeePercent: '0.45' }).maxFeePercent).toBe(0.45);
    expect(compareQuerySchema.safeParse({ maxFeePercent: '0' }).success).toBe(true);
    expect(compareQuerySchema.safeParse({ maxFeePercent: '5' }).success).toBe(true);
    expect(compareQuerySchema.safeParse({ maxFeePercent: '5.01' }).success).toBe(false);
    expect(compareQuerySchema.safeParse({ maxFeePercent: '-0.1' }).success).toBe(false);
    expect(compareQuerySchema.safeParse({ maxFeePercent: 'abc' }).success).toBe(false);
  });

  it('bounds equity allocation to integers 0-100', () => {
    expect(compareQuerySchema.parse({ minEquityAllocation: '50' }).minEquityAllocation).toBe(50);
    expect(compareQuerySchema.safeParse({ minEquityAllocation: '50.5' }).success).toBe(false);
    expect(compareQuerySchema.safeParse({ maxEquityAllocation: '101' }).success).toBe(false);
    expect(compareQuerySchema.safeParse({ maxEquityAllocation: '-1' }).success).toBe(false);
  });
});

describe('bestMatchSchema', () => {
  it('applies the defaults (BALANCED, no ESG preference)', () => {
    expect(bestMatchSchema.parse({})).toEqual({ riskLevel: 'BALANCED', preferEsg: false });
  });

  it('bounds maxFeePercent to 0-5', () => {
    expect(bestMatchSchema.safeParse({ maxFeePercent: 5 }).success).toBe(true);
    expect(bestMatchSchema.safeParse({ maxFeePercent: 5.1 }).success).toBe(false);
  });
});
