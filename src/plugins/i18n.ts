import fp from 'fastify-plugin';
import type { FastifyInstance } from 'fastify';
import { parseAcceptLanguage, DEFAULT_LOCALE } from '../lib/i18n/index.js';

export default fp(async (fastify: FastifyInstance) => {
  fastify.decorateRequest('locale', DEFAULT_LOCALE);

  fastify.addHook('onRequest', async (request) => {
    request.locale = parseAcceptLanguage(request.headers['accept-language']);
  });
});
