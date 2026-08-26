import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { FastifyReply, FastifyRequest } from 'fastify';

// Minimal env so importing src/config (via the handler) does not exit the process.
const mocks = vi.hoisted(() => {
  process.env.DATABASE_URL = 'postgresql://localhost:5432/test';
  process.env.REDIS_URL = 'redis://localhost:6379';
  process.env.SUPABASE_URL = 'https://test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
  return { deleteUser: vi.fn(), storageRemove: vi.fn(), storageList: vi.fn() };
});

vi.mock('../../../src/lib/supabase.js', () => ({
  supabaseAdmin: {
    auth: { admin: { deleteUser: mocks.deleteUser } },
    storage: {
      from: vi.fn(() => ({ remove: mocks.storageRemove, list: mocks.storageList })),
    },
  },
}));

import { deleteMeHandler } from '../../../src/modules/user/user.handler.js';

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

interface UserPrismaMock {
  findUnique: ReturnType<typeof vi.fn>;
  delete: ReturnType<typeof vi.fn>;
}

function createRequest(
  user: UserPrismaMock,
  document: { findMany: ReturnType<typeof vi.fn> } = { findMany: vi.fn().mockResolvedValue([]) },
) {
  return {
    userId: 'user-local-id',
    locale: 'fr',
    log: { error: vi.fn() },
    server: { prisma: { user, document } },
  } as unknown as FastifyRequest & { log: { error: ReturnType<typeof vi.fn> } };
}

