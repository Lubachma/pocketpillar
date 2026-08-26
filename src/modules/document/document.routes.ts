import type { FastifyInstance } from 'fastify';
import { authenticate } from '../../plugins/auth.js';
import {
  uploadDocumentHandler,
  listDocumentsHandler,
  downloadDocumentHandler,
  deleteDocumentHandler,
} from './document.handler.js';

export default async function documentRoutes(fastify: FastifyInstance) {
  fastify.addHook('preHandler', authenticate);

  fastify.post(
    '/documents',
    {
      config: {
        rateLimit: { max: 20, timeWindow: '1 minute' },
      },
      bodyLimit: 11_534_336, // ~11 MB to allow overhead
      schema: {
        tags: ['documents'],
        description: 'Upload a document (multipart/form-data)',
        consumes: ['multipart/form-data'],
      },
    },
    uploadDocumentHandler,
  );

  fastify.get(
    '/documents',
    {
      schema: {
        tags: ['documents'],
        description: 'List user documents',
        querystring: {
          type: 'object',
          properties: {
            type: { type: 'string' },
          },
        },
      },
    },
    listDocumentsHandler,
  );

  fastify.get(
    '/documents/:id/download',
    {
      schema: {
        tags: ['documents'],
        description: 'Get a signed download URL for a document',
        params: {
          type: 'object',
          required: ['id'],
          properties: {
            id: { type: 'string', format: 'uuid' },
          },
        },
      },
    },
    downloadDocumentHandler,
  );

  fastify.delete(
    '/documents/:id',
    {
      schema: {
        tags: ['documents'],
        description: 'Delete a document',
        params: {
          type: 'object',
          required: ['id'],
          properties: {
            id: { type: 'string', format: 'uuid' },
          },
        },
      },
    },
    deleteDocumentHandler,
  );
}
