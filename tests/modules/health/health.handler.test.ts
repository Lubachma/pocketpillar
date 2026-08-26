import { describe, it, expect } from 'vitest';
import { createRequire } from 'node:module';
import type { FastifyReply, FastifyRequest } from 'fastify';
import { healthHandler } from '../../../src/modules/health/health.handler.js';

const { version } = createRequire(import.meta.url)('../../../package.json') as {
  version: string;
};

describe('healthHandler', () => {
  it('reports the version read from package.json (not hardcoded)', async () => {
    let payload: unknown;
    const reply = {
      send(p: unknown) {
        payload = p;
        return this;
      },
    } as unknown as FastifyReply;

    await healthHandler({} as FastifyRequest, reply);

    expect(payload).toMatchObject({ status: 'ok', version });
    expect(typeof (payload as { uptime: number }).uptime).toBe('number');
  });
});
