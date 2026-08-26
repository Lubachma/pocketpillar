import type { Locale, TranslationMap } from '../types.js';
import { fr } from './fr.js';
import { de } from './de.js';
import { en } from './en.js';

export const translations: Record<Locale, TranslationMap> = { fr, de, en };
