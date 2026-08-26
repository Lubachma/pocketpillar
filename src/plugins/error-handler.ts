import fp from 'fastify-plugin';
import type { FastifyInstance, FastifyError } from 'fastify';
import { t } from '../lib/i18n/index.js';

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
