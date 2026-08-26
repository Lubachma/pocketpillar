import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Readable } from 'node:stream';
import type { FastifyReply, FastifyRequest } from 'fastify';
import { MAX_FILE_SIZE } from '../../../src/modules/document/document.schema.js';

// Minimal env so importing src/config (via the handler) does not exit the process.
const mocks = vi.hoisted(() => {
  process.env.DATABASE_URL = 'postgresql://localhost:5432/test';
  process.env.REDIS_URL = 'redis://localhost:6379';
  process.env.SUPABASE_URL = 'https://test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
  return { storageUpload: vi.fn(), storageRemove: vi.fn() };
});

vi.mock('../../../src/lib/supabase.js', () => ({
  supabaseAdmin: {
    storage: {
      from: vi.fn(() => ({ upload: mocks.storageUpload, remove: mocks.storageRemove })),
    },
  },
}));

import { uploadDocumentHandler } from '../../../src/modules/document/document.handler.js';

const PDF_HEADER = Buffer.from('%PDF');

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

const DOC_ROW = {
  id: 'doc-1',
  type: 'TAX_DECLARATION',
  filename: 'fiche.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 0,
  year: 2025,
  uploadedAt: new Date('2026-01-01T00:00:00.000Z'),
};

interface UploadOptions {
  mimetype?: string;
  filename?: string;
  chunks?: Buffer[];
  fields?: Record<string, { value: string }>;
}

function createRequest(options: UploadOptions = {}) {
  const {
    mimetype = 'application/pdf',
    filename = 'fiche.pdf',
    chunks = [Buffer.from('%PDF-1.7 corps du fichier')],
    fields = { type: { value: 'TAX_DECLARATION' }, year: { value: '2025' } },
  } = options;
  const fileStream = Readable.from(chunks);
  const resumeSpy = vi.spyOn(fileStream, 'resume');
  const create = vi
    .fn()
    .mockImplementation(({ data }) =>
      Promise.resolve({ ...DOC_ROW, ...data, uploadedAt: DOC_ROW.uploadedAt }),
    );
  // Premium gating: not premium by default (no subscription) with 0 documents
  // stored — under the free limit, historical behavior is unchanged.
  const subscriptionFindUnique = vi.fn().mockResolvedValue(null);
  const documentCount = vi.fn().mockResolvedValue(0);
  const request = {
    userId: 'user-1',
    locale: 'fr',
    log: { error: vi.fn(), warn: vi.fn() },
    file: vi.fn().mockResolvedValue({
      mimetype,
      filename,
      file: fileStream,
      fields,
    }),
    server: {
      prisma: {
        document: { create, count: documentCount },
        subscription: { findUnique: subscriptionFindUnique },
      },
      redis: { get: vi.fn().mockResolvedValue(null), set: vi.fn().mockResolvedValue('OK') },
    },
  };
  return {
    request: request as unknown as FastifyRequest & {
      log: { error: ReturnType<typeof vi.fn>; warn: ReturnType<typeof vi.fn> };
    },
    create,
    resumeSpy,
    subscriptionFindUnique,
    documentCount,
  };
}

/** Upload mock that consumes the streamed body like Supabase would. */
function mockUploadCapture(captured: { body: Buffer | null }) {
  mocks.storageUpload.mockImplementation(async (_path: string, body: AsyncIterable<Buffer>) => {
    const parts: Buffer[] = [];
    for await (const chunk of body) {
      parts.push(chunk);
    }
    captured.body = Buffer.concat(parts);
    return { data: { path: _path }, error: null };
  });
}

