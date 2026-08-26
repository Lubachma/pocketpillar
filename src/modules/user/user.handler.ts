import type { FastifyRequest, FastifyReply } from 'fastify';
import { config } from '../../config/index.js';
import { t } from '../../lib/i18n/index.js';
import { supabaseAdmin } from '../../lib/supabase.js';
import { premiumStatus } from '../subscription/subscription.service.js';
import { updateUserSchema } from './user.schema.js';

const userSelect = {
  id: true,
  email: true,
  canton: true,
  birthYear: true,
  replacementRateGoal: true,
  municipality: true,
  createdAt: true,
} as const;

export async function getMeHandler(request: FastifyRequest, reply: FastifyReply) {
  const user = await request.server.prisma.user.findUnique({
    where: { id: request.userId! },
    select: userSelect,
  });

  if (!user) {
    return reply.status(404).send({ error: t(request.locale, 'error.user_not_found') });
  }

  return reply.send({
    ...user,
    createdAt: user.createdAt.toISOString(),
    premium: await premiumStatus(request.server, user.id),
  });
}

export async function updateMeHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = updateUserSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const user = await request.server.prisma.user.update({
    where: { id: request.userId! },
    data: parsed.data,
    select: userSelect,
  });

  return reply.send({
    ...user,
    createdAt: user.createdAt.toISOString(),
    premium: await premiumStatus(request.server, user.id),
  });
}

const DOCUMENTS_BUCKET = 'documents'; // same bucket as document.handler.ts

/**
 * DELETE /users/me — account deletion (App Store guideline 5.1.1 / GDPR).
 * Purges the user's Storage objects, removes the local user row (Prisma cascades
 * to profile, accounts, tax situation and documents), then the Supabase auth
 * account.
 */
export async function deleteMeHandler(request: FastifyRequest, reply: FastifyReply) {
  const user = await request.server.prisma.user.findUnique({
    where: { id: request.userId! },
    select: { supabaseId: true },
  });

  if (!user) {
    return reply.status(404).send({ error: t(request.locale, 'error.user_not_found') });
  }

  // Purge the Storage objects before the cascade removes their DB rows — afterwards
  // the paths would be lost and the files orphaned in the bucket. Best-effort:
  // a Storage failure must not block the account deletion.
  const documents = await request.server.prisma.document.findMany({
    where: { userId: request.userId! },
    select: { storagePath: true },
  });

  if (documents.length > 0) {
    try {
      const { error: storageError } = await supabaseAdmin.storage
        .from(DOCUMENTS_BUCKET)
        .remove(documents.map((d) => d.storagePath));
      if (storageError) {
        request.log.error({ err: storageError }, 'Storage purge failed during account deletion');
      }
    } catch (err) {
      // Best-effort: a rejected remove() must not block the account deletion.
      request.log.error({ err }, 'Storage purge threw during account deletion');
    }
  }

  await request.server.prisma.user.delete({ where: { id: request.userId! } });

  // Race: an upload concurrent with the deletion can slip past the path-based
  // purge above (its DB row vanished with the cascade before the purge read
  // the paths). Sweep the whole `${userId}/` prefix — best-effort, like above.
  try {
    const { data: leftovers, error: listError } = await supabaseAdmin.storage
      .from(DOCUMENTS_BUCKET)
      .list(request.userId!, { limit: 1000 });
    if (listError) {
      request.log.error({ err: listError }, 'Storage sweep failed during account deletion');
    } else if (leftovers.length > 0) {
      const { error: sweepError } = await supabaseAdmin.storage
        .from(DOCUMENTS_BUCKET)
        .remove(leftovers.map((f) => `${request.userId!}/${f.name}`));
      if (sweepError) {
        request.log.error({ err: sweepError }, 'Storage sweep failed during account deletion');
      }
    }
  } catch (err) {
    request.log.error({ err }, 'Storage sweep threw during account deletion');
  }

  const { error } = await supabaseAdmin.auth.admin.deleteUser(user.supabaseId);
  if (error) {
    // The data is gone; the orphaned auth account can no longer resolve a user.
    request.log.error({ err: error }, 'Supabase user delete failed after account deletion');
  }

  return reply.status(204).send();
}
