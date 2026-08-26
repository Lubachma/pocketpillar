import type { FastifyRequest, FastifyReply } from 'fastify';
import { randomUUID } from 'node:crypto';
import { basename } from 'node:path';
import { once } from 'node:events';
import { PassThrough } from 'node:stream';
import { config } from '../../config/index.js';
import { t } from '../../lib/i18n/index.js';
import { supabaseAdmin } from '../../lib/supabase.js';
import {
  uploadDocumentFieldsSchema,
  listDocumentsQuerySchema,
  documentParamsSchema,
  ALLOWED_MIME_TYPES,
  MAX_FILE_SIZE,
} from './document.schema.js';
import { FREE_DOCUMENT_LIMIT, isPremiumUser } from '../subscription/subscription.service.js';

const BUCKET = 'documents';

function sanitizeFilename(raw: string): string {
  return basename(raw)
    .replace(/[^A-Za-z0-9._-]/g, '_')
    .slice(0, 200);
}

function validateMagicBytes(buffer: Buffer, mime: string): boolean {
  if (buffer.length < 4) return false;
  if (mime === 'application/pdf') return buffer.slice(0, 4).toString() === '%PDF';
  if (mime === 'image/png') return buffer.readUInt32BE(0) === 0x89504e47;
  if (mime === 'image/jpeg') return buffer[0] === 0xff && buffer[1] === 0xd8;
  return false;
}

