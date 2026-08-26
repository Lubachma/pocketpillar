import type { TranslationMap } from '../types.js';

export const en: TranslationMap = {
  // Auth
  'auth.missing_header': 'Missing or invalid authorization header',
  'auth.invalid_token': 'Invalid or expired token',
  'auth.user_not_found': 'User not found',
  'auth.forbidden': 'Action not allowed',
  'auth.register_success': 'Registration successful',
  'auth.email_taken': 'An account already exists with this email',

  // Calculators
  'calc.3a_catchup.must_max_current':
    'You must first maximize your current year 3a contribution before catching up on previous years.',
  'calc.property.min_withdrawal': 'The minimum withdrawal for property purchase is CHF 20,000.',
  'calc.divorce.no_marriage_capital': 'No BVG capital accumulated during marriage to split.',

  // Documents
  'doc.file_required': 'File is required',
  'doc.invalid_mime': 'Unsupported file type. Use PDF, JPEG, or PNG.',
  'doc.file_too_large': 'File exceeds the maximum size of 10 MB',
  'doc.upload_failed': 'File upload failed',
  'doc.not_found': 'Document not found',
  'doc.download_failed': 'Failed to generate download link',
  'doc.delete_failed': 'Failed to delete the file',

  // Errors
  'error.validation': 'Validation error',
  'error.not_found': 'Resource not found',
  'error.internal': 'An internal error occurred',
  'error.user_not_found': 'User not found',
  'error.profile_not_found': 'Financial profile not found',
  'error.account_not_found': 'Account not found',
  'error.tax_not_found': 'Tax situation not found',
  'error.provider_not_found': 'Provider not found',
  'error.incomplete_profile':
    'Incomplete profile. Please fill in canton, birth year, and financial profile.',

  // Recommendations
  'rec.open_3a.title': 'Open a pillar 3a account',
  'rec.open_3a.description':
    "You don't have a pillar 3a. By contributing the maximum of CHF {{max}}/year, you save CHF {{saving}} in taxes per year.",
  'rec.max_3a.title': 'Maximize your 3a contributions',
  'rec.max_3a.description':
    "You're contributing CHF {{current}}/year but the maximum is CHF {{max}}. By increasing by CHF {{gap}}, you save an additional CHF {{saving}} in taxes.",
  'rec.provider_switch.title': 'Switch 3a provider',
  'rec.provider_switch.description':
    '{{provider}} ({{product}}) offers fees of {{newFee}}% instead of approx. {{oldFee}}%. On CHF {{balance}}, that represents approx. CHF {{saving}}/year in fee savings.',
  'rec.bvg_rachat.title': 'Voluntary BVG purchase',
  'rec.bvg_rachat.description':
    'Your BVG capital gap is approx. CHF {{gap}}. A purchase of CHF {{rachat}} is fully tax-deductible and would save you CHF {{saving}} in taxes.',
  'rec.open_additional_3a.title': 'Open an additional pillar 3a account',
  'rec.open_additional_3a.description':
    'With {{count}} pillar 3a account(s) and a projected capital of approx. CHF {{balance}} at retirement, a lump-sum withdrawal would bear the full brunt of tax progression. By opening an additional account ({{target}} in total) and staggering withdrawals over {{target}} years, you would save approx. CHF {{saving}} in capital withdrawal tax.',

  // Pension score
  'score.criterion.replacement_rate': 'Replacement rate',
  'score.criterion.pillar_3a': 'Pillar 3a savings',
  'score.criterion.age_awareness': 'Retirement horizon',

  // Premium subscription
  'sub.premium_required': 'This feature is part of PocketPillar Premium.',
  'sub.document_limit':
    'Limit reached: 1 document on the free plan. Upgrade to Premium for unlimited documents.',
};
