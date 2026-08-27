import type { TranslationMap } from '../types.js';

export const de: TranslationMap = {
  // Auth
  'auth.missing_header': 'Fehlender oder ungültiger Autorisierungs-Header',
  'auth.invalid_token': 'Ungültiges oder abgelaufenes Token',
  'auth.unavailable':
    'Authentifizierungsdienst vorübergehend nicht verfügbar — bitte erneut versuchen',
  'auth.user_not_found': 'Benutzer nicht gefunden',
  'auth.forbidden': 'Aktion nicht erlaubt',
  'auth.register_success': 'Registrierung erfolgreich',
  'auth.email_taken': 'Ein Konto mit dieser E-Mail existiert bereits',

  // Calculators
  'calc.3a_catchup.must_max_current':
    'Sie müssen zuerst Ihren 3a-Beitrag für das laufende Jahr maximieren, bevor Sie frühere Jahre nachholen können.',
  'calc.property.min_withdrawal': "Der Mindestbezug für den Immobilienkauf beträgt CHF 20'000.",
  'calc.divorce.no_marriage_capital': 'Kein während der Ehe angespartes BVG-Kapital aufzuteilen.',

  // Documents
  'doc.file_required': 'Datei erforderlich',
  'doc.invalid_mime': 'Dateityp nicht unterstützt. Verwenden Sie PDF, JPEG oder PNG.',
  'doc.file_too_large': 'Die Datei überschreitet die maximale Größe von 10 MB',
  'doc.upload_failed': 'Datei-Upload fehlgeschlagen',
  'doc.not_found': 'Dokument nicht gefunden',
  'doc.download_failed': 'Download-Link konnte nicht erstellt werden',
  'doc.delete_failed': 'Die Datei konnte nicht gelöscht werden',

  // Errors
  'error.validation': 'Validierungsfehler',
  'error.not_found': 'Ressource nicht gefunden',
  'error.internal': 'Ein interner Fehler ist aufgetreten',
  'error.user_not_found': 'Benutzer nicht gefunden',
  'error.profile_not_found': 'Finanzprofil nicht gefunden',
  'error.account_not_found': 'Konto nicht gefunden',
  'error.tax_not_found': 'Steuersituation nicht gefunden',
  'error.provider_not_found': 'Anbieter nicht gefunden',
  'error.incomplete_profile':
    'Unvollständiges Profil. Bitte Kanton, Geburtsjahr und Finanzprofil angeben.',

  // Recommendations
  'rec.open_3a.title': 'Säule-3a-Konto eröffnen',
  'rec.open_3a.description':
    'Sie haben keine Säule 3a. Mit dem Maximalbeitrag von CHF {{max}}/Jahr sparen Sie CHF {{saving}} Steuern pro Jahr.',
  'rec.max_3a.title': 'Ihre 3a-Einzahlungen maximieren',
  'rec.max_3a.description':
    'Sie zahlen CHF {{current}}/Jahr ein, das Maximum beträgt CHF {{max}}. Mit einer Erhöhung um CHF {{gap}} sparen Sie zusätzlich CHF {{saving}} Steuern.',
  'rec.provider_switch.title': '3a-Anbieter wechseln',
  'rec.provider_switch.description':
    '{{provider}} ({{product}}) bietet Gebühren von {{newFee}}% statt ca. {{oldFee}}%. Bei CHF {{balance}} bedeutet das ca. CHF {{saving}}/Jahr Gebührenersparnis.',
  'rec.bvg_rachat.title': 'Freiwilliger BVG-Einkauf',
  'rec.bvg_rachat.description':
    'Ihre BVG-Kapitallücke beträgt ca. CHF {{gap}}. Ein Einkauf von CHF {{rachat}} ist vollständig abzugsfähig und spart Ihnen CHF {{saving}} Steuern.',
  'rec.open_additional_3a.title': 'Ein zusätzliches 3a-Konto eröffnen',
  'rec.open_additional_3a.description':
    'Mit {{count}} 3a-Konto(s) und einem prognostizierten Kapital von ca. CHF {{balance}} bei der Pensionierung würde ein einmaliger Bezug die Steuerprogression voll treffen. Mit einem zusätzlichen Konto ({{target}} total) und gestaffelten Bezügen über {{target}} Jahre sparen Sie ca. CHF {{saving}} Kapitalbezugssteuern.',

  // Pension score
  'score.criterion.replacement_rate': 'Ersatzquote',
  'score.criterion.pillar_3a': 'Säule-3a-Ersparnis',
  'score.criterion.age_awareness': 'Pensionshorizont',

  // Premium-Abo
  'sub.premium_required': 'Diese Funktion ist Teil von PocketPillar Premium.',
  'sub.document_limit':
    'Limit erreicht: 1 Dokument in der Gratisversion. Mit Premium sind Dokumente unbegrenzt.',
};