export async function uploadDocumentHandler(request: FastifyRequest, reply: FastifyReply) {
  const data = await request.file();
  if (!data) {
    return reply.status(400).send({ error: t(request.locale, 'doc.file_required') });
  }

  // Free plan: 1 document (Premium = unlimited) — rejected before reading
  // the stream; like other rejections, the multipart body is drained.
  if (!(await isPremiumUser(request.server, request.userId!))) {
    const count = await request.server.prisma.document.count({
      where: { userId: request.userId! },
    });
    if (count >= FREE_DOCUMENT_LIMIT) {
      data.file.resume();
      return reply.status(402).send({ error: t(request.locale, 'sub.document_limit') });
    }
  }

  // Validate MIME type
  if (!ALLOWED_MIME_TYPES.includes(data.mimetype)) {
    // Drain the stream — an unconsumed multipart file stalls the request.
    data.file.resume();
    return reply.status(400).send({ error: t(request.locale, 'doc.invalid_mime') });
  }

  // Read the leading bytes for the magic-bytes check before opening the upload.
  const iterator = data.file[Symbol.asyncIterator]();
  const headerChunks: Buffer[] = [];
  let totalBytes = 0;
  while (totalBytes < 4) {
    const next = await iterator.next();
    if (next.done) break;
    headerChunks.push(next.value);
    totalBytes += next.value.length;
  }

  // Validate magic bytes match declared MIME type
  if (!validateMagicBytes(Buffer.concat(headerChunks), data.mimetype)) {
    data.file.resume();
    return reply.status(400).send({ error: t(request.locale, 'doc.invalid_mime') });
  }

  const userId = request.userId!;
  const fileId = randomUUID();
  const safeFilename = sanitizeFilename(data.filename);
  const storagePath = `${userId}/${fileId}-${safeFilename}`;

  // Stream the file to Supabase Storage through a PassThrough — the file is
  // never buffered whole in memory. The leading bytes are re-injected first.
  const stream = new PassThrough();
  const uploadPromise = supabaseAdmin.storage.from(BUCKET).upload(storagePath, stream, {
    contentType: data.mimetype,
    upsert: false,
  });
  // A rejection is observed on the await below, once the pump has finished.
  uploadPromise.catch(() => {});

  for (const chunk of headerChunks) {
    stream.write(chunk);
  }

  // Pump the rest of the file, cutting the stream off at the size limit.
  let tooLarge = false;
  for (;;) {
    const next = await iterator.next();
    if (next.done) break;
    totalBytes += next.value.length;
    if (totalBytes > MAX_FILE_SIZE) {
      tooLarge = true;
      break;
    }
    if (!stream.write(next.value)) {
      await once(stream, 'drain');
    }
  }

  if (tooLarge) {
    // Destroying the body aborts the upload — no object is stored.
    stream.destroy(new Error('file too large'));
    data.file.resume();
    return reply.status(400).send({ error: t(request.locale, 'doc.file_too_large') });
  }

  stream.end();
  const { error: storageError } = await uploadPromise;

  if (storageError) {
    request.log.error({ err: storageError }, 'Storage upload failed');
    return reply.status(500).send({ error: t(request.locale, 'doc.upload_failed') });
  }

  // Parse fields from multipart (the body is fully consumed by now)
  const fields: Record<string, string> = {};
  for (const [key, field] of Object.entries(data.fields)) {
    if (field && typeof field === 'object' && 'value' in field) {
      fields[key] = (field as { value: string }).value;
    }
  }

  const parsed = uploadDocumentFieldsSchema.safeParse(fields);
  if (!parsed.success) {
    // The file is already stored — remove it rather than leave an orphan.
    try {
      await supabaseAdmin.storage.from(BUCKET).remove([storagePath]);
    } catch (err) {
      request.log.warn({ err }, 'Storage cleanup after rejected upload failed');
    }
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  // Save metadata in Prisma
  const doc = await request.server.prisma.document.create({
    data: {
      userId,
      type: parsed.data.type,
      filename: safeFilename,
      storagePath,
      mimeType: data.mimetype,
      sizeBytes: totalBytes,
      year: parsed.data.year,
    },
  });

  return reply.status(201).send({
    id: doc.id,
    type: doc.type,
    filename: doc.filename,
    mimeType: doc.mimeType,
    sizeBytes: doc.sizeBytes,
    year: doc.year,
    uploadedAt: doc.uploadedAt.toISOString(),
  });
}

export async function listDocumentsHandler(
  request: FastifyRequest<{ Querystring: unknown }>,
  reply: FastifyReply,
) {
  const parsed = listDocumentsQuerySchema.safeParse(request.query);
  if (!parsed.success) {
    return reply.status(400).send({ error: t(request.locale, 'error.validation') });
  }

  const documents = await request.server.prisma.document.findMany({
    where: {
      userId: request.userId!,
      ...(parsed.data.type ? { type: parsed.data.type } : {}),
    },
    orderBy: { uploadedAt: 'desc' },
    select: {
      id: true,
      type: true,
      filename: true,
      mimeType: true,
      sizeBytes: true,
      year: true,
      uploadedAt: true,
    },
  });

  return reply.send(documents.map((d) => ({ ...d, uploadedAt: d.uploadedAt.toISOString() })));
}

export async function downloadDocumentHandler(
  request: FastifyRequest<{ Params: unknown }>,
  reply: FastifyReply,
) {
  const parsed = documentParamsSchema.safeParse(request.params);
  if (!parsed.success) {
    return reply.status(400).send({ error: t(request.locale, 'error.validation') });
  }

  const doc = await request.server.prisma.document.findFirst({
    where: { id: parsed.data.id, userId: request.userId! },
  });

  if (!doc) {
    return reply.status(404).send({ error: t(request.locale, 'doc.not_found') });
  }

  const { data: signedUrl, error } = await supabaseAdmin.storage
    .from(BUCKET)
    .createSignedUrl(doc.storagePath, 300); // 5 minutes

  if (error || !signedUrl) {
    return reply.status(500).send({ error: t(request.locale, 'doc.download_failed') });
  }

  return reply.send({
    url: signedUrl.signedUrl,
    filename: doc.filename,
    mimeType: doc.mimeType,
  });
}

export async function deleteDocumentHandler(
  request: FastifyRequest<{ Params: unknown }>,
  reply: FastifyReply,
) {
  const parsed = documentParamsSchema.safeParse(request.params);
  if (!parsed.success) {
    return reply.status(400).send({ error: t(request.locale, 'error.validation') });
  }

  const doc = await request.server.prisma.document.findFirst({
    where: { id: parsed.data.id, userId: request.userId! },
  });

  if (!doc) {
    return reply.status(404).send({ error: t(request.locale, 'doc.not_found') });
  }

  // Delete from Supabase Storage
  const { error: storageError } = await supabaseAdmin.storage
    .from(BUCKET)
    .remove([doc.storagePath]);

  if (storageError) {
    request.log.error({ err: storageError, storagePath: doc.storagePath }, 'Storage delete failed');
    return reply.status(500).send({ error: t(request.locale, 'doc.delete_failed') });
  }

  // Delete from Prisma
  await request.server.prisma.document.delete({ where: { id: doc.id } });

  return reply.status(204).send();
}
