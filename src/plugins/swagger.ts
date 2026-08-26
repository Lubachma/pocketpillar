import fp from 'fastify-plugin';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import type { FastifyInstance } from 'fastify';

export default fp(async (fastify: FastifyInstance) => {
  await fastify.register(swagger, {
    openapi: {
      info: {
        title: 'PocketPillar API',
        description:
          'Swiss 2nd/3rd-pillar pension planning API — tax engine anchored to official FTA data',
        version: '1.0.0',
      },
      tags: [
        { name: 'health', description: 'Health check endpoints' },
        { name: 'user', description: 'User profile' },
        { name: 'financial-profile', description: 'Financial profile & pillar accounts' },
        { name: 'calculator', description: 'Pension calculation engine' },
        { name: 'provider', description: 'Pillar 3a provider data & comparison' },
        { name: 'recommendation', description: 'Personalized optimization recommendations' },
      ],
    },
  });

  await fastify.register(swaggerUi, {
    routePrefix: '/docs',
  });
});
