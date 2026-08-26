import type { FastifyRequest, FastifyReply } from 'fastify';
import { createRequire } from 'node:module';
import type { HealthResponse, ReadinessResponse } from './health.schema.js';

/** API version — single source of truth is package.json */
const { version: APP_VERSION } = createRequire(import.meta.url)('../../../package.json') as {
  version: string;
};

export async function healthHandler(_req: FastifyRequest, reply: FastifyReply) {
  const response: HealthResponse = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: APP_VERSION,
    uptime: process.uptime(),
  };

  return reply.send(response);
}

export async function readinessHandler(req: FastifyRequest, reply: FastifyReply) {
  const checks: ReadinessResponse['checks'] = {
    database: { status: 'error' },
    redis: { status: 'error' },
  };

  // Check database
  try {
    const start = performance.now();
    await req.server.prisma.$queryRaw`SELECT 1`;
    checks.database = { status: 'ok', latencyMs: Math.round(performance.now() - start) };
  } catch {
    checks.database = { status: 'error' };
  }

  // Check Redis
  try {
    const start = performance.now();
    await req.server.redis.ping();
    checks.redis = { status: 'ok', latencyMs: Math.round(performance.now() - start) };
  } catch {
    checks.redis = { status: 'error' };
  }

  const allOk = checks.database.status === 'ok' && checks.redis.status === 'ok';

  const response: ReadinessResponse = {
    status: allOk ? 'ok' : 'degraded',
    timestamp: new Date().toISOString(),
    checks,
  };

  return reply.status(allOk ? 200 : 503).send(response);
}
