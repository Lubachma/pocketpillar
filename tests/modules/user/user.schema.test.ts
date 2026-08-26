import { describe, it, expect } from 'vitest';
import { updateUserSchema, userResponseSchema } from '../../../src/modules/user/user.schema.js';
import { SWISS_PENSION } from '../../../src/lib/constants/swiss-pension.js';

describe('updateUserSchema', () => {
  it('accepts an empty object (all fields optional)', () => {
    expect(updateUserSchema.parse({})).toEqual({});
  });

  it('accepts a valid canton and birthYear', () => {
    expect(updateUserSchema.parse({ canton: 'VD', birthYear: 1985 })).toEqual({
      canton: 'VD',
      birthYear: 1985,
    });
  });

  it('rejects an unknown canton', () => {
    expect(updateUserSchema.safeParse({ canton: 'XX' }).success).toBe(false);
    expect(updateUserSchema.safeParse({ canton: 'vd' }).success).toBe(false);
  });

  it('bounds birthYear to 1930 and to users aged at least 16 (dynamic upper bound)', () => {
    const maxBirthYear = SWISS_PENSION.CURRENT_YEAR - 16;
    expect(updateUserSchema.safeParse({ birthYear: 1929 }).success).toBe(false);
    expect(updateUserSchema.safeParse({ birthYear: 1930 }).success).toBe(true);
    expect(updateUserSchema.safeParse({ birthYear: maxBirthYear }).success).toBe(true);
    expect(updateUserSchema.safeParse({ birthYear: maxBirthYear + 1 }).success).toBe(false);
    expect(updateUserSchema.safeParse({ birthYear: 1985.5 }).success).toBe(false);
  });

  it('bounds replacementRateGoal to 50-100', () => {
    expect(updateUserSchema.safeParse({ replacementRateGoal: 49 }).success).toBe(false);
    expect(updateUserSchema.safeParse({ replacementRateGoal: 50 }).success).toBe(true);
    expect(updateUserSchema.safeParse({ replacementRateGoal: 70 }).success).toBe(true);
    expect(updateUserSchema.safeParse({ replacementRateGoal: 100 }).success).toBe(true);
    expect(updateUserSchema.safeParse({ replacementRateGoal: 101 }).success).toBe(false);
    expect(updateUserSchema.safeParse({ replacementRateGoal: 70.5 }).success).toBe(false);
  });

  it('accepts a municipality, an explicit null to clear it, but rejects empty/overlong values', () => {
    expect(updateUserSchema.parse({ municipality: 'Lausanne' })).toEqual({
      municipality: 'Lausanne',
    });
    expect(updateUserSchema.parse({ municipality: null })).toEqual({ municipality: null });
    expect(updateUserSchema.safeParse({ municipality: '' }).success).toBe(false);
    expect(updateUserSchema.safeParse({ municipality: 'x'.repeat(101) }).success).toBe(false);
  });
});

describe('userResponseSchema', () => {
  const valid = {
    id: '123e4567-e89b-42d3-a456-426614174000',
    email: 'user@example.ch',
    canton: 'ZH',
    birthYear: 1985,
    replacementRateGoal: 70,
    municipality: 'Zürich',
    createdAt: '2026-01-15T10:00:00.000Z',
  };

  it('accepts a valid response, including null canton, birthYear and municipality', () => {
    expect(userResponseSchema.safeParse(valid).success).toBe(true);
    expect(
      userResponseSchema.safeParse({ ...valid, canton: null, birthYear: null, municipality: null })
        .success,
    ).toBe(true);
  });

  it('rejects a non-UUID id and an invalid canton', () => {
    expect(userResponseSchema.safeParse({ ...valid, id: 'not-a-uuid' }).success).toBe(false);
    expect(userResponseSchema.safeParse({ ...valid, canton: 'XX' }).success).toBe(false);
  });
});
