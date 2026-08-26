import type { FastifyInstance } from 'fastify';
import { healthHandler, readinessHandler } from './health.handler.js';

export default async function healthRoutes(fastify: FastifyInstance) {
  fastify.get(
    '/health',
    {
      schema: {
        tags: ['health'],
        description: 'Liveness check',
        response: {
          200: {
            type: 'object',
            properties: {
              status: { type: 'string' },
              timestamp: { type: 'string' },
              version: { type: 'string' },
              uptime: { type: 'number' },
            },
          },
        },
      },
    },
    healthHandler,
  );

  fastify.get(
    '/health/ready',
    {
      schema: {
        tags: ['health'],
        description: 'Readiness check (DB + Redis)',
        response: {
          200: {
            type: 'object',
            properties: {
              status: { type: 'string' },
              timestamp: { type: 'string' },
              checks: {
                type: 'object',
                properties: {
                  database: {
                    type: 'object',
                    properties: {
                      status: { type: 'string' },
                      latencyMs: { type: 'number' },
                    },
                  },
                  redis: {
                    type: 'object',
                    properties: {
                      status: { type: 'string' },
                      latencyMs: { type: 'number' },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
    readinessHandler,
  );
}
