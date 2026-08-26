// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'PocketPillar';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get authCancel => 'Annuler';

  @override
  String get authCheckEmail =>
      'Vérifiez votre boîte de réception pour confirmer votre adresse e-mail, puis connectez-vous';

  @override
  String get authConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get authCreateAccount => 'Créer mon compte';

  @override
  String get authEmail => 'Adresse e-mail';

  @override
  String get authEmailInvalid => 'Adresse e-mail invalide';

  @override
  String get authEmailTaken =>
      'Cette adresse e-mail est déjà liée à un autre compte';

  @override
  String get authGoToLogin => 'Aller à la connexion';

  @override
  String get authLoginFailed => 'Échec de la connexion';

  @override
  String get authLoginSubtitle => 'Votre prévoyance suisse, en toute sécurité';

  @override
  String get authNoAccount => 'Pas encore de compte ? Créer un compte';

  @override
  String get authDemoBannerTitle => 'Démo publique';

  @override
  String get authDemoBannerBody =>
      'Compte de démonstration partagé et public — les mêmes données (fictives) pour tous les visiteurs, réinitialisées chaque nuit. N\'y saisis aucune donnée personnelle réelle.';

  @override
  String get authDemoSignIn => 'Se connecter avec le compte démo';

  @override
  String get authOr => 'ou';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authPasswordMinLength =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get authPasswordRequired => 'Mot de passe requis';

  @override
  String get authPasswordsMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get authRegisterTitle => 'Créer un compte';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authSignInWithApple => 'Se connecter avec Apple';

  @override
  String get authSignOut => 'Se déconnecter';

  @override
  String get authSignUpFailed => 'Échec de la création du compte';

  @override
  String get biometricLockedMessage =>
      'Authentifiez-vous pour accéder à vos données financières';

  @override
  String get biometricReason =>
      'Déverrouillez PocketPillar pour accéder à vos données';

  @override
  String get biometricUnlock => 'Déverrouiller';

  @override
  String get errorNetwork => 'Erreur réseau';

  @override
  String get errorSessionExpired =>
      'Votre session a expiré, veuillez vous reconnecter';

  @override
  String get errorUnknown => 'Erreur inconnue';

  @override
  String get notificationYearEndChecklist =>
      'N\'oubliez pas votre checklist de fin d\'année ! Maximisez vos avantages fiscaux avant le 31 décembre.';

  @override
  String notification3aReminder(String amount) {
    return 'Pensez à votre versement 3a ! Vous pouvez verser jusqu\'à CHF $amount cette année.';
  }

  @override
  String notification3aReminderContextual(String amount, int days) {
    return 'Il vous reste CHF $amount à verser sur votre 3a avant le 31 décembre ($days jours restants).';
  }

  @override
  String get tabCalculator => 'Bilan';

  @override
  String get tabDashboard => 'Accueil';

  @override
  String get tabDocuments => 'Documents';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabProviders => 'Prestataires';

  @override
  String get tabScenarios => 'Scénarios';

  @override
  String get onboardingTitle => 'Bienvenue';

  @override
  String get checklistTitle => 'Checklist';

  @override
  String get coupleTitle => 'Couple';

  @override
  String get financialProfileTitle => 'Profil financier';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsBiometricLock => 'Verrouillage biométrique';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsSectionLanguage => 'Langue';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsAnnualReminders => 'Rappels annuels';

  @override
  String get settingsAnnualRemindersSubtitle =>
      'Checklist de fin d\'année (15 décembre) et versement 3a (1er novembre), à 10 h';

  @override
  String get settingsNotificationsDenied =>
      'Notifications refusées — activez-les dans les réglages système pour recevoir les rappels';

  @override
  String get settingsDeleteAccount => 'Supprimer le compte';

  @override
  String get settingsDeleteConfirmTitle => 'Supprimer définitivement ?';

  @override
  String get settingsDeleteConfirmBody =>
      'Cette action est irréversible : votre compte et toutes vos données (profil financier, comptes LPP et 3a, documents) seront supprimées.';

  @override
  String get dashboardTitle => 'PocketPillar';

  @override
  String get dashboardWelcomeHeader => 'Votre prévoyance, simplifiée';

  @override
  String get dashboardWelcomeSubtitle =>
      'Comprenez et optimisez votre retraite en quelques minutes';

  @override
  String get dashboardCtaCheck => 'Vérifiez votre retraite en 2 min';

  @override
  String get dashboardTipOfDay => 'Conseil du jour';

  @override
  String dashboardSummary(int percent) {
    return 'Votre pension couvrira $percent% de votre revenu';
  }

  @override
  String get dashboardScoreLabel => 'Santé prévoyance';

  @override
  String get dashboardRecOpen3a =>
      'Ouvrez un pilier 3a pour économiser sur vos impôts et préparer votre retraite';

  @override
  String get dashboardRecLowCoverage =>
      'Votre taux de couverture est bas. Augmentez vos cotisations pour améliorer votre retraite.';

  @override
  String get dashboardRecGoodTrack =>
      'Vous êtes sur la bonne voie ! Continuez à optimiser votre prévoyance.';

  @override
  String get dashboardActionGuided => 'Bilan guidé';

  @override
  String get dashboardActionExpert => 'Mode expert';

  @override
  String get dashboardActionLearn => 'Comprendre';

  @override
  String get dashboardQuickActions => 'Actions rapides';

  @override
  String get dashboardStatusOnline => 'API connectée';

  @override
  String get dashboardStatusOffline => 'API hors ligne';

  @override
  String dashboardUptime(int hours) {
    return 'En ligne depuis $hours h';
  }

  @override
  String get dashboardApiVersion => 'Version API';

  @override
  String get dashboardSince => 'depuis';

  @override
  String get dashboardGoalProgress => 'Progression vers l\'objectif';

  @override
  String get dashboardGoalReached => 'Objectif atteint !';

  @override
  String get dashboardRecommendedProvider => 'Prestataire recommandé pour vous';

  @override
  String get dashboardGreeting => 'Bonjour';

  @override
  String get dashboardGreetingEvening => 'Bonsoir';

  @override
  String get dashboardEmptyTitle => 'Complétez votre profil';

  @override
  String get dashboardEmptyBody =>
      'Renseignez votre situation financière pour obtenir votre projection de retraite et des recommandations personnalisées.';

  @override
  String get dashboardEmptyCta => 'Compléter mon profil';

  @override
  String get dashboardSynthesisTitle => 'Votre projection retraite';

  @override
  String get dashboardRecommendationsTitle => 'Recommandations';

  @override
  String get dashboardRecommendationsEmpty =>
      'Complétez votre profil pour recevoir des recommandations personnalisées.';

  @override
  String dashboardEstimatedAnnualImpact(String amount) {
    return 'Impact estimé : $amount/an';
  }

  @override
  String dashboardScoreBenchmarkTitle(int min, int max) {
    return 'Comparaison avec les $min–$max ans';
  }

  @override
  String dashboardScoreBenchmark3a(String user, String average) {
    return 'Pilier 3a : $user (moyenne : $average)';
  }

  @override
  String dashboardScoreBenchmarkRate(String user, String average) {
    return 'Taux de remplacement : $user (moyenne : $average)';
  }

  @override
  String dashboardScoreBenchmarkBvg(String user, String average) {
    return 'Capital LPP : $user (moyenne : $average)';
  }

  @override
  String get calculatorTitle => 'Calculateur';

  @override
  String get calculatorLppGap => 'Écart LPP';

  @override
  String get calculatorTaxSavings => 'Économies 3a';

  @override
  String get calculatorRetirement => 'Retraite';

  @override
  String get calculatorCalculate => 'Calculer';

  @override
  String get calculatorGrossIncome => 'Revenu brut (CHF)';

  @override
  String get calculatorAge => 'Âge';

  @override
  String get calculatorCanton => 'Canton';

  @override
  String get calculatorBvgCapital => 'Capital LPP (CHF)';

  @override
  String get calculatorAnnualContribution => 'Cotisation annuelle (CHF)';

  @override
  String get calculatorTaxableIncome => 'Revenu imposable (CHF)';

  @override
  String get calculatorContribution3a => 'Versement 3a (CHF)';

  @override
  String get calculatorPillar3aBalance => 'Solde 3a (CHF)';

  @override
  String get calculatorCoordinatedSalary => 'Salaire coordonné';

  @override
  String get calculatorBvgMinContribution => 'Cotisation LPP min.';

  @override
  String get calculatorProjectedCapital => 'Capital projeté';

  @override
  String get calculatorProjectedPension => 'Rente projetée/an';

  @override
  String get calculatorPensionGap => 'Écart de rente';

  @override
  String get calculatorFederalSaving => 'Économie fédérale';

  @override
  String get calculatorCantonalSaving => 'Économie cantonale';

  @override
  String get calculatorCommunalSaving => 'Économie communale';

  @override
  String get calculatorTotalSaving => 'Économie totale';

  @override
  String get calculatorEffectiveReturn => 'Rendement effectif';

  @override
  String get calculatorYearsToRetirement => 'Années jusqu\'à la retraite';

  @override
  String get calculatorProjectedPillar2 => 'Capital 2e pilier projeté';

  @override
  String get calculatorProjectedPillar3a => 'Capital 3a projeté';

  @override
  String get calculatorAnnualRetirementIncome => 'Revenu annuel retraite';

  @override
  String get calculatorReplacementRate => 'Taux de remplacement';

  @override
  String get providersTitle => 'Prestataires 3a';

  @override
  String get providersRanking => 'Classement';

  @override
  String get providersAll => 'Tous les prestataires';

  @override
  String get providersProducts => 'produits';

  @override
  String get providersFilter => 'Filtrer';

  @override
  String get providersCompare => 'Comparer';

  @override
  String get providersFees => 'Frais (%)';

  @override
  String get providersFeeComparison => 'Comparaison des frais';

  @override
  String providersCompareSelected(int count) {
    return 'Comparer $count produits';
  }

  @override
  String get providersTapToCompare => 'Touchez pour comparer';

  @override
  String get providersFeeShort => 'Frais';

  @override
  String get providersEquityShort => 'Actions';

  @override
  String get providersReturnShort => 'Rend. 3a';

  @override
  String get providersEsgBadge => 'Durable';

  @override
  String get providersVisitWebsite => 'Visiter le site web';

  @override
  String get providersWebsiteError => 'Impossible d\'ouvrir le lien';

  @override
  String get providersEmpty => 'Aucun prestataire disponible pour le moment';

  @override
  String get providersDigital => 'Digital';

  @override
  String get providersCategory => 'Catégorie';

  @override
  String get providersRiskLevel => 'Risque';

  @override
  String get providersFeesDetail => 'Détail des frais';

  @override
  String get providersTer => 'TER (frais de fonds)';

  @override
  String get providersAllInFee => 'Frais tout compris';

  @override
  String get providersCustodyFee => 'Frais de garde';

  @override
  String get providersEntryFee => 'Frais d\'entrée';

  @override
  String get providersExitFee => 'Frais de sortie';

  @override
  String get providersPerformance => 'Rendement par année';

  @override
  String get providersPerformanceWindow => '5 dernières années';

  @override
  String get providersCategoryPassiveIndex => 'Fonds indiciel (passif)';

  @override
  String get providersCategoryActiveManaged => 'Gestion active';

  @override
  String get providersCategoryInsurance => 'Assurance vie 3a';

  @override
  String get providersCategorySavings => 'Compte épargne';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileLanguage => 'Langue';

  @override
  String get profileAbout => 'À propos';

  @override
  String get profileVersion => 'Version';

  @override
  String get profileApi => 'Serveur API';

  @override
  String get profileSectionPersonal => 'Informations personnelles';

  @override
  String get profileSalary => 'Salaire (CHF)';

  @override
  String get profileAge => 'Âge';

  @override
  String get profileCanton => 'Canton';

  @override
  String get profileMunicipality => 'Commune';

  @override
  String get profileHas3a => 'Pilier 3a';

  @override
  String get profile3aBalance => 'Solde 3a (CHF)';

  @override
  String get profileMaritalStatus => 'Situation familiale';

  @override
  String get profileGoalSection => 'Objectif';

  @override
  String get profileTargetRate => 'Taux de remplacement cible';

  @override
  String get profileAppearance => 'Apparence';

  @override
  String get profileAppearanceSystem => 'Système';

  @override
  String get profileAppearanceLight => 'Clair';

  @override
  String get profileAppearanceDark => 'Sombre';

  @override
  String get profileSectionAccount => 'Compte';

  @override
  String get profileSectionSecurity => 'Sécurité';

  @override
  String get profileSettingsSubtitle => 'Canton, revenus, situation et comptes';

  @override
  String get profileSelectCanton => 'Sélectionner';

  @override
  String get profileBirthYear => 'Année de naissance';

  @override
  String get profileBirthYearInvalid => 'Année de naissance invalide';

  @override
  String get profileSectionSituation => 'Situation financière';

  @override
  String get profileEmploymentStatus => 'Statut professionnel';

  @override
  String get profileEmploymentEmployed => 'Salarié(e)';

  @override
  String get profileEmploymentSelfEmployed => 'Indépendant(e)';

  @override
  String get profileEmploymentUnemployed => 'Sans emploi';

  @override
  String get profileEmploymentRetired => 'Retraité(e)';

  @override
  String get profileMaritalDivorced => 'Divorcé(e)';

  @override
  String get profileMaritalWidowed => 'Veuf(ve)';

  @override
  String get profileChildren => 'Nombre d\'enfants';

  @override
  String get profileChildrenInvalid => 'Nombre d\'enfants invalide';

  @override
  String get profileGrossAnnualIncome => 'Revenu brut annuel (CHF)';

  @override
  String get profileNetAnnualIncome => 'Revenu net annuel (CHF, optionnel)';

  @override
  String get profileFieldRequired => 'Champ requis';

  @override
  String get profileAmountInvalid => 'Montant invalide';

  @override
  String get profileRateInvalid => 'Taux invalide';

  @override
  String get profileSaved => 'Profil enregistré';

  @override
  String get profileSectionPillar2 => 'Comptes LPP (2e pilier)';

  @override
  String get profileSectionPillar3a => 'Comptes 3a';

  @override
  String get profileEmptyPillar2 => 'Aucun compte LPP renseigné';

  @override
  String get profileEmptyPillar3a => 'Aucun compte 3a renseigné';

  @override
  String get profilePillar2DefaultName => 'Compte LPP';

  @override
  String get profileAddPillar2 => 'Ajouter un compte LPP';

  @override
  String get profileAddPillar3a => 'Ajouter un compte 3a';

  @override
  String get profilePillar2New => 'Nouveau compte LPP';

  @override
  String get profilePillar2Edit => 'Modifier le compte LPP';

  @override
  String get profilePillar3aNew => 'Nouveau compte 3a';

  @override
  String get profilePillar3aEdit => 'Modifier le compte 3a';

  @override
  String get profileProviderName => 'Prestataire';

  @override
  String get profileCurrentCapital => 'Capital actuel (CHF)';

  @override
  String get profileConversionRate => 'Taux de conversion (%)';

  @override
  String get profileAnnualContribution => 'Cotisation annuelle (CHF)';

  @override
  String get profileAdvancedSection => 'Avancé';

  @override
  String get profileInsuredSalary => 'Salaire assuré (CHF)';

  @override
  String get profileCoordinationDeduction => 'Déduction de coordination (CHF)';

  @override
  String get profileAnnualSupraContribution =>
      'Cotisation surobligatoire annuelle (CHF)';

  @override
  String get profileCurrentBalance => 'Solde actuel (CHF)';

  @override
  String get profileInterestRate => 'Taux d\'intérêt / rendement (%)';

  @override
  String get profileAccountType => 'Type de compte';

  @override
  String get profileAccountTypeBank => 'Banque';

  @override
  String get profileAccountTypeInsurance => 'Assurance';

  @override
  String get profileVestedBenefits => 'Compte de libre passage';

  @override
  String get profileDeleteAccountTitle => 'Supprimer ce compte ?';

  @override
  String get profileDeleteAccountBody => 'Cette action est définitive.';

  @override
  String get profileAccountSaved => 'Compte enregistré';

  @override
  String get profileAccountDeleted => 'Compte supprimé';

  @override
  String get ocrScanSalaryButton => 'Scanner un certificat de salaire';

  @override
  String get ocrScanLppButton => 'Scanner un relevé LPP';

  @override
  String get ocrScanSalaryTitle => 'Certificat de salaire';

  @override
  String get ocrScanLppTitle => 'Relevé LPP';

  @override
  String get ocrSourceCamera => 'Prendre une photo';

  @override
  String get ocrSourceGallery => 'Choisir une image';

  @override
  String get ocrScanning => 'Analyse du document…';

  @override
  String get ocrNoTextFound =>
      'Aucun texte détecté sur l\'image. Réessayez avec une photo plus nette.';

  @override
  String get ocrNoValuesFound =>
      'Aucune valeur reconnue sur ce document. Vous pouvez réessayer avec une autre photo.';

  @override
  String get ocrProposalTitle => 'Valeurs détectées';

  @override
  String get ocrProposalBody =>
      'Vérifiez et ajustez les valeurs avant de les appliquer.';

  @override
  String get ocrPrivacyNote =>
      'Analyse locale : l\'image ne quitte jamais votre appareil.';

  @override
  String get ocrApply => 'Appliquer';

  @override
  String get ocrScanError =>
      'L\'analyse a échoué. Réessayez avec une photo plus nette.';

  @override
  String get ocrApplied => 'Champs préremplis — vérifiez puis enregistrez';

  @override
  String get onboardingPillarsTitle => 'Votre retraite repose sur 3 piliers';

  @override
  String get onboardingPillarsDesc =>
      'Le système suisse de prévoyance est unique au monde. Découvrez comment il fonctionne.';

  @override
  String get onboardingDetailsTitle => 'Comment ça marche ?';

  @override
  String get onboardingDetailsDesc =>
      'Chaque pilier a un rôle différent dans votre retraite';

  @override
  String get onboardingP1Title => '1er pilier (AVS)';

  @override
  String get onboardingP1Desc =>
      'Rente de base obligatoire, financée par vos cotisations salariales';

  @override
  String get onboardingP2Title => '2e pilier (LPP)';

  @override
  String get onboardingP2Desc =>
      'Prévoyance professionnelle via votre employeur, capital accumulé';

  @override
  String get onboardingP3aTitle => 'Pilier 3a';

  @override
  String get onboardingP3aDesc =>
      'Épargne volontaire avec avantages fiscaux, c\'est vous qui décidez';

  @override
  String get onboardingFeaturesTitle => 'PocketPillar vous aide à...';

  @override
  String get onboardingFeaturesDesc =>
      'Tout ce dont vous avez besoin pour votre prévoyance';

  @override
  String get onboardingFeatureScore => 'Évaluer votre santé prévoyance';

  @override
  String get onboardingFeatureSimulate => 'Simuler votre retraite en détail';

  @override
  String get onboardingFeatureCompare => 'Comparer les prestataires 3a';

  @override
  String get onboardingFeatureTips => 'Recevoir des conseils personnalisés';

  @override
  String get onboardingReadyTitle => 'C\'est parti !';

  @override
  String get onboardingReadyDesc =>
      'Ça prend 2 minutes. Découvrez où en est votre prévoyance.';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingReplay => 'Revoir l\'introduction';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue sur PocketPillar';

  @override
  String get onboardingWelcomeDesc =>
      'Optimisez votre prévoyance suisse. Simulez, comparez et maximisez vos 2e et 3e piliers.';

  @override
  String get onboardingCalculatorTitle => 'Calculateurs intelligents';

  @override
  String get onboardingCalculatorDesc =>
      'Analysez votre écart LPP, calculez vos économies fiscales 3a par canton, et projetez votre retraite.';

  @override
  String get onboardingProvidersTitle => 'Comparez les prestataires';

  @override
  String get onboardingProvidersDesc =>
      'VIAC, Frankly, finpension et plus encore. Trouvez le pilier 3a avec les meilleurs frais et rendements.';

  @override
  String get pillar1Short => '1er pilier';

  @override
  String get pillar1Name => 'AVS / AI';

  @override
  String get pillar2Short => '2e pilier';

  @override
  String get pillar2Name => 'LPP / Caisse de pension';

  @override
  String get pillar3aShort => 'Pilier 3a';

  @override
  String get pillar3aName => 'Prévoyance privée';

  @override
  String get guidedTitle => 'Votre bilan';

  @override
  String get guidedResultsTitle => 'Vos résultats';

  @override
  String get guidedSalaryTitle => 'Quel est votre salaire annuel ?';

  @override
  String get guidedSalarySubtitle => 'Salaire brut avant déductions';

  @override
  String get guidedAgeTitle => 'Quel âge avez-vous ?';

  @override
  String get guidedAgeSubtitle =>
      'Votre âge influence vos cotisations et projections';

  @override
  String get guidedAgeYears => 'ans';

  @override
  String get guidedCantonTitle => 'Où habitez-vous ?';

  @override
  String get guidedCantonSubtitle =>
      'Les taux d\'imposition varient selon le canton';

  @override
  String get guided3aTitle => 'Avez-vous un pilier 3a ?';

  @override
  String get guided3aSubtitle =>
      'Le pilier 3a est votre épargne personnelle avec avantages fiscaux';

  @override
  String get guided3aQuestion => 'Épargnez-vous dans un 3a ?';

  @override
  String get guided3aBalance => 'Solde approximatif';

  @override
  String get guidedYes => 'Oui';

  @override
  String get guidedNo => 'Non';

  @override
  String get guidedNext => 'Suivant';

  @override
  String get guidedBack => 'Retour';

  @override
  String get guidedSeeResults => 'Voir mes résultats';

  @override
  String get guidedMaritalTitle => 'Quelle est votre situation familiale ?';

  @override
  String get guidedMaritalSubtitle =>
      'Votre situation influence le calcul de vos impôts';

  @override
  String get guidedMaritalSingle => 'Célibataire';

  @override
  String get guidedMaritalMarried => 'Marié(e)';

  @override
  String get guidedMaritalPartnership => 'Partenariat enregistré';

  @override
  String get guidedSituationTitle => 'Votre situation';

  @override
  String get guidedSituationSubtitle => 'Âge, canton et situation familiale';

  @override
  String get guidedPillar2Title => 'Votre 2e pilier (LPP)';

  @override
  String get guidedPillar2Subtitle =>
      'Capital et cotisations de votre caisse de pension — voir votre certificat de prévoyance';

  @override
  String guidedStepOf(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String resultsSummaryPhrase(int percent) {
    return 'Votre pension couvrira $percent% de votre revenu actuel';
  }

  @override
  String resultsPensionMonthly(String amount) {
    return 'Soit environ $amount par mois';
  }

  @override
  String get resultsYourPillars => 'Vos 3 piliers';

  @override
  String get resultsReplacementRate => 'Taux de remplacement';

  @override
  String get resultsYearsToRetirement => 'Années jusqu\'à la retraite';

  @override
  String get resultsTaxSavings => 'Économies fiscales';

  @override
  String get resultsAnnualSavings => 'd\'économies par an';

  @override
  String resultsEffectiveReturn(String rate) {
    return 'Rendement effectif : $rate%';
  }

  @override
  String get resultsWhatToDo => 'Que faire maintenant ?';

  @override
  String get resultsRecOpen3a =>
      'Ouvrez un pilier 3a pour économiser des impôts et préparer votre retraite';

  @override
  String resultsRecMax3a(String amount) {
    return 'Versez le maximum de $amount en 3a pour optimiser vos impôts';
  }

  @override
  String resultsRecTaxSaving(String amount) {
    return 'Vous économisez $amount d\'impôts par an grâce au 3a';
  }

  @override
  String get resultsRecIncreaseCoverage =>
      'Votre couverture est inférieure à 60%. Envisagez un rachat LPP ou augmentez vos cotisations 3a.';

  @override
  String get resultsRecBvgBuyback =>
      'Un rachat LPP pourrait combler votre écart de rente et réduire vos impôts';

  @override
  String get resultsAboveAverage => 'Au-dessus de la moyenne pour votre âge';

  @override
  String get resultsBelowAverage => 'En dessous de la moyenne pour votre âge';

  @override
  String get resultsNearAverage => 'Dans la moyenne pour votre âge';

  @override
  String get resultsCompareToggle => 'Comparer avec/sans 3a';

  @override
  String get resultsCompareWith3a => 'Avec 3a (par mois)';

  @override
  String get resultsCompareWithout3a => 'Sans 3a (par mois)';

  @override
  String get resultsDeltaLabel => 'Différence';

  @override
  String get resultsApproximateBadge => 'Estimation approximative (hors ligne)';

  @override
  String get cantonPickerTitle => 'Choisir un canton';

  @override
  String get cantonPickerSearch => 'Rechercher un canton';

  @override
  String get municipalityPickerTitle => 'Choisir une commune';

  @override
  String get municipalityPickerSearch => 'Rechercher une commune';

  @override
  String get municipalityCantonalAverageOption =>
      'Moyenne cantonale (commune non listée)';

  @override
  String get municipalityPickerEmpty =>
      'Aucune commune couverte pour ce canton — la moyenne cantonale est utilisée.';

  @override
  String get municipalityPickerNoResults => 'Aucun résultat';

  @override
  String get municipalityPickerError => 'Impossible de charger les communes';

  @override
  String get municipalitySelectCantonFirst => 'Choisissez d\'abord un canton';

  @override
  String get helpSectionWhat => 'C\'est quoi ?';

  @override
  String get helpSectionWhy => 'Pourquoi c\'est important ?';

  @override
  String get helpSectionWhere => 'Où trouver cette info ?';

  @override
  String get helpPillarSystemTitle => 'Système des 3 piliers';

  @override
  String get helpPillarSystemExplanation =>
      'La Suisse organise la retraite en 3 niveaux : une rente de base (AVS), une prévoyance professionnelle (LPP), et une épargne privée (3a). Ensemble, ils visent à maintenir votre niveau de vie.';

  @override
  String get helpPillarSystemWhy =>
      'Comprendre ce système vous aide à identifier ce que vous pouvez optimiser pour votre retraite.';

  @override
  String get helpPillarSystemWhere =>
      'Votre certificat de salaire et votre certificat de prévoyance annuel détaillent vos cotisations.';

  @override
  String get helpPillar1AvsTitle => 'AVS (1er pilier)';

  @override
  String get helpPillar1AvsExplanation =>
      'L\'AVS est la rente de base que tout le monde reçoit à la retraite. Elle est financée par vos cotisations salariales (prélevées automatiquement) et celles de votre employeur.';

  @override
  String get helpPillar1AvsWhy =>
      'L\'AVS seule ne couvre qu\'environ 40% de votre dernier salaire. C\'est pourquoi les 2e et 3e piliers sont essentiels.';

  @override
  String get helpPillar1AvsWhere =>
      'Demandez un extrait de compte AVS sur le site de votre caisse cantonale de compensation.';

  @override
  String get helpPillar2BvgTitle => 'LPP / 2e pilier';

  @override
  String get helpPillar2BvgExplanation =>
      'La prévoyance professionnelle est une épargne obligatoire gérée par votre employeur. Vous et votre employeur cotisez chaque mois. Ce capital s\'accumule et vous sera versé à la retraite.';

  @override
  String get helpPillar2BvgWhy =>
      'C\'est souvent le plus gros montant de votre retraite. Vérifiez votre certificat de prévoyance annuel pour connaître votre capital.';

  @override
  String get helpPillar2BvgWhere =>
      'Votre certificat de prévoyance annuel, envoyé par la caisse de pension de votre employeur.';

  @override
  String get helpPillar3aTitle => 'Pilier 3a';

  @override
  String get helpPillar3aExplanation =>
      'Le pilier 3a est une épargne volontaire que vous gérez vous-même. Vous choisissez votre prestataire, le montant et le type de placement. L\'argent est bloqué jusqu\'à la retraite (sauf exceptions).';

  @override
  String get helpPillar3aWhy =>
      'Chaque franc versé en 3a est déductible de vos impôts. C\'est le moyen le plus simple de payer moins d\'impôts tout en préparant sa retraite.';

  @override
  String get helpPillar3aWhere =>
      'Connectez-vous au site de votre prestataire 3a (banque ou app) pour voir votre solde.';

  @override
  String get helpCoordinatedSalaryTitle => 'Salaire coordonné';

  @override
  String get helpCoordinatedSalaryExplanation =>
      'C\'est la partie de votre salaire sur laquelle sont calculées vos cotisations LPP. On soustrait un montant fixe (déduction de coordination) de votre salaire brut.';

  @override
  String get helpCoordinatedSalaryWhy =>
      'Plus il est élevé, plus vos cotisations et votre future rente seront importantes.';

  @override
  String get helpCoordinatedSalaryWhere =>
      'Indiqué sur votre certificat de prévoyance LPP annuel.';

  @override
  String get helpConversionRateTitle => 'Taux de conversion';

  @override
  String get helpConversionRateExplanation =>
      'Ce pourcentage transforme votre capital LPP en rente annuelle. Par exemple, avec un taux de 6.8% et CHF 500\'000 de capital, vous recevez CHF 34\'000 par an.';

  @override
  String get helpConversionRateWhy =>
      'Un taux plus élevé = une meilleure rente. Le taux minimum légal est de 6.8%, mais les caisses peuvent appliquer un taux plus bas sur la part surobligatoire.';

  @override
  String get helpConversionRateWhere =>
      'Indiqué sur votre certificat de prévoyance annuel ou le règlement de votre caisse de pension.';

  @override
  String get helpBvgCapitalTitle => 'Capital LPP';

  @override
  String get helpBvgCapitalExplanation =>
      'C\'est l\'argent accumulé dans votre caisse de pension (2e pilier). Vos cotisations et celles de votre employeur s\'additionnent chaque mois, avec des intérêts.';

  @override
  String get helpBvgCapitalWhy =>
      'C\'est généralement le plus gros actif que vous possédez. Il détermine directement le montant de votre rente à la retraite.';

  @override
  String get helpBvgCapitalWhere =>
      'Votre certificat de prévoyance annuel, rubrique \'avoir de vieillesse\'.';

  @override
  String get helpReplacementRateTitle => 'Taux de remplacement';

  @override
  String get helpReplacementRateExplanation =>
      'Le pourcentage de votre dernier salaire que vous toucherez à la retraite. Par exemple, 65% signifie que si vous gagnez CHF 100\'000, votre rente sera d\'environ CHF 65\'000 par an.';

  @override
  String get helpReplacementRateWhy =>
      'L\'objectif est généralement 60-80%. En dessous de 60%, votre niveau de vie risque de baisser significativement à la retraite.';

  @override
  String get helpReplacementRateWhere =>
      'PocketPillar le calcule pour vous à partir de vos données. Vous pouvez aussi le demander à votre caisse de pension.';

  @override
  String get helpPensionGapTitle => 'Écart de rente';

  @override
  String get helpPensionGapExplanation =>
      'La différence entre la rente que vous devriez recevoir selon la loi et ce que vous recevrez réellement. Si votre employeur cotise au minimum légal, l\'écart peut être nul.';

  @override
  String get helpPensionGapWhy =>
      'Un écart positif signifie que vous êtes en dessous du minimum légal et pourrait indiquer un problème avec vos cotisations.';

  @override
  String get helpPensionGapWhere =>
      'Comparez votre certificat de prévoyance avec les minimums LPP, ou utilisez le calculateur PocketPillar.';

  @override
  String get helpTaxSavings3aTitle => 'Économies fiscales 3a';

  @override
  String get helpTaxSavings3aExplanation =>
      'Chaque franc versé dans votre 3a réduit votre revenu imposable. Selon votre canton et votre revenu, vous pouvez économiser entre CHF 1\'500 et CHF 3\'000 d\'impôts par an.';

  @override
  String get helpTaxSavings3aWhy =>
      'C\'est de l\'argent que vous gardez au lieu de le donner au fisc. Plus vous gagnez, plus l\'économie est importante.';

  @override
  String get helpTaxSavings3aWhere =>
      'Utilisez le calculateur fiscal de PocketPillar en sélectionnant votre canton.';

  @override
  String get helpBvgBuybackTitle => 'Rachat LPP';

  @override
  String get helpBvgBuybackExplanation =>
      'Un versement volontaire dans votre 2e pilier pour combler des lacunes de cotisation. Par exemple, si vous n\'avez pas travaillé en Suisse pendant quelques années.';

  @override
  String get helpBvgBuybackWhy =>
      'Le montant est 100% déductible des impôts l\'année du versement. C\'est une stratégie fiscale très efficace.';

  @override
  String get helpBvgBuybackWhere =>
      'Votre certificat de prévoyance indique le montant maximum de rachat possible. Contactez votre caisse de pension.';

  @override
  String get helpRetirementAgeTitle => 'Âge de la retraite';

  @override
  String get helpRetirementAgeExplanation =>
      'En Suisse, l\'âge de référence est de 65 ans (transition AVS 21 pour les femmes nées 1961-1963 : 64 ans et 6 mois en 2026). Vous pouvez prendre une retraite anticipée dès 58 ans ou la reporter jusqu\'à 70 ans.';

  @override
  String get helpRetirementAgeWhy =>
      'Chaque année d\'anticipation réduit votre rente. Chaque année de report l\'augmente. C\'est un choix financier important.';

  @override
  String get helpRetirementAgeWhere =>
      'Site de l\'OFAS (Office fédéral des assurances sociales) ou votre caisse de compensation cantonale.';

  @override
  String get helpContribution3aMaxTitle => 'Plafond 3a';

  @override
  String get helpContribution3aMaxExplanation =>
      'Le montant maximum que vous pouvez verser en 3a est fixé par la loi. En 2026, c\'est CHF 7\'258 si vous avez un 2e pilier, ou CHF 36\'288 sans 2e pilier (max 20% du revenu net).';

  @override
  String get helpContribution3aMaxWhy =>
      'Verser le maximum est presque toujours avantageux : vous maximisez votre économie d\'impôts.';

  @override
  String get helpContribution3aMaxWhere =>
      'Le montant est publié chaque année par l\'OFAS. PocketPillar est toujours à jour.';

  @override
  String get helpGrossIncomeTitle => 'Revenu brut';

  @override
  String get helpGrossIncomeExplanation =>
      'Votre salaire annuel avant toute déduction (impôts, AVS, LPP, etc.). C\'est le montant indiqué sur votre contrat de travail.';

  @override
  String get helpGrossIncomeWhy =>
      'C\'est la base de calcul pour vos cotisations et vos projections de retraite.';

  @override
  String get helpGrossIncomeWhere =>
      'Votre contrat de travail, votre fiche de salaire mensuelle, ou votre certificat de salaire annuel.';

  @override
  String get helpEffectiveReturnTitle => 'Rendement effectif';

  @override
  String get helpEffectiveReturnExplanation =>
      'Le pourcentage de rendement réel de votre versement 3a, en tenant compte de l\'économie d\'impôts. C\'est comme un bonus immédiat sur votre investissement.';

  @override
  String get helpEffectiveReturnWhy =>
      'Un rendement effectif de 30% signifie que pour CHF 7\'258 versés, vous récupérez environ CHF 2\'177 en impôts économisés.';

  @override
  String get helpEffectiveReturnWhere =>
      'Utilisez le calculateur fiscal de PocketPillar pour voir votre rendement effectif selon votre canton.';

  @override
  String get tipMax3a2026Title => 'Maximum 3a 2026';

  @override
  String get tipMax3a2026Body =>
      'Le montant maximum 3a pour 2026 est de CHF 7\'258. Versez-le avant le 31 décembre pour économiser sur vos impôts !';

  @override
  String get tipBvgBuybackTitle => 'Rachat LPP = double économie';

  @override
  String get tipBvgBuybackBody =>
      'Un rachat LPP est 100% déductible de vos impôts ET augmente votre rente. Demandez votre potentiel de rachat à votre caisse.';

  @override
  String get tip3aTaxDeductionTitle => 'Le 3a réduit vos impôts';

  @override
  String get tip3aTaxDeductionBody =>
      'Chaque franc versé en 3a est déductible de votre revenu imposable. Selon votre canton, ça peut représenter plus de 30% de rendement immédiat !';

  @override
  String get tipStartEarlyTitle => 'Commencez tôt';

  @override
  String get tipStartEarlyBody =>
      'Commencer à épargner en 3a à 25 ans plutôt qu\'à 35 ans peut vous faire gagner plus de CHF 100\'000 grâce aux intérêts composés.';

  @override
  String get tipCompoundInterestTitle => 'La magie des intérêts composés';

  @override
  String get tipCompoundInterestBody =>
      'Vos intérêts génèrent eux-mêmes des intérêts. Sur 30 ans, un placement 3a à 3% de rendement double quasiment votre capital investi.';

  @override
  String get tipMultiple3aTitle => 'Plusieurs comptes 3a';

  @override
  String get tipMultiple3aBody =>
      'Ouvrir plusieurs comptes 3a (jusqu\'à 5) permet d\'étaler les retraits et de réduire l\'impôt sur le capital à la sortie.';

  @override
  String get tipRetirementGapTitle => 'L\'écart de retraite';

  @override
  String get tipRetirementGapBody =>
      'En moyenne, les 1er et 2e piliers ne couvrent que 60% de votre dernier salaire. Le 3a est essentiel pour combler cet écart.';

  @override
  String get tip3PillarsTitle => 'Pourquoi 3 piliers ?';

  @override
  String get tip3PillarsBody =>
      'Le système suisse répartit le risque : l\'État (AVS), l\'employeur (LPP) et vous-même (3a). Chacun joue un rôle dans votre sécurité financière.';

  @override
  String get tipAvsMaxTitle => 'Rente AVS maximum';

  @override
  String get tipAvsMaxBody =>
      'La rente AVS maximale est de CHF 2\'520/mois pour une personne seule (2026). Même les hauts revenus sont plafonnés à ce montant.';

  @override
  String get tipPillar2InterestTitle => 'Taux d\'intérêt LPP';

  @override
  String get tipPillar2InterestBody =>
      'Votre capital LPP obligatoire est rémunéré au minimum 1.25% par an. Certaines caisses offrent plus sur la part surobligatoire.';

  @override
  String get tip3aWithdrawalTitle => 'Retrait anticipé du 3a';

  @override
  String get tip3aWithdrawalBody =>
      'Vous pouvez retirer votre 3a avant la retraite pour acheter un logement, vous installer à votre compte, ou quitter la Suisse.';

  @override
  String get tipCantonTaxesTitle => 'L\'impact du canton';

  @override
  String get tipCantonTaxesBody =>
      'L\'économie fiscale 3a varie énormément selon le canton. À Genève, elle peut être 2x plus élevée qu\'à Zoug sur le même revenu.';

  @override
  String get bestmatchTitle => 'Trouver mon 3a idéal';

  @override
  String get bestmatchSubtitle =>
      'Répondez à quelques questions pour trouver le meilleur pilier 3a';

  @override
  String get bestmatchRiskQuestion =>
      'Comment souhaitez-vous placer votre argent ?';

  @override
  String get bestmatchRiskExplanation =>
      'Plus le rendement potentiel est élevé, plus la valeur peut varier à court terme';

  @override
  String get bestmatchRiskConservativeTitle => 'Sécurité avant tout';

  @override
  String get bestmatchRiskConservativeDesc =>
      'Mon argent varie peu, même si ça rapporte moins';

  @override
  String get bestmatchRiskModerateTitle => 'Prudent';

  @override
  String get bestmatchRiskModerateDesc =>
      'J\'accepte de petites variations pour un meilleur rendement';

  @override
  String get bestmatchRiskBalancedTitle => 'Équilibré';

  @override
  String get bestmatchRiskBalancedDesc =>
      'Un mix entre sécurité et rendement, le plus populaire';

  @override
  String get bestmatchRiskGrowthTitle => 'Dynamique';

  @override
  String get bestmatchRiskGrowthDesc =>
      'Je vise le rendement maximum, les baisses temporaires ne me font pas peur';

  @override
  String get bestmatchRiskAggressiveTitle => '100% actions';

  @override
  String get bestmatchRiskAggressiveDesc =>
      'Tout en actions pour le long terme, idéal si la retraite est loin';

  @override
  String get bestmatchRiskConservative => 'Conservateur (0-25% actions)';

  @override
  String get bestmatchRiskModerate => 'Modéré (25-50% actions)';

  @override
  String get bestmatchRiskBalanced => 'Équilibré (50-75% actions)';

  @override
  String get bestmatchRiskGrowth => 'Croissance (75-100% actions)';

  @override
  String get bestmatchRiskAggressive => 'Agressif (100% actions)';

  @override
  String get bestmatchPreferences => 'Vos préférences';

  @override
  String get bestmatchMaxFee => 'Frais annuels maximum';

  @override
  String get bestmatchFeeHint =>
      'Des frais bas = plus d\'argent pour vous. La moyenne suisse est d\'environ 0.8%.';

  @override
  String get bestmatchEsg => 'Investissement durable';

  @override
  String get bestmatchEsgHint =>
      'Exclut les entreprises polluantes, armes, tabac';

  @override
  String get bestmatchFind => 'Trouver les meilleurs';

  @override
  String get bestmatchResultsTitle => 'Vos meilleurs choix';

  @override
  String get bestmatchNoResults => 'Aucun résultat';

  @override
  String get bestmatchTryDifferent => 'Essayez avec des critères différents';

  @override
  String get bestmatchRestart => 'Recommencer';

  @override
  String get bestmatchScoreExplanation =>
      'Le score combine les frais, le rendement sur 3 ans, l\'adéquation à votre profil de risque et la durabilité (ESG).';

  @override
  String get privacyLocalData =>
      'Vos données financières sont stockées sur des serveurs sécurisés en Europe (Irlande). Elles servent uniquement à fournir le service. Le verrouillage biométrique et vos identifiants restent sur votre appareil.';

  @override
  String get privacyTitle => 'Politique de confidentialité';

  @override
  String get privacySectionDataCollected => 'Données collectées';

  @override
  String get privacyBodyDataCollected =>
      'PocketPillar collecte votre adresse e-mail, vos informations financières (salaire, avoirs de prévoyance, situation fiscale) et les documents que vous uploadez. Ces données sont nécessaires au fonctionnement de l\'application.';

  @override
  String get privacySectionPurpose => 'Finalité du traitement';

  @override
  String get privacyBodyPurpose =>
      'Vos données sont utilisées exclusivement pour calculer votre situation de prévoyance, générer des recommandations personnalisées et stocker vos documents de prévoyance de manière sécurisée.';

  @override
  String get privacySectionStorage => 'Stockage et sécurité';

  @override
  String get privacyBodyStorage =>
      'Votre profil et vos données financières sont stockés sur des serveurs sécurisés dans l\'UE (Irlande). Vos identifiants et jetons de session restent dans le stockage sécurisé de l\'appareil (Keychain iOS / Keystore Android). Les documents sont chiffrés en transit et au repos. L\'accès biométrique (Face ID / Touch ID) protège l\'ouverture de l\'app.';

  @override
  String get privacySectionSharing => 'Partage des données';

  @override
  String get privacyBodySharing =>
      'PocketPillar ne vend et ne loue jamais vos données personnelles. Elles ne sont transmises qu\'aux sous-traitants techniques indispensables au service (hébergement Supabase, UE) et jamais à des fins publicitaires.';

  @override
  String get privacySectionRights => 'Vos droits (nDSG)';

  @override
  String get privacyBodyRights =>
      'Conformément à la nouvelle loi suisse sur la protection des données (nDSG), vous avez le droit d\'accéder à vos données, de les rectifier, de les exporter et de demander leur suppression complète à tout moment.';

  @override
  String get privacySectionSecurity => 'Mesures de sécurité';

  @override
  String get privacyBodySecurity =>
      'Authentification sécurisée avec jetons (JWT), verrouillage biométrique, stockage chiffré des identifiants sur l\'appareil, blocage des captures d\'écran sur Android, URLs de téléchargement à durée limitée (5 min), validation des types de fichiers.';

  @override
  String get privacySectionContact => 'Contact';

  @override
  String get privacyBodyContact =>
      'Pour toute question concernant vos données personnelles : privacy@pocketpillar.ch';

  @override
  String get buybackTitle => 'Rachat LPP';

  @override
  String get buybackWhatTitle => 'C\'est quoi ?';

  @override
  String get buybackWhatBody =>
      'Un rachat LPP est un versement volontaire dans votre caisse de pension pour combler des lacunes de cotisation. Par exemple, si vous n\'avez pas toujours travaillé en Suisse ou si vous avez eu une augmentation de salaire.';

  @override
  String get buybackBenefitsTitle => 'Avantages';

  @override
  String get buybackBenefitsBody =>
      'Le montant est 100% déductible de vos impôts l\'année du versement. Votre rente future augmente. C\'est l\'une des meilleures stratégies fiscales en Suisse.';

  @override
  String get buybackStepsTitle => 'Comment faire ?';

  @override
  String get buybackStepsBody =>
      '1. Consultez votre certificat de prévoyance pour le montant maximum de rachat\n2. Contactez votre caisse de pension\n3. Effectuez le versement avant le 31 décembre\n4. Déduisez le montant de votre déclaration fiscale';

  @override
  String get compareTitle => 'Comparaison';

  @override
  String get compareFees => 'Frais annuels';

  @override
  String get compareReturns => 'Rendement moyen 3 ans';

  @override
  String get compareAllocation => 'Part en actions';

  @override
  String get compareScore => 'Score';

  @override
  String get compareFeesLabel => 'Frais';

  @override
  String get compareReturn3y => 'Rend. 3a';

  @override
  String get compareEsgLabel => 'Durable';

  @override
  String get compareEquity => 'Actions';

  @override
  String get compareLowest => 'Le moins cher';

  @override
  String get compareBestChoice => 'Meilleur choix global';

  @override
  String get docTitle => 'Documents';

  @override
  String get docEmptyTitle => 'Aucun document';

  @override
  String get docEmptyDescription =>
      'Ajoutez vos documents de prévoyance pour les garder en sécurité';

  @override
  String get docDelete => 'Supprimer';

  @override
  String get docUploadTitle => 'Ajouter un document';

  @override
  String get docTypeLabel => 'Type de document';

  @override
  String get docIncludeYear => 'Associer une année';

  @override
  String get docYearLabel => 'Année';

  @override
  String get docChooseFile => 'Choisir un fichier';

  @override
  String get docUploading => 'Envoi en cours...';

  @override
  String get docTypeSalarySlip => 'Certificat de salaire';

  @override
  String get docTypeBvgStatement => 'Certificat LPP/BVG';

  @override
  String get docTypePillar3aStatement => 'Relevé pilier 3a';

  @override
  String get docTypeTaxDeclaration => 'Déclaration d\'impôt';

  @override
  String get docTypeOther => 'Autre';

  @override
  String get docUploadSuccess => 'Document ajouté';

  @override
  String get docDeleted => 'Document supprimé';

  @override
  String get docDeleteConfirmTitle => 'Supprimer ce document ?';

  @override
  String get docDeleteConfirmBody => 'Cette action est définitive.';

  @override
  String get docFileTooLarge =>
      'Le fichier dépasse la taille maximale de 10 Mo';

  @override
  String get docInvalidFile => 'Format non pris en charge (PDF, JPEG ou PNG)';

  @override
  String get docReadError => 'Impossible de lire le fichier';

  @override
  String get docOpenError => 'Impossible d\'ouvrir le document';

  @override
  String get scenarioTitle => 'Scénarios de vie';

  @override
  String get scenarioSectionTitle => 'Simulez l\'impact sur votre retraite';

  @override
  String get scenarioFooter =>
      'Ces simulations sont indicatives. Consultez un conseiller pour des décisions importantes.';

  @override
  String get scenarioMonth => 'mois';

  @override
  String get scenarioYear => 'an';

  @override
  String get scenarioPrefillFailed =>
      'Profil non chargé — le formulaire utilise les valeurs par défaut.';

  @override
  String get scenario3aCatchupTitle => 'Rattrapage 3a';

  @override
  String get scenario3aCatchupSubtitle =>
      'Rattrapez vos années non-cotisées (réforme 2025)';

  @override
  String get scenario3aCatchupInputSection => 'Votre situation';

  @override
  String get scenario3aCatchupYearsMissed => 'Années sans cotisation';

  @override
  String get scenario3aCatchupResultSection => 'Potentiel de rattrapage';

  @override
  String get scenario3aCatchupMaxPerYear => 'Maximum par année';

  @override
  String get scenario3aCatchupTotalCatchup => 'Rattrapage total possible';

  @override
  String get scenario3aCatchupTaxSaving => 'Économie fiscale estimée';

  @override
  String get scenario3aCatchupInfo =>
      'Depuis 2025, vous pouvez rattraper jusqu\'à 10 années de cotisations 3a manquées. Vous devez d\'abord maximiser l\'année en cours.';

  @override
  String get scenarioPropertyTitle => 'Achat immobilier';

  @override
  String get scenarioPropertySubtitle =>
      'Impact du retrait EPL sur votre rente';

  @override
  String get scenarioPropertyInputSection => 'Montants';

  @override
  String get scenarioPropertyBvgCapital => 'Capital LPP actuel';

  @override
  String get scenarioPropertyWithdrawal => 'Montant du retrait';

  @override
  String get scenarioPropertyMaxWithdrawal => 'Retrait max. autorisé';

  @override
  String get scenarioPropertyEffectiveWithdrawal => 'Retrait effectif';

  @override
  String get scenarioPropertyImpactSection => 'Impact sur la retraite';

  @override
  String get scenarioPropertyCapitalWithout =>
      'Capital à la retraite (sans retrait)';

  @override
  String get scenarioPropertyCapitalWith =>
      'Capital à la retraite (avec retrait)';

  @override
  String get scenarioPropertyPensionLoss => 'Perte de rente mensuelle';

  @override
  String get scenarioDivorceTitle => 'Divorce';

  @override
  String get scenarioDivorceSubtitle => 'Partage LPP et impact sur la rente';

  @override
  String get scenarioDivorceMySection => 'Votre LPP';

  @override
  String get scenarioDivorceMyCapitalMarriage => 'Capital au mariage';

  @override
  String get scenarioDivorceMyCapitalNow => 'Capital actuel';

  @override
  String get scenarioDivorceSpouseSection => 'LPP du conjoint';

  @override
  String get scenarioDivorceSpouseCapitalMarriage => 'Capital au mariage';

  @override
  String get scenarioDivorceSpouseCapitalNow => 'Capital actuel';

  @override
  String get scenarioDivorceYearsMarried => 'Années de mariage';

  @override
  String get scenarioDivorceResultSection => 'Résultat du partage';

  @override
  String get scenarioDivorceTotalMarriageCapital =>
      'Capital accumulé pendant le mariage';

  @override
  String get scenarioDivorceMyShare => 'Votre part (50%)';

  @override
  String get scenarioDivorceTransfer => 'Transfert';

  @override
  String get scenarioDivorceCapitalAfter => 'Votre capital après divorce';

  @override
  String get scenarioWithdrawalTitle => 'Retrait échelonné';

  @override
  String get scenarioWithdrawalSubtitle =>
      'Optimisez la fiscalité de vos retraits 3a';

  @override
  String get scenarioWithdrawalInputSection => 'Vos avoirs';

  @override
  String get scenarioWithdrawal3aBalance => 'Solde total 3a';

  @override
  String get scenarioWithdrawalAccounts => 'Nombre de comptes 3a';

  @override
  String get scenarioWithdrawalPillar2Capital =>
      'Capital LPP en capital (si retrait)';

  @override
  String get scenarioWithdrawalComparison => 'Comparaison fiscale';

  @override
  String get scenarioWithdrawalSaving => 'Économie fiscale';

  @override
  String get scenarioWithdrawalTip =>
      'En Suisse, les retraits de capital sont imposés à un taux progressif. Répartir les retraits sur plusieurs années permet de rester dans des tranches d\'imposition plus basses.';

  @override
  String get scenarioDivorcePensionImpact => 'Impact sur la rente annuelle';

  @override
  String get scenario3aCatchupStatusEmployed => 'Salarié·e (avec 2e pilier)';

  @override
  String get scenario3aCatchupStatusSelfEmployed =>
      'Indépendant·e (sans 2e pilier)';

  @override
  String get scenario3aCatchupEligibleYears => 'Années rattrapables';

  @override
  String get scenario3aCatchupCurrentYearGap =>
      'À verser d\'abord (année en cours)';

  @override
  String get scenario3aCatchupMarginalRate => 'Taux marginal estimé';

  @override
  String get scenario3aCatchupYearlySection => 'Détail par année';

  @override
  String get scenarioWithdrawalStrategyLumpSum => 'Retrait unique';

  @override
  String scenarioWithdrawalStrategyStaggered(int years) {
    return 'Échelonné sur $years ans';
  }

  @override
  String get scenarioWithdrawalBestStrategy => 'Meilleure stratégie';

  @override
  String get scenarioWithdrawalEffectiveRate => 'Taux d\'impôt effectif';

  @override
  String get scenarioDivorceAvsImpact => 'Impact estimé sur la rente AVS';

  @override
  String get scenarioDivorceDisclaimer =>
      'Simulation indicative du partage LPP prévu par la loi (50/50 des avoirs accumulés pendant le mariage). Elle ne constitue pas un conseil juridique.';

  @override
  String get scenarioDivorceYouReceive => 'Vous recevez';

  @override
  String get scenarioDivorceYouPay => 'Vous payez';

  @override
  String get scenarioDivorceCapitalExceedsNow =>
      'Le capital au mariage ne peut pas dépasser le capital actuel';

  @override
  String get pdfTitle => 'Bilan Prévoyance PocketPillar';

  @override
  String get pdfExportButton => 'Exporter le bilan PDF';

  @override
  String get pdfSectionTitle => 'Exporter';

  @override
  String get pdfAge => 'Âge';

  @override
  String get pdfSalary => 'Salaire';

  @override
  String get pdfCanton => 'Canton';

  @override
  String get pdfPillarsTitle => 'Vos 3 piliers';

  @override
  String get pdfPillar1 => '1er pilier (AVS)';

  @override
  String get pdfPillar2 => '2e pilier (LPP)';

  @override
  String get pdfPillar3a => 'Pilier 3a';

  @override
  String get pdfProjectionTitle => 'Projection retraite';

  @override
  String get pdfRetirementAge => 'Âge de la retraite';

  @override
  String get pdfYearsRemaining => 'Années restantes';

  @override
  String get pdfReplacementRate => 'Taux de remplacement';

  @override
  String get pdfAnnualIncome => 'Revenu annuel estimé';

  @override
  String get pdfMonthlyIncome => 'Revenu mensuel estimé';

  @override
  String get pdfTaxTitle => 'Économies fiscales (3a)';

  @override
  String pdfTaxDetail(String amount) {
    return 'Économie annuelle estimée : $amount';
  }

  @override
  String get pdfRecommendationsTitle => 'Recommandations';

  @override
  String get pdfRecOpen3a =>
      'Ouvrir un pilier 3a pour bénéficier d\'avantages fiscaux et améliorer votre prévoyance.';

  @override
  String pdfRecMax3a(String amount) {
    return 'Maximisez votre cotisation 3a annuelle ($amount) pour optimiser vos économies fiscales.';
  }

  @override
  String get pdfRecIncreaseCoverage =>
      'Votre taux de remplacement est inférieur à 60%. Envisagez un rachat LPP ou une augmentation de votre épargne 3a.';

  @override
  String get pdfRecGoodTrack =>
      'Vous êtes sur la bonne voie ! Continuez à épargner régulièrement.';

  @override
  String get generalSimulationDisclaimer =>
      'Simulation indicative basée sur des barèmes simplifiés. PocketPillar fournit de l\'information, pas du conseil en placement (LSFin).';

  @override
  String get pdfDisclaimer =>
      'Ce document est fourni à titre indicatif uniquement et ne constitue pas un conseil financier. Les projections sont basées sur des estimations et peuvent varier. Consultez un conseiller financier pour des recommandations personnalisées. PocketPillar © 2026.';

  @override
  String get checklistCompleted => 'complétés';

  @override
  String get checklistAllDone => 'Tout est fait !';

  @override
  String get checklistCardTitle => 'Checklist fin d\'année';

  @override
  String checklistCardRemaining(int count) {
    return '$count actions restantes';
  }

  @override
  String get checklistMax3aTitle => 'Maximiser le pilier 3a';

  @override
  String get checklistMax3aDescription =>
      'Versez le montant maximum avant le 31 décembre pour optimiser vos impôts.';

  @override
  String checklistMax3aValue(String max) {
    return 'Maximum : $max';
  }

  @override
  String get checklistBvgBuybackTitle => 'Vérifier le rachat LPP';

  @override
  String get checklistBvgBuybackDescription =>
      'Contactez votre caisse de pension pour connaître votre potentiel de rachat.';

  @override
  String get checklistCertificateTitle =>
      'Demander le certificat de prévoyance';

  @override
  String get checklistCertificateDescription =>
      'Demandez votre certificat LPP annuel à votre employeur ou caisse de pension.';

  @override
  String get checklistTaxDocsTitle => 'Préparer les justificatifs fiscaux';

  @override
  String get checklistTaxDocsDescription =>
      'Rassemblez vos attestations 3a et certificats LPP pour votre déclaration d\'impôts.';

  @override
  String get checklistUpdateProfileTitle => 'Mettre à jour le profil';

  @override
  String get checklistUpdateProfileDescription =>
      'Vérifiez que votre salaire, âge et situation sont à jour dans PocketPillar.';

  @override
  String get checklistPlanNextTitle => 'Planifier l\'année suivante';

  @override
  String get checklistPlanNextDescription =>
      'Explorez les scénarios pour définir votre stratégie de prévoyance pour l\'année prochaine.';

  @override
  String get coupleScenarioTitle => 'Mode Couple';

  @override
  String get coupleScenarioSubtitle => 'Simulez votre retraite à deux';

  @override
  String get coupleSectionTitle => 'Couple';

  @override
  String get couplePartnerHas3a => 'Le partenaire a un 3e pilier';

  @override
  String get coupleCalculate => 'Calculer la retraite du couple';

  @override
  String get coupleYou => 'Vous';

  @override
  String get couplePartner => 'Partenaire';

  @override
  String get coupleAvs => 'AVS/mois';

  @override
  String get coupleBvg => 'LPP/mois';

  @override
  String get couplePillar3a => 'Capital 3a';

  @override
  String get coupleTotalMonthly => 'Total/mois';

  @override
  String get coupleCombinedTitle => 'Revenu combiné du couple';

  @override
  String get coupleCombinedMonthly => 'par mois (rente combinée)';

  @override
  String get coupleReplacementRate => 'Taux de remplacement combiné';

  @override
  String get coupleAvsCapWarning =>
      'Le plafond AVS couple (150% du maximum individuel) s\'applique. Votre rente AVS combinée est réduite.';

  @override
  String get coupleWithdrawalTitle => 'Plan de retrait optimal';

  @override
  String get coupleWithdraw3a => 'Retrait pilier 3a';

  @override
  String get coupleWithdrawBvg => 'Retrait capital LPP';

  @override
  String coupleTaxEstimate(String amount) {
    return 'Impôt estimé : $amount';
  }

  @override
  String get coupleFormIntro =>
      'Vos données sont pré-remplies depuis votre profil. Saisissez celles de votre partenaire pour lancer la simulation.';

  @override
  String get coupleReplacementIndividual => 'Taux de remplacement';

  @override
  String get coupleSituationTitle => 'Votre situation';

  @override
  String get coupleFiscalStatus => 'Situation fiscale simulée';

  @override
  String get coupleStatusMarried => 'Marié·e·s';

  @override
  String get coupleStatusPartnership => 'Partenariat enregistré';

  @override
  String get coupleStatusConcubinage => 'Concubinage';

  @override
  String get coupleTaxTitle => 'Fiscalité du couple';

  @override
  String get coupleTaxMarriedJoint => 'Imposition commune (mariage)';

  @override
  String get coupleTaxUnmarriedSeparate => 'Imposition séparée (concubinage)';

  @override
  String coupleTaxCheaperMarried(String amount) {
    return 'Le mariage vous fait économiser environ $amount d\'impôts par an.';
  }

  @override
  String coupleTaxCheaperConcubinage(String amount) {
    return 'Le concubinage vous fait économiser environ $amount d\'impôts par an.';
  }

  @override
  String get coupleTaxEqual =>
      'Mariage et concubinage sont équivalents fiscalement.';

  @override
  String get coupleTaxDisclaimer =>
      'Estimation indicative calculée sur les revenus bruts (barèmes simplifiés fédéral, cantonal et communal).';

  @override
  String get coupleWithdrawalTotalTax => 'Impôt total du plan';

  @override
  String get coupleWithdrawalSimultaneous => 'Impôt si retraits la même année';

  @override
  String get coupleWithdrawalSavings => 'Économie grâce à l\'échelonnement';

  @override
  String get coupleWithdrawalEmpty =>
      'Aucun capital 3a ou LPP projeté : le plan de retraits apparaîtra dès qu\'un capital est renseigné.';

  @override
  String get paywallTitle => 'PocketPillar Premium';

  @override
  String get paywallHeadline => 'Débloquez tout votre potentiel de prévoyance';

  @override
  String get paywallPriceFallback => 'CHF 39/an';

  @override
  String paywallPricePerYear(String price) {
    return '$price par an';
  }

  @override
  String get paywallFeaturesTitle => 'Inclus dans Premium';

  @override
  String get paywallFeatureCatchup =>
      'Rattrapage 3a : détail année par année et plan d\'action';

  @override
  String get paywallFeatureScenarios =>
      '4 scénarios avancés : couple, retrait échelonné, achat immobilier, divorce';

  @override
  String get paywallFeatureOcr =>
      'Scan de documents (OCR) pour préremplir votre profil';

  @override
  String get paywallFeatureRecommendations =>
      'Recommandations complètes et meilleur prestataire pour votre profil';

  @override
  String get paywallFeaturePdf => 'Export PDF de votre bilan';

  @override
  String get paywallFeatureDocuments => 'Documents illimités';

  @override
  String get paywallSubscribe => 'Débloquer Premium';

  @override
  String get paywallRestore => 'Restaurer mes achats';

  @override
  String get paywallLegal =>
      'Abonnement annuel renouvelé automatiquement. Gérez ou résiliez à tout moment dans les réglages de votre store (App Store / Google Play).';

  @override
  String get paywallUnavailableTitle => 'Achat indisponible';

  @override
  String get paywallUnavailableBody =>
      'L\'achat intégré n\'est pas disponible pour le moment. Réessayez plus tard — vos fonctionnalités gratuites restent accessibles.';

  @override
  String get paywallOfferingError =>
      'Impossible de charger l\'offre. Vérifiez votre connexion puis réessayez.';

  @override
  String get paywallPurchaseFailed =>
      'L\'achat n\'a pas abouti. Réessayez plus tard.';

  @override
  String get paywallPurchaseSuccess => 'Premium activé — merci !';

  @override
  String get paywallRestoreSuccess => 'Abonnement restauré !';

  @override
  String get paywallRestoreNothing =>
      'Aucun abonnement à restaurer pour ce compte.';

  @override
  String get paywallRestoreFailed =>
      'La restauration n\'a pas abouti. Réessayez plus tard.';

  @override
  String get paywallAlreadyActive => 'Votre abonnement Premium est actif.';

  @override
  String get settingsPremiumTitle => 'PocketPillar Premium';

  @override
  String get settingsPremiumActive => 'Abonné';

  @override
  String settingsPremiumActiveUntil(String date) {
    return 'Abonné — jusqu\'au $date';
  }

  @override
  String get settingsPremiumInactive => 'Non abonné — CHF 39/an';

  @override
  String get premiumBadgeLabel => 'Premium';

  @override
  String get premiumDiscoverCta => 'Découvrir Premium';

  @override
  String get premiumUpsellRecommendations =>
      'Les recommandations personnalisées et le comparatif complet font partie de PocketPillar Premium.';

  @override
  String get premiumUpsellBestMatch =>
      'La recherche du prestataire idéal fait partie de PocketPillar Premium.';

  @override
  String get catchupUpsellTitle => 'Débloquez le plan année par année';

  @override
  String get catchupUpsellBody =>
      'Avec Premium, visualisez chaque année rattrapable et votre plan d\'action détaillé.';
}
