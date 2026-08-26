import Fastify from 'fastify';
import helmet from '@fastify/helmet';
import sensible from '@fastify/sensible';
import rateLimit from '@fastify/rate-limit';
import { config } from './config/index.js';
import { loggerConfig } from './config/logger.js';
import corsPlugin from './plugins/cors.js';
import prismaPlugin from './plugins/prisma.js';
import redisPlugin from './plugins/redis.js';
import authPlugin from './plugins/auth.js';
import i18nPlugin from './plugins/i18n.js';
import errorHandlerPlugin from './plugins/error-handler.js';
import healthRoutes from './modules/health/health.routes.js';
import userRoutes from './modules/user/user.routes.js';
import financialProfileRoutes from './modules/financial-profile/financial-profile.routes.js';
import calculatorRoutes from './modules/calculator/calculator.routes.js';
import providerRoutes from './modules/provider/provider.routes.js';
import recommendationRoutes from './modules/recommendation/recommendation.routes.js';
import multipart from '@fastify/multipart';
import authRoutes from './modules/auth/auth.routes.js';
import documentRoutes from './modules/document/document.routes.js';
import subscriptionRoutes from './modules/subscription/subscription.routes.js';

export async function createApp() {
  const app = Fastify({
    logger: loggerConfig,
    // Exactly one trusted proxy hop (the managed LB/ingress in front of the
    // app). `true` would trust X-Forwarded-For at any depth and let clients
    // spoof req.ip straight past the rate limiter.
    trustProxy: 1,
    bodyLimit: 65_536, // 64KB
  });

  // Security & utilities
  await app.register(helmet);
  await app.register(sensible);
  await app.register(rateLimit, { max: 100, timeWindow: '1 minute' });

  // Plugins
  await app.register(corsPlugin);
  await app.register(prismaPlugin);
  await app.register(redisPlugin);
  await app.register(authPlugin);
  await app.register(i18nPlugin);
  await app.register(errorHandlerPlugin);
  await app.register(multipart, { limits: { fileSize: 11_534_336 } });

  // Swagger — dev/test only
  if (config.NODE_ENV !== 'production') {
    const swaggerPlugin = await import('./plugins/swagger.js');
    await app.register(swaggerPlugin.default);

    // Redirect root to API docs in dev
    app.get('/', async (_req, reply) => reply.redirect('/docs'));
  } else {
    // Simple health response in production
    app.get('/', async (_req, reply) => reply.send({ status: 'ok' }));
  }

  // Routes
  await app.register(authRoutes);
  await app.register(healthRoutes);
  await app.register(userRoutes);
  await app.register(financialProfileRoutes);
  await app.register(calculatorRoutes);
  await app.register(providerRoutes);
  await app.register(recommendationRoutes);
  await app.register(documentRoutes);
  await app.register(subscriptionRoutes);

  return app;
}
