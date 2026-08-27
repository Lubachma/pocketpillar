import { describe, it, expect, beforeEach, afterAll, vi } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { Prisma } from '@prisma/client';

// Minimal env so importing src/config (via the harness) does not exit the process.
const mocks = vi.hoisted(() => {
  process.env.DATABASE_URL = 'postgresql://localhost:5432/test';
  process.env.REDIS_URL = 'redis://localhost:6379';
  process.env.SUPABASE_URL = 'https://test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
  return { getUser: vi.fn() };
});

vi.mock('../../src/lib/supabase.js', () => ({
  supabaseAdmin: { auth: { getUser: mocks.getUser } },
}));

import { buildTestApp, createFakePrisma } from '../helpers/test-app.js';

/**
 * HTTP contract coverage for the two core-domain modules the harness was
 * missing (review 08.2026): financial-profile and provider. Wiring-level
 * assertions only — auth gates, §4 404-until-created, the P2023
 * malformed-id mapping, and the public provider catalogue.
 */
describe('financial-profile & provider routes (HTTP contract)', () => {
  let app: FastifyInstance;
  let prisma: ReturnType<typeof createFakePrisma>;

  const TOKEN_SUB = '123e4567-e89b-42d3-a456-426614174000';
  const AUTH = { authorization: 'Bearer token-abc' };

  beforeEach(async () => {
    if (app) await app.close();
    mocks.getUser.mockClear();
    prisma = createFakePrisma();
    app = await buildTestApp({ prisma });
    mocks.getUser.mockResolvedValue({
      data: { user: { id: TOKEN_SUB, email: 'user@example.ch' } },
      error: null,
    });
    prisma.user.findUnique.mockResolvedValue({ id: 'local-user-1' });
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /financial-profile without a token → 401 { error }', async () => {
    const response = await app.inject({ method: 'GET', url: '/financial-profile' });

    expect(response.statusCode).toBe(401);
    expect(Object.keys(response.json())).toEqual(['error']);
  });

  it('GET /financial-profile before creation → 404 (contract §4)', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/financial-profile',
      headers: AUTH,
    });

    expect(response.statusCode).toBe(404);
    expect(response.json()).toEqual({ error: 'Profil financier non trouvé' });
  });

  it('PATCH /financial-profile/pillar2/:id with a malformed id → 404, never a 500', async () => {
    // What the driver raises when `where: { id }` gets a non-UUID —
    // mapped by the global error handler (review 08.2026).
    prisma.pillar2Account.update.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('malformed UUID', {
        code: 'P2023',
        clientVersion: 'test',
      }),
    );

    const response = await app.inject({
      method: 'PATCH',
      url: '/financial-profile/pillar2/not-a-uuid',
      headers: AUTH,
      payload: { currentCapital: 1_000_000 },
    });

    expect(response.statusCode).toBe(404);
    expect(response.json()).toEqual({ error: 'Ressource non trouvée' });
  });

  it('DELETE /financial-profile/pillar3a/:id unknown to this user → 404', async () => {
    const response = await app.inject({
      method: 'DELETE',
      url: '/financial-profile/pillar3a/123e4567-e89b-42d3-a456-426614174999',
      headers: AUTH,
    });

    expect(response.statusCode).toBe(404);
  });

  it('GET /providers is public and returns the catalogue', async () => {
    const response = await app.inject({ method: 'GET', url: '/providers' });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual([]);
    expect(mocks.getUser).not.toHaveBeenCalled();
  });

  it('POST /providers/best-match without a token → 401 (premium-gated, §11)', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/providers/best-match',
      payload: {},
    });

    expect(response.statusCode).toBe(401);
  });
});
