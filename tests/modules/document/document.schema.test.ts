import { describe, it, expect } from 'vitest';
import {
  uploadDocumentFieldsSchema,
  listDocumentsQuerySchema,
  documentParamsSchema,
} from '../../../src/modules/document/document.schema.js';
import { SWISS_PENSION } from '../../../src/lib/constants/swiss-pension.js';

describe('uploadDocumentFieldsSchema', () => {
  it('accepts all document types', () => {
    for (const type of [
      'SALARY_SLIP',
      'BVG_STATEMENT',
      'PILLAR3A_STATEMENT',
      'TAX_DECLARATION',
      'OTHER',
    ]) {
      expect(uploadDocumentFieldsSchema.safeParse({ type }).success).toBe(true);
    }
    expect(uploadDocumentFieldsSchema.safeParse({ type: 'PAYSLIP' }).success).toBe(false);
  });

  it('coerces the year from a multipart string field and bounds it to 2000-current year', () => {
    const currentYear = SWISS_PENSION.CURRENT_YEAR;
    expect(uploadDocumentFieldsSchema.parse({ type: 'SALARY_SLIP', year: '2024' }).year).toBe(2024);
    expect(
      uploadDocumentFieldsSchema.safeParse({ type: 'SALARY_SLIP', year: '1999' }).success,
    ).toBe(false);
    expect(
      uploadDocumentFieldsSchema.safeParse({ type: 'SALARY_SLIP', year: '2000' }).success,
    ).toBe(true);
    // A document cannot be dated in the future.
    expect(
      uploadDocumentFieldsSchema.safeParse({ type: 'SALARY_SLIP', year: String(currentYear) })
        .success,
    ).toBe(true);
    expect(
      uploadDocumentFieldsSchema.safeParse({ type: 'SALARY_SLIP', year: String(currentYear + 1) })
        .success,
    ).toBe(false);
    expect(
      uploadDocumentFieldsSchema.safeParse({ type: 'SALARY_SLIP', year: '20.5' }).success,
    ).toBe(false);
  });
});

describe('listDocumentsQuerySchema', () => {
  it('accepts an empty query or a valid type filter', () => {
    expect(listDocumentsQuerySchema.parse({})).toEqual({});
    expect(listDocumentsQuerySchema.safeParse({ type: 'TAX_DECLARATION' }).success).toBe(true);
    expect(listDocumentsQuerySchema.safeParse({ type: 'UNKNOWN' }).success).toBe(false);
  });
});

describe('documentParamsSchema', () => {
  it('requires a UUID id', () => {
    expect(
      documentParamsSchema.safeParse({ id: '123e4567-e89b-42d3-a456-426614174000' }).success,
    ).toBe(true);
    expect(documentParamsSchema.safeParse({ id: '42' }).success).toBe(false);
  });
});
