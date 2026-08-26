import type { PrismaClient } from '@prisma/client';
import type { Redis } from 'ioredis';
import type { Locale } from '../lib/i18n/index.js';

declare module 'fastify' {
  interface FastifyInstance {
    prisma: PrismaClient;
    redis: Redis;
  }

  interface FastifyRequest {
    userId: string | null;
    locale: Locale;
  }
}
