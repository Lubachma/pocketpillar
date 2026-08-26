import type { TranslationMap } from '../types.js';

export const fr: TranslationMap = {
  // Auth
  'auth.missing_header': "En-tête d'autorisation manquant ou invalide",
  'auth.invalid_token': 'Jeton invalide ou expiré',
  'auth.user_not_found': 'Utilisateur non trouvé',
  'auth.forbidden': 'Action non autorisée',
  'auth.register_success': 'Inscription réussie',
  'auth.email_taken': 'Un compte existe déjà avec cet email',

  // Calculators
  'calc.3a_catchup.must_max_current':
    "Vous devez d'abord maximiser votre cotisation 3a de l'année en cours avant de rattraper les années précédentes.",
  'calc.property.min_withdrawal': "Le retrait minimum pour l'achat immobilier est de CHF 20'000.",
  'calc.divorce.no_marriage_capital': 'Aucun capital LPP accumulé pendant le mariage à partager.',

  // Documents
  'doc.file_required': 'Fichier requis',
  'doc.invalid_mime': 'Type de fichier non supporté. Utilisez PDF, JPEG ou PNG.',
  'doc.file_too_large': 'Le fichier dépasse la taille maximale de 10 Mo',
  'doc.upload_failed': "Échec de l'upload du fichier",
  'doc.not_found': 'Document non trouvé',
  'doc.download_failed': 'Échec de la génération du lien de téléchargement',
  'doc.delete_failed': 'Échec de la suppression du fichier',

  // Errors
  'error.validation': 'Erreur de validation',
  'error.not_found': 'Ressource non trouvée',
  'error.internal': 'Une erreur interne est survenue',
  'error.user_not_found': 'Utilisateur non trouvé',
  'error.profile_not_found': 'Profil financier non trouvé',
  'error.account_not_found': 'Compte non trouvé',
  'error.tax_not_found': 'Situation fiscale non trouvée',
  'error.provider_not_found': 'Prestataire non trouvé',
  'error.incomplete_profile':
    'Profil incomplet. Renseignez canton, année de naissance et profil financier.',

  // Recommendations
  'rec.open_3a.title': 'Ouvrir un compte pilier 3a',
  'rec.open_3a.description':
    "Vous n'avez pas de pilier 3a. En versant le maximum de CHF {{max}}/an, vous économisez CHF {{saving}} d'impôts par an.",
  'rec.max_3a.title': 'Maximiser vos versements 3a',
  'rec.max_3a.description':
    "Vous versez CHF {{current}}/an mais le maximum est CHF {{max}}. En augmentant de CHF {{gap}}, vous économisez CHF {{saving}} d'impôts supplémentaires.",
  'rec.provider_switch.title': 'Changer de prestataire 3a',
  'rec.provider_switch.description':
    "{{provider}} ({{product}}) propose des frais de {{newFee}}% au lieu d'environ {{oldFee}}%. Sur CHF {{balance}}, cela représente environ CHF {{saving}}/an d'économie en frais.",
  'rec.bvg_rachat.title': 'Rachat LPP volontaire',
  'rec.bvg_rachat.description':
    "Votre écart de capital LPP est d'environ CHF {{gap}}. Un rachat de CHF {{rachat}} est entièrement déductible et vous ferait économiser CHF {{saving}} d'impôts.",
  'rec.open_additional_3a.title': 'Ouvrir un compte 3a supplémentaire',
  'rec.open_additional_3a.description':
    "Avec {{count}} compte(s) 3a et un capital projeté d'environ CHF {{balance}} à la retraite, un retrait unique subirait de plein fouet la progressivité de l'impôt. En ouvrant un compte supplémentaire ({{target}} au total) et en échelonnant les retraits sur {{target}} années, vous économiseriez environ CHF {{saving}} d'impôt sur le capital.",

  // Pension score
  'score.criterion.replacement_rate': 'Taux de remplacement',
  'score.criterion.pillar_3a': 'Épargne 3a',
  'score.criterion.age_awareness': 'Horizon retraite',

  // Premium subscription
  'sub.premium_required': 'Cette fonctionnalité fait partie de PocketPillar Premium.',
  'sub.document_limit':
    'Limite atteinte : 1 document en version gratuite. Passez à Premium pour des documents illimités.',
};
