import type { FastifyInstance } from 'fastify';
import { authenticate } from '../../plugins/auth.js';
import {
  getFinancialProfile,
  upsertFinancialProfile,
  getPillar2Accounts,
  createPillar2Account,
  updatePillar2Account,
  deletePillar2Account,
  getPillar3aAccounts,
  createPillar3aAccount,
  updatePillar3aAccount,
  deletePillar3aAccount,
  getTaxSituation,
  upsertTaxSituation,
} from './financial-profile.handler.js';

export default async function financialProfileRoutes(fastify: FastifyInstance) {
  fastify.addHook('preHandler', authenticate);

  // ─── Financial Profile (1:1) ────────────
  fastify.get(
    '/financial-profile',
    { schema: { tags: ['financial-profile'] } },
    getFinancialProfile,
  );
  fastify.put(
    '/financial-profile',
    { schema: { tags: ['financial-profile'] } },
    upsertFinancialProfile,
  );

  // ─── Pillar 2 (1:N) ────────────────────
  fastify.get(
    '/financial-profile/pillar2',
    { schema: { tags: ['financial-profile'] } },
    getPillar2Accounts,
  );
  fastify.post(
    '/financial-profile/pillar2',
    { schema: { tags: ['financial-profile'] } },
    createPillar2Account,
  );
  fastify.patch(
    '/financial-profile/pillar2/:id',
    { schema: { tags: ['financial-profile'] } },
    updatePillar2Account,
  );
  fastify.delete(
    '/financial-profile/pillar2/:id',
    { schema: { tags: ['financial-profile'] } },
    deletePillar2Account,
  );

  // ─── Pillar 3a (1:N) ───────────────────
  fastify.get(
    '/financial-profile/pillar3a',
    { schema: { tags: ['financial-profile'] } },
    getPillar3aAccounts,
  );
  fastify.post(
    '/financial-profile/pillar3a',
    { schema: { tags: ['financial-profile'] } },
    createPillar3aAccount,
  );
  fastify.patch(
    '/financial-profile/pillar3a/:id',
    { schema: { tags: ['financial-profile'] } },
    updatePillar3aAccount,
  );
  fastify.delete(
    '/financial-profile/pillar3a/:id',
    { schema: { tags: ['financial-profile'] } },
    deletePillar3aAccount,
  );

  // ─── Tax Situation (1:1) ────────────────
  fastify.get(
    '/financial-profile/tax',
    { schema: { tags: ['financial-profile'] } },
    getTaxSituation,
  );
  fastify.put(
    '/financial-profile/tax',
    { schema: { tags: ['financial-profile'] } },
    upsertTaxSituation,
  );
}
