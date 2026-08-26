import { translations } from './translations/index.js';
import { DEFAULT_LOCALE, SUPPORTED_LOCALES } from './types.js';
import type { Locale, TranslationKey } from './types.js';

export type { Locale, TranslationKey };
export { DEFAULT_LOCALE, SUPPORTED_LOCALES };

/** Translate a key with optional interpolation */
export function t(
  locale: Locale,
  key: TranslationKey,
  params?: Record<string, string | number>,
): string {
  const map = translations[locale] ?? translations[DEFAULT_LOCALE];
  let text = map[key] ?? translations[DEFAULT_LOCALE][key] ?? key;

  if (params) {
    for (const [k, v] of Object.entries(params)) {
      text = text.replaceAll(`{{${k}}}`, String(v));
    }
  }

  return text;
}

/** Parse Accept-Language header and return best matching locale */
export function parseAcceptLanguage(header?: string): Locale {
  if (!header) return DEFAULT_LOCALE;

  const parts = header
    .split(',')
    .map((part) => {
      const [lang, q] = part.trim().split(';q=');
      return { lang: lang.trim().toLowerCase(), q: q ? parseFloat(q) : 1.0 };
    })
    .sort((a, b) => b.q - a.q);

  for (const { lang } of parts) {
    // Exact match (fr, de, en)
    if (SUPPORTED_LOCALES.includes(lang as Locale)) {
      return lang as Locale;
    }
    // Prefix match (fr-CH -> fr, de-CH -> de, en-US -> en)
    const prefix = lang.split('-')[0];
    if (SUPPORTED_LOCALES.includes(prefix as Locale)) {
      return prefix as Locale;
    }
  }

  return DEFAULT_LOCALE;
}
