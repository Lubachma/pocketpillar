import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import Fastify, { type FastifyInstance } from 'fastify';
import rateLimit from '@fastify/rate-limit';
import i18nPlugin from '../../src/plugins/i18n.js';
import errorHandlerPlugin from '../../src/plugins/error-handler.js';

/**
 * Unified error contract: every error — unknown route, native Fastify validation,
 * unexpected throw — is served as `{ error: string }` (never the native
 * `{ statusCode, error, message }` shape).
 */
describe('error-handler plugin', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = Fastify({ logger: false });
    await app.register(i18nPlugin);
    await app.register(errorHandlerPlugin);
    app.get('/boom', async () => {
      throw new Error('sensitive internals');
    });
    // Rate limit scoped to this route only (encapsulated context) so the other
    // tests are not throttled.
    await app.register(async (limited) => {
      await limited.register(rateLimit, { max: 1, timeWindow: '1 minute' });
      limited.get('/limited', async () => ({ ok: true }));
    });
    app.post(
      '/validated',
      {
        schema: {
          body: {
            type: 'object',
            required: ['email'],
            properties: { email: { type: 'string' } },
          },
        },
      },
      async () => ({ ok: true }),
    );
  });

  afterAll(async () => {
    await app.close();
  });

  it('maps unknown routes to 404 { error } (localized)', async () => {
    const fr = await app.inject({ method: 'GET', url: '/no-such-route' });
    expect(fr.statusCode).toBe(404);
    expect(fr.json()).toEqual({ error: 'Ressource non trouvée' });

    const en = await app.inject({
      method: 'GET',
      url: '/no-such-route',
      headers: { 'accept-language': 'en' },
    });
    expect(en.statusCode).toBe(404);
    expect(en.json()).toEqual({ error: 'Resource not found' });
  });

  it('maps unexpected throws to 500 { error } without leaking internals', async () => {
    const res = await app.inject({ method: 'GET', url: '/boom' });
    expect(res.statusCode).toBe(500);
    const body = res.json();
    expect(body).toEqual({ error: 'Une erreur interne est survenue' });
    expect(JSON.stringify(body)).not.toContain('sensitive internals');
  });

  it('maps rate-limit rejections to 429 { error }', async () => {
    const first = await app.inject({ method: 'GET', url: '/limited' });
    expect(first.statusCode).toBe(200);

    const res = await app.inject({ method: 'GET', url: '/limited' });
    expect(res.statusCode).toBe(429);
    const body = res.json();
    // Single { error } shape — the native statusCode/message fields are gone.
    expect(typeof body.error).toBe('string');
    expect(body.statusCode).toBeUndefined();
    expect(body.message).toBeUndefined();
  });

  it('maps native Fastify schema-validation errors to 400 { error }', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/validated',
      payload: {},
    });
    expect(res.statusCode).toBe(400);
    const body = res.json();
    // Single { error } shape — no native statusCode/message fields.
    expect(typeof body.error).toBe('string');
    expect(body.statusCode).toBeUndefined();
    expect(body.message).toBeUndefined();
  });
});
