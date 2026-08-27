export type Locale = 'fr' | 'de' | 'en';

export const SUPPORTED_LOCALES: Locale[] = ['fr', 'de', 'en'];
export const DEFAULT_LOCALE: Locale = 'fr';

export interface TranslationMap {
  // ─── Auth errors ────────────────────────
  'auth.missing_header': string;
  'auth.invalid_token': string;
  'auth.unavailable': string;
  'auth.user_not_found': string;
  'auth.forbidden': string;
  'auth.register_success': string;
  'auth.email_taken': string;

  // ─── Calculators ───────────────────────
  'calc.3a_catchup.must_max_current': string;
  'calc.property.min_withdrawal': string;
  'calc.divorce.no_marriage_capital': string;

  // ─── Documents ─────────────────────────
  'doc.file_required': string;
  'doc.invalid_mime': string;
  'doc.file_too_large': string;
  'doc.upload_failed': string;
  'doc.not_found': string;
  'doc.download_failed': string;
  'doc.delete_failed': string;

  // ─── Validation / generic errors ────────
  'error.validation': string;
  'error.not_found': string;
  'error.internal': string;
  'error.user_not_found': string;
  'error.profile_not_found': string;
  'error.account_not_found': string;
  'error.tax_not_found': string;
  'error.provider_not_found': string;
  'error.incomplete_profile': string;

  // ─── Recommendations ───────────────────
  'rec.open_3a.title': string;
  'rec.open_3a.description': string;
  'rec.max_3a.title': string;
  'rec.max_3a.description': string;
  'rec.provider_switch.title': string;
  'rec.provider_switch.description': string;
  'rec.bvg_rachat.title': string;
  'rec.bvg_rachat.description': string;
  'rec.open_additional_3a.title': string;
  'rec.open_additional_3a.description': string;

  // ─── Pension score ──────────────────────
  'score.criterion.replacement_rate': string;
  'score.criterion.pillar_3a': string;
  'score.criterion.age_awareness': string;

  // ─── Premium subscription ──────────────
  'sub.premium_required': string;
  'sub.document_limit': string;
}

export type TranslationKey = keyof TranslationMap;
