import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'PocketPillar'**
  String get appTitle;

  /// No description provided for @commonContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinue;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @authCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get authCancel;

  /// No description provided for @authCheckEmail.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre boîte de réception pour confirmer votre adresse e-mail, puis connectez-vous'**
  String get authCheckEmail;

  /// No description provided for @authConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authConfirmPassword;

  /// No description provided for @authCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get authCreateAccount;

  /// No description provided for @authEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get authEmail;

  /// No description provided for @authEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide'**
  String get authEmailInvalid;

  /// No description provided for @authEmailTaken.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse e-mail est déjà liée à un autre compte'**
  String get authEmailTaken;

  /// No description provided for @authGoToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Aller à la connexion'**
  String get authGoToLogin;

  /// No description provided for @authLoginFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion'**
  String get authLoginFailed;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre prévoyance suisse, en toute sécurité'**
  String get authLoginSubtitle;

  /// No description provided for @authNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? Créer un compte'**
  String get authNoAccount;

  /// No description provided for @authDemoBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Démo publique'**
  String get authDemoBannerTitle;

  /// No description provided for @authDemoBannerBody.
  ///
  /// In fr, this message translates to:
  /// **'Compte de démonstration partagé et public — les mêmes données (fictives) pour tous les visiteurs, réinitialisées chaque nuit. N\'y saisis aucune donnée personnelle réelle.'**
  String get authDemoBannerBody;

  /// No description provided for @authDemoSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec le compte démo'**
  String get authDemoSignIn;

  /// No description provided for @authOr.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get authOr;

  /// No description provided for @authPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPassword;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 8 caractères'**
  String get authPasswordMinLength;

  /// No description provided for @authPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get authPasswordsMismatch;

  /// No description provided for @authRegisterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authRegisterTitle;

  /// No description provided for @authSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSignIn;

  /// No description provided for @authSignInWithApple.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec Apple'**
  String get authSignInWithApple;

  /// No description provided for @authSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get authSignOut;

  /// No description provided for @authSignUpFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la création du compte'**
  String get authSignUpFailed;

  /// No description provided for @biometricLockedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Authentifiez-vous pour accéder à vos données financières'**
  String get biometricLockedMessage;

  /// No description provided for @biometricReason.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouillez PocketPillar pour accéder à vos données'**
  String get biometricReason;

  /// No description provided for @biometricUnlock.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller'**
  String get biometricUnlock;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau'**
  String get errorNetwork;

  /// No description provided for @errorSessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré, veuillez vous reconnecter'**
  String get errorSessionExpired;

  /// No description provided for @errorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inconnue'**
  String get errorUnknown;

  /// No description provided for @notificationYearEndChecklist.
  ///
  /// In fr, this message translates to:
  /// **'N\'oubliez pas votre checklist de fin d\'année ! Maximisez vos avantages fiscaux avant le 31 décembre.'**
  String get notificationYearEndChecklist;

  /// No description provided for @notification3aReminder.
  ///
  /// In fr, this message translates to:
  /// **'Pensez à votre versement 3a ! Vous pouvez verser jusqu\'à CHF {amount} cette année.'**
  String notification3aReminder(String amount);

  /// No description provided for @notification3aReminderContextual.
  ///
  /// In fr, this message translates to:
  /// **'Il vous reste CHF {amount} à verser sur votre 3a avant le 31 décembre ({days} jours restants).'**
  String notification3aReminderContextual(String amount, int days);

  /// No description provided for @tabCalculator.
  ///
  /// In fr, this message translates to:
  /// **'Bilan'**
  String get tabCalculator;

  /// No description provided for @tabDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get tabDashboard;

  /// No description provided for @tabDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents'**
  String get tabDocuments;

  /// No description provided for @tabProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @tabProviders.
  ///
  /// In fr, this message translates to:
  /// **'Prestataires'**
  String get tabProviders;

  /// No description provided for @tabScenarios.
  ///
  /// In fr, this message translates to:
  /// **'Scénarios'**
  String get tabScenarios;

  /// No description provided for @onboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get onboardingTitle;

  /// No description provided for @checklistTitle.
  ///
  /// In fr, this message translates to:
  /// **'Checklist'**
  String get checklistTitle;

  /// No description provided for @coupleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Couple'**
  String get coupleTitle;

  /// No description provided for @financialProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil financier'**
  String get financialProfileTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsBiometricLock.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage biométrique'**
  String get settingsBiometricLock;

  /// No description provided for @settingsSectionProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get settingsSectionProfile;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsAnnualReminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels annuels'**
  String get settingsAnnualReminders;

  /// No description provided for @settingsAnnualRemindersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Checklist de fin d\'année (15 décembre) et versement 3a (1er novembre), à 10 h'**
  String get settingsAnnualRemindersSubtitle;

  /// No description provided for @settingsSectionLearn.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre'**
  String get settingsSectionLearn;

  /// No description provided for @settingsUnderstandTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre ma prévoyance'**
  String get settingsUnderstandTitle;

  /// No description provided for @settingsUnderstandSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les 3 piliers et nos calculs, expliqués simplement'**
  String get settingsUnderstandSubtitle;

  /// No description provided for @understandIntro.
  ///
  /// In fr, this message translates to:
  /// **'La prévoyance suisse repose sur 3 piliers : l\'AVS de l\'État, la caisse de pension de votre employeur et votre épargne personnelle 3a. Touchez un pilier pour comprendre son rôle.'**
  String get understandIntro;

  /// No description provided for @understandPillarsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les 3 piliers'**
  String get understandPillarsTitle;

  /// No description provided for @understandCalcTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment calculons-nous ?'**
  String get understandCalcTitle;

  /// No description provided for @understandCalcIntro.
  ///
  /// In fr, this message translates to:
  /// **'Chaque chiffre de l\'app vient d\'une des règles ci-dessous — paramètres légaux 2026 et barèmes officiels, jamais de moyennes inventées.'**
  String get understandCalcIntro;

  /// No description provided for @understandCalcAvsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rente AVS'**
  String get understandCalcAvsTitle;

  /// No description provided for @understandCalcAvsBody.
  ///
  /// In fr, this message translates to:
  /// **'Estimée à partir de votre revenu et de vos années de cotisation projetées jusqu\'à la retraite (échelle 44 simplifiée). Dès 2026, la 13e rente est incluse (13 mensualités par an). Votre rente réelle dépendra de votre parcours exact — demandez un extrait de compte AVS pour le connaître.'**
  String get understandCalcAvsBody;

  /// No description provided for @understandCalcLppTitle.
  ///
  /// In fr, this message translates to:
  /// **'Capital et rente LPP'**
  String get understandCalcLppTitle;

  /// No description provided for @understandCalcLppBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre capital actuel grandit chaque année avec vos cotisations (parts employé + employeur) et l\'intérêt minimal légal de 1.25 %. À la retraite : rente = capital × taux de conversion. 6.8 % est le minimum légal sur la part obligatoire — saisissez le taux de votre certificat pour un résultat plus fidèle.'**
  String get understandCalcLppBody;

  /// No description provided for @understandCalc3aTitle.
  ///
  /// In fr, this message translates to:
  /// **'Épargne 3a'**
  String get understandCalc3aTitle;

  /// No description provided for @understandCalc3aBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre solde actuel est projeté avec vos versements annuels et le rendement choisi. À la retraite, le 3a se retire en capital (pas en rente) — il est donc affiché à part, avec l\'impôt de retrait estimé.'**
  String get understandCalc3aBody;

  /// No description provided for @understandCalcTaxTitle.
  ///
  /// In fr, this message translates to:
  /// **'Impôts'**
  String get understandCalcTaxTitle;

  /// No description provided for @understandCalcTaxBody.
  ///
  /// In fr, this message translates to:
  /// **'Économies 3a, comparaison mariage/concubinage, impôt au retrait des capitaux : tout est calculé avec les barèmes officiels 2026 de la Confédération, de votre canton et de votre commune — vérifiés contre le calculateur officiel de l\'AFC. Votre revenu brut sert de base (vos déductions personnelles ne sont pas connues) : les montants sont des estimations.'**
  String get understandCalcTaxBody;

  /// No description provided for @understandCalcLimitsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce que nous ne modélisons pas'**
  String get understandCalcLimitsTitle;

  /// No description provided for @understandCalcLimitsBody.
  ///
  /// In fr, this message translates to:
  /// **'Les parcours particuliers : divorce et splitting AVS, bonifications pour tâches éducatives, arrivée en Suisse en cours de carrière, invalidité, taux de caisse sur la part surobligatoire. PocketPillar est un outil d\'estimation et d\'information — pas un conseil. Pour une décision importante, parlez-en à un professionnel.'**
  String get understandCalcLimitsBody;

  /// No description provided for @understandMethodologyLink.
  ///
  /// In fr, this message translates to:
  /// **'Méthodologie complète et sources (publiées sur GitHub)'**
  String get understandMethodologyLink;

  /// No description provided for @settingsNotificationsDenied.
  ///
  /// In fr, this message translates to:
  /// **'Notifications refusées — activez-les dans les réglages système pour recevoir les rappels'**
  String get settingsNotificationsDenied;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement ?'**
  String get settingsDeleteConfirmTitle;

  /// No description provided for @settingsDeleteConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible : votre compte et toutes vos données (profil financier, comptes LPP et 3a, documents) seront supprimées.'**
  String get settingsDeleteConfirmBody;

  /// No description provided for @dashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'PocketPillar'**
  String get dashboardTitle;

  /// No description provided for @dashboardWelcomeHeader.
  ///
  /// In fr, this message translates to:
  /// **'Votre prévoyance, simplifiée'**
  String get dashboardWelcomeHeader;

  /// No description provided for @dashboardWelcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Comprenez et optimisez votre retraite en quelques minutes'**
  String get dashboardWelcomeSubtitle;

  /// No description provided for @dashboardCtaCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre retraite en 2 min'**
  String get dashboardCtaCheck;

  /// No description provided for @dashboardTipOfDay.
  ///
  /// In fr, this message translates to:
  /// **'Conseil du jour'**
  String get dashboardTipOfDay;

  /// No description provided for @dashboardSummary.
  ///
  /// In fr, this message translates to:
  /// **'Votre pension couvrira {percent}% de votre revenu'**
  String dashboardSummary(int percent);

  /// No description provided for @dashboardScoreLabel.
  ///
  /// In fr, this message translates to:
  /// **'Santé prévoyance'**
  String get dashboardScoreLabel;

  /// No description provided for @dashboardRecOpen3a.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez un pilier 3a pour économiser sur vos impôts et préparer votre retraite'**
  String get dashboardRecOpen3a;

  /// No description provided for @dashboardRecLowCoverage.
  ///
  /// In fr, this message translates to:
  /// **'Votre taux de couverture est bas. Augmentez vos cotisations pour améliorer votre retraite.'**
  String get dashboardRecLowCoverage;

  /// No description provided for @dashboardRecGoodTrack.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes sur la bonne voie ! Continuez à optimiser votre prévoyance.'**
  String get dashboardRecGoodTrack;

  /// No description provided for @dashboardActionGuided.
  ///
  /// In fr, this message translates to:
  /// **'Bilan guidé'**
  String get dashboardActionGuided;

  /// No description provided for @dashboardActionExpert.
  ///
  /// In fr, this message translates to:
  /// **'Mode expert'**
  String get dashboardActionExpert;

  /// No description provided for @dashboardActionLearn.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre'**
  String get dashboardActionLearn;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardStatusOnline.
  ///
  /// In fr, this message translates to:
  /// **'API connectée'**
  String get dashboardStatusOnline;

  /// No description provided for @dashboardStatusOffline.
  ///
  /// In fr, this message translates to:
  /// **'API hors ligne'**
  String get dashboardStatusOffline;

  /// No description provided for @dashboardUptime.
  ///
  /// In fr, this message translates to:
  /// **'En ligne depuis {hours} h'**
  String dashboardUptime(int hours);

  /// No description provided for @dashboardApiVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version API'**
  String get dashboardApiVersion;

  /// No description provided for @dashboardSince.
  ///
  /// In fr, this message translates to:
  /// **'depuis'**
  String get dashboardSince;

  /// No description provided for @dashboardGoalProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression vers l\'objectif'**
  String get dashboardGoalProgress;

  /// No description provided for @dashboardGoalReached.
  ///
  /// In fr, this message translates to:
  /// **'Objectif atteint !'**
  String get dashboardGoalReached;

  /// No description provided for @dashboardRecommendedProvider.
  ///
  /// In fr, this message translates to:
  /// **'Prestataire recommandé pour vous'**
  String get dashboardRecommendedProvider;

  /// No description provided for @dashboardGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get dashboardGreeting;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre profil'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez votre situation financière pour obtenir votre projection de retraite et des recommandations personnalisées.'**
  String get dashboardEmptyBody;

  /// No description provided for @dashboardEmptyCta.
  ///
  /// In fr, this message translates to:
  /// **'Compléter mon profil'**
  String get dashboardEmptyCta;

  /// No description provided for @dashboardSynthesisTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre projection retraite'**
  String get dashboardSynthesisTitle;

  /// No description provided for @dashboardRecommendationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations'**
  String get dashboardRecommendationsTitle;

  /// No description provided for @dashboardRecommendationsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre profil pour recevoir des recommandations personnalisées.'**
  String get dashboardRecommendationsEmpty;

  /// No description provided for @dashboardEstimatedAnnualImpact.
  ///
  /// In fr, this message translates to:
  /// **'Impact estimé : {amount}/an'**
  String dashboardEstimatedAnnualImpact(String amount);

  /// No description provided for @dashboardScoreBenchmarkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison avec les {min}–{max} ans'**
  String dashboardScoreBenchmarkTitle(int min, int max);

  /// No description provided for @dashboardScoreBenchmark3a.
  ///
  /// In fr, this message translates to:
  /// **'Pilier 3a : {user} (moyenne : {average})'**
  String dashboardScoreBenchmark3a(String user, String average);

  /// No description provided for @dashboardScoreBenchmarkRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de remplacement : {user} (moyenne : {average})'**
  String dashboardScoreBenchmarkRate(String user, String average);

  /// No description provided for @dashboardScoreBenchmarkBvg.
  ///
  /// In fr, this message translates to:
  /// **'Capital LPP : {user} (moyenne : {average})'**
  String dashboardScoreBenchmarkBvg(String user, String average);

  /// No description provided for @calculatorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calculateur'**
  String get calculatorTitle;

  /// No description provided for @calculatorLppGap.
  ///
  /// In fr, this message translates to:
  /// **'Écart LPP'**
  String get calculatorLppGap;

  /// No description provided for @calculatorTaxSavings.
  ///
  /// In fr, this message translates to:
  /// **'Économies 3a'**
  String get calculatorTaxSavings;

  /// No description provided for @calculatorRetirement.
  ///
  /// In fr, this message translates to:
  /// **'Retraite'**
  String get calculatorRetirement;

  /// No description provided for @calculatorCalculate.
  ///
  /// In fr, this message translates to:
  /// **'Calculer'**
  String get calculatorCalculate;

  /// No description provided for @calculatorGrossIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu brut (CHF)'**
  String get calculatorGrossIncome;

  /// No description provided for @calculatorAge.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get calculatorAge;

  /// No description provided for @calculatorCanton.
  ///
  /// In fr, this message translates to:
  /// **'Canton'**
  String get calculatorCanton;

  /// No description provided for @calculatorBvgCapital.
  ///
  /// In fr, this message translates to:
  /// **'Capital LPP (CHF)'**
  String get calculatorBvgCapital;

  /// No description provided for @calculatorAnnualContribution.
  ///
  /// In fr, this message translates to:
  /// **'Cotisation annuelle (CHF)'**
  String get calculatorAnnualContribution;

  /// No description provided for @calculatorTaxableIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu imposable (CHF)'**
  String get calculatorTaxableIncome;

  /// No description provided for @calculatorContribution3a.
  ///
  /// In fr, this message translates to:
  /// **'Versement 3a (CHF)'**
  String get calculatorContribution3a;

  /// No description provided for @calculatorPillar3aBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde 3a (CHF)'**
  String get calculatorPillar3aBalance;

  /// No description provided for @calculatorCoordinatedSalary.
  ///
  /// In fr, this message translates to:
  /// **'Salaire coordonné'**
  String get calculatorCoordinatedSalary;

  /// No description provided for @calculatorBvgMinContribution.
  ///
  /// In fr, this message translates to:
  /// **'Cotisation LPP min.'**
  String get calculatorBvgMinContribution;

  /// No description provided for @calculatorProjectedCapital.
  ///
  /// In fr, this message translates to:
  /// **'Capital projeté'**
  String get calculatorProjectedCapital;

  /// No description provided for @calculatorProjectedPension.
  ///
  /// In fr, this message translates to:
  /// **'Rente projetée/an'**
  String get calculatorProjectedPension;

  /// No description provided for @calculatorPensionGap.
  ///
  /// In fr, this message translates to:
  /// **'Écart de rente'**
  String get calculatorPensionGap;

  /// No description provided for @calculatorFederalSaving.
  ///
  /// In fr, this message translates to:
  /// **'Économie fédérale'**
  String get calculatorFederalSaving;

  /// No description provided for @calculatorCantonalSaving.
  ///
  /// In fr, this message translates to:
  /// **'Économie cantonale'**
  String get calculatorCantonalSaving;

  /// No description provided for @calculatorCommunalSaving.
  ///
  /// In fr, this message translates to:
  /// **'Économie communale'**
  String get calculatorCommunalSaving;

  /// No description provided for @calculatorTotalSaving.
  ///
  /// In fr, this message translates to:
  /// **'Économie totale'**
  String get calculatorTotalSaving;

  /// No description provided for @calculatorEffectiveReturn.
  ///
  /// In fr, this message translates to:
  /// **'Rendement effectif'**
  String get calculatorEffectiveReturn;

  /// No description provided for @calculatorYearsToRetirement.
  ///
  /// In fr, this message translates to:
  /// **'Années jusqu\'à la retraite'**
  String get calculatorYearsToRetirement;

  /// No description provided for @calculatorProjectedPillar2.
  ///
  /// In fr, this message translates to:
  /// **'Capital 2e pilier projeté'**
  String get calculatorProjectedPillar2;

  /// No description provided for @calculatorProjectedPillar3a.
  ///
  /// In fr, this message translates to:
  /// **'Capital 3a projeté'**
  String get calculatorProjectedPillar3a;

  /// No description provided for @calculatorWithdrawalTax3a.
  ///
  /// In fr, this message translates to:
  /// **'Impôt au retrait du 3a (estimé)'**
  String get calculatorWithdrawalTax3a;

  /// No description provided for @calculatorNet3aAfterTax.
  ///
  /// In fr, this message translates to:
  /// **'Capital 3a net après impôt'**
  String get calculatorNet3aAfterTax;

  /// No description provided for @calculatorAnnualRetirementIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu annuel retraite'**
  String get calculatorAnnualRetirementIncome;

  /// No description provided for @calculatorReplacementRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de remplacement'**
  String get calculatorReplacementRate;

  /// No description provided for @providersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prestataires 3a'**
  String get providersTitle;

  /// No description provided for @providersRanking.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get providersRanking;

  /// No description provided for @providersAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous les prestataires'**
  String get providersAll;

  /// No description provided for @providersProducts.
  ///
  /// In fr, this message translates to:
  /// **'produits'**
  String get providersProducts;

  /// No description provided for @providersFilter.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get providersFilter;

  /// No description provided for @providersCompare.
  ///
  /// In fr, this message translates to:
  /// **'Comparer'**
  String get providersCompare;

  /// No description provided for @providersFees.
  ///
  /// In fr, this message translates to:
  /// **'Frais (%)'**
  String get providersFees;

  /// No description provided for @providersFeeComparison.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison des frais'**
  String get providersFeeComparison;

  /// No description provided for @providersCompareSelected.
  ///
  /// In fr, this message translates to:
  /// **'Comparer {count} produits'**
  String providersCompareSelected(int count);

  /// No description provided for @providersTapToCompare.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour comparer'**
  String get providersTapToCompare;

  /// No description provided for @providersFeeShort.
  ///
  /// In fr, this message translates to:
  /// **'Frais'**
  String get providersFeeShort;

  /// No description provided for @providersEquityShort.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get providersEquityShort;

  /// No description provided for @providersReturnShort.
  ///
  /// In fr, this message translates to:
  /// **'Rend. 3a'**
  String get providersReturnShort;

  /// No description provided for @providersEsgBadge.
  ///
  /// In fr, this message translates to:
  /// **'Durable'**
  String get providersEsgBadge;

  /// No description provided for @providersVisitWebsite.
  ///
  /// In fr, this message translates to:
  /// **'Visiter le site web'**
  String get providersVisitWebsite;

  /// No description provided for @providersWebsiteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le lien'**
  String get providersWebsiteError;

  /// No description provided for @providersEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun prestataire disponible pour le moment'**
  String get providersEmpty;

  /// No description provided for @providersDigital.
  ///
  /// In fr, this message translates to:
  /// **'Digital'**
  String get providersDigital;

  /// No description provided for @providersCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get providersCategory;

  /// No description provided for @providersRiskLevel.
  ///
  /// In fr, this message translates to:
  /// **'Risque'**
  String get providersRiskLevel;

  /// No description provided for @providersFeesDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail des frais'**
  String get providersFeesDetail;

  /// No description provided for @providersTer.
  ///
  /// In fr, this message translates to:
  /// **'TER (frais de fonds)'**
  String get providersTer;

  /// No description provided for @providersAllInFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais tout compris'**
  String get providersAllInFee;

  /// No description provided for @providersCustodyFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de garde'**
  String get providersCustodyFee;

  /// No description provided for @providersEntryFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais d\'entrée'**
  String get providersEntryFee;

  /// No description provided for @providersExitFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de sortie'**
  String get providersExitFee;

  /// No description provided for @providersPerformance.
  ///
  /// In fr, this message translates to:
  /// **'Rendement par année'**
  String get providersPerformance;

  /// No description provided for @providersPerformanceWindow.
  ///
  /// In fr, this message translates to:
  /// **'5 dernières années'**
  String get providersPerformanceWindow;

  /// No description provided for @providersCategoryPassiveIndex.
  ///
  /// In fr, this message translates to:
  /// **'Fonds indiciel (passif)'**
  String get providersCategoryPassiveIndex;

  /// No description provided for @providersCategoryActiveManaged.
  ///
  /// In fr, this message translates to:
  /// **'Gestion active'**
  String get providersCategoryActiveManaged;

  /// No description provided for @providersCategoryInsurance.
  ///
  /// In fr, this message translates to:
  /// **'Assurance vie 3a'**
  String get providersCategoryInsurance;

  /// No description provided for @providersCategorySavings.
  ///
  /// In fr, this message translates to:
  /// **'Compte épargne'**
  String get providersCategorySavings;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get profileLanguage;

  /// No description provided for @profileAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get profileAbout;

  /// No description provided for @profileVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get profileVersion;

  /// No description provided for @profileApi.
  ///
  /// In fr, this message translates to:
  /// **'Serveur API'**
  String get profileApi;

  /// No description provided for @profileSectionPersonal.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get profileSectionPersonal;

  /// No description provided for @profileSalary.
  ///
  /// In fr, this message translates to:
  /// **'Salaire (CHF)'**
  String get profileSalary;

  /// No description provided for @profileAge.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get profileAge;

  /// No description provided for @profileCanton.
  ///
  /// In fr, this message translates to:
  /// **'Canton'**
  String get profileCanton;

  /// No description provided for @profileMunicipality.
  ///
  /// In fr, this message translates to:
  /// **'Commune'**
  String get profileMunicipality;

  /// No description provided for @profileHas3a.
  ///
  /// In fr, this message translates to:
  /// **'Pilier 3a'**
  String get profileHas3a;

  /// No description provided for @profile3aBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde 3a (CHF)'**
  String get profile3aBalance;

  /// No description provided for @profileMaritalStatus.
  ///
  /// In fr, this message translates to:
  /// **'Situation familiale'**
  String get profileMaritalStatus;

  /// No description provided for @profileGoalSection.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get profileGoalSection;

  /// No description provided for @profileTargetRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de remplacement cible'**
  String get profileTargetRate;

  /// No description provided for @profileAppearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get profileAppearance;

  /// No description provided for @profileAppearanceSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get profileAppearanceSystem;

  /// No description provided for @profileAppearanceLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get profileAppearanceLight;

  /// No description provided for @profileAppearanceDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get profileAppearanceDark;

  /// No description provided for @profileSectionAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get profileSectionSecurity;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Canton, revenus, situation et comptes'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileSelectCanton.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get profileSelectCanton;

  /// No description provided for @profileBirthYear.
  ///
  /// In fr, this message translates to:
  /// **'Année de naissance'**
  String get profileBirthYear;

  /// No description provided for @profileBirthYearInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Année de naissance invalide'**
  String get profileBirthYearInvalid;

  /// No description provided for @profileSectionSituation.
  ///
  /// In fr, this message translates to:
  /// **'Situation financière'**
  String get profileSectionSituation;

  /// No description provided for @profileEmploymentStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut professionnel'**
  String get profileEmploymentStatus;

  /// No description provided for @profileEmploymentEmployed.
  ///
  /// In fr, this message translates to:
  /// **'Salarié(e)'**
  String get profileEmploymentEmployed;

  /// No description provided for @profileEmploymentSelfEmployed.
  ///
  /// In fr, this message translates to:
  /// **'Indépendant(e)'**
  String get profileEmploymentSelfEmployed;

  /// No description provided for @profileEmploymentUnemployed.
  ///
  /// In fr, this message translates to:
  /// **'Sans emploi'**
  String get profileEmploymentUnemployed;

  /// No description provided for @profileEmploymentRetired.
  ///
  /// In fr, this message translates to:
  /// **'Retraité(e)'**
  String get profileEmploymentRetired;

  /// No description provided for @profileMaritalDivorced.
  ///
  /// In fr, this message translates to:
  /// **'Divorcé(e)'**
  String get profileMaritalDivorced;

  /// No description provided for @profileMaritalWidowed.
  ///
  /// In fr, this message translates to:
  /// **'Veuf(ve)'**
  String get profileMaritalWidowed;

  /// No description provided for @profileChildren.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'enfants'**
  String get profileChildren;

  /// No description provided for @profileChildrenInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'enfants invalide'**
  String get profileChildrenInvalid;

  /// No description provided for @profileGrossAnnualIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu brut annuel (CHF)'**
  String get profileGrossAnnualIncome;

  /// No description provided for @profileNetAnnualIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu net annuel (CHF, optionnel)'**
  String get profileNetAnnualIncome;

  /// No description provided for @profileFieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get profileFieldRequired;

  /// No description provided for @profileAmountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get profileAmountInvalid;

  /// No description provided for @profileRateInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Taux invalide'**
  String get profileRateInvalid;

  /// No description provided for @profileSaved.
  ///
  /// In fr, this message translates to:
  /// **'Profil enregistré'**
  String get profileSaved;

  /// No description provided for @profileSectionPillar2.
  ///
  /// In fr, this message translates to:
  /// **'Comptes LPP (2e pilier)'**
  String get profileSectionPillar2;

  /// No description provided for @profileSectionPillar3a.
  ///
  /// In fr, this message translates to:
  /// **'Comptes 3a'**
  String get profileSectionPillar3a;

  /// No description provided for @profileEmptyPillar2.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte LPP renseigné'**
  String get profileEmptyPillar2;

  /// No description provided for @profileEmptyPillar3a.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte 3a renseigné'**
  String get profileEmptyPillar3a;

  /// No description provided for @profilePillar2DefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Compte LPP'**
  String get profilePillar2DefaultName;

  /// No description provided for @profileAddPillar2.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un compte LPP'**
  String get profileAddPillar2;

  /// No description provided for @profileAddPillar3a.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un compte 3a'**
  String get profileAddPillar3a;

  /// No description provided for @profilePillar2New.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau compte LPP'**
  String get profilePillar2New;

  /// No description provided for @profilePillar2Edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le compte LPP'**
  String get profilePillar2Edit;

  /// No description provided for @profilePillar3aNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau compte 3a'**
  String get profilePillar3aNew;

  /// No description provided for @profilePillar3aEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le compte 3a'**
  String get profilePillar3aEdit;

  /// No description provided for @profileProviderName.
  ///
  /// In fr, this message translates to:
  /// **'Prestataire'**
  String get profileProviderName;

  /// No description provided for @profileCurrentCapital.
  ///
  /// In fr, this message translates to:
  /// **'Capital actuel (CHF)'**
  String get profileCurrentCapital;

  /// No description provided for @profileConversionRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de conversion (%)'**
  String get profileConversionRate;

  /// No description provided for @profileAnnualContribution.
  ///
  /// In fr, this message translates to:
  /// **'Cotisation annuelle (CHF)'**
  String get profileAnnualContribution;

  /// No description provided for @profileAdvancedSection.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get profileAdvancedSection;

  /// No description provided for @profileInsuredSalary.
  ///
  /// In fr, this message translates to:
  /// **'Salaire assuré (CHF)'**
  String get profileInsuredSalary;

  /// No description provided for @profileCoordinationDeduction.
  ///
  /// In fr, this message translates to:
  /// **'Déduction de coordination (CHF)'**
  String get profileCoordinationDeduction;

  /// No description provided for @profileAnnualSupraContribution.
  ///
  /// In fr, this message translates to:
  /// **'Cotisation surobligatoire annuelle (CHF)'**
  String get profileAnnualSupraContribution;

  /// No description provided for @profileCurrentBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel (CHF)'**
  String get profileCurrentBalance;

  /// No description provided for @profileInterestRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'intérêt / rendement (%)'**
  String get profileInterestRate;

  /// No description provided for @profileAccountType.
  ///
  /// In fr, this message translates to:
  /// **'Type de compte'**
  String get profileAccountType;

  /// No description provided for @profileAccountTypeBank.
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get profileAccountTypeBank;

  /// No description provided for @profileAccountTypeInsurance.
  ///
  /// In fr, this message translates to:
  /// **'Assurance'**
  String get profileAccountTypeInsurance;

  /// No description provided for @profileVestedBenefits.
  ///
  /// In fr, this message translates to:
  /// **'Compte de libre passage'**
  String get profileVestedBenefits;

  /// No description provided for @profileDeleteAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce compte ?'**
  String get profileDeleteAccountTitle;

  /// No description provided for @profileDeleteAccountBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive.'**
  String get profileDeleteAccountBody;

  /// No description provided for @profileAccountSaved.
  ///
  /// In fr, this message translates to:
  /// **'Compte enregistré'**
  String get profileAccountSaved;

  /// No description provided for @profileAccountDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get profileAccountDeleted;

  /// No description provided for @ocrScanSalaryButton.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un certificat de salaire'**
  String get ocrScanSalaryButton;

  /// No description provided for @ocrScanLppButton.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un relevé LPP'**
  String get ocrScanLppButton;

  /// No description provided for @ocrScanSalaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Certificat de salaire'**
  String get ocrScanSalaryTitle;

  /// No description provided for @ocrScanLppTitle.
  ///
  /// In fr, this message translates to:
  /// **'Relevé LPP'**
  String get ocrScanLppTitle;

  /// No description provided for @ocrSourceCamera.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get ocrSourceCamera;

  /// No description provided for @ocrSourceGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une image'**
  String get ocrSourceGallery;

  /// No description provided for @ocrScanning.
  ///
  /// In fr, this message translates to:
  /// **'Analyse du document…'**
  String get ocrScanning;

  /// No description provided for @ocrNoTextFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun texte détecté sur l\'image. Réessayez avec une photo plus nette.'**
  String get ocrNoTextFound;

  /// No description provided for @ocrNoValuesFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune valeur reconnue sur ce document. Vous pouvez réessayer avec une autre photo.'**
  String get ocrNoValuesFound;

  /// No description provided for @ocrProposalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs détectées'**
  String get ocrProposalTitle;

  /// No description provided for @ocrProposalBody.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez et ajustez les valeurs avant de les appliquer.'**
  String get ocrProposalBody;

  /// No description provided for @ocrPrivacyNote.
  ///
  /// In fr, this message translates to:
  /// **'Analyse locale : l\'image ne quitte jamais votre appareil.'**
  String get ocrPrivacyNote;

  /// No description provided for @ocrApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get ocrApply;

  /// No description provided for @ocrScanError.
  ///
  /// In fr, this message translates to:
  /// **'L\'analyse a échoué. Réessayez avec une photo plus nette.'**
  String get ocrScanError;

  /// No description provided for @ocrApplied.
  ///
  /// In fr, this message translates to:
  /// **'Champs préremplis — vérifiez puis enregistrez'**
  String get ocrApplied;

  /// No description provided for @onboardingPillarsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre retraite repose sur 3 piliers'**
  String get onboardingPillarsTitle;

  /// No description provided for @onboardingPillarsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Le système suisse de prévoyance est unique au monde. Découvrez comment il fonctionne.'**
  String get onboardingPillarsDesc;

  /// No description provided for @onboardingDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche ?'**
  String get onboardingDetailsTitle;

  /// No description provided for @onboardingDetailsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Chaque pilier a un rôle différent dans votre retraite'**
  String get onboardingDetailsDesc;

  /// No description provided for @onboardingP1Title.
  ///
  /// In fr, this message translates to:
  /// **'1er pilier (AVS)'**
  String get onboardingP1Title;

  /// No description provided for @onboardingP1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Rente de base obligatoire, financée par vos cotisations salariales'**
  String get onboardingP1Desc;

  /// No description provided for @onboardingP2Title.
  ///
  /// In fr, this message translates to:
  /// **'2e pilier (LPP)'**
  String get onboardingP2Title;

  /// No description provided for @onboardingP2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Prévoyance professionnelle via votre employeur, capital accumulé'**
  String get onboardingP2Desc;

  /// No description provided for @onboardingP3aTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pilier 3a'**
  String get onboardingP3aTitle;

  /// No description provided for @onboardingP3aDesc.
  ///
  /// In fr, this message translates to:
  /// **'Épargne volontaire avec avantages fiscaux, c\'est vous qui décidez'**
  String get onboardingP3aDesc;

  /// No description provided for @onboardingFeaturesTitle.
  ///
  /// In fr, this message translates to:
  /// **'PocketPillar vous aide à...'**
  String get onboardingFeaturesTitle;

  /// No description provided for @onboardingFeaturesDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tout ce dont vous avez besoin pour votre prévoyance'**
  String get onboardingFeaturesDesc;

  /// No description provided for @onboardingFeatureScore.
  ///
  /// In fr, this message translates to:
  /// **'Évaluer votre santé prévoyance'**
  String get onboardingFeatureScore;

  /// No description provided for @onboardingFeatureSimulate.
  ///
  /// In fr, this message translates to:
  /// **'Simuler votre retraite en détail'**
  String get onboardingFeatureSimulate;

  /// No description provided for @onboardingFeatureCompare.
  ///
  /// In fr, this message translates to:
  /// **'Comparer les prestataires 3a'**
  String get onboardingFeatureCompare;

  /// No description provided for @onboardingFeatureTips.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir des conseils personnalisés'**
  String get onboardingFeatureTips;

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti !'**
  String get onboardingReadyTitle;

  /// No description provided for @onboardingReadyDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ça prend 2 minutes. Découvrez où en est votre prévoyance.'**
  String get onboardingReadyDesc;

  /// No description provided for @onboardingNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// No description provided for @onboardingReplay.
  ///
  /// In fr, this message translates to:
  /// **'Revoir l\'introduction'**
  String get onboardingReplay;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur PocketPillar'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Optimisez votre prévoyance suisse. Simulez, comparez et maximisez vos 2e et 3e piliers.'**
  String get onboardingWelcomeDesc;

  /// No description provided for @onboardingCalculatorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calculateurs intelligents'**
  String get onboardingCalculatorTitle;

  /// No description provided for @onboardingCalculatorDesc.
  ///
  /// In fr, this message translates to:
  /// **'Analysez votre écart LPP, calculez vos économies fiscales 3a par canton, et projetez votre retraite.'**
  String get onboardingCalculatorDesc;

  /// No description provided for @onboardingProvidersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comparez les prestataires'**
  String get onboardingProvidersTitle;

  /// No description provided for @onboardingProvidersDesc.
  ///
  /// In fr, this message translates to:
  /// **'VIAC, Frankly, finpension et plus encore. Trouvez le pilier 3a avec les meilleurs frais et rendements.'**
  String get onboardingProvidersDesc;

  /// No description provided for @pillar1Short.
  ///
  /// In fr, this message translates to:
  /// **'1er pilier'**
  String get pillar1Short;

  /// No description provided for @pillar1Name.
  ///
  /// In fr, this message translates to:
  /// **'AVS / AI'**
  String get pillar1Name;

  /// No description provided for @pillar2Short.
  ///
  /// In fr, this message translates to:
  /// **'2e pilier'**
  String get pillar2Short;

  /// No description provided for @pillar2Name.
  ///
  /// In fr, this message translates to:
  /// **'LPP / Caisse de pension'**
  String get pillar2Name;

  /// No description provided for @pillar3aShort.
  ///
  /// In fr, this message translates to:
  /// **'Pilier 3a'**
  String get pillar3aShort;

  /// No description provided for @pillar3aName.
  ///
  /// In fr, this message translates to:
  /// **'Prévoyance privée'**
  String get pillar3aName;

  /// No description provided for @guidedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre bilan'**
  String get guidedTitle;

  /// No description provided for @guidedResultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos résultats'**
  String get guidedResultsTitle;

  /// No description provided for @guidedSalaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel est votre salaire annuel ?'**
  String get guidedSalaryTitle;

  /// No description provided for @guidedSalarySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Salaire brut avant déductions'**
  String get guidedSalarySubtitle;

  /// No description provided for @guidedAgeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel âge avez-vous ?'**
  String get guidedAgeTitle;

  /// No description provided for @guidedAgeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre âge influence vos cotisations et projections'**
  String get guidedAgeSubtitle;

  /// No description provided for @guidedAgeYears.
  ///
  /// In fr, this message translates to:
  /// **'ans'**
  String get guidedAgeYears;

  /// No description provided for @guidedCantonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où habitez-vous ?'**
  String get guidedCantonTitle;

  /// No description provided for @guidedCantonSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les taux d\'imposition varient selon le canton'**
  String get guidedCantonSubtitle;

  /// No description provided for @guided3aTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avez-vous un pilier 3a ?'**
  String get guided3aTitle;

  /// No description provided for @guided3aSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le pilier 3a est votre épargne personnelle avec avantages fiscaux'**
  String get guided3aSubtitle;

  /// No description provided for @guided3aQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Épargnez-vous dans un 3a ?'**
  String get guided3aQuestion;

  /// No description provided for @guided3aBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde approximatif'**
  String get guided3aBalance;

  /// No description provided for @guidedYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get guidedYes;

  /// No description provided for @guidedNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get guidedNo;

  /// No description provided for @guidedNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get guidedNext;

  /// No description provided for @guidedBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get guidedBack;

  /// No description provided for @guidedSeeResults.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes résultats'**
  String get guidedSeeResults;

  /// No description provided for @guidedMaritalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelle est votre situation familiale ?'**
  String get guidedMaritalTitle;

  /// No description provided for @guidedMaritalSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre situation influence le calcul de vos impôts'**
  String get guidedMaritalSubtitle;

  /// No description provided for @guidedMaritalSingle.
  ///
  /// In fr, this message translates to:
  /// **'Célibataire'**
  String get guidedMaritalSingle;

  /// No description provided for @guidedMaritalMarried.
  ///
  /// In fr, this message translates to:
  /// **'Marié(e)'**
  String get guidedMaritalMarried;

  /// No description provided for @guidedMaritalPartnership.
  ///
  /// In fr, this message translates to:
  /// **'Partenariat enregistré'**
  String get guidedMaritalPartnership;

  /// No description provided for @guidedSituationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre situation'**
  String get guidedSituationTitle;

  /// No description provided for @guidedSituationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Âge, canton et situation familiale'**
  String get guidedSituationSubtitle;

  /// No description provided for @guidedPillar2Title.
  ///
  /// In fr, this message translates to:
  /// **'Votre 2e pilier (LPP)'**
  String get guidedPillar2Title;

  /// No description provided for @guidedPillar2Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Capital et cotisations de votre caisse de pension — voir votre certificat de prévoyance'**
  String get guidedPillar2Subtitle;

  /// No description provided for @guidedStepOf.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}'**
  String guidedStepOf(int current, int total);

  /// No description provided for @resultsSummaryPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Votre pension couvrira {percent}% de votre revenu actuel'**
  String resultsSummaryPhrase(int percent);

  /// No description provided for @resultsPensionMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Soit environ {amount} par mois'**
  String resultsPensionMonthly(String amount);

  /// No description provided for @resultsYourPillars.
  ///
  /// In fr, this message translates to:
  /// **'Vos 3 piliers'**
  String get resultsYourPillars;

  /// No description provided for @resultsReplacementRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de remplacement'**
  String get resultsReplacementRate;

  /// No description provided for @resultsYearsToRetirement.
  ///
  /// In fr, this message translates to:
  /// **'Années jusqu\'à la retraite'**
  String get resultsYearsToRetirement;

  /// No description provided for @resultsHowCalculated.
  ///
  /// In fr, this message translates to:
  /// **'Comment ces chiffres sont-ils calculés ?'**
  String get resultsHowCalculated;

  /// No description provided for @resultsTaxSavings.
  ///
  /// In fr, this message translates to:
  /// **'Économies fiscales'**
  String get resultsTaxSavings;

  /// No description provided for @resultsAnnualSavings.
  ///
  /// In fr, this message translates to:
  /// **'d\'économies par an'**
  String get resultsAnnualSavings;

  /// No description provided for @resultsEffectiveReturn.
  ///
  /// In fr, this message translates to:
  /// **'Rendement effectif : {rate}%'**
  String resultsEffectiveReturn(String rate);

  /// No description provided for @resultsWhatToDo.
  ///
  /// In fr, this message translates to:
  /// **'Que faire maintenant ?'**
  String get resultsWhatToDo;

  /// No description provided for @resultsRecOpen3a.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez un pilier 3a pour économiser des impôts et préparer votre retraite'**
  String get resultsRecOpen3a;

  /// No description provided for @resultsRecMax3a.
  ///
  /// In fr, this message translates to:
  /// **'Versez le maximum de {amount} en 3a pour optimiser vos impôts'**
  String resultsRecMax3a(String amount);

  /// No description provided for @resultsRecTaxSaving.
  ///
  /// In fr, this message translates to:
  /// **'Vous économisez {amount} d\'impôts par an grâce au 3a'**
  String resultsRecTaxSaving(String amount);

  /// No description provided for @resultsRecIncreaseCoverage.
  ///
  /// In fr, this message translates to:
  /// **'Votre couverture est inférieure à 60%. Envisagez un rachat LPP ou augmentez vos cotisations 3a.'**
  String get resultsRecIncreaseCoverage;

  /// No description provided for @resultsRecBvgBuyback.
  ///
  /// In fr, this message translates to:
  /// **'Un rachat LPP pourrait combler votre écart de rente et réduire vos impôts'**
  String get resultsRecBvgBuyback;

  /// No description provided for @resultsAboveAverage.
  ///
  /// In fr, this message translates to:
  /// **'Au-dessus de la moyenne pour votre âge'**
  String get resultsAboveAverage;

  /// No description provided for @resultsBelowAverage.
  ///
  /// In fr, this message translates to:
  /// **'En dessous de la moyenne pour votre âge'**
  String get resultsBelowAverage;

  /// No description provided for @resultsNearAverage.
  ///
  /// In fr, this message translates to:
  /// **'Dans la moyenne pour votre âge'**
  String get resultsNearAverage;

  /// No description provided for @resultsCompareToggle.
  ///
  /// In fr, this message translates to:
  /// **'Comparer avec/sans 3a'**
  String get resultsCompareToggle;

  /// No description provided for @resultsCompareWith3a.
  ///
  /// In fr, this message translates to:
  /// **'Avec 3a (par mois)'**
  String get resultsCompareWith3a;

  /// No description provided for @resultsCompareWithout3a.
  ///
  /// In fr, this message translates to:
  /// **'Sans 3a (par mois)'**
  String get resultsCompareWithout3a;

  /// No description provided for @resultsDeltaLabel.
  ///
  /// In fr, this message translates to:
  /// **'Différence'**
  String get resultsDeltaLabel;

  /// No description provided for @resultsApproximateBadge.
  ///
  /// In fr, this message translates to:
  /// **'Estimation approximative (hors ligne)'**
  String get resultsApproximateBadge;

  /// No description provided for @cantonPickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un canton'**
  String get cantonPickerTitle;

  /// No description provided for @cantonPickerSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un canton'**
  String get cantonPickerSearch;

  /// No description provided for @municipalityPickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une commune'**
  String get municipalityPickerTitle;

  /// No description provided for @municipalityPickerSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une commune'**
  String get municipalityPickerSearch;

  /// No description provided for @municipalityCantonalAverageOption.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne cantonale (commune non listée)'**
  String get municipalityCantonalAverageOption;

  /// No description provided for @municipalityPickerEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commune couverte pour ce canton — la moyenne cantonale est utilisée.'**
  String get municipalityPickerEmpty;

  /// No description provided for @municipalityPickerNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get municipalityPickerNoResults;

  /// No description provided for @municipalityPickerError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les communes'**
  String get municipalityPickerError;

  /// No description provided for @municipalitySelectCantonFirst.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez d\'abord un canton'**
  String get municipalitySelectCantonFirst;

  /// No description provided for @helpSectionWhat.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi ?'**
  String get helpSectionWhat;

  /// No description provided for @helpSectionWhy.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi c\'est important ?'**
  String get helpSectionWhy;

  /// No description provided for @helpSectionWhere.
  ///
  /// In fr, this message translates to:
  /// **'Où trouver cette info ?'**
  String get helpSectionWhere;

  /// No description provided for @helpPillarSystemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Système des 3 piliers'**
  String get helpPillarSystemTitle;

  /// No description provided for @helpPillarSystemExplanation.
  ///
  /// In fr, this message translates to:
  /// **'La Suisse organise la retraite en 3 niveaux : une rente de base (AVS), une prévoyance professionnelle (LPP), et une épargne privée (3a). Ensemble, ils visent à maintenir votre niveau de vie.'**
  String get helpPillarSystemExplanation;

  /// No description provided for @helpPillarSystemWhy.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre ce système vous aide à identifier ce que vous pouvez optimiser pour votre retraite.'**
  String get helpPillarSystemWhy;

  /// No description provided for @helpPillarSystemWhere.
  ///
  /// In fr, this message translates to:
  /// **'Votre certificat de salaire et votre certificat de prévoyance annuel détaillent vos cotisations.'**
  String get helpPillarSystemWhere;

  /// No description provided for @helpPillar1AvsTitle.
  ///
  /// In fr, this message translates to:
  /// **'AVS (1er pilier)'**
  String get helpPillar1AvsTitle;

  /// No description provided for @helpPillar1AvsExplanation.
  ///
  /// In fr, this message translates to:
  /// **'L\'AVS est la rente de base que tout le monde reçoit à la retraite. Elle est financée par vos cotisations salariales (prélevées automatiquement) et celles de votre employeur.'**
  String get helpPillar1AvsExplanation;

  /// No description provided for @helpPillar1AvsWhy.
  ///
  /// In fr, this message translates to:
  /// **'L\'AVS seule ne couvre qu\'environ 40% de votre dernier salaire. C\'est pourquoi les 2e et 3e piliers sont essentiels.'**
  String get helpPillar1AvsWhy;

  /// No description provided for @helpPillar1AvsWhere.
  ///
  /// In fr, this message translates to:
  /// **'Demandez un extrait de compte AVS sur le site de votre caisse cantonale de compensation.'**
  String get helpPillar1AvsWhere;

  /// No description provided for @helpPillar2BvgTitle.
  ///
  /// In fr, this message translates to:
  /// **'LPP / 2e pilier'**
  String get helpPillar2BvgTitle;

  /// No description provided for @helpPillar2BvgExplanation.
  ///
  /// In fr, this message translates to:
  /// **'La prévoyance professionnelle est une épargne obligatoire gérée par votre employeur. Vous et votre employeur cotisez chaque mois. Ce capital s\'accumule et vous sera versé à la retraite.'**
  String get helpPillar2BvgExplanation;

  /// No description provided for @helpPillar2BvgWhy.
  ///
  /// In fr, this message translates to:
  /// **'C\'est souvent le plus gros montant de votre retraite. Vérifiez votre certificat de prévoyance annuel pour connaître votre capital.'**
  String get helpPillar2BvgWhy;

  /// No description provided for @helpPillar2BvgWhere.
  ///
  /// In fr, this message translates to:
  /// **'Votre certificat de prévoyance annuel, envoyé par la caisse de pension de votre employeur.'**
  String get helpPillar2BvgWhere;

  /// No description provided for @helpPillar3aTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pilier 3a'**
  String get helpPillar3aTitle;

  /// No description provided for @helpPillar3aExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Le pilier 3a est une épargne volontaire que vous gérez vous-même. Vous choisissez votre prestataire, le montant et le type de placement. L\'argent est bloqué jusqu\'à la retraite (sauf exceptions).'**
  String get helpPillar3aExplanation;

  /// No description provided for @helpPillar3aWhy.
  ///
  /// In fr, this message translates to:
  /// **'Chaque franc versé en 3a est déductible de vos impôts. C\'est le moyen le plus simple de payer moins d\'impôts tout en préparant sa retraite.'**
  String get helpPillar3aWhy;

  /// No description provided for @helpPillar3aWhere.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous au site de votre prestataire 3a (banque ou app) pour voir votre solde.'**
  String get helpPillar3aWhere;

  /// No description provided for @helpCoordinatedSalaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Salaire coordonné'**
  String get helpCoordinatedSalaryTitle;

  /// No description provided for @helpCoordinatedSalaryExplanation.
  ///
  /// In fr, this message translates to:
  /// **'C\'est la partie de votre salaire sur laquelle sont calculées vos cotisations LPP. On soustrait un montant fixe (déduction de coordination) de votre salaire brut.'**
  String get helpCoordinatedSalaryExplanation;

  /// No description provided for @helpCoordinatedSalaryWhy.
  ///
  /// In fr, this message translates to:
  /// **'Plus il est élevé, plus vos cotisations et votre future rente seront importantes.'**
  String get helpCoordinatedSalaryWhy;

  /// No description provided for @helpCoordinatedSalaryWhere.
  ///
  /// In fr, this message translates to:
  /// **'Indiqué sur votre certificat de prévoyance LPP annuel.'**
  String get helpCoordinatedSalaryWhere;

  /// No description provided for @helpConversionRateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Taux de conversion'**
  String get helpConversionRateTitle;

  /// No description provided for @helpConversionRateExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Ce pourcentage transforme votre capital LPP en rente annuelle. Par exemple, avec un taux de 6.8% et CHF 500\'000 de capital, vous recevez CHF 34\'000 par an.'**
  String get helpConversionRateExplanation;

  /// No description provided for @helpConversionRateWhy.
  ///
  /// In fr, this message translates to:
  /// **'Un taux plus élevé = une meilleure rente. Le taux minimum légal est de 6.8%, mais les caisses peuvent appliquer un taux plus bas sur la part surobligatoire.'**
  String get helpConversionRateWhy;

  /// No description provided for @helpConversionRateWhere.
  ///
  /// In fr, this message translates to:
  /// **'Indiqué sur votre certificat de prévoyance annuel ou le règlement de votre caisse de pension.'**
  String get helpConversionRateWhere;

  /// No description provided for @helpBvgCapitalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Capital LPP'**
  String get helpBvgCapitalTitle;

  /// No description provided for @helpBvgCapitalExplanation.
  ///
  /// In fr, this message translates to:
  /// **'C\'est l\'argent accumulé dans votre caisse de pension (2e pilier). Vos cotisations et celles de votre employeur s\'additionnent chaque mois, avec des intérêts.'**
  String get helpBvgCapitalExplanation;

  /// No description provided for @helpBvgCapitalWhy.
  ///
  /// In fr, this message translates to:
  /// **'C\'est généralement le plus gros actif que vous possédez. Il détermine directement le montant de votre rente à la retraite.'**
  String get helpBvgCapitalWhy;

  /// No description provided for @helpBvgCapitalWhere.
  ///
  /// In fr, this message translates to:
  /// **'Votre certificat de prévoyance annuel, rubrique \'avoir de vieillesse\'.'**
  String get helpBvgCapitalWhere;

  /// No description provided for @helpReplacementRateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Taux de remplacement'**
  String get helpReplacementRateTitle;

  /// No description provided for @helpReplacementRateExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Le pourcentage de votre dernier salaire que vous toucherez à la retraite. Par exemple, 65% signifie que si vous gagnez CHF 100\'000, votre rente sera d\'environ CHF 65\'000 par an.'**
  String get helpReplacementRateExplanation;

  /// No description provided for @helpReplacementRateWhy.
  ///
  /// In fr, this message translates to:
  /// **'L\'objectif est généralement 60-80%. En dessous de 60%, votre niveau de vie risque de baisser significativement à la retraite.'**
  String get helpReplacementRateWhy;

  /// No description provided for @helpReplacementRateWhere.
  ///
  /// In fr, this message translates to:
  /// **'PocketPillar le calcule pour vous à partir de vos données. Vous pouvez aussi le demander à votre caisse de pension.'**
  String get helpReplacementRateWhere;

  /// No description provided for @helpPensionGapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Écart de rente'**
  String get helpPensionGapTitle;

  /// No description provided for @helpPensionGapExplanation.
  ///
  /// In fr, this message translates to:
  /// **'La différence entre la rente que vous devriez recevoir selon la loi et ce que vous recevrez réellement. Si votre employeur cotise au minimum légal, l\'écart peut être nul.'**
  String get helpPensionGapExplanation;

  /// No description provided for @helpPensionGapWhy.
  ///
  /// In fr, this message translates to:
  /// **'Un écart positif signifie que vous êtes en dessous du minimum légal et pourrait indiquer un problème avec vos cotisations.'**
  String get helpPensionGapWhy;

  /// No description provided for @helpPensionGapWhere.
  ///
  /// In fr, this message translates to:
  /// **'Comparez votre certificat de prévoyance avec les minimums LPP, ou utilisez le calculateur PocketPillar.'**
  String get helpPensionGapWhere;

  /// No description provided for @helpTaxSavings3aTitle.
  ///
  /// In fr, this message translates to:
  /// **'Économies fiscales 3a'**
  String get helpTaxSavings3aTitle;

  /// No description provided for @helpTaxSavings3aExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Chaque franc versé dans votre 3a réduit votre revenu imposable. Selon votre canton et votre revenu, vous pouvez économiser entre CHF 1\'500 et CHF 3\'000 d\'impôts par an.'**
  String get helpTaxSavings3aExplanation;

  /// No description provided for @helpTaxSavings3aWhy.
  ///
  /// In fr, this message translates to:
  /// **'C\'est de l\'argent que vous gardez au lieu de le donner au fisc. Plus vous gagnez, plus l\'économie est importante.'**
  String get helpTaxSavings3aWhy;

  /// No description provided for @helpTaxSavings3aWhere.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez le calculateur fiscal de PocketPillar en sélectionnant votre canton.'**
  String get helpTaxSavings3aWhere;

  /// No description provided for @helpBvgBuybackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rachat LPP'**
  String get helpBvgBuybackTitle;

  /// No description provided for @helpBvgBuybackExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Un versement volontaire dans votre 2e pilier pour combler des lacunes de cotisation. Par exemple, si vous n\'avez pas travaillé en Suisse pendant quelques années.'**
  String get helpBvgBuybackExplanation;

  /// No description provided for @helpBvgBuybackWhy.
  ///
  /// In fr, this message translates to:
  /// **'Le montant est 100% déductible des impôts l\'année du versement. C\'est une stratégie fiscale très efficace.'**
  String get helpBvgBuybackWhy;

  /// No description provided for @helpBvgBuybackWhere.
  ///
  /// In fr, this message translates to:
  /// **'Votre certificat de prévoyance indique le montant maximum de rachat possible. Contactez votre caisse de pension.'**
  String get helpBvgBuybackWhere;

  /// No description provided for @helpRetirementAgeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Âge de la retraite'**
  String get helpRetirementAgeTitle;

  /// No description provided for @helpRetirementAgeExplanation.
  ///
  /// In fr, this message translates to:
  /// **'En Suisse, l\'âge de référence est de 65 ans (transition AVS 21 pour les femmes nées 1961-1963 : 64 ans et 6 mois en 2026). Vous pouvez prendre une retraite anticipée dès 58 ans ou la reporter jusqu\'à 70 ans.'**
  String get helpRetirementAgeExplanation;

  /// No description provided for @helpRetirementAgeWhy.
  ///
  /// In fr, this message translates to:
  /// **'Chaque année d\'anticipation réduit votre rente. Chaque année de report l\'augmente. C\'est un choix financier important.'**
  String get helpRetirementAgeWhy;

  /// No description provided for @helpRetirementAgeWhere.
  ///
  /// In fr, this message translates to:
  /// **'Site de l\'OFAS (Office fédéral des assurances sociales) ou votre caisse de compensation cantonale.'**
  String get helpRetirementAgeWhere;

  /// No description provided for @helpContribution3aMaxTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plafond 3a'**
  String get helpContribution3aMaxTitle;

  /// No description provided for @helpContribution3aMaxExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Le montant maximum que vous pouvez verser en 3a est fixé par la loi. En 2026, c\'est CHF 7\'258 si vous avez un 2e pilier, ou CHF 36\'288 sans 2e pilier (max 20% du revenu net).'**
  String get helpContribution3aMaxExplanation;

  /// No description provided for @helpContribution3aMaxWhy.
  ///
  /// In fr, this message translates to:
  /// **'Verser le maximum est presque toujours avantageux : vous maximisez votre économie d\'impôts.'**
  String get helpContribution3aMaxWhy;

  /// No description provided for @helpContribution3aMaxWhere.
  ///
  /// In fr, this message translates to:
  /// **'Le montant est publié chaque année par l\'OFAS. PocketPillar est toujours à jour.'**
  String get helpContribution3aMaxWhere;

  /// No description provided for @helpGrossIncomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Revenu brut'**
  String get helpGrossIncomeTitle;

  /// No description provided for @helpGrossIncomeExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Votre salaire annuel avant toute déduction (impôts, AVS, LPP, etc.). C\'est le montant indiqué sur votre contrat de travail.'**
  String get helpGrossIncomeExplanation;

  /// No description provided for @helpGrossIncomeWhy.
  ///
  /// In fr, this message translates to:
  /// **'C\'est la base de calcul pour vos cotisations et vos projections de retraite.'**
  String get helpGrossIncomeWhy;

  /// No description provided for @helpGrossIncomeWhere.
  ///
  /// In fr, this message translates to:
  /// **'Votre contrat de travail, votre fiche de salaire mensuelle, ou votre certificat de salaire annuel.'**
  String get helpGrossIncomeWhere;

  /// No description provided for @helpEffectiveReturnTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rendement effectif'**
  String get helpEffectiveReturnTitle;

  /// No description provided for @helpEffectiveReturnExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Le pourcentage de rendement réel de votre versement 3a, en tenant compte de l\'économie d\'impôts. C\'est comme un bonus immédiat sur votre investissement.'**
  String get helpEffectiveReturnExplanation;

  /// No description provided for @helpEffectiveReturnWhy.
  ///
  /// In fr, this message translates to:
  /// **'Un rendement effectif de 30% signifie que pour CHF 7\'258 versés, vous récupérez environ CHF 2\'177 en impôts économisés.'**
  String get helpEffectiveReturnWhy;

  /// No description provided for @helpEffectiveReturnWhere.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez le calculateur fiscal de PocketPillar pour voir votre rendement effectif selon votre canton.'**
  String get helpEffectiveReturnWhere;

  /// No description provided for @helpAnnualContributionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cotisation annuelle LPP'**
  String get helpAnnualContributionTitle;

  /// No description provided for @helpAnnualContributionExplanation.
  ///
  /// In fr, this message translates to:
  /// **'C\'est le montant épargné chaque année dans votre caisse de pension : votre part ET celle de votre employeur (il paie au moins autant que vous). Ce n\'est donc pas seulement la retenue visible sur votre fiche de salaire.'**
  String get helpAnnualContributionExplanation;

  /// No description provided for @helpAnnualContributionWhy.
  ///
  /// In fr, this message translates to:
  /// **'La projection ajoute cette épargne chaque année jusqu\'à la retraite, avec l\'intérêt minimal légal de 1.25 %. Si vous n\'indiquez que votre moitié, votre capital projeté sera fortement sous-estimé.'**
  String get helpAnnualContributionWhy;

  /// No description provided for @helpAnnualContributionWhere.
  ///
  /// In fr, this message translates to:
  /// **'Votre certificat de prévoyance annuel, rubrique « cotisations d\'épargne » — additionnez les parts employé et employeur (les primes de risque n\'en font pas partie).'**
  String get helpAnnualContributionWhere;

  /// No description provided for @helpWithdrawalTaxTitle.
  ///
  /// In fr, this message translates to:
  /// **'Impôt au retrait du capital'**
  String get helpWithdrawalTaxTitle;

  /// No description provided for @helpWithdrawalTaxExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Un capital de prévoyance retiré (3a ou caisse de pension) est imposé une seule fois, séparément de vos autres revenus et à taux réduit.'**
  String get helpWithdrawalTaxExplanation;

  /// No description provided for @helpWithdrawalTaxWhy.
  ///
  /// In fr, this message translates to:
  /// **'Cet impôt réduit le montant réellement disponible — nous affichons donc le capital brut et le net estimé. Étaler les retraits sur plusieurs années fiscales le réduit souvent (voir « Retrait échelonné »).'**
  String get helpWithdrawalTaxWhy;

  /// No description provided for @helpWithdrawalTaxWhere.
  ///
  /// In fr, this message translates to:
  /// **'Estimé avec les barèmes officiels 2026 de votre canton et de votre commune. Le montant exact dépend de votre situation l\'année du retrait.'**
  String get helpWithdrawalTaxWhere;

  /// No description provided for @helpPensionScoreTitle.
  ///
  /// In fr, this message translates to:
  /// **'Score de prévoyance'**
  String get helpPensionScoreTitle;

  /// No description provided for @helpPensionScoreExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Une note sur 100 qui résume votre préparation à la retraite : taux de remplacement (40 pts), épargne 3a (30 pts) et temps restant pour agir (30 pts).'**
  String get helpPensionScoreExplanation;

  /// No description provided for @helpPensionScoreWhy.
  ///
  /// In fr, this message translates to:
  /// **'Il montre d\'un coup d\'œil où vous en êtes et ce qui pèse le plus. La comparaison affiche la moyenne de votre tranche d\'âge — un repère, pas un objectif.'**
  String get helpPensionScoreWhy;

  /// No description provided for @helpPensionScoreWhere.
  ///
  /// In fr, this message translates to:
  /// **'Calculé par PocketPillar à partir de votre profil ; il se met à jour dès que vous modifiez vos données.'**
  String get helpPensionScoreWhere;

  /// No description provided for @tipMax3a2026Title.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 3a 2026'**
  String get tipMax3a2026Title;

  /// No description provided for @tipMax3a2026Body.
  ///
  /// In fr, this message translates to:
  /// **'Le montant maximum 3a pour 2026 est de CHF 7\'258. Versez-le avant le 31 décembre pour économiser sur vos impôts !'**
  String get tipMax3a2026Body;

  /// No description provided for @tipBvgBuybackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rachat LPP = double économie'**
  String get tipBvgBuybackTitle;

  /// No description provided for @tipBvgBuybackBody.
  ///
  /// In fr, this message translates to:
  /// **'Un rachat LPP est 100% déductible de vos impôts ET augmente votre rente. Demandez votre potentiel de rachat à votre caisse.'**
  String get tipBvgBuybackBody;

  /// No description provided for @tip3aTaxDeductionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le 3a réduit vos impôts'**
  String get tip3aTaxDeductionTitle;

  /// No description provided for @tip3aTaxDeductionBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque franc versé en 3a est déductible de votre revenu imposable. Selon votre canton, ça peut représenter plus de 30% de rendement immédiat !'**
  String get tip3aTaxDeductionBody;

  /// No description provided for @tipStartEarlyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commencez tôt'**
  String get tipStartEarlyTitle;

  /// No description provided for @tipStartEarlyBody.
  ///
  /// In fr, this message translates to:
  /// **'Commencer à épargner en 3a à 25 ans plutôt qu\'à 35 ans peut vous faire gagner plus de CHF 100\'000 grâce aux intérêts composés.'**
  String get tipStartEarlyBody;

  /// No description provided for @tipCompoundInterestTitle.
  ///
  /// In fr, this message translates to:
  /// **'La magie des intérêts composés'**
  String get tipCompoundInterestTitle;

  /// No description provided for @tipCompoundInterestBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos intérêts génèrent eux-mêmes des intérêts. Sur 30 ans, un placement 3a à 3% de rendement double quasiment votre capital investi.'**
  String get tipCompoundInterestBody;

  /// No description provided for @tipMultiple3aTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs comptes 3a'**
  String get tipMultiple3aTitle;

  /// No description provided for @tipMultiple3aBody.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir plusieurs comptes 3a (jusqu\'à 5) permet d\'étaler les retraits et de réduire l\'impôt sur le capital à la sortie.'**
  String get tipMultiple3aBody;

  /// No description provided for @tipRetirementGapTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'écart de retraite'**
  String get tipRetirementGapTitle;

  /// No description provided for @tipRetirementGapBody.
  ///
  /// In fr, this message translates to:
  /// **'En moyenne, les 1er et 2e piliers ne couvrent que 60% de votre dernier salaire. Le 3a est essentiel pour combler cet écart.'**
  String get tipRetirementGapBody;

  /// No description provided for @tip3PillarsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi 3 piliers ?'**
  String get tip3PillarsTitle;

  /// No description provided for @tip3PillarsBody.
  ///
  /// In fr, this message translates to:
  /// **'Le système suisse répartit le risque : l\'État (AVS), l\'employeur (LPP) et vous-même (3a). Chacun joue un rôle dans votre sécurité financière.'**
  String get tip3PillarsBody;

  /// No description provided for @tipAvsMaxTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rente AVS maximum'**
  String get tipAvsMaxTitle;

  /// No description provided for @tipAvsMaxBody.
  ///
  /// In fr, this message translates to:
  /// **'La rente AVS maximale est de CHF 2\'520/mois pour une personne seule (2026). Même les hauts revenus sont plafonnés à ce montant.'**
  String get tipAvsMaxBody;

  /// No description provided for @tipPillar2InterestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'intérêt LPP'**
  String get tipPillar2InterestTitle;

  /// No description provided for @tipPillar2InterestBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre capital LPP obligatoire est rémunéré au minimum 1.25% par an. Certaines caisses offrent plus sur la part surobligatoire.'**
  String get tipPillar2InterestBody;

  /// No description provided for @tip3aWithdrawalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retrait anticipé du 3a'**
  String get tip3aWithdrawalTitle;

  /// No description provided for @tip3aWithdrawalBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez retirer votre 3a avant la retraite pour acheter un logement, vous installer à votre compte, ou quitter la Suisse.'**
  String get tip3aWithdrawalBody;

  /// No description provided for @tipCantonTaxesTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'impact du canton'**
  String get tipCantonTaxesTitle;

  /// No description provided for @tipCantonTaxesBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'économie fiscale 3a varie énormément selon le canton. À Genève, elle peut être 2x plus élevée qu\'à Zoug sur le même revenu.'**
  String get tipCantonTaxesBody;

  /// No description provided for @bestmatchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouver mon 3a idéal'**
  String get bestmatchTitle;

  /// No description provided for @bestmatchSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Répondez à quelques questions pour trouver le meilleur pilier 3a'**
  String get bestmatchSubtitle;

  /// No description provided for @bestmatchRiskQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Comment souhaitez-vous placer votre argent ?'**
  String get bestmatchRiskQuestion;

  /// No description provided for @bestmatchRiskExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Plus le rendement potentiel est élevé, plus la valeur peut varier à court terme'**
  String get bestmatchRiskExplanation;

  /// No description provided for @bestmatchRiskConservativeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité avant tout'**
  String get bestmatchRiskConservativeTitle;

  /// No description provided for @bestmatchRiskConservativeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Mon argent varie peu, même si ça rapporte moins'**
  String get bestmatchRiskConservativeDesc;

  /// No description provided for @bestmatchRiskModerateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prudent'**
  String get bestmatchRiskModerateTitle;

  /// No description provided for @bestmatchRiskModerateDesc.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte de petites variations pour un meilleur rendement'**
  String get bestmatchRiskModerateDesc;

  /// No description provided for @bestmatchRiskBalancedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Équilibré'**
  String get bestmatchRiskBalancedTitle;

  /// No description provided for @bestmatchRiskBalancedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Un mix entre sécurité et rendement, le plus populaire'**
  String get bestmatchRiskBalancedDesc;

  /// No description provided for @bestmatchRiskGrowthTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dynamique'**
  String get bestmatchRiskGrowthTitle;

  /// No description provided for @bestmatchRiskGrowthDesc.
  ///
  /// In fr, this message translates to:
  /// **'Je vise le rendement maximum, les baisses temporaires ne me font pas peur'**
  String get bestmatchRiskGrowthDesc;

  /// No description provided for @bestmatchRiskAggressiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'100% actions'**
  String get bestmatchRiskAggressiveTitle;

  /// No description provided for @bestmatchRiskAggressiveDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tout en actions pour le long terme, idéal si la retraite est loin'**
  String get bestmatchRiskAggressiveDesc;

  /// No description provided for @bestmatchRiskConservative.
  ///
  /// In fr, this message translates to:
  /// **'Conservateur (0-25% actions)'**
  String get bestmatchRiskConservative;

  /// No description provided for @bestmatchRiskModerate.
  ///
  /// In fr, this message translates to:
  /// **'Modéré (25-50% actions)'**
  String get bestmatchRiskModerate;

  /// No description provided for @bestmatchRiskBalanced.
  ///
  /// In fr, this message translates to:
  /// **'Équilibré (50-75% actions)'**
  String get bestmatchRiskBalanced;

  /// No description provided for @bestmatchRiskGrowth.
  ///
  /// In fr, this message translates to:
  /// **'Croissance (75-100% actions)'**
  String get bestmatchRiskGrowth;

  /// No description provided for @bestmatchRiskAggressive.
  ///
  /// In fr, this message translates to:
  /// **'Agressif (100% actions)'**
  String get bestmatchRiskAggressive;

  /// No description provided for @bestmatchPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Vos préférences'**
  String get bestmatchPreferences;

  /// No description provided for @bestmatchMaxFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais annuels maximum'**
  String get bestmatchMaxFee;

  /// No description provided for @bestmatchFeeHint.
  ///
  /// In fr, this message translates to:
  /// **'Des frais bas = plus d\'argent pour vous. La moyenne suisse est d\'environ 0.8%.'**
  String get bestmatchFeeHint;

  /// No description provided for @bestmatchEsg.
  ///
  /// In fr, this message translates to:
  /// **'Investissement durable'**
  String get bestmatchEsg;

  /// No description provided for @bestmatchEsgHint.
  ///
  /// In fr, this message translates to:
  /// **'Exclut les entreprises polluantes, armes, tabac'**
  String get bestmatchEsgHint;

  /// No description provided for @bestmatchFind.
  ///
  /// In fr, this message translates to:
  /// **'Trouver les meilleurs'**
  String get bestmatchFind;

  /// No description provided for @bestmatchResultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos meilleurs choix'**
  String get bestmatchResultsTitle;

  /// No description provided for @bestmatchNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get bestmatchNoResults;

  /// No description provided for @bestmatchTryDifferent.
  ///
  /// In fr, this message translates to:
  /// **'Essayez avec des critères différents'**
  String get bestmatchTryDifferent;

  /// No description provided for @bestmatchRestart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get bestmatchRestart;

  /// No description provided for @bestmatchScoreExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Le score combine les frais, le rendement sur 3 ans, l\'adéquation à votre profil de risque et la durabilité (ESG).'**
  String get bestmatchScoreExplanation;

  /// No description provided for @privacyLocalData.
  ///
  /// In fr, this message translates to:
  /// **'Vos données financières sont stockées sur des serveurs sécurisés en Europe (Irlande). Elles servent uniquement à fournir le service. Le verrouillage biométrique et vos identifiants restent sur votre appareil.'**
  String get privacyLocalData;

  /// No description provided for @privacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyTitle;

  /// No description provided for @privacySectionDataCollected.
  ///
  /// In fr, this message translates to:
  /// **'Données collectées'**
  String get privacySectionDataCollected;

  /// No description provided for @privacyBodyDataCollected.
  ///
  /// In fr, this message translates to:
  /// **'PocketPillar collecte votre adresse e-mail, vos informations financières (salaire, avoirs de prévoyance, situation fiscale) et les documents que vous uploadez. Ces données sont nécessaires au fonctionnement de l\'application.'**
  String get privacyBodyDataCollected;

  /// No description provided for @privacySectionPurpose.
  ///
  /// In fr, this message translates to:
  /// **'Finalité du traitement'**
  String get privacySectionPurpose;

  /// No description provided for @privacyBodyPurpose.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont utilisées exclusivement pour calculer votre situation de prévoyance, générer des recommandations personnalisées et stocker vos documents de prévoyance de manière sécurisée.'**
  String get privacyBodyPurpose;

  /// No description provided for @privacySectionStorage.
  ///
  /// In fr, this message translates to:
  /// **'Stockage et sécurité'**
  String get privacySectionStorage;

  /// No description provided for @privacyBodyStorage.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil et vos données financières sont stockés sur des serveurs sécurisés dans l\'UE (Irlande). Vos identifiants et jetons de session restent dans le stockage sécurisé de l\'appareil (Keychain iOS / Keystore Android). Les documents sont chiffrés en transit et au repos. L\'accès biométrique (Face ID / Touch ID) protège l\'ouverture de l\'app.'**
  String get privacyBodyStorage;

  /// No description provided for @privacySectionSharing.
  ///
  /// In fr, this message translates to:
  /// **'Partage des données'**
  String get privacySectionSharing;

  /// No description provided for @privacyBodySharing.
  ///
  /// In fr, this message translates to:
  /// **'PocketPillar ne vend et ne loue jamais vos données personnelles. Elles ne sont transmises qu\'aux sous-traitants techniques indispensables au service (hébergement Supabase, UE) et jamais à des fins publicitaires.'**
  String get privacyBodySharing;

  /// No description provided for @privacySectionRights.
  ///
  /// In fr, this message translates to:
  /// **'Vos droits (nDSG)'**
  String get privacySectionRights;

  /// No description provided for @privacyBodyRights.
  ///
  /// In fr, this message translates to:
  /// **'Conformément à la nouvelle loi suisse sur la protection des données (nDSG), vous avez le droit d\'accéder à vos données, de les rectifier, de les exporter et de demander leur suppression complète à tout moment.'**
  String get privacyBodyRights;

  /// No description provided for @privacySectionSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Mesures de sécurité'**
  String get privacySectionSecurity;

  /// No description provided for @privacyBodySecurity.
  ///
  /// In fr, this message translates to:
  /// **'Authentification sécurisée avec jetons (JWT), verrouillage biométrique, stockage chiffré des identifiants sur l\'appareil, blocage des captures d\'écran sur Android, URLs de téléchargement à durée limitée (5 min), validation des types de fichiers.'**
  String get privacyBodySecurity;

  /// No description provided for @privacySectionContact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get privacySectionContact;

  /// No description provided for @privacyBodyContact.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question concernant vos données personnelles : privacy@pocketpillar.ch'**
  String get privacyBodyContact;

  /// No description provided for @buybackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rachat LPP'**
  String get buybackTitle;

  /// No description provided for @buybackWhatTitle.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi ?'**
  String get buybackWhatTitle;

  /// No description provided for @buybackWhatBody.
  ///
  /// In fr, this message translates to:
  /// **'Un rachat LPP est un versement volontaire dans votre caisse de pension pour combler des lacunes de cotisation. Par exemple, si vous n\'avez pas toujours travaillé en Suisse ou si vous avez eu une augmentation de salaire.'**
  String get buybackWhatBody;

  /// No description provided for @buybackBenefitsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avantages'**
  String get buybackBenefitsTitle;

  /// No description provided for @buybackBenefitsBody.
  ///
  /// In fr, this message translates to:
  /// **'Le montant est 100% déductible de vos impôts l\'année du versement. Votre rente future augmente. C\'est l\'une des meilleures stratégies fiscales en Suisse.'**
  String get buybackBenefitsBody;

  /// No description provided for @buybackStepsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment faire ?'**
  String get buybackStepsTitle;

  /// No description provided for @buybackStepsBody.
  ///
  /// In fr, this message translates to:
  /// **'1. Consultez votre certificat de prévoyance pour le montant maximum de rachat\n2. Contactez votre caisse de pension\n3. Effectuez le versement avant le 31 décembre\n4. Déduisez le montant de votre déclaration fiscale'**
  String get buybackStepsBody;

  /// No description provided for @compareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison'**
  String get compareTitle;

  /// No description provided for @compareFees.
  ///
  /// In fr, this message translates to:
  /// **'Frais annuels'**
  String get compareFees;

  /// No description provided for @compareReturns.
  ///
  /// In fr, this message translates to:
  /// **'Rendement moyen 3 ans'**
  String get compareReturns;

  /// No description provided for @compareAllocation.
  ///
  /// In fr, this message translates to:
  /// **'Part en actions'**
  String get compareAllocation;

  /// No description provided for @compareScore.
  ///
  /// In fr, this message translates to:
  /// **'Score'**
  String get compareScore;

  /// No description provided for @compareFeesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Frais'**
  String get compareFeesLabel;

  /// No description provided for @compareReturn3y.
  ///
  /// In fr, this message translates to:
  /// **'Rend. 3a'**
  String get compareReturn3y;

  /// No description provided for @compareEsgLabel.
  ///
  /// In fr, this message translates to:
  /// **'Durable'**
  String get compareEsgLabel;

  /// No description provided for @compareEquity.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get compareEquity;

  /// No description provided for @compareLowest.
  ///
  /// In fr, this message translates to:
  /// **'Le moins cher'**
  String get compareLowest;

  /// No description provided for @compareBestChoice.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur choix global'**
  String get compareBestChoice;

  /// No description provided for @docTitle.
  ///
  /// In fr, this message translates to:
  /// **'Documents'**
  String get docTitle;

  /// No description provided for @docEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document'**
  String get docEmptyTitle;

  /// No description provided for @docEmptyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos documents de prévoyance pour les garder en sécurité'**
  String get docEmptyDescription;

  /// No description provided for @docDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get docDelete;

  /// No description provided for @docUploadTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un document'**
  String get docUploadTitle;

  /// No description provided for @docTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de document'**
  String get docTypeLabel;

  /// No description provided for @docIncludeYear.
  ///
  /// In fr, this message translates to:
  /// **'Associer une année'**
  String get docIncludeYear;

  /// No description provided for @docYearLabel.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get docYearLabel;

  /// No description provided for @docChooseFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get docChooseFile;

  /// No description provided for @docUploading.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours...'**
  String get docUploading;

  /// No description provided for @docTypeSalarySlip.
  ///
  /// In fr, this message translates to:
  /// **'Certificat de salaire'**
  String get docTypeSalarySlip;

  /// No description provided for @docTypeBvgStatement.
  ///
  /// In fr, this message translates to:
  /// **'Certificat LPP/BVG'**
  String get docTypeBvgStatement;

  /// No description provided for @docTypePillar3aStatement.
  ///
  /// In fr, this message translates to:
  /// **'Relevé pilier 3a'**
  String get docTypePillar3aStatement;

  /// No description provided for @docTypeTaxDeclaration.
  ///
  /// In fr, this message translates to:
  /// **'Déclaration d\'impôt'**
  String get docTypeTaxDeclaration;

  /// No description provided for @docTypeOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get docTypeOther;

  /// No description provided for @docUploadSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Document ajouté'**
  String get docUploadSuccess;

  /// No description provided for @docDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Document supprimé'**
  String get docDeleted;

  /// No description provided for @docDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce document ?'**
  String get docDeleteConfirmTitle;

  /// No description provided for @docDeleteConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive.'**
  String get docDeleteConfirmBody;

  /// No description provided for @docFileTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier dépasse la taille maximale de 10 Mo'**
  String get docFileTooLarge;

  /// No description provided for @docInvalidFile.
  ///
  /// In fr, this message translates to:
  /// **'Format non pris en charge (PDF, JPEG ou PNG)'**
  String get docInvalidFile;

  /// No description provided for @docReadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire le fichier'**
  String get docReadError;

  /// No description provided for @docOpenError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le document'**
  String get docOpenError;

  /// No description provided for @scenarioTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scénarios de vie'**
  String get scenarioTitle;

  /// No description provided for @scenarioSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Simulez l\'impact sur votre retraite'**
  String get scenarioSectionTitle;

  /// No description provided for @scenarioFooter.
  ///
  /// In fr, this message translates to:
  /// **'Ces simulations sont indicatives. Consultez un conseiller pour des décisions importantes.'**
  String get scenarioFooter;

  /// No description provided for @scenarioMonth.
  ///
  /// In fr, this message translates to:
  /// **'mois'**
  String get scenarioMonth;

  /// No description provided for @scenarioYear.
  ///
  /// In fr, this message translates to:
  /// **'an'**
  String get scenarioYear;

  /// No description provided for @scenarioPrefillFailed.
  ///
  /// In fr, this message translates to:
  /// **'Profil non chargé — le formulaire utilise les valeurs par défaut.'**
  String get scenarioPrefillFailed;

  /// No description provided for @scenario3aCatchupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapage 3a'**
  String get scenario3aCatchupTitle;

  /// No description provided for @scenario3aCatchupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapez vos années non-cotisées (réforme 2025)'**
  String get scenario3aCatchupSubtitle;

  /// No description provided for @scenario3aCatchupInputSection.
  ///
  /// In fr, this message translates to:
  /// **'Votre situation'**
  String get scenario3aCatchupInputSection;

  /// No description provided for @scenario3aCatchupYearsMissed.
  ///
  /// In fr, this message translates to:
  /// **'Années sans cotisation'**
  String get scenario3aCatchupYearsMissed;

  /// No description provided for @scenario3aCatchupResultSection.
  ///
  /// In fr, this message translates to:
  /// **'Potentiel de rattrapage'**
  String get scenario3aCatchupResultSection;

  /// No description provided for @scenario3aCatchupMaxPerYear.
  ///
  /// In fr, this message translates to:
  /// **'Maximum par année'**
  String get scenario3aCatchupMaxPerYear;

  /// No description provided for @scenario3aCatchupTotalCatchup.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapage total possible'**
  String get scenario3aCatchupTotalCatchup;

  /// No description provided for @scenario3aCatchupTaxSaving.
  ///
  /// In fr, this message translates to:
  /// **'Économie fiscale estimée'**
  String get scenario3aCatchupTaxSaving;

  /// No description provided for @scenario3aCatchupInfo.
  ///
  /// In fr, this message translates to:
  /// **'Depuis 2025, vous pouvez rattraper jusqu\'à 10 années de cotisations 3a manquées. Vous devez d\'abord maximiser l\'année en cours.'**
  String get scenario3aCatchupInfo;

  /// No description provided for @scenarioPropertyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Achat immobilier'**
  String get scenarioPropertyTitle;

  /// No description provided for @scenarioPropertySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Impact du retrait EPL sur votre rente'**
  String get scenarioPropertySubtitle;

  /// No description provided for @scenarioPropertyInputSection.
  ///
  /// In fr, this message translates to:
  /// **'Montants'**
  String get scenarioPropertyInputSection;

  /// No description provided for @scenarioPropertyBvgCapital.
  ///
  /// In fr, this message translates to:
  /// **'Capital LPP actuel'**
  String get scenarioPropertyBvgCapital;

  /// No description provided for @scenarioPropertyWithdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Montant du retrait'**
  String get scenarioPropertyWithdrawal;

  /// No description provided for @scenarioPropertyMaxWithdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Retrait max. autorisé'**
  String get scenarioPropertyMaxWithdrawal;

  /// No description provided for @scenarioPropertyEffectiveWithdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Retrait effectif'**
  String get scenarioPropertyEffectiveWithdrawal;

  /// No description provided for @scenarioPropertyImpactSection.
  ///
  /// In fr, this message translates to:
  /// **'Impact sur la retraite'**
  String get scenarioPropertyImpactSection;

  /// No description provided for @scenarioPropertyCapitalWithout.
  ///
  /// In fr, this message translates to:
  /// **'Capital à la retraite (sans retrait)'**
  String get scenarioPropertyCapitalWithout;

  /// No description provided for @scenarioPropertyCapitalWith.
  ///
  /// In fr, this message translates to:
  /// **'Capital à la retraite (avec retrait)'**
  String get scenarioPropertyCapitalWith;

  /// No description provided for @scenarioPropertyPensionLoss.
  ///
  /// In fr, this message translates to:
  /// **'Perte de rente mensuelle'**
  String get scenarioPropertyPensionLoss;

  /// No description provided for @scenarioDivorceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Divorce'**
  String get scenarioDivorceTitle;

  /// No description provided for @scenarioDivorceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Partage LPP et impact sur la rente'**
  String get scenarioDivorceSubtitle;

  /// No description provided for @scenarioDivorceMySection.
  ///
  /// In fr, this message translates to:
  /// **'Votre LPP'**
  String get scenarioDivorceMySection;

  /// No description provided for @scenarioDivorceMyCapitalMarriage.
  ///
  /// In fr, this message translates to:
  /// **'Capital au mariage'**
  String get scenarioDivorceMyCapitalMarriage;

  /// No description provided for @scenarioDivorceMyCapitalNow.
  ///
  /// In fr, this message translates to:
  /// **'Capital actuel'**
  String get scenarioDivorceMyCapitalNow;

  /// No description provided for @scenarioDivorceSpouseSection.
  ///
  /// In fr, this message translates to:
  /// **'LPP du conjoint'**
  String get scenarioDivorceSpouseSection;

  /// No description provided for @scenarioDivorceSpouseCapitalMarriage.
  ///
  /// In fr, this message translates to:
  /// **'Capital au mariage'**
  String get scenarioDivorceSpouseCapitalMarriage;

  /// No description provided for @scenarioDivorceSpouseCapitalNow.
  ///
  /// In fr, this message translates to:
  /// **'Capital actuel'**
  String get scenarioDivorceSpouseCapitalNow;

  /// No description provided for @scenarioDivorceYearsMarried.
  ///
  /// In fr, this message translates to:
  /// **'Années de mariage'**
  String get scenarioDivorceYearsMarried;

  /// No description provided for @scenarioDivorceResultSection.
  ///
  /// In fr, this message translates to:
  /// **'Résultat du partage'**
  String get scenarioDivorceResultSection;

  /// No description provided for @scenarioDivorceTotalMarriageCapital.
  ///
  /// In fr, this message translates to:
  /// **'Capital accumulé pendant le mariage'**
  String get scenarioDivorceTotalMarriageCapital;

  /// No description provided for @scenarioDivorceMyShare.
  ///
  /// In fr, this message translates to:
  /// **'Votre part (50%)'**
  String get scenarioDivorceMyShare;

  /// No description provided for @scenarioDivorceTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get scenarioDivorceTransfer;

  /// No description provided for @scenarioDivorceCapitalAfter.
  ///
  /// In fr, this message translates to:
  /// **'Votre capital après divorce'**
  String get scenarioDivorceCapitalAfter;

  /// No description provided for @scenarioWithdrawalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retrait échelonné'**
  String get scenarioWithdrawalTitle;

  /// No description provided for @scenarioWithdrawalSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Optimisez la fiscalité de vos retraits 3a'**
  String get scenarioWithdrawalSubtitle;

  /// No description provided for @scenarioWithdrawalInputSection.
  ///
  /// In fr, this message translates to:
  /// **'Vos avoirs'**
  String get scenarioWithdrawalInputSection;

  /// No description provided for @scenarioWithdrawal3aBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde total 3a'**
  String get scenarioWithdrawal3aBalance;

  /// No description provided for @scenarioWithdrawalAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de comptes 3a'**
  String get scenarioWithdrawalAccounts;

  /// No description provided for @scenarioWithdrawalPillar2Capital.
  ///
  /// In fr, this message translates to:
  /// **'Capital LPP en capital (si retrait)'**
  String get scenarioWithdrawalPillar2Capital;

  /// No description provided for @scenarioWithdrawalComparison.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison fiscale'**
  String get scenarioWithdrawalComparison;

  /// No description provided for @scenarioWithdrawalSaving.
  ///
  /// In fr, this message translates to:
  /// **'Économie fiscale'**
  String get scenarioWithdrawalSaving;

  /// No description provided for @scenarioWithdrawalTip.
  ///
  /// In fr, this message translates to:
  /// **'En Suisse, les retraits de capital sont imposés à un taux progressif. Répartir les retraits sur plusieurs années permet de rester dans des tranches d\'imposition plus basses.'**
  String get scenarioWithdrawalTip;

  /// No description provided for @scenarioDivorcePensionImpact.
  ///
  /// In fr, this message translates to:
  /// **'Impact sur la rente annuelle'**
  String get scenarioDivorcePensionImpact;

  /// No description provided for @scenario3aCatchupStatusEmployed.
  ///
  /// In fr, this message translates to:
  /// **'Salarié·e (avec 2e pilier)'**
  String get scenario3aCatchupStatusEmployed;

  /// No description provided for @scenario3aCatchupStatusSelfEmployed.
  ///
  /// In fr, this message translates to:
  /// **'Indépendant·e (sans 2e pilier)'**
  String get scenario3aCatchupStatusSelfEmployed;

  /// No description provided for @scenario3aCatchupEligibleYears.
  ///
  /// In fr, this message translates to:
  /// **'Années rattrapables'**
  String get scenario3aCatchupEligibleYears;

  /// No description provided for @scenario3aCatchupCurrentYearGap.
  ///
  /// In fr, this message translates to:
  /// **'À verser d\'abord (année en cours)'**
  String get scenario3aCatchupCurrentYearGap;

  /// No description provided for @scenario3aCatchupMarginalRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux marginal estimé'**
  String get scenario3aCatchupMarginalRate;

  /// No description provided for @scenario3aCatchupYearlySection.
  ///
  /// In fr, this message translates to:
  /// **'Détail par année'**
  String get scenario3aCatchupYearlySection;

  /// No description provided for @scenarioWithdrawalStrategyLumpSum.
  ///
  /// In fr, this message translates to:
  /// **'Retrait unique'**
  String get scenarioWithdrawalStrategyLumpSum;

  /// No description provided for @scenarioWithdrawalStrategyStaggered.
  ///
  /// In fr, this message translates to:
  /// **'Échelonné sur {years} ans'**
  String scenarioWithdrawalStrategyStaggered(int years);

  /// No description provided for @scenarioWithdrawalBestStrategy.
  ///
  /// In fr, this message translates to:
  /// **'Meilleure stratégie'**
  String get scenarioWithdrawalBestStrategy;

  /// No description provided for @scenarioWithdrawalEffectiveRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'impôt effectif'**
  String get scenarioWithdrawalEffectiveRate;

  /// No description provided for @scenarioDivorceAvsImpact.
  ///
  /// In fr, this message translates to:
  /// **'Impact estimé sur la rente AVS'**
  String get scenarioDivorceAvsImpact;

  /// No description provided for @scenarioDivorceDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Simulation indicative du partage LPP prévu par la loi (50/50 des avoirs accumulés pendant le mariage). Elle ne constitue pas un conseil juridique.'**
  String get scenarioDivorceDisclaimer;

  /// No description provided for @scenarioDivorceYouReceive.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevez'**
  String get scenarioDivorceYouReceive;

  /// No description provided for @scenarioDivorceYouPay.
  ///
  /// In fr, this message translates to:
  /// **'Vous payez'**
  String get scenarioDivorceYouPay;

  /// No description provided for @scenarioDivorceCapitalExceedsNow.
  ///
  /// In fr, this message translates to:
  /// **'Le capital au mariage ne peut pas dépasser le capital actuel'**
  String get scenarioDivorceCapitalExceedsNow;

  /// No description provided for @pdfTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bilan Prévoyance PocketPillar'**
  String get pdfTitle;

  /// No description provided for @pdfExportButton.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le bilan PDF'**
  String get pdfExportButton;

  /// No description provided for @pdfSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get pdfSectionTitle;

  /// No description provided for @pdfAge.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get pdfAge;

  /// No description provided for @pdfSalary.
  ///
  /// In fr, this message translates to:
  /// **'Salaire'**
  String get pdfSalary;

  /// No description provided for @pdfCanton.
  ///
  /// In fr, this message translates to:
  /// **'Canton'**
  String get pdfCanton;

  /// No description provided for @pdfPillarsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos 3 piliers'**
  String get pdfPillarsTitle;

  /// No description provided for @pdfPillar1.
  ///
  /// In fr, this message translates to:
  /// **'1er pilier (AVS)'**
  String get pdfPillar1;

  /// No description provided for @pdfPillar2.
  ///
  /// In fr, this message translates to:
  /// **'2e pilier (LPP)'**
  String get pdfPillar2;

  /// No description provided for @pdfPillar3a.
  ///
  /// In fr, this message translates to:
  /// **'Pilier 3a'**
  String get pdfPillar3a;

  /// No description provided for @pdfProjectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Projection retraite'**
  String get pdfProjectionTitle;

  /// No description provided for @pdfRetirementAge.
  ///
  /// In fr, this message translates to:
  /// **'Âge de la retraite'**
  String get pdfRetirementAge;

  /// No description provided for @pdfYearsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Années restantes'**
  String get pdfYearsRemaining;

  /// No description provided for @pdfReplacementRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de remplacement'**
  String get pdfReplacementRate;

  /// No description provided for @pdfAnnualIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu annuel estimé'**
  String get pdfAnnualIncome;

  /// No description provided for @pdfMonthlyIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu mensuel estimé'**
  String get pdfMonthlyIncome;

  /// No description provided for @pdfTaxTitle.
  ///
  /// In fr, this message translates to:
  /// **'Économies fiscales (3a)'**
  String get pdfTaxTitle;

  /// No description provided for @pdfTaxDetail.
  ///
  /// In fr, this message translates to:
  /// **'Économie annuelle estimée : {amount}'**
  String pdfTaxDetail(String amount);

  /// No description provided for @pdfRecommendationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations'**
  String get pdfRecommendationsTitle;

  /// No description provided for @pdfRecOpen3a.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir un pilier 3a pour bénéficier d\'avantages fiscaux et améliorer votre prévoyance.'**
  String get pdfRecOpen3a;

  /// No description provided for @pdfRecMax3a.
  ///
  /// In fr, this message translates to:
  /// **'Maximisez votre cotisation 3a annuelle ({amount}) pour optimiser vos économies fiscales.'**
  String pdfRecMax3a(String amount);

  /// No description provided for @pdfRecIncreaseCoverage.
  ///
  /// In fr, this message translates to:
  /// **'Votre taux de remplacement est inférieur à 60%. Envisagez un rachat LPP ou une augmentation de votre épargne 3a.'**
  String get pdfRecIncreaseCoverage;

  /// No description provided for @pdfRecGoodTrack.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes sur la bonne voie ! Continuez à épargner régulièrement.'**
  String get pdfRecGoodTrack;

  /// No description provided for @generalSimulationDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Simulation indicative : barèmes officiels 2026, calculée sur le revenu brut (sans vos déductions individuelles). PocketPillar fournit de l\'information, pas du conseil en placement (LSFin).'**
  String get generalSimulationDisclaimer;

  /// No description provided for @pdfDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Ce document est fourni à titre indicatif uniquement et ne constitue pas un conseil financier. Les projections sont basées sur des estimations et peuvent varier. Consultez un conseiller financier pour des recommandations personnalisées. PocketPillar © 2026.'**
  String get pdfDisclaimer;

  /// No description provided for @checklistCompleted.
  ///
  /// In fr, this message translates to:
  /// **'complétés'**
  String get checklistCompleted;

  /// No description provided for @checklistAllDone.
  ///
  /// In fr, this message translates to:
  /// **'Tout est fait !'**
  String get checklistAllDone;

  /// No description provided for @checklistCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Checklist fin d\'année'**
  String get checklistCardTitle;

  /// No description provided for @checklistCardRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{count} actions restantes'**
  String checklistCardRemaining(int count);

  /// No description provided for @checklistMax3aTitle.
  ///
  /// In fr, this message translates to:
  /// **'Maximiser le pilier 3a'**
  String get checklistMax3aTitle;

  /// No description provided for @checklistMax3aDescription.
  ///
  /// In fr, this message translates to:
  /// **'Versez le montant maximum avant le 31 décembre pour optimiser vos impôts.'**
  String get checklistMax3aDescription;

  /// No description provided for @checklistMax3aValue.
  ///
  /// In fr, this message translates to:
  /// **'Maximum : {max}'**
  String checklistMax3aValue(String max);

  /// No description provided for @checklistBvgBuybackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le rachat LPP'**
  String get checklistBvgBuybackTitle;

  /// No description provided for @checklistBvgBuybackDescription.
  ///
  /// In fr, this message translates to:
  /// **'Contactez votre caisse de pension pour connaître votre potentiel de rachat.'**
  String get checklistBvgBuybackDescription;

  /// No description provided for @checklistCertificateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demander le certificat de prévoyance'**
  String get checklistCertificateTitle;

  /// No description provided for @checklistCertificateDescription.
  ///
  /// In fr, this message translates to:
  /// **'Demandez votre certificat LPP annuel à votre employeur ou caisse de pension.'**
  String get checklistCertificateDescription;

  /// No description provided for @checklistTaxDocsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préparer les justificatifs fiscaux'**
  String get checklistTaxDocsTitle;

  /// No description provided for @checklistTaxDocsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Rassemblez vos attestations 3a et certificats LPP pour votre déclaration d\'impôts.'**
  String get checklistTaxDocsDescription;

  /// No description provided for @checklistUpdateProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour le profil'**
  String get checklistUpdateProfileTitle;

  /// No description provided for @checklistUpdateProfileDescription.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que votre salaire, âge et situation sont à jour dans PocketPillar.'**
  String get checklistUpdateProfileDescription;

  /// No description provided for @checklistPlanNextTitle.
  ///
  /// In fr, this message translates to:
  /// **'Planifier l\'année suivante'**
  String get checklistPlanNextTitle;

  /// No description provided for @checklistPlanNextDescription.
  ///
  /// In fr, this message translates to:
  /// **'Explorez les scénarios pour définir votre stratégie de prévoyance pour l\'année prochaine.'**
  String get checklistPlanNextDescription;

  /// No description provided for @coupleScenarioTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode Couple'**
  String get coupleScenarioTitle;

  /// No description provided for @coupleScenarioSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Simulez votre retraite à deux'**
  String get coupleScenarioSubtitle;

  /// No description provided for @coupleSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Couple'**
  String get coupleSectionTitle;

  /// No description provided for @couplePartnerHas3a.
  ///
  /// In fr, this message translates to:
  /// **'Le partenaire a un 3e pilier'**
  String get couplePartnerHas3a;

  /// No description provided for @coupleCalculate.
  ///
  /// In fr, this message translates to:
  /// **'Calculer la retraite du couple'**
  String get coupleCalculate;

  /// No description provided for @coupleYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get coupleYou;

  /// No description provided for @couplePartner.
  ///
  /// In fr, this message translates to:
  /// **'Partenaire'**
  String get couplePartner;

  /// No description provided for @coupleAvs.
  ///
  /// In fr, this message translates to:
  /// **'AVS/mois'**
  String get coupleAvs;

  /// No description provided for @coupleBvg.
  ///
  /// In fr, this message translates to:
  /// **'LPP/mois'**
  String get coupleBvg;

  /// No description provided for @couplePillar3a.
  ///
  /// In fr, this message translates to:
  /// **'Capital 3a projeté'**
  String get couplePillar3a;

  /// No description provided for @coupleTotalMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Total/mois'**
  String get coupleTotalMonthly;

  /// No description provided for @coupleCombinedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Revenu combiné du couple'**
  String get coupleCombinedTitle;

  /// No description provided for @coupleCombinedMonthly.
  ///
  /// In fr, this message translates to:
  /// **'par mois (rente combinée)'**
  String get coupleCombinedMonthly;

  /// No description provided for @coupleReplacementRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de remplacement combiné'**
  String get coupleReplacementRate;

  /// No description provided for @coupleAvsCapWarning.
  ///
  /// In fr, this message translates to:
  /// **'Le plafond AVS couple (150% du maximum individuel) s\'applique. Votre rente AVS combinée est réduite.'**
  String get coupleAvsCapWarning;

  /// No description provided for @coupleAvsCapPhasing.
  ///
  /// In fr, this message translates to:
  /// **'Le plafond s\'applique lorsque les deux rentes sont versées ; tant qu\'un seul conjoint est à la retraite, sa rente reste entière.'**
  String get coupleAvsCapPhasing;

  /// No description provided for @coupleWithdrawalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plan de retrait optimal'**
  String get coupleWithdrawalTitle;

  /// No description provided for @coupleWithdraw3a.
  ///
  /// In fr, this message translates to:
  /// **'Retrait pilier 3a'**
  String get coupleWithdraw3a;

  /// No description provided for @coupleWithdrawBvg.
  ///
  /// In fr, this message translates to:
  /// **'Retrait capital LPP'**
  String get coupleWithdrawBvg;

  /// No description provided for @coupleTaxEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Impôt estimé : {amount}'**
  String coupleTaxEstimate(String amount);

  /// No description provided for @coupleFormIntro.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont pré-remplies depuis votre profil. Saisissez celles de votre partenaire pour lancer la simulation.'**
  String get coupleFormIntro;

  /// No description provided for @coupleReplacementIndividual.
  ///
  /// In fr, this message translates to:
  /// **'Taux de remplacement'**
  String get coupleReplacementIndividual;

  /// No description provided for @coupleSituationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre situation'**
  String get coupleSituationTitle;

  /// No description provided for @coupleFiscalStatus.
  ///
  /// In fr, this message translates to:
  /// **'Situation fiscale simulée'**
  String get coupleFiscalStatus;

  /// No description provided for @coupleStatusMarried.
  ///
  /// In fr, this message translates to:
  /// **'Marié·e·s'**
  String get coupleStatusMarried;

  /// No description provided for @coupleStatusPartnership.
  ///
  /// In fr, this message translates to:
  /// **'Partenariat enregistré'**
  String get coupleStatusPartnership;

  /// No description provided for @coupleStatusConcubinage.
  ///
  /// In fr, this message translates to:
  /// **'Concubinage'**
  String get coupleStatusConcubinage;

  /// No description provided for @coupleTaxTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fiscalité du couple'**
  String get coupleTaxTitle;

  /// No description provided for @coupleTaxMarriedJoint.
  ///
  /// In fr, this message translates to:
  /// **'Imposition commune (mariage)'**
  String get coupleTaxMarriedJoint;

  /// No description provided for @coupleTaxUnmarriedSeparate.
  ///
  /// In fr, this message translates to:
  /// **'Imposition séparée (concubinage)'**
  String get coupleTaxUnmarriedSeparate;

  /// No description provided for @coupleTaxCheaperMarried.
  ///
  /// In fr, this message translates to:
  /// **'Le mariage vous fait économiser environ {amount} d\'impôts par an.'**
  String coupleTaxCheaperMarried(String amount);

  /// No description provided for @coupleTaxCheaperConcubinage.
  ///
  /// In fr, this message translates to:
  /// **'Le concubinage vous fait économiser environ {amount} d\'impôts par an.'**
  String coupleTaxCheaperConcubinage(String amount);

  /// No description provided for @coupleTaxEqual.
  ///
  /// In fr, this message translates to:
  /// **'Mariage et concubinage sont équivalents fiscalement.'**
  String get coupleTaxEqual;

  /// No description provided for @coupleTaxDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Estimation indicative calculée sur les revenus bruts (barèmes officiels 2026 : IFD, cantonal et communal).'**
  String get coupleTaxDisclaimer;

  /// No description provided for @coupleConversionRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de conversion LPP (%)'**
  String get coupleConversionRate;

  /// No description provided for @coupleConversionRateHint.
  ///
  /// In fr, this message translates to:
  /// **'6.8 % = minimum légal, garanti sur la seule part obligatoire. Votre caisse applique souvent un taux global plus bas — voir votre certificat LPP.'**
  String get coupleConversionRateHint;

  /// No description provided for @coupleWithdrawalTotalTax.
  ///
  /// In fr, this message translates to:
  /// **'Impôt total du plan'**
  String get coupleWithdrawalTotalTax;

  /// No description provided for @coupleWithdrawalSimultaneous.
  ///
  /// In fr, this message translates to:
  /// **'Impôt si retraits la même année'**
  String get coupleWithdrawalSimultaneous;

  /// No description provided for @coupleWithdrawalSavings.
  ///
  /// In fr, this message translates to:
  /// **'Économie grâce à l\'échelonnement'**
  String get coupleWithdrawalSavings;

  /// No description provided for @coupleWithdrawalEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun capital 3a ou LPP projeté : le plan de retraits apparaîtra dès qu\'un capital est renseigné.'**
  String get coupleWithdrawalEmpty;

  /// No description provided for @paywallTitle.
  ///
  /// In fr, this message translates to:
  /// **'PocketPillar Premium'**
  String get paywallTitle;

  /// No description provided for @paywallHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Débloquez tout votre potentiel de prévoyance'**
  String get paywallHeadline;

  /// No description provided for @paywallPriceFallback.
  ///
  /// In fr, this message translates to:
  /// **'CHF 39/an'**
  String get paywallPriceFallback;

  /// No description provided for @paywallPricePerYear.
  ///
  /// In fr, this message translates to:
  /// **'{price} par an'**
  String paywallPricePerYear(String price);

  /// No description provided for @paywallFeaturesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inclus dans Premium'**
  String get paywallFeaturesTitle;

  /// No description provided for @paywallFeatureCatchup.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapage 3a : détail année par année et plan d\'action'**
  String get paywallFeatureCatchup;

  /// No description provided for @paywallFeatureScenarios.
  ///
  /// In fr, this message translates to:
  /// **'4 scénarios avancés : couple, retrait échelonné, achat immobilier, divorce'**
  String get paywallFeatureScenarios;

  /// No description provided for @paywallFeatureOcr.
  ///
  /// In fr, this message translates to:
  /// **'Scan de documents (OCR) pour préremplir votre profil'**
  String get paywallFeatureOcr;

  /// No description provided for @paywallFeatureRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations complètes et meilleur prestataire pour votre profil'**
  String get paywallFeatureRecommendations;

  /// No description provided for @paywallFeaturePdf.
  ///
  /// In fr, this message translates to:
  /// **'Export PDF de votre bilan'**
  String get paywallFeaturePdf;

  /// No description provided for @paywallFeatureDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents illimités'**
  String get paywallFeatureDocuments;

  /// No description provided for @paywallSubscribe.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer Premium'**
  String get paywallSubscribe;

  /// No description provided for @paywallRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer mes achats'**
  String get paywallRestore;

  /// No description provided for @paywallLegal.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement annuel renouvelé automatiquement. Gérez ou résiliez à tout moment dans les réglages de votre store (App Store / Google Play).'**
  String get paywallLegal;

  /// No description provided for @paywallUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Achat indisponible'**
  String get paywallUnavailableTitle;

  /// No description provided for @paywallUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'achat intégré n\'est pas disponible pour le moment. Réessayez plus tard — vos fonctionnalités gratuites restent accessibles.'**
  String get paywallUnavailableBody;

  /// No description provided for @paywallOfferingError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'offre. Vérifiez votre connexion puis réessayez.'**
  String get paywallOfferingError;

  /// No description provided for @paywallPurchaseFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'achat n\'a pas abouti. Réessayez plus tard.'**
  String get paywallPurchaseFailed;

  /// No description provided for @paywallPurchaseSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Premium activé — merci !'**
  String get paywallPurchaseSuccess;

  /// No description provided for @paywallRestoreSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement restauré !'**
  String get paywallRestoreSuccess;

  /// No description provided for @paywallRestoreNothing.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement à restaurer pour ce compte.'**
  String get paywallRestoreNothing;

  /// No description provided for @paywallRestoreFailed.
  ///
  /// In fr, this message translates to:
  /// **'La restauration n\'a pas abouti. Réessayez plus tard.'**
  String get paywallRestoreFailed;

  /// No description provided for @paywallAlreadyActive.
  ///
  /// In fr, this message translates to:
  /// **'Votre abonnement Premium est actif.'**
  String get paywallAlreadyActive;

  /// No description provided for @settingsPremiumTitle.
  ///
  /// In fr, this message translates to:
  /// **'PocketPillar Premium'**
  String get settingsPremiumTitle;

  /// No description provided for @settingsPremiumActive.
  ///
  /// In fr, this message translates to:
  /// **'Abonné'**
  String get settingsPremiumActive;

  /// No description provided for @settingsPremiumActiveUntil.
  ///
  /// In fr, this message translates to:
  /// **'Abonné — jusqu\'au {date}'**
  String settingsPremiumActiveUntil(String date);

  /// No description provided for @settingsPremiumInactive.
  ///
  /// In fr, this message translates to:
  /// **'Non abonné — CHF 39/an'**
  String get settingsPremiumInactive;

  /// No description provided for @premiumBadgeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Premium'**
  String get premiumBadgeLabel;

  /// No description provided for @premiumDiscoverCta.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir Premium'**
  String get premiumDiscoverCta;

  /// No description provided for @premiumUpsellRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Les recommandations personnalisées et le comparatif complet font partie de PocketPillar Premium.'**
  String get premiumUpsellRecommendations;

  /// No description provided for @premiumUpsellBestMatch.
  ///
  /// In fr, this message translates to:
  /// **'La recherche du prestataire idéal fait partie de PocketPillar Premium.'**
  String get premiumUpsellBestMatch;

  /// No description provided for @catchupUpsellTitle.
  ///
  /// In fr, this message translates to:
  /// **'Débloquez le plan année par année'**
  String get catchupUpsellTitle;

  /// No description provided for @catchupUpsellBody.
  ///
  /// In fr, this message translates to:
  /// **'Avec Premium, visualisez chaque année rattrapable et votre plan d\'action détaillé.'**
  String get catchupUpsellBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
