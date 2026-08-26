import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Prisma } from '@prisma/client';
import type { FastifyReply, FastifyRequest } from 'fastify';

// Minimal env so importing src/config (via the handler) does not exit the process.
vi.hoisted(() => {
  process.env.DATABASE_URL = 'postgresql://localhost:5432/test';
  process.env.REDIS_URL = 'redis://localhost:6379';
  process.env.SUPABASE_URL = 'https://test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
});

import {
  updatePillar2Account,
  updatePillar3aAccount,
} from '../../../src/modules/financial-profile/financial-profile.handler.js';

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

function p2025() {
  return new Prisma.PrismaClientKnownRequestError('Record to update not found.', {
    code: 'P2025',
    clientVersion: '7.5.0',
  });
}

function createRequest(model: { update: ReturnType<typeof vi.fn> }, body: unknown) {
  return {
    userId: 'user-1',
    locale: 'fr',
    params: { id: 'account-1' },
    body,
    server: { prisma: { pillar2Account: model, pillar3aAccount: model } },
  } as unknown as FastifyRequest<{ Params: { id: string }; Body: unknown }>;
}

describe('updatePillar2Account (PUT /financial-profile/pillar2/:id)', () => {
  beforeEach(() => vi.clearAllMocks());

  it('updates in a single round-trip and returns the row', async () => {
    const updated = { id: 'account-1', currentCapital: 50_000 };
    const model = { update: vi.fn().mockResolvedValue(updated) };
    const reply = createReply();

    await updatePillar2Account(createRequest(model, { currentCapital: 50_000 }), reply);

    expect(model.update).toHaveBeenCalledWith({
      where: { id: 'account-1', userId: 'user-1' },
      data: { currentCapital: 50_000 },
    });
    expect(reply.statusCode).toBe(200);
    expect(reply.payload).toEqual(updated);
  });

  it('maps P2025 (unknown id or other owner) to 404', async () => {
    const model = { update: vi.fn().mockRejectedValue(p2025()) };
    const reply = createReply();

    await updatePillar2Account(createRequest(model, { currentCapital: 50_000 }), reply);

    expect(reply.statusCode).toBe(404);
    expect(reply.payload).toEqual({ error: 'Compte non trouvé' });
  });

  it('rethrows unexpected Prisma errors', async () => {
    const model = { update: vi.fn().mockRejectedValue(new Error('db down')) };

    await expect(
      updatePillar2Account(createRequest(model, { currentCapital: 50_000 }), createReply()),
    ).rejects.toThrow('db down');
  });

  it('rejects an invalid body (400) without touching Prisma', async () => {
    const model = { update: vi.fn() };
    const reply = createReply();

    await updatePillar2Account(createRequest(model, { currentCapital: -5 }), reply);

    expect(reply.statusCode).toBe(400);
    expect(model.update).not.toHaveBeenCalled();
  });
});

describe('updatePillar3aAccount (PUT /financial-profile/pillar3a/:id)', () => {
  beforeEach(() => vi.clearAllMocks());

  it('updates in a single round-trip and returns the row', async () => {
    const updated = { id: 'account-1', currentBalance: 10_000 };
    const model = { update: vi.fn().mockResolvedValue(updated) };
    const reply = createReply();

    await updatePillar3aAccount(createRequest(model, { currentBalance: 10_000 }), reply);

    expect(model.update).toHaveBeenCalledWith({
      where: { id: 'account-1', userId: 'user-1' },
      data: { currentBalance: 10_000 },
    });
    expect(reply.statusCode).toBe(200);
    expect(reply.payload).toEqual(updated);
  });

  it('maps P2025 (unknown id or other owner) to 404', async () => {
    const model = { update: vi.fn().mockRejectedValue(p2025()) };
    const reply = createReply();

    await updatePillar3aAccount(createRequest(model, { currentBalance: 10_000 }), reply);

    expect(reply.statusCode).toBe(404);
    expect(reply.payload).toEqual({ error: 'Compte non trouvé' });
  });
});
