import { describe, it, expect, beforeAll, afterAll, vi } from 'vitest';
import Fastify, { type FastifyInstance } from 'fastify';

// Importing src/app.js pulls src/config, which validates the environment
// and exits the process when variables are missing (CI has no .env —
// locally the root .env masked this). Same hoisted stub as
// tests/integration/http-contract.test.ts.
vi.hoisted(() => {
  process.env.DATABASE_URL = 'postgresql://localhost:5432/test';
  process.env.REDIS_URL = 'redis://localhost:6379';
  process.env.SUPABASE_URL = 'https://test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
});

import { TRUST_PROXY } from '../src/app.js';

/**
 * Locks the trust-proxy policy actually used by `createApp` (imported, not
 * duplicated): X-Forwarded-For must be honoured ONLY when the immediate
 * peer is the platform's private network (Fly proxy) or loopback — never
 * for a direct external client. A hop-count (`trustProxy: 1`) fails both
 * ways: on fastify ≤5.11 it let direct clients spoof req.ip past the
 * per-IP rate limiter; on fastify ≥5.12 it fails closed and every request
 * would share the load balancer's IP.
 */
describe('TRUST_PROXY policy', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = Fastify({ trustProxy: TRUST_PROXY });
    app.get('/ip', (request) => ({ ip: request.ip }));
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  const inject = (remoteAddress: string, forwardedFor?: string) =>
    app.inject({
      method: 'GET',
      url: '/ip',
      remoteAddress,
      headers: forwardedFor ? { 'x-forwarded-for': forwardedFor } : {},
    });

  it('honours X-Forwarded-For from the private-network proxy (Fly IPv4)', async () => {
    const res = await inject('172.19.0.3', '203.0.113.7');
    expect(res.json()).toEqual({ ip: '203.0.113.7' });
  });

  it('honours X-Forwarded-For from an IPv4-MAPPED private peer (::ffff:172.x — the form Node reports on Fly)', async () => {
    const res = await inject('::ffff:172.19.0.5', '203.0.113.7');
    expect(res.json()).toEqual({ ip: '203.0.113.7' });
  });

  it('honours X-Forwarded-For from the private-network proxy (Fly fdaa:: IPv6)', async () => {
    const res = await inject('fdaa:0:1234::5', '203.0.113.7');
    expect(res.json()).toEqual({ ip: '203.0.113.7' });
  });

  it('honours X-Forwarded-For from loopback (local dev behind a dev proxy)', async () => {
    const res = await inject('127.0.0.1', '203.0.113.7');
    expect(res.json()).toEqual({ ip: '203.0.113.7' });
  });

  it('IGNORES X-Forwarded-For from a direct external client (spoof attempt)', async () => {
    // A public peer forging the header must keep its own address —
    // otherwise one abuser could impersonate any bucket of the per-IP
    // rate limiter (or dodge their own).
    const res = await inject('203.0.113.50', '198.51.100.10');
    expect(res.json()).toEqual({ ip: '203.0.113.50' });
  });

  it('keeps the peer address when no header is present', async () => {
    const res = await inject('172.19.0.3');
    expect(res.json()).toEqual({ ip: '172.19.0.3' });
  });
});
