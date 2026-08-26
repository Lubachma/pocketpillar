import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Prisma } from '@prisma/client';
import type { FastifyReply, FastifyRequest } from 'fastify';

// Minimal env so importing src/config (via the handler) does not exit the process.
const mocks = vi.hoisted(() => {
  process.env.DATABASE_URL = 'postgresql://localhost:5432/test';
  process.env.REDIS_URL = 'redis://localhost:6379';
  process.env.SUPABASE_URL = 'https://test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
  return { getUser: vi.fn() };
});

vi.mock('../../../src/lib/supabase.js', () => ({
  supabaseAdmin: { auth: { getUser: mocks.getUser } },
}));

import { registerHandler } from '../../../src/modules/auth/auth.handler.js';

const TOKEN_SUB = '123e4567-e89b-42d3-a456-426614174000';
const TOKEN_EMAIL = 'user@example.ch';

function createReply() {
  const reply = {
    statusCode: 200,
    payload: undefined as unknown,
    status(code: number) {
      reply.statusCode = code;
      return reply;
    },
    send(payload?: unknown) {
      reply.payload = payload;
      return reply;
    },
  };
  return reply as unknown as FastifyReply & { statusCode: number; payload: unknown };
}

interface PrismaMock {
  findUnique: ReturnType<typeof vi.fn>;
  create: ReturnType<typeof vi.fn>;
}

function createRequest(body: unknown, prisma: PrismaMock, withAuth = true) {
  return {
    headers: withAuth ? { authorization: 'Bearer valid-token' } : {},
    body,
    locale: 'fr',
    log: { warn: vi.fn() },
    server: { prisma: { user: prisma } },
  } as unknown as FastifyRequest<{ Body: unknown }>;
}

function mockValidToken(email: string | undefined = TOKEN_EMAIL) {
  mocks.getUser.mockResolvedValue({
    data: { user: { id: TOKEN_SUB, email } },
    error: null,
  });
}

