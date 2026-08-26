import { z } from 'zod';
import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';

const cantonValues = [
  'ZH',
  'BE',
  'LU',
  'UR',
  'SZ',
  'OW',
  'NW',
  'GL',
  'ZG',
  'FR',
  'SO',
  'BS',
  'BL',
  'SH',
  'AR',
  'AI',
  'SG',
  'GR',
  'AG',
  'TG',
  'TI',
  'VD',
  'VS',
  'NE',
  'GE',
  'JU',
] as const;

export const updateUserSchema = z.object({
  canton: z.enum(cantonValues).optional(),
  // Users must be at least 16 — the bound follows the current year.
  birthYear: z
    .number()
    .int()
    .min(1930)
    .max(SWISS_PENSION.CURRENT_YEAR - 16)
    .optional(),
  replacementRateGoal: z.number().int().min(50).max(100).optional(),
  // Municipality of residence (free text) — explicit null to clear it.
  municipality: z.string().min(1).max(100).nullable().optional(),
});

export const userResponseSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  canton: z.enum(cantonValues).nullable(),
  birthYear: z.number().nullable(),
  replacementRateGoal: z.number(),
  municipality: z.string().nullable(),
  createdAt: z.string(),
});

export type UpdateUserInput = z.infer<typeof updateUserSchema>;