describe('uploadDocumentHandler (POST /documents)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.storageRemove.mockResolvedValue({ data: [], error: null });
  });

  it('returns 400 when no file is attached', async () => {
    const { request } = createRequest();
    (request.file as ReturnType<typeof vi.fn>).mockResolvedValue(undefined);
    const reply = createReply();

    await uploadDocumentHandler(request, reply);

    expect(reply.statusCode).toBe(400);
    expect(mocks.storageUpload).not.toHaveBeenCalled();
  });

  it('402 at the free-plan limit (1 document, non-premium) — stream drained, no upload', async () => {
    const { request, resumeSpy, documentCount } = createRequest();
    documentCount.mockResolvedValue(1);
    const reply = createReply();

    await uploadDocumentHandler(request, reply);

    expect(reply.statusCode).toBe(402);
    expect(resumeSpy).toHaveBeenCalled();
    expect(mocks.storageUpload).not.toHaveBeenCalled();
  });

  it('premium: no document limit (upload accepted with 5 existing documents)', async () => {
    const { request, subscriptionFindUnique, documentCount } = createRequest();
    subscriptionFindUnique.mockResolvedValue({
      expiresAt: new Date(Date.now() + 86_400_000),
    });
    documentCount.mockResolvedValue(5);
    const captured = { body: null as Buffer | null };
    mockUploadCapture(captured);
    const reply = createReply();

    await uploadDocumentHandler(request, reply);

    expect(reply.statusCode).toBe(201);
  });

  it('streams a valid file to Storage without buffering it whole (201)', async () => {
    const chunks = [Buffer.from('%PDF-1.7 '), Buffer.alloc(1024, 1), Buffer.from('queue')];
    const { request, create } = createRequest({ chunks });
    const captured = { body: null as Buffer | null };
    mockUploadCapture(captured);
    const reply = createReply();

    await uploadDocumentHandler(request, reply);

    expect(reply.statusCode).toBe(201);
    expect(mocks.storageUpload).toHaveBeenCalledTimes(1);
    const [path, body, options] = mocks.storageUpload.mock.calls[0] as [
      string,
      AsyncIterable<Buffer>,
      { contentType: string },
    ];
    expect(path).toMatch(/^user-1\/.+-fiche\.pdf$/);
    // A stream is handed to Supabase — not an in-memory Buffer.
    expect(Buffer.isBuffer(body)).toBe(false);
    expect(options.contentType).toBe('application/pdf');
    // The full content (magic bytes re-injected) reached Storage unaltered.
    expect(captured.body).toEqual(Buffer.concat(chunks));
    expect(create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ sizeBytes: Buffer.concat(chunks).length }),
      }),
    );
    expect((reply.payload as { sizeBytes: number }).sizeBytes).toBe(Buffer.concat(chunks).length);
  });

  it('validates the magic bytes across a chunk boundary (< 4 bytes first chunk)', async () => {
    const chunks = [Buffer.from('%P'), Buffer.from('DF-1.7 suite')];
    const { request } = createRequest({ chunks });
    const captured = { body: null as Buffer | null };
    mockUploadCapture(captured);
    const reply = createReply();

    await uploadDocumentHandler(request, reply);

    expect(reply.statusCode).toBe(201);
    expect(captured.body).toEqual(Buffer.concat(chunks));
  });

  it('rejects a disallowed MIME type (400) and drains the stream', async () => {
    const { request, resumeSpy } = createRequest({ mimetype: 'text/plain' });
    const reply = createReply();

    await uploadDocumentHandler(request, reply);

    expect(reply.statusCode).toBe(400);
    expect(reply.payload).toEqual({
      error: 'Type de fichier non supporté. Utilisez PDF, JPEG ou PNG.',
    });
    expect(resumeSpy).toHaveBeenCalled();
    expect(mocks.storageUpload).not.toHaveBeenCalled();
  });

  it('rejects content that does not match the declared MIME (400), before any upload', async () => {
    const { request, resumeSpy } = createRequest({
      chunks: [Buffer.from('not-a-pdf-at-all')],
    });
    const reply = createReply();

    await uploadDocumentHandler(request, reply);

    expect(reply.statusCode).toBe(400);
    expect(reply.payload).toEqual({
      error: 'Type de fichier non supporté. Utilisez PDF, JPEG ou PNG.',
    });
    expect(resumeSpy).toHaveBeenCalled();
    expect(mocks.storageUpload).not.toHaveBeenCalled();
  });

  it('rejects a file larger than 10 MB (400) and aborts the upload mid-stream', async () => {
    const { request, create, resumeSpy } = createRequest({
      chunks: [PDF_HEADER, Buffer.alloc(MAX_FILE_SIZE)],
    });
    // The upload promise rejects when the handler destroys the body stream.
    mocks.storageUpload.mockImplementation(async (_path: string, body: AsyncIterable<Buffer>) => {
      // Consume until the handler aborts — like the real client would.
      for await (const chunk of body) void chunk;
      return { data: null, error: null };
    });
    const reply = createReply();

    await uploadDocumentHandler(request, reply);

    expect(reply.statusCode).toBe(400);
    expect(reply.payload).toEqual({ error: 'Le fichier dépasse la taille maximale de 10 Mo' });
    expect(resumeSpy).toHaveBeenCalled();
    expect(create).not.toHaveBeenCalled();
  });

  it('returns 500 when the Storage upload fails', async () => {
    const { request, create } = createRequest();
    mocks.storageUpload.mockImplementation(async (_path: string, body: AsyncIterable<Buffer>) => {
      // Drain the body like the real client.
      for await (const chunk of body) void chunk;
      return { data: null, error: new Error('storage down') };
    });
    const reply = createReply();

    await uploadDocumentHandler(request, reply);

    expect(reply.statusCode).toBe(500);
    expect(create).not.toHaveBeenCalled();
  });

  it('removes the stored file when the fields are invalid (no orphan left behind)', async () => {
    const { request, create } = createRequest({ fields: {} });
    mocks.storageUpload.mockImplementation(async (_path: string, body: AsyncIterable<Buffer>) => {
      for await (const chunk of body) void chunk; // drain
      return { data: { path: _path }, error: null };
    });
    const reply = createReply();

    await uploadDocumentHandler(request, reply);

    expect(reply.statusCode).toBe(400);
    expect(create).not.toHaveBeenCalled();
    const [uploadedPath] = mocks.storageUpload.mock.calls[0] as [string];
    expect(mocks.storageRemove).toHaveBeenCalledWith([uploadedPath]);
  });
});
