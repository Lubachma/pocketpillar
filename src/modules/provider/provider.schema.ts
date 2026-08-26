import { z } from 'zod';

const riskLevelValues = ['CONSERVATIVE', 'MODERATE', 'BALANCED', 'GROWTH', 'AGGRESSIVE'] as const;

export const compareQuerySchema = z.object({
  riskLevel: z.enum(riskLevelValues).optional(),
  sustainableOnly: z
    .string()
    .transform((v) => v === 'true')
    .optional(),
  maxFeePercent: z.coerce.number().min(0).max(5).optional(),
  minEquityAllocation: z.coerce.number().int().min(0).max(100).optional(),
  maxEquityAllocation: z.coerce.number().int().min(0).max(100).optional(),
});

export const bestMatchSchema = z.object({
  riskLevel: z.enum(riskLevelValues).default('BALANCED'),
  preferEsg: z.boolean().default(false),
  maxFeePercent: z.number().min(0).max(5).optional(),
});