describe('registerHandler', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('rejects requests without a Bearer token (401)', async () => {
    const prisma = { findUnique: vi.fn(), create: vi.fn() };
    const reply = createReply();

    await registerHandler(createRequest({}, prisma, false), reply);

    expect(reply.statusCode).toBe(401);
    expect(mocks.getUser).not.toHaveBeenCalled();
  });

  it('rejects an invalid or expired token (401)', async () => {
    mocks.getUser.mockResolvedValue({ data: { user: null }, error: new Error('bad token') });
    const prisma = { findUnique: vi.fn(), create: vi.fn() };
    const reply = createReply();

    await registerHandler(createRequest({}, prisma), reply);

    expect(reply.statusCode).toBe(401);
  });

  it('rejects a body whose supabaseId does not match the token subject (403)', async () => {
    mockValidToken();
    const prisma = { findUnique: vi.fn(), create: vi.fn() };
    const reply = createReply();

    await registerHandler(
      createRequest(
        { email: TOKEN_EMAIL, supabaseId: '223e4567-e89b-42d3-a456-426614174000' },
        prisma,
      ),
      reply,
    );

    expect(reply.statusCode).toBe(403);
    expect(prisma.create).not.toHaveBeenCalled();
  });

  it('returns the existing user when the supabaseId is already registered', async () => {
    mockValidToken();
    const existing = {
      id: 'local-id',
      email: TOKEN_EMAIL,
      canton: 'ZH',
      birthYear: 1990,
      createdAt: new Date('2026-01-01T00:00:00.000Z'),
    };
    const prisma = {
      findUnique: vi.fn().mockResolvedValue(existing),
      create: vi.fn(),
    };
    const reply = createReply();

    await registerHandler(
      createRequest({ email: TOKEN_EMAIL, supabaseId: TOKEN_SUB }, prisma),
      reply,
    );

    expect(reply.statusCode).toBe(200);
    expect(reply.payload).toMatchObject({ id: 'local-id', email: TOKEN_EMAIL });
    expect(prisma.create).not.toHaveBeenCalled();
  });

  it('uses the verified token email, never the body email (account-linking protection)', async () => {
    // Attack scenario: the caller controls the body. The email used for the create
    // must come from the JWT claims — here the body email is someone else's.
    mockValidToken();
    const created = {
      id: 'new-id',
      email: TOKEN_EMAIL,
      canton: null,
      birthYear: null,
      createdAt: new Date('2026-01-01T00:00:00.000Z'),
    };
    const prisma = {
      findUnique: vi.fn().mockResolvedValue(null),
      create: vi.fn().mockResolvedValue(created),
    };
    const reply = createReply();

    await registerHandler(
      createRequest({ email: 'victim@example.ch', supabaseId: TOKEN_SUB }, prisma),
      reply,
    );

    expect(reply.statusCode).toBe(200);
    expect(prisma.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { supabaseId: TOKEN_SUB, email: TOKEN_EMAIL },
      }),
    );
  });

  it('refuses to re-link an existing account owned by a different Supabase user (409)', async () => {
    mockValidToken();
    const prisma = {
      findUnique: vi.fn().mockImplementation(({ where }: { where: Record<string, string> }) => {
        if (where.supabaseId) return Promise.resolve(null); // not registered under this token
        if (where.email === TOKEN_EMAIL)
          return Promise.resolve({ supabaseId: 'another-supabase-user' });
        return Promise.resolve(null);
      }),
      create: vi.fn(),
    };
    const reply = createReply();

    await registerHandler(
      createRequest({ email: TOKEN_EMAIL, supabaseId: TOKEN_SUB }, prisma),
      reply,
    );

    expect(reply.statusCode).toBe(409);
    expect(reply.payload).toEqual({ error: 'Un compte existe déjà avec cet email' });
    expect(prisma.create).not.toHaveBeenCalled();
  });

  it('maps a unique-constraint violation on create (P2002 race) to 409', async () => {
    // Two concurrent registers with the same email both pass the findUnique guard;
    // the loser hits the DB unique constraint and must get a 409, not a 500.
    mockValidToken();
    const prisma = {
      findUnique: vi.fn().mockResolvedValue(null),
      create: vi.fn().mockRejectedValue(
        new Prisma.PrismaClientKnownRequestError(
          'Unique constraint failed on the fields: (email)',
          {
            code: 'P2002',
            clientVersion: '7.5.0',
          },
        ),
      ),
    };
    const reply = createReply();

    await registerHandler(
      createRequest({ email: TOKEN_EMAIL, supabaseId: TOKEN_SUB }, prisma),
      reply,
    );

    expect(reply.statusCode).toBe(409);
    expect(reply.payload).toEqual({ error: 'Un compte existe déjà avec cet email' });
  });

  it('accepts a body without email (the field is ignored — the email comes from the JWT)', async () => {
    mockValidToken();
    const created = {
      id: 'new-id',
      email: TOKEN_EMAIL,
      canton: null,
      birthYear: null,
      createdAt: new Date('2026-01-01T00:00:00.000Z'),
    };
    const prisma = {
      findUnique: vi.fn().mockResolvedValue(null),
      create: vi.fn().mockResolvedValue(created),
    };
    const reply = createReply();

    await registerHandler(createRequest({ supabaseId: TOKEN_SUB }, prisma), reply);

    expect(reply.statusCode).toBe(200);
    expect(prisma.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { supabaseId: TOKEN_SUB, email: TOKEN_EMAIL },
      }),
    );
  });

  it('rejects a token without an email claim (400)', async () => {
    mocks.getUser.mockResolvedValue({
      data: { user: { id: TOKEN_SUB, email: undefined } },
      error: null,
    });
    const prisma = { findUnique: vi.fn(), create: vi.fn() };
    const reply = createReply();

    await registerHandler(
      createRequest({ email: TOKEN_EMAIL, supabaseId: TOKEN_SUB }, prisma),
      reply,
    );

    expect(reply.statusCode).toBe(400);
    expect(prisma.create).not.toHaveBeenCalled();
  });

  it('returns 401 (not 500) when the Supabase validation call throws (network failure)', async () => {
    // A getUser that rejects must not bubble up as an internal error.
    mocks.getUser.mockRejectedValue(new Error('network down'));
    const prisma = { findUnique: vi.fn(), create: vi.fn() };
    const reply = createReply();

    await registerHandler(createRequest({}, prisma), reply);

    expect(reply.statusCode).toBe(401);
    expect(prisma.create).not.toHaveBeenCalled();
  });
});
