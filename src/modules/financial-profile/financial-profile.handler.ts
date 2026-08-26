import type { FastifyRequest, FastifyReply } from 'fastify';
import { Prisma } from '@prisma/client';
import { config } from '../../config/index.js';
import { t } from '../../lib/i18n/index.js';
import {
  createFinancialProfileSchema,
  updateFinancialProfileSchema,
  createPillar2AccountSchema,
  updatePillar2AccountSchema,
  createPillar3aAccountSchema,
  updatePillar3aAccountSchema,
  upsertTaxSituationSchema,
} from './financial-profile.schema.js';

// ─── Financial Profile ────────────────────────

export async function getFinancialProfile(request: FastifyRequest, reply: FastifyReply) {
  const profile = await request.server.prisma.financialProfile.findUnique({
    where: { userId: request.userId! },
  });

  if (!profile) {
    return reply.status(404).send({ error: t(request.locale, 'error.profile_not_found') });
  }

  return reply.send(profile);
}

export async function upsertFinancialProfile(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const existing = await request.server.prisma.financialProfile.findUnique({
    where: { userId: request.userId! },
  });

  const schema = existing ? updateFinancialProfileSchema : createFinancialProfileSchema;
  const parsed = schema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const profile = await request.server.prisma.financialProfile.upsert({
    where: { userId: request.userId! },
    create: { userId: request.userId!, ...parsed.data } as Parameters<
      typeof request.server.prisma.financialProfile.upsert
    >[0]['create'],
    update: parsed.data,
  });

  return reply.status(existing ? 200 : 201).send(profile);
}

// ─── Pillar 2 ─────────────────────────────────

export async function getPillar2Accounts(request: FastifyRequest, reply: FastifyReply) {
  const accounts = await request.server.prisma.pillar2Account.findMany({
    where: { userId: request.userId! },
    orderBy: { createdAt: 'desc' },
  });

  return reply.send(accounts);
}

export async function createPillar2Account(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = createPillar2AccountSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const account = await request.server.prisma.pillar2Account.create({
    data: { userId: request.userId!, ...parsed.data },
  });

  return reply.status(201).send(account);
}

export async function updatePillar2Account(
  request: FastifyRequest<{ Params: { id: string }; Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = updatePillar2AccountSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  try {
    // Single round-trip: update throws P2025 when the id is unknown to this user.
    const account = await request.server.prisma.pillar2Account.update({
      where: { id: request.params.id, userId: request.userId! },
      data: parsed.data,
    });
    return reply.send(account);
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2025') {
      return reply.status(404).send({ error: t(request.locale, 'error.account_not_found') });
    }
    throw err;
  }
}

export async function deletePillar2Account(
  request: FastifyRequest<{ Params: { id: string } }>,
  reply: FastifyReply,
) {
  const result = await request.server.prisma.pillar2Account.deleteMany({
    where: { id: request.params.id, userId: request.userId! },
  });

  if (result.count === 0) {
    return reply.status(404).send({ error: t(request.locale, 'error.account_not_found') });
  }

  return reply.status(204).send();
}

// ─── Pillar 3a ────────────────────────────────

export async function getPillar3aAccounts(request: FastifyRequest, reply: FastifyReply) {
  const accounts = await request.server.prisma.pillar3aAccount.findMany({
    where: { userId: request.userId! },
    orderBy: { createdAt: 'desc' },
  });

  return reply.send(accounts);
}

export async function createPillar3aAccount(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = createPillar3aAccountSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const account = await request.server.prisma.pillar3aAccount.create({
    data: { userId: request.userId!, ...parsed.data },
  });

  return reply.status(201).send(account);
}

export async function updatePillar3aAccount(
  request: FastifyRequest<{ Params: { id: string }; Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = updatePillar3aAccountSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  try {
    // Single round-trip: update throws P2025 when the id is unknown to this user.
    const account = await request.server.prisma.pillar3aAccount.update({
      where: { id: request.params.id, userId: request.userId! },
      data: parsed.data,
    });
    return reply.send(account);
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2025') {
      return reply.status(404).send({ error: t(request.locale, 'error.account_not_found') });
    }
    throw err;
  }
}

export async function deletePillar3aAccount(
  request: FastifyRequest<{ Params: { id: string } }>,
  reply: FastifyReply,
) {
  const result = await request.server.prisma.pillar3aAccount.deleteMany({
    where: { id: request.params.id, userId: request.userId! },
  });

  if (result.count === 0) {
    return reply.status(404).send({ error: t(request.locale, 'error.account_not_found') });
  }

  return reply.status(204).send();
}

// ─── Tax Situation ────────────────────────────

export async function getTaxSituation(request: FastifyRequest, reply: FastifyReply) {
  const tax = await request.server.prisma.taxSituation.findUnique({
    where: { userId: request.userId! },
  });

  if (!tax) {
    return reply.status(404).send({ error: t(request.locale, 'error.tax_not_found') });
  }

  return reply.send(tax);
}

export async function upsertTaxSituation(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  const parsed = upsertTaxSituationSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  const existing = await request.server.prisma.taxSituation.findUnique({
    where: { userId: request.userId! },
  });

  const tax = await request.server.prisma.taxSituation.upsert({
    where: { userId: request.userId! },
    create: { userId: request.userId!, ...parsed.data },
    update: parsed.data,
  });

  return reply.status(existing ? 200 : 201).send(tax);
}
