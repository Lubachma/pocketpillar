import type { FastifyRequest, FastifyReply } from 'fastify';
import { Prisma } from '@prisma/client';
import { config } from '../../config/index.js';
import { t } from '../../lib/i18n/index.js';
import { supabaseAdmin } from '../../lib/supabase.js';
import { registerBodySchema } from './auth.schema.js';

/**
 * POST /auth/register
 * Semi-public: requires a valid Supabase JWT but does NOT require an existing Prisma User.
 * Creates a User row with supabaseId + email.
 */
export async function registerHandler(
  request: FastifyRequest<{ Body: unknown }>,
  reply: FastifyReply,
) {
  // --- Validate JWT ---
  const authHeader = request.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return reply.status(401).send({ error: t(request.locale, 'auth.missing_header') });
  }

  const token = authHeader.slice(7);

  let supabaseUser;
  try {
    const {
      data: { user },
      error: authError,
    } = await supabaseAdmin.auth.getUser(token);
    if (authError) throw authError;
    supabaseUser = user;
  } catch (err) {
    request.log.warn({ err }, 'Supabase getUser failed');
    return reply.status(401).send({ error: t(request.locale, 'auth.invalid_token') });
  }

  if (!supabaseUser) {
    return reply.status(401).send({ error: t(request.locale, 'auth.invalid_token') });
  }

  // --- Validate body ---
  const parsed = registerBodySchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: t(request.locale, 'error.validation'),
      details: config.NODE_ENV === 'development' ? parsed.error.issues : undefined,
    });
  }

  // Ensure the JWT subject matches the body
  if (supabaseUser.id !== parsed.data.supabaseId) {
    return reply.status(403).send({ error: t(request.locale, 'auth.forbidden') });
  }

  // The email is taken from the verified token claims — never from the request body,
  // which an attacker could use to target someone else's account.
  const email = supabaseUser.email;
  if (!email) {
    return reply.status(400).send({ error: t(request.locale, 'error.validation') });
  }

  // --- Create user ---
  // Look up by supabaseId first; if none exists, refuse to re-link an account
  // that already belongs to a different Supabase user (409).
  let user = await request.server.prisma.user.findUnique({
    where: { supabaseId: supabaseUser.id },
    select: { id: true, email: true, canton: true, birthYear: true, createdAt: true },
  });

  if (!user) {
    // Never re-link an account that already belongs to a different Supabase user.
    const existingByEmail = await request.server.prisma.user.findUnique({
      where: { email },
      select: { supabaseId: true },
    });
    if (existingByEmail && existingByEmail.supabaseId !== supabaseUser.id) {
      return reply.status(409).send({ error: t(request.locale, 'auth.email_taken') });
    }

    try {
      user = await request.server.prisma.user.create({
        data: {
          supabaseId: supabaseUser.id,
          email,
        },
        select: { id: true, email: true, canton: true, birthYear: true, createdAt: true },
      });
    } catch (err) {
      // Defense in depth: a concurrent register on the same email races past the
      // check above and loses on the unique constraint (P2002) — answer 409.
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        return reply.status(409).send({ error: t(request.locale, 'auth.email_taken') });
      }
      throw err;
    }
  }

  return reply.status(200).send({ ...user, createdAt: user.createdAt.toISOString() });
}