describe('deleteMeHandler (DELETE /users/me)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.storageRemove.mockResolvedValue({ data: [], error: null });
    mocks.storageList.mockResolvedValue({ data: [], error: null });
  });

  it('returns 404 when the user row no longer exists', async () => {
    const prisma = {
      findUnique: vi.fn().mockResolvedValue(null),
      delete: vi.fn(),
    };
    const request = createRequest(prisma);
    const reply = createReply();

    await deleteMeHandler(request, reply);

    expect(reply.statusCode).toBe(404);
    expect(reply.payload).toEqual({ error: 'Utilisateur non trouvé' });
    expect(prisma.delete).not.toHaveBeenCalled();
    expect(mocks.deleteUser).not.toHaveBeenCalled();
  });

  it('deletes the Prisma row (cascades to profile, accounts, documents) and the Supabase user', async () => {
    const prisma = {
      findUnique: vi.fn().mockResolvedValue({ supabaseId: 'supabase-uid-1' }),
      delete: vi.fn().mockResolvedValue({}),
    };
    const document = { findMany: vi.fn().mockResolvedValue([]) };
    mocks.deleteUser.mockResolvedValue({ error: null });
    const request = createRequest(prisma, document);
    const reply = createReply();

    await deleteMeHandler(request, reply);

    expect(prisma.delete).toHaveBeenCalledWith({ where: { id: 'user-local-id' } });
    expect(mocks.deleteUser).toHaveBeenCalledWith('supabase-uid-1');
    // No documents → nothing to purge from the bucket.
    expect(mocks.storageRemove).not.toHaveBeenCalled();
    expect(reply.statusCode).toBe(204);
  });

  it('purges the Storage objects (exact paths) before deleting the Prisma row', async () => {
    const callOrder: string[] = [];
    const prisma = {
      findUnique: vi.fn().mockResolvedValue({ supabaseId: 'supabase-uid-1' }),
      delete: vi.fn().mockImplementation(() => {
        callOrder.push('prisma.delete');
        return Promise.resolve({});
      }),
    };
    const document = {
      findMany: vi
        .fn()
        .mockResolvedValue([
          { storagePath: 'user-local-id/aaa-certificat.pdf' },
          { storagePath: 'user-local-id/bbb-fiche.pdf' },
        ]),
    };
    mocks.storageRemove.mockImplementation(() => {
      callOrder.push('storage.remove');
      return Promise.resolve({ data: [], error: null });
    });
    mocks.deleteUser.mockResolvedValue({ error: null });
    const request = createRequest(prisma, document);
    const reply = createReply();

    await deleteMeHandler(request, reply);

    expect(mocks.storageRemove).toHaveBeenCalledWith([
      'user-local-id/aaa-certificat.pdf',
      'user-local-id/bbb-fiche.pdf',
    ]);
    expect(callOrder).toEqual(['storage.remove', 'prisma.delete']);
    expect(reply.statusCode).toBe(204);
  });

  it('still returns 204 when the Storage purge fails (best-effort, failure is logged)', async () => {
    const prisma = {
      findUnique: vi.fn().mockResolvedValue({ supabaseId: 'supabase-uid-1' }),
      delete: vi.fn().mockResolvedValue({}),
    };
    const document = {
      findMany: vi.fn().mockResolvedValue([{ storagePath: 'user-local-id/aaa.pdf' }]),
    };
    mocks.storageRemove.mockResolvedValue({ data: null, error: new Error('storage down') });
    mocks.deleteUser.mockResolvedValue({ error: null });
    const request = createRequest(prisma, document);
    const reply = createReply();

    await deleteMeHandler(request, reply);

    expect(prisma.delete).toHaveBeenCalledWith({ where: { id: 'user-local-id' } });
    expect(reply.statusCode).toBe(204);
    expect(request.log.error).toHaveBeenCalled();
  });

  it('still returns 204 when the Supabase deletion fails (data is gone; failure is logged)', async () => {
    const prisma = {
      findUnique: vi.fn().mockResolvedValue({ supabaseId: 'supabase-uid-1' }),
      delete: vi.fn().mockResolvedValue({}),
    };
    mocks.deleteUser.mockResolvedValue({ error: new Error('supabase down') });
    const request = createRequest(prisma);
    const reply = createReply();

    await deleteMeHandler(request, reply);

    expect(reply.statusCode).toBe(204);
    expect(request.log.error).toHaveBeenCalled();
  });

  it('sweeps the ${userId}/ prefix after the delete — covers an upload racing the deletion', async () => {
    const callOrder: string[] = [];
    const prisma = {
      findUnique: vi.fn().mockResolvedValue({ supabaseId: 'supabase-uid-1' }),
      delete: vi.fn().mockImplementation(() => {
        callOrder.push('prisma.delete');
        return Promise.resolve({});
      }),
    };
    // No DB documents: the racing upload's row was already gone with the cascade.
    const document = { findMany: vi.fn().mockResolvedValue([]) };
    // …but its file is still in the bucket under the user's prefix.
    mocks.storageList.mockImplementation(() => {
      callOrder.push('storage.list');
      return Promise.resolve({ data: [{ name: 'orphan-upload.pdf' }], error: null });
    });
    mocks.deleteUser.mockResolvedValue({ error: null });
    const request = createRequest(prisma, document);
    const reply = createReply();

    await deleteMeHandler(request, reply);

    expect(mocks.storageList).toHaveBeenCalledWith('user-local-id', { limit: 1000 });
    expect(mocks.storageRemove).toHaveBeenCalledWith(['user-local-id/orphan-upload.pdf']);
    // The sweep runs after the cascade, so the row is already gone.
    expect(callOrder).toEqual(['prisma.delete', 'storage.list']);
    expect(reply.statusCode).toBe(204);
  });

  it('still returns 204 when the prefix sweep fails (best-effort, failure is logged)', async () => {
    const prisma = {
      findUnique: vi.fn().mockResolvedValue({ supabaseId: 'supabase-uid-1' }),
      delete: vi.fn().mockResolvedValue({}),
    };
    mocks.storageList.mockResolvedValue({ data: null, error: new Error('storage down') });
    mocks.deleteUser.mockResolvedValue({ error: null });
    const request = createRequest(prisma);
    const reply = createReply();

    await deleteMeHandler(request, reply);

    expect(reply.statusCode).toBe(204);
    expect(request.log.error).toHaveBeenCalled();
  });
});
