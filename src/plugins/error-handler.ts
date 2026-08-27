import fp from 'fastify-plugin';
import type { FastifyInstance, FastifyError } from 'fastify';
import { t } from '../lib/i18n/index.js';
import { Prisma } from '@prisma/client';

/**
 * Unified error contract: every error response is `{ error: string }`.
 * Handlers already send localized `{ error }` payloads; this maps the native
 * Fastify errors (schema validation, rate limit, unknown routes, unexpected 500s)
 * to the same shape so clients only ever parse one format.
 */
export default fp(async (fastify: FastifyInstance) => {
  fastify.setNotFoundHandler((request, reply) => {
    return reply.status(404).send({ error: t(request.locale, 'error.not_found') });
  });

  fastify.setErrorHandler((error: FastifyError, request, reply) => {
    // Prisma P2023 ("inconsistent column data"): a malformed id in a
    // `where` — e.g. a non-UUID `:id` in the URL. Indistinguishable from a
    // nonexistent resource: 404, never a 500 (review 08.2026).
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2023') {
      return reply.status(404).send({ error: t(request.locale, 'error.not_found') });
    }

    const statusCode = error.statusCode ?? 500;

    // Unexpected failures: log server-side, never leak internals to the client.
    if (statusCode >= 500) {
      request.log.error({ err: error }, 'Unhandled error');
      return reply.status(statusCode).send({ error: t(request.locale, 'error.internal') });
    }

    // Native client errors (schema validation, rate limit, body too large, …):
    // keep Fastify's message, normalized to the { error } shape.
    return reply.status(statusCode).send({ error: error.message });
  });
});
