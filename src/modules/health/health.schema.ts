import { z } from 'zod';

export const healthResponseSchema = z.object({
  status: z.literal('ok'),
  timestamp: z.string(),
  version: z.string(),
  uptime: z.number(),
});

export const readinessResponseSchema = z.object({
  status: z.enum(['ok', 'degraded']),
  timestamp: z.string(),
  checks: z.object({
    database: z.object({ status: z.enum(['ok', 'error']), latencyMs: z.number().optional() }),
    redis: z.object({ status: z.enum(['ok', 'error']), latencyMs: z.number().optional() }),
  }),
});

export type HealthResponse = z.infer<typeof healthResponseSchema>;
export type ReadinessResponse = z.infer<typeof readinessResponseSchema>;
