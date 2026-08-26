import { z } from 'zod';
import { SWISS_PENSION } from '../../lib/constants/swiss-pension.js';

export const documentTypeValues = [
  'SALARY_SLIP',
  'BVG_STATEMENT',
  'PILLAR3A_STATEMENT',
  'TAX_DECLARATION',
  'OTHER',
] as const;

export const uploadDocumentFieldsSchema = z.object({
  type: z.enum(documentTypeValues),
  year: z.coerce.number().int().min(2000).max(SWISS_PENSION.CURRENT_YEAR).optional(),
});

export const listDocumentsQuerySchema = z.object({
  type: z.enum(documentTypeValues).optional(),
});

export const documentParamsSchema = z.object({
  id: z.string().uuid(),
});

export const ALLOWED_MIME_TYPES = ['application/pdf', 'image/jpeg', 'image/png'];
export const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB
