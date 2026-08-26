import { describe, it, expect } from 'vitest';
import { registerBodySchema } from '../../../src/modules/auth/auth.schema.js';

describe('registerBodySchema', () => {
  it('accepts a valid email and Supabase UUID', () => {
    const parsed = registerBodySchema.parse({
      email: 'user@example.ch',
      supabaseId: '123e4567-e89b-42d3-a456-426614174000',
    });
    expect(parsed.email).toBe('user@example.ch');
  });

  it('rejects invalid emails', () => {
    for (const email of ['not-an-email', 'missing@tld', '@example.ch', '']) {
      expect(registerBodySchema.safeParse({ email, supabaseId: crypto.randomUUID() }).success).toBe(
        false,
      );
    }
  });

  it('rejects a non-UUID supabaseId', () => {
    expect(
      registerBodySchema.safeParse({ email: 'user@example.ch', supabaseId: 'abc123' }).success,
    ).toBe(false);
  });

  it('accepts a missing email — the email comes from the JWT, the body field is ignored', () => {
    const supabaseId = '123e4567-e89b-42d3-a456-426614174000';
    const parsed = registerBodySchema.parse({ supabaseId });
    expect(parsed.supabaseId).toBe(supabaseId);
    expect(parsed.email).toBeUndefined();
  });

  it('rejects missing fields', () => {
    expect(registerBodySchema.safeParse({}).success).toBe(false);
    expect(registerBodySchema.safeParse({ email: 'user@example.ch' }).success).toBe(false);
  });
});
