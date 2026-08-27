// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'PocketPillar';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get authCancel => 'Abbrechen';

  @override
  String get authCheckEmail =>
      'Bitte bestätigen Sie Ihre E-Mail-Adresse über den Link in Ihrem Posteingang und melden Sie sich danach an';

  @override
  String get authConfirmPassword => 'Passwort bestätigen';

  @override
  String get authCreateAccount => 'Mein Konto erstellen';

  @override
  String get authEmail => 'E-Mail-Adresse';

  @override
  String get authEmailInvalid => 'Ungültige E-Mail-Adresse';

  @override
  String get authEmailTaken =>
      'Diese E-Mail-Adresse ist bereits mit einem anderen Konto verknüpft';

  @override
  String get authGoToLogin => 'Zur Anmeldung';

  @override
  String get authLoginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String get authLoginSubtitle => 'Ihre Schweizer Vorsorge, sicher geschützt';

  @override
  String get authNoAccount => 'Noch kein Konto? Konto erstellen';

  @override
  String get authDemoBannerTitle => 'Öffentliche Demo';

  @override
  String get authDemoBannerBody =>
      'Geteiltes, öffentliches Demokonto — alle sehen dieselben (fiktiven) Daten, jede Nacht zurückgesetzt. Gib keine echten persönlichen Daten ein.';

  @override
  String get authDemoSignIn => 'Mit dem Demokonto anmelden';

  @override
  String get authOr => 'oder';

  @override
  String get authPassword => 'Passwort';

  @override
  String get authPasswordMinLength =>
      'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get authPasswordRequired => 'Passwort erforderlich';

  @override
  String get authPasswordsMismatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get authRegisterTitle => 'Konto erstellen';

  @override
  String get authSignIn => 'Anmelden';

  @override
  String get authSignInWithApple => 'Mit Apple anmelden';

  @override
  String get authSignOut => 'Abmelden';

  @override
  String get authSignUpFailed => 'Kontoerstellung fehlgeschlagen';

  @override
  String get biometricLockedMessage =>
      'Authentifizieren Sie sich, um auf Ihre Finanzdaten zuzugreifen';

  @override
  String get biometricReason =>
      'Entsperren Sie PocketPillar, um auf Ihre Daten zuzugreifen';

  @override
  String get biometricUnlock => 'Entsperren';

  @override
  String get errorNetwork => 'Netzwerkfehler';

  @override
  String get errorSessionExpired =>
      'Ihre Sitzung ist abgelaufen, bitte melden Sie sich erneut an';

  @override
  String get errorUnknown => 'Unbekannter Fehler';

  @override
  String get notificationYearEndChecklist =>
      'Vergessen Sie nicht Ihre Jahresend-Checkliste! Maximieren Sie Ihre Steuervorteile vor dem 31. Dezember.';

  @override
  String notification3aReminder(String amount) {
    return 'Denken Sie an Ihre 3a-Einzahlung! Sie können dieses Jahr bis zu CHF $amount einzahlen.';
  }

  @override
  String notification3aReminderContextual(String amount, int days) {
    return 'Ihnen fehlen noch CHF $amount für Ihre 3a-Einzahlung vor dem 31. Dezember (noch $days Tage).';
  }

  @override
  String get tabCalculator => 'Bilanz';

  @override
  String get tabDashboard => 'Startseite';

  @override
  String get tabDocuments => 'Dokumente';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabProviders => 'Anbieter';

  @override
  String get tabScenarios => 'Szenarien';

  @override
  String get onboardingTitle => 'Willkommen';

  @override
  String get checklistTitle => 'Checkliste';

  @override
  String get coupleTitle => 'Paar';

  @override
  String get financialProfileTitle => 'Finanzprofil';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsBiometricLock => 'Biometrische Sperre';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsSectionLanguage => 'Sprache';

  @override
  String get settingsSectionNotifications => 'Mitteilungen';

  @override
  String get settingsAnnualReminders => 'Jährliche Erinnerungen';

  @override
  String get settingsAnnualRemindersSubtitle =>
      'Jahresend-Checkliste (15. Dezember) und 3a-Einzahlung (1. November), um 10 Uhr';

  @override
  String get settingsSectionLearn => 'Verstehen';

  @override
  String get settingsUnderstandTitle => 'Meine Vorsorge verstehen';

  @override
  String get settingsUnderstandSubtitle =>
      'Die 3 Säulen und unsere Berechnungen, einfach erklärt';

  @override
  String get understandIntro =>
      'Die Schweizer Vorsorge ruht auf 3 Säulen: der staatlichen AHV, der Pensionskasse Ihres Arbeitgebers und Ihrem persönlichen 3a-Sparen. Tippen Sie auf eine Säule, um ihre Rolle zu verstehen.';

  @override
  String get understandPillarsTitle => 'Die 3 Säulen';

  @override
  String get understandCalcTitle => 'Wie rechnen wir?';

  @override
  String get understandCalcIntro =>
      'Jede Zahl in der App stammt aus einer der folgenden Regeln — gesetzliche Parameter 2026 und offizielle Tarife, nie erfundene Durchschnitte.';

  @override
  String get understandCalcAvsTitle => 'AHV-Rente';

  @override
  String get understandCalcAvsBody =>
      'Geschätzt aus Ihrem Einkommen und den bis zur Pensionierung projizierten Beitragsjahren (vereinfachte Skala 44). Ab 2026 ist die 13. Rente enthalten (13 Monatszahlungen pro Jahr). Ihre tatsächliche Rente hängt von Ihrem genauen Werdegang ab — bestellen Sie einen AHV-Kontoauszug, um ihn zu kennen.';

  @override
  String get understandCalcLppTitle => 'BVG-Kapital und -Rente';

  @override
  String get understandCalcLppBody =>
      'Ihr aktuelles Kapital wächst jedes Jahr mit Ihren Sparbeiträgen (Arbeitnehmer- + Arbeitgeberanteil) und dem gesetzlichen Mindestzins von 1.25 %. Bei der Pensionierung gilt: Rente = Kapital × Umwandlungssatz. 6.8 % ist das gesetzliche Minimum auf dem obligatorischen Teil — erfassen Sie den Satz Ihres Ausweises für ein genaueres Ergebnis.';

  @override
  String get understandCalc3aTitle => '3a-Sparen';

  @override
  String get understandCalc3aBody =>
      'Ihr aktueller Saldo wird mit Ihren jährlichen Einzahlungen und der gewählten Rendite projiziert. Bei der Pensionierung wird das 3a als Kapital bezogen (nicht als Rente) — es wird deshalb separat ausgewiesen, mit der geschätzten Bezugssteuer.';

  @override
  String get understandCalcTaxTitle => 'Steuern';

  @override
  String get understandCalcTaxBody =>
      '3a-Steuerersparnis, Vergleich Ehe/Konkubinat, Steuer beim Kapitalbezug: alles wird mit den offiziellen Tarifen 2026 von Bund, Kanton und Gemeinde berechnet — geprüft gegen den offiziellen Rechner der ESTV. Basis ist Ihr Bruttoeinkommen (Ihre persönlichen Abzüge sind nicht bekannt): die Beträge sind Schätzungen.';

  @override
  String get understandCalcLimitsTitle => 'Was wir nicht abbilden';

  @override
  String get understandCalcLimitsBody =>
      'Besondere Lebensläufe: Scheidung und AHV-Splitting, Erziehungsgutschriften, Zuzug in die Schweiz während der Karriere, Invalidität, Kassensätze auf dem überobligatorischen Teil. PocketPillar ist ein Schätz- und Informationstool — keine Beratung. Besprechen Sie wichtige Entscheide mit einer Fachperson.';

  @override
  String get understandMethodologyLink =>
      'Vollständige Methodik und Quellen (auf GitHub veröffentlicht)';

  @override
  String get settingsNotificationsDenied =>
      'Mitteilungen verweigert — aktivieren Sie sie in den Systemeinstellungen, um Erinnerungen zu erhalten';

  @override
  String get settingsDeleteAccount => 'Konto löschen';

  @override
  String get settingsDeleteConfirmTitle => 'Endgültig löschen?';

  @override
  String get settingsDeleteConfirmBody =>
      'Diese Aktion ist unwiderruflich: Ihr Konto und alle Ihre Daten (Finanzprofil, LPP- und 3a-Konten, Dokumente) werden gelöscht.';

  @override
  String get dashboardTitle => 'PocketPillar';

  @override
  String get dashboardWelcomeHeader => 'Ihre Vorsorge, vereinfacht';

  @override
  String get dashboardWelcomeSubtitle =>
      'Verstehen und optimieren Sie Ihre Rente in wenigen Minuten';

  @override
  String get dashboardCtaCheck => 'Prüfen Sie Ihre Rente in 2 Min.';

  @override
  String get dashboardTipOfDay => 'Tipp des Tages';

  @override
  String dashboardSummary(int percent) {
    return 'Ihre Rente deckt $percent% Ihres Einkommens';
  }

  @override
  String get dashboardScoreLabel => 'Vorsorge-Gesundheit';

  @override
  String get dashboardRecOpen3a =>
      'Eröffnen Sie eine Säule 3a, um Steuern zu sparen und Ihre Rente vorzubereiten';

  @override
  String get dashboardRecLowCoverage =>
      'Ihre Deckungsquote ist niedrig. Erhöhen Sie Ihre Beiträge für eine bessere Rente.';

  @override
  String get dashboardRecGoodTrack =>
      'Sie sind auf dem richtigen Weg! Optimieren Sie Ihre Vorsorge weiter.';

  @override
  String get dashboardActionGuided => 'Geführte Bilanz';

  @override
  String get dashboardActionExpert => 'Expertenmodus';

  @override
  String get dashboardActionLearn => 'Verstehen';

  @override
  String get dashboardQuickActions => 'Schnellaktionen';

  @override
  String get dashboardStatusOnline => 'API verbunden';

  @override
  String get dashboardStatusOffline => 'API offline';

  @override
  String dashboardUptime(int hours) {
    return 'Online seit $hours Std.';
  }

  @override
  String get dashboardApiVersion => 'API-Version';

  @override
  String get dashboardSince => 'seit';

  @override
  String get dashboardGoalProgress => 'Fortschritt zum Ziel';

  @override
  String get dashboardGoalReached => 'Ziel erreicht!';

  @override
  String get dashboardRecommendedProvider => 'Empfohlener Anbieter für Sie';

  @override
  String get dashboardGreeting => 'Guten Tag';

  @override
  String get dashboardGreetingEvening => 'Guten Abend';

  @override
  String get dashboardEmptyTitle => 'Vervollständigen Sie Ihr Profil';

  @override
  String get dashboardEmptyBody =>
      'Geben Sie Ihre finanzielle Situation ein, um Ihre Vorsorgeprojektion und personalisierte Empfehlungen zu erhalten.';

  @override
  String get dashboardEmptyCta => 'Mein Profil vervollständigen';

  @override
  String get dashboardSynthesisTitle => 'Ihre Vorsorgeprojektion';

  @override
  String get dashboardRecommendationsTitle => 'Empfehlungen';

  @override
  String get dashboardRecommendationsEmpty =>
      'Vervollständigen Sie Ihr Profil, um personalisierte Empfehlungen zu erhalten.';

  @override
  String dashboardEstimatedAnnualImpact(String amount) {
    return 'Geschätzte Wirkung: $amount/Jahr';
  }

  @override
  String dashboardScoreBenchmarkTitle(int min, int max) {
    return 'Vergleich mit $min–$max-Jährigen';
  }

  @override
  String dashboardScoreBenchmark3a(String user, String average) {
    return 'Säule 3a: $user (Durchschnitt: $average)';
  }

  @override
  String dashboardScoreBenchmarkRate(String user, String average) {
    return 'Ersatzquote: $user (Durchschnitt: $average)';
  }

  @override
  String dashboardScoreBenchmarkBvg(String user, String average) {
    return 'BVG-Guthaben: $user (Durchschnitt: $average)';
  }

  @override
  String get calculatorTitle => 'Rechner';

  @override
  String get calculatorLppGap => 'BVG-Lücke';

  @override
  String get calculatorTaxSavings => '3a-Steuerersparnis';

  @override
  String get calculatorRetirement => 'Rente';

  @override
  String get calculatorCalculate => 'Berechnen';

  @override
  String get calculatorGrossIncome => 'Bruttoeinkommen (CHF)';

  @override
  String get calculatorAge => 'Alter';

  @override
  String get calculatorCanton => 'Kanton';

  @override
  String get calculatorBvgCapital => 'BVG-Kapital (CHF)';

  @override
  String get calculatorAnnualContribution => 'Jahresbeitrag (CHF)';

  @override
  String get calculatorTaxableIncome => 'Steuerbares Einkommen (CHF)';

  @override
  String get calculatorContribution3a => '3a-Einzahlung (CHF)';

  @override
  String get calculatorPillar3aBalance => '3a-Guthaben (CHF)';

  @override
  String get calculatorCoordinatedSalary => 'Koordinierter Lohn';

  @override
  String get calculatorBvgMinContribution => 'BVG-Mindestbeitrag';

  @override
  String get calculatorProjectedCapital => 'Projiziertes Kapital';

  @override
  String get calculatorProjectedPension => 'Projizierte Rente/Jahr';

  @override
  String get calculatorPensionGap => 'Rentenlücke';

  @override
  String get calculatorFederalSaving => 'Bundesersparnis';

  @override
  String get calculatorCantonalSaving => 'Kantonsersparnis';

  @override
  String get calculatorCommunalSaving => 'Gemeindeersparnis';

  @override
  String get calculatorTotalSaving => 'Gesamtersparnis';

  @override
  String get calculatorEffectiveReturn => 'Effektive Rendite';

  @override
  String get calculatorYearsToRetirement => 'Jahre bis zur Rente';

  @override
  String get calculatorProjectedPillar2 => 'Projiziertes 2. Säule-Kapital';

  @override
  String get calculatorProjectedPillar3a => 'Projiziertes 3a-Guthaben';

  @override
  String get calculatorWithdrawalTax3a => 'Steuer beim 3a-Bezug (geschätzt)';

  @override
  String get calculatorNet3aAfterTax => '3a-Kapital netto nach Steuer';

  @override
  String get calculatorAnnualRetirementIncome => 'Jährliches Renteneinkommen';

  @override
  String get calculatorReplacementRate => 'Ersatzquote';

  @override
  String get providersTitle => '3a-Anbieter';

  @override
  String get providersRanking => 'Ranking';

  @override
  String get providersAll => 'Alle Anbieter';

  @override
  String get providersProducts => 'Produkte';

  @override
  String get providersFilter => 'Filtern';

  @override
  String get providersCompare => 'Vergleichen';

  @override
  String get providersFees => 'Gebühren (%)';

  @override
  String get providersFeeComparison => 'Gebührenvergleich';

  @override
  String providersCompareSelected(int count) {
    return '$count Produkte vergleichen';
  }

  @override
  String get providersTapToCompare => 'Tippen zum Vergleichen';

  @override
  String get providersFeeShort => 'Gebühren';

  @override
  String get providersEquityShort => 'Aktien';

  @override
  String get providersReturnShort => 'Rend. 3J';

  @override
  String get providersEsgBadge => 'Nachhaltig';

  @override
  String get providersVisitWebsite => 'Website besuchen';

  @override
  String get providersWebsiteError => 'Der Link konnte nicht geöffnet werden';

  @override
  String get providersEmpty => 'Momentan keine Anbieter verfügbar';

  @override
  String get providersDigital => 'Digital';

  @override
  String get providersCategory => 'Kategorie';

  @override
  String get providersRiskLevel => 'Risiko';

  @override
  String get providersFeesDetail => 'Gebührendetails';

  @override
  String get providersTer => 'TER (Fondskosten)';

  @override
  String get providersAllInFee => 'Gesamtkosten';

  @override
  String get providersCustodyFee => 'Depotgebühr';

  @override
  String get providersEntryFee => 'Einstiegsgebühr';

  @override
  String get providersExitFee => 'Ausstiegsgebühr';

  @override
  String get providersPerformance => 'Rendite pro Jahr';

  @override
  String get providersPerformanceWindow => 'Letzte 5 Jahre';

  @override
  String get providersCategoryPassiveIndex => 'Indexfonds (passiv)';

  @override
  String get providersCategoryActiveManaged => 'Aktiv verwaltet';

  @override
  String get providersCategoryInsurance => 'Lebensversicherung 3a';

  @override
  String get providersCategorySavings => 'Sparkonto';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileLanguage => 'Sprache';

  @override
  String get profileAbout => 'Über';

  @override
  String get profileVersion => 'Version';

  @override
  String get profileApi => 'API-Server';

  @override
  String get profileSectionPersonal => 'Persönliche Angaben';

  @override
  String get profileSalary => 'Gehalt (CHF)';

  @override
  String get profileAge => 'Alter';

  @override
  String get profileCanton => 'Kanton';

  @override
  String get profileMunicipality => 'Gemeinde';

  @override
  String get profileHas3a => 'Säule 3a';

  @override
  String get profile3aBalance => '3a-Guthaben (CHF)';

  @override
  String get profileMaritalStatus => 'Familienstand';

  @override
  String get profileGoalSection => 'Ziel';

  @override
  String get profileTargetRate => 'Ziel-Ersatzquote';

  @override
  String get profileAppearance => 'Erscheinungsbild';

  @override
  String get profileAppearanceSystem => 'System';

  @override
  String get profileAppearanceLight => 'Hell';

  @override
  String get profileAppearanceDark => 'Dunkel';

  @override
  String get profileSectionAccount => 'Konto';

  @override
  String get profileSectionSecurity => 'Sicherheit';

  @override
  String get profileSettingsSubtitle =>
      'Kanton, Einkommen, Situation und Konten';

  @override
  String get profileSelectCanton => 'Auswählen';

  @override
  String get profileBirthYear => 'Geburtsjahr';

  @override
  String get profileBirthYearInvalid => 'Ungültiges Geburtsjahr';

  @override
  String get profileSectionSituation => 'Finanzielle Situation';

  @override
  String get profileEmploymentStatus => 'Beruflicher Status';

  @override
  String get profileEmploymentEmployed => 'Angestellt';

  @override
  String get profileEmploymentSelfEmployed => 'Selbstständig';

  @override
  String get profileEmploymentUnemployed => 'Arbeitslos';

  @override
  String get profileEmploymentRetired => 'Pensioniert';

  @override
  String get profileMaritalDivorced => 'Geschieden';

  @override
  String get profileMaritalWidowed => 'Verwitwet';

  @override
  String get profileChildren => 'Anzahl Kinder';

  @override
  String get profileChildrenInvalid => 'Ungültige Anzahl Kinder';

  @override
  String get profileGrossAnnualIncome => 'Bruttojahreseinkommen (CHF)';

  @override
  String get profileNetAnnualIncome => 'Nettojahreseinkommen (CHF, optional)';

  @override
  String get profileFieldRequired => 'Pflichtfeld';

  @override
  String get profileAmountInvalid => 'Ungültiger Betrag';

  @override
  String get profileRateInvalid => 'Ungültiger Satz';

  @override
  String get profileSaved => 'Profil gespeichert';

  @override
  String get profileSectionPillar2 => 'BVG-Konten (2. Säule)';

  @override
  String get profileSectionPillar3a => '3a-Konten';

  @override
  String get profileEmptyPillar2 => 'Kein BVG-Konto erfasst';

  @override
  String get profileEmptyPillar3a => 'Kein 3a-Konto erfasst';

  @override
  String get profilePillar2DefaultName => 'BVG-Konto';

  @override
  String get profileAddPillar2 => 'BVG-Konto hinzufügen';

  @override
  String get profileAddPillar3a => '3a-Konto hinzufügen';

  @override
  String get profilePillar2New => 'Neues BVG-Konto';

  @override
  String get profilePillar2Edit => 'BVG-Konto bearbeiten';

  @override
  String get profilePillar3aNew => 'Neues 3a-Konto';

  @override
  String get profilePillar3aEdit => '3a-Konto bearbeiten';

  @override
  String get profileProviderName => 'Anbieter';

  @override
  String get profileCurrentCapital => 'Aktuelles Kapital (CHF)';

  @override
  String get profileConversionRate => 'Umwandlungssatz (%)';

  @override
  String get profileAnnualContribution => 'Jährlicher Beitrag (CHF)';

  @override
  String get profileAdvancedSection => 'Erweitert';

  @override
  String get profileInsuredSalary => 'Versicherter Lohn (CHF)';

  @override
  String get profileCoordinationDeduction => 'Koordinationsabzug (CHF)';

  @override
  String get profileAnnualSupraContribution =>
      'Jährlicher überobligatorischer Beitrag (CHF)';

  @override
  String get profileCurrentBalance => 'Aktuelles Guthaben (CHF)';

  @override
  String get profileInterestRate => 'Zins / Rendite (%)';

  @override
  String get profileAccountType => 'Kontotyp';

  @override
  String get profileAccountTypeBank => 'Bank';

  @override
  String get profileAccountTypeInsurance => 'Versicherung';

  @override
  String get profileVestedBenefits => 'Freizügigkeitskonto';

  @override
  String get profileDeleteAccountTitle => 'Dieses Konto löschen?';

  @override
  String get profileDeleteAccountBody => 'Diese Aktion ist endgültig.';

  @override
  String get profileAccountSaved => 'Konto gespeichert';

  @override
  String get profileAccountDeleted => 'Konto gelöscht';

  @override
  String get ocrScanSalaryButton => 'Lohnausweis scannen';

  @override
  String get ocrScanLppButton => 'LPP-Ausweis scannen';

  @override
  String get ocrScanSalaryTitle => 'Lohnausweis';

  @override
  String get ocrScanLppTitle => 'LPP-Ausweis';

  @override
  String get ocrSourceCamera => 'Foto aufnehmen';

  @override
  String get ocrSourceGallery => 'Bild auswählen';

  @override
  String get ocrScanning => 'Dokument wird analysiert…';

  @override
  String get ocrNoTextFound =>
      'Kein Text auf dem Bild erkannt. Versuchen Sie es mit einem schärferen Foto erneut.';

  @override
  String get ocrNoValuesFound =>
      'Keine Werte auf diesem Dokument erkannt. Versuchen Sie es mit einem anderen Foto erneut.';

  @override
  String get ocrProposalTitle => 'Erkannte Werte';

  @override
  String get ocrProposalBody =>
      'Prüfen und passen Sie die Werte an, bevor Sie sie übernehmen.';

  @override
  String get ocrPrivacyNote =>
      'Lokale Analyse: Das Bild verlässt Ihr Gerät nie.';

  @override
  String get ocrApply => 'Übernehmen';

  @override
  String get ocrScanError =>
      'Die Analyse ist fehlgeschlagen. Versuchen Sie es mit einem schärferen Foto erneut.';

  @override
  String get ocrApplied => 'Felder vorausgefüllt — bitte prüfen und speichern';

  @override
  String get onboardingPillarsTitle => 'Ihre Rente basiert auf 3 Säulen';

  @override
  String get onboardingPillarsDesc =>
      'Das Schweizer Vorsorgesystem ist weltweit einzigartig. Entdecken Sie, wie es funktioniert.';

  @override
  String get onboardingDetailsTitle => 'Wie funktioniert es?';

  @override
  String get onboardingDetailsDesc =>
      'Jede Säule hat eine andere Rolle in Ihrer Rente';

  @override
  String get onboardingP1Title => '1. Säule (AHV)';

  @override
  String get onboardingP1Desc =>
      'Obligatorische Grundrente, finanziert durch Ihre Lohnbeiträge';

  @override
  String get onboardingP2Title => '2. Säule (BVG)';

  @override
  String get onboardingP2Desc =>
      'Berufliche Vorsorge über Ihren Arbeitgeber, angespartes Kapital';

  @override
  String get onboardingP3aTitle => 'Säule 3a';

  @override
  String get onboardingP3aDesc =>
      'Freiwilliges Sparen mit Steuervorteilen, Sie entscheiden';

  @override
  String get onboardingFeaturesTitle => 'PocketPillar hilft Ihnen...';

  @override
  String get onboardingFeaturesDesc =>
      'Alles, was Sie für Ihre Vorsorge brauchen';

  @override
  String get onboardingFeatureScore => 'Bewerten Sie Ihre Vorsorge-Gesundheit';

  @override
  String get onboardingFeatureSimulate => 'Simulieren Sie Ihre Rente im Detail';

  @override
  String get onboardingFeatureCompare => '3a-Anbieter vergleichen';

  @override
  String get onboardingFeatureTips => 'Personalisierte Tipps erhalten';

  @override
  String get onboardingReadyTitle => 'Los geht\'s!';

  @override
  String get onboardingReadyDesc =>
      'Es dauert 2 Minuten. Erfahren Sie, wie es um Ihre Vorsorge steht.';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStart => 'Starten';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingReplay => 'Einführung erneut anzeigen';

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei PocketPillar';

  @override
  String get onboardingWelcomeDesc =>
      'Optimieren Sie Ihre Schweizer Vorsorge. Simulieren, vergleichen und maximieren Sie Ihre 2. und 3. Säule.';

  @override
  String get onboardingCalculatorTitle => 'Intelligente Rechner';

  @override
  String get onboardingCalculatorDesc =>
      'Analysieren Sie Ihre BVG-Lücke, berechnen Sie Ihre kantonale 3a-Steuerersparnis und planen Sie Ihre Rente.';

  @override
  String get onboardingProvidersTitle => 'Anbieter vergleichen';

  @override
  String get onboardingProvidersDesc =>
      'VIAC, Frankly, finpension und mehr. Finden Sie die 3. Säule mit den besten Gebühren und Renditen.';

  @override
  String get pillar1Short => '1. Säule';

  @override
  String get pillar1Name => 'AHV / IV';

  @override
  String get pillar2Short => '2. Säule';

  @override
  String get pillar2Name => 'BVG / Pensionskasse';

  @override
  String get pillar3aShort => 'Säule 3a';

  @override
  String get pillar3aName => 'Private Vorsorge';

  @override
  String get guidedTitle => 'Ihre Bilanz';

  @override
  String get guidedResultsTitle => 'Ihre Ergebnisse';

  @override
  String get guidedSalaryTitle => 'Wie hoch ist Ihr Jahresgehalt?';

  @override
  String get guidedSalarySubtitle => 'Bruttogehalt vor Abzügen';

  @override
  String get guidedAgeTitle => 'Wie alt sind Sie?';

  @override
  String get guidedAgeSubtitle =>
      'Ihr Alter beeinflusst Ihre Beiträge und Prognosen';

  @override
  String get guidedAgeYears => 'Jahre';

  @override
  String get guidedCantonTitle => 'Wo wohnen Sie?';

  @override
  String get guidedCantonSubtitle => 'Die Steuersätze variieren je nach Kanton';

  @override
  String get guided3aTitle => 'Haben Sie eine Säule 3a?';

  @override
  String get guided3aSubtitle =>
      'Die Säule 3a ist Ihr persönliches Sparen mit Steuervorteilen';

  @override
  String get guided3aQuestion => 'Sparen Sie in einer 3a?';

  @override
  String get guided3aBalance => 'Ungefähres Guthaben';

  @override
  String get guidedYes => 'Ja';

  @override
  String get guidedNo => 'Nein';

  @override
  String get guidedNext => 'Weiter';

  @override
  String get guidedBack => 'Zurück';

  @override
  String get guidedSeeResults => 'Meine Ergebnisse sehen';

  @override
  String get guidedMaritalTitle => 'Wie ist Ihr Familienstand?';

  @override
  String get guidedMaritalSubtitle =>
      'Ihr Familienstand beeinflusst Ihre Steuerberechnung';

  @override
  String get guidedMaritalSingle => 'Ledig';

  @override
  String get guidedMaritalMarried => 'Verheiratet';

  @override
  String get guidedMaritalPartnership => 'Eingetragene Partnerschaft';

  @override
  String get guidedSituationTitle => 'Ihre Situation';

  @override
  String get guidedSituationSubtitle => 'Alter, Kanton und Familienstand';

  @override
  String get guidedPillar2Title => 'Ihre 2. Säule (BVG)';

  @override
  String get guidedPillar2Subtitle =>
      'Kapital und Beiträge Ihrer Pensionskasse — siehe Vorsorgeausweis';

  @override
  String guidedStepOf(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String resultsSummaryPhrase(int percent) {
    return 'Ihre Rente wird $percent% Ihres aktuellen Einkommens decken';
  }

  @override
  String resultsPensionMonthly(String amount) {
    return 'Das sind etwa $amount pro Monat';
  }

  @override
  String get resultsYourPillars => 'Ihre 3 Säulen';

  @override
  String get resultsReplacementRate => 'Ersatzquote';

  @override
  String get resultsYearsToRetirement => 'Jahre bis zur Rente';

  @override
  String get resultsHowCalculated => 'Wie werden diese Zahlen berechnet?';

  @override
  String get resultsTaxSavings => 'Steuerersparnisse';

  @override
  String get resultsAnnualSavings => 'Ersparnis pro Jahr';

  @override
  String resultsEffectiveReturn(String rate) {
    return 'Effektive Rendite: $rate%';
  }

  @override
  String get resultsWhatToDo => 'Was jetzt tun?';

  @override
  String get resultsRecOpen3a =>
      'Eröffnen Sie eine Säule 3a, um Steuern zu sparen und Ihre Rente vorzubereiten';

  @override
  String resultsRecMax3a(String amount) {
    return 'Zahlen Sie das Maximum von $amount in die 3a ein, um Ihre Steuern zu optimieren';
  }

  @override
  String resultsRecTaxSaving(String amount) {
    return 'Sie sparen $amount Steuern pro Jahr dank der 3a';
  }

  @override
  String get resultsRecIncreaseCoverage =>
      'Ihre Deckung liegt unter 60%. Erwägen Sie einen BVG-Einkauf oder erhöhen Sie Ihre 3a-Beiträge.';

  @override
  String get resultsRecBvgBuyback =>
      'Ein BVG-Einkauf könnte Ihre Rentenlücke schließen und Ihre Steuern senken';

  @override
  String get resultsAboveAverage => 'Über dem Durchschnitt für Ihr Alter';

  @override
  String get resultsBelowAverage => 'Unter dem Durchschnitt für Ihr Alter';

  @override
  String get resultsNearAverage => 'Im Durchschnitt für Ihr Alter';

  @override
  String get resultsCompareToggle => 'Mit/ohne 3a vergleichen';

  @override
  String get resultsCompareWith3a => 'Mit 3a (pro Monat)';

  @override
  String get resultsCompareWithout3a => 'Ohne 3a (pro Monat)';

  @override
  String get resultsDeltaLabel => 'Unterschied';

  @override
  String get resultsApproximateBadge => 'Ungefähre Schätzung (offline)';

  @override
  String get cantonPickerTitle => 'Kanton wählen';

  @override
  String get cantonPickerSearch => 'Kanton suchen';

  @override
  String get municipalityPickerTitle => 'Gemeinde wählen';

  @override
  String get municipalityPickerSearch => 'Gemeinde suchen';

  @override
  String get municipalityCantonalAverageOption =>
      'Kantonaler Durchschnitt (Gemeinde nicht aufgeführt)';

  @override
  String get municipalityPickerEmpty =>
      'Für diesen Kanton sind keine Gemeinden abgedeckt — der kantonale Durchschnitt wird verwendet.';

  @override
  String get municipalityPickerNoResults => 'Keine Ergebnisse';

  @override
  String get municipalityPickerError =>
      'Gemeinden konnten nicht geladen werden';

  @override
  String get municipalitySelectCantonFirst => 'Wählen Sie zuerst einen Kanton';

  @override
  String get helpSectionWhat => 'Was ist das?';

  @override
  String get helpSectionWhy => 'Warum ist das wichtig?';

  @override
  String get helpSectionWhere => 'Wo finde ich diese Info?';

  @override
  String get helpPillarSystemTitle => '3-Säulen-System';

  @override
  String get helpPillarSystemExplanation =>
      'Die Schweiz organisiert die Altersvorsorge in 3 Stufen: eine Grundrente (AHV), eine berufliche Vorsorge (BVG) und ein privates Sparen (3a). Zusammen sollen sie Ihren Lebensstandard erhalten.';

  @override
  String get helpPillarSystemWhy =>
      'Dieses System zu verstehen hilft Ihnen, Optimierungsmöglichkeiten für Ihre Rente zu erkennen.';

  @override
  String get helpPillarSystemWhere =>
      'Ihr Lohnausweis und Ihr jährlicher Vorsorgeausweis zeigen Ihre Beiträge.';

  @override
  String get helpPillar1AvsTitle => 'AHV (1. Säule)';

  @override
  String get helpPillar1AvsExplanation =>
      'Die AHV ist die Grundrente, die alle bei der Pensionierung erhalten. Sie wird durch Ihre Lohnbeiträge (automatisch abgezogen) und die Ihres Arbeitgebers finanziert.';

  @override
  String get helpPillar1AvsWhy =>
      'Die AHV allein deckt nur etwa 40% Ihres letzten Gehalts. Deshalb sind die 2. und 3. Säule wichtig.';

  @override
  String get helpPillar1AvsWhere =>
      'Fordern Sie einen AHV-Kontoauszug auf der Website Ihrer kantonalen Ausgleichskasse an.';

  @override
  String get helpPillar2BvgTitle => 'BVG / 2. Säule';

  @override
  String get helpPillar2BvgExplanation =>
      'Die berufliche Vorsorge ist ein obligatorisches Sparen, das von Ihrem Arbeitgeber verwaltet wird. Sie und Ihr Arbeitgeber zahlen jeden Monat ein. Dieses Kapital sammelt sich an und wird Ihnen bei der Pensionierung ausbezahlt.';

  @override
  String get helpPillar2BvgWhy =>
      'Es ist oft der größte Betrag Ihrer Rente. Prüfen Sie Ihren jährlichen Vorsorgeausweis, um Ihr Kapital zu kennen.';

  @override
  String get helpPillar2BvgWhere =>
      'Ihr jährlicher Vorsorgeausweis, von der Pensionskasse Ihres Arbeitgebers gesendet.';

  @override
  String get helpPillar3aTitle => 'Säule 3a';

  @override
  String get helpPillar3aExplanation =>
      'Die Säule 3a ist freiwilliges Sparen, das Sie selbst verwalten. Sie wählen Ihren Anbieter, den Betrag und die Anlageart. Das Geld ist bis zur Pensionierung blockiert (mit Ausnahmen).';

  @override
  String get helpPillar3aWhy =>
      'Jeder in die 3a eingezahlte Franken ist steuerlich absetzbar. Es ist der einfachste Weg, weniger Steuern zu zahlen und gleichzeitig die Rente vorzubereiten.';

  @override
  String get helpPillar3aWhere =>
      'Melden Sie sich auf der Website Ihres 3a-Anbieters (Bank oder App) an, um Ihr Guthaben zu sehen.';

  @override
  String get helpCoordinatedSalaryTitle => 'Koordinierter Lohn';

  @override
  String get helpCoordinatedSalaryExplanation =>
      'Das ist der Teil Ihres Gehalts, auf dem Ihre BVG-Beiträge berechnet werden. Ein fester Betrag (Koordinationsabzug) wird von Ihrem Bruttogehalt abgezogen.';

  @override
  String get helpCoordinatedSalaryWhy =>
      'Je höher er ist, desto größer sind Ihre Beiträge und Ihre zukünftige Rente.';

  @override
  String get helpCoordinatedSalaryWhere =>
      'Auf Ihrem jährlichen BVG-Vorsorgeausweis angegeben.';

  @override
  String get helpConversionRateTitle => 'Umwandlungssatz';

  @override
  String get helpConversionRateExplanation =>
      'Dieser Prozentsatz wandelt Ihr BVG-Kapital in eine Jahresrente um. Zum Beispiel: Bei 6.8% und CHF 500\'000 Kapital erhalten Sie CHF 34\'000 pro Jahr.';

  @override
  String get helpConversionRateWhy =>
      'Ein höherer Satz = eine bessere Rente. Der gesetzliche Mindestsatz beträgt 6.8%, aber Kassen können auf dem überobligatorischen Teil einen niedrigeren Satz anwenden.';

  @override
  String get helpConversionRateWhere =>
      'Auf Ihrem jährlichen Vorsorgeausweis oder im Reglement Ihrer Pensionskasse angegeben.';

  @override
  String get helpBvgCapitalTitle => 'BVG-Kapital';

  @override
  String get helpBvgCapitalExplanation =>
      'Das ist das in Ihrer Pensionskasse (2. Säule) angesammelte Geld. Ihre und die Beiträge Ihres Arbeitgebers kommen jeden Monat hinzu, plus Zinsen.';

  @override
  String get helpBvgCapitalWhy =>
      'Es ist normalerweise Ihr größtes Vermögen. Es bestimmt direkt die Höhe Ihrer Rente bei der Pensionierung.';

  @override
  String get helpBvgCapitalWhere =>
      'Ihr jährlicher Vorsorgeausweis, Rubrik \'Altersguthaben\'.';

  @override
  String get helpReplacementRateTitle => 'Ersatzquote';

  @override
  String get helpReplacementRateExplanation =>
      'Der Prozentsatz Ihres letzten Gehalts, den Sie bei der Pensionierung erhalten. Zum Beispiel: 65% bedeutet, dass Sie bei CHF 100\'000 Gehalt etwa CHF 65\'000 pro Jahr erhalten.';

  @override
  String get helpReplacementRateWhy =>
      'Das Ziel liegt normalerweise bei 60-80%. Unter 60% könnte Ihr Lebensstandard bei der Pensionierung deutlich sinken.';

  @override
  String get helpReplacementRateWhere =>
      'PocketPillar berechnet ihn für Sie anhand Ihrer Daten. Sie können ihn auch bei Ihrer Pensionskasse anfragen.';

  @override
  String get helpPensionGapTitle => 'Rentenlücke';

  @override
  String get helpPensionGapExplanation =>
      'Die Differenz zwischen der Rente, die Sie gesetzlich erhalten sollten, und dem, was Sie tatsächlich erhalten. Wenn Ihr Arbeitgeber das gesetzliche Minimum einzahlt, kann die Lücke null sein.';

  @override
  String get helpPensionGapWhy =>
      'Eine positive Lücke bedeutet, dass Sie unter dem gesetzlichen Minimum liegen und könnte auf ein Problem mit Ihren Beiträgen hinweisen.';

  @override
  String get helpPensionGapWhere =>
      'Vergleichen Sie Ihren Vorsorgeausweis mit den BVG-Mindestbeträgen oder verwenden Sie den PocketPillar-Rechner.';

  @override
  String get helpTaxSavings3aTitle => '3a-Steuerersparnisse';

  @override
  String get helpTaxSavings3aExplanation =>
      'Jeder in die 3a eingezahlte Franken reduziert Ihr steuerbares Einkommen. Je nach Kanton und Einkommen können Sie zwischen CHF 1\'500 und CHF 3\'000 Steuern pro Jahr sparen.';

  @override
  String get helpTaxSavings3aWhy =>
      'Das ist Geld, das Sie behalten, statt es dem Fiskus zu geben. Je mehr Sie verdienen, desto größer die Ersparnis.';

  @override
  String get helpTaxSavings3aWhere =>
      'Verwenden Sie den PocketPillar-Steuerrechner und wählen Sie Ihren Kanton.';

  @override
  String get helpBvgBuybackTitle => 'BVG-Einkauf';

  @override
  String get helpBvgBuybackExplanation =>
      'Eine freiwillige Einzahlung in Ihre 2. Säule, um Beitragslücken zu schließen. Zum Beispiel, wenn Sie einige Jahre nicht in der Schweiz gearbeitet haben.';

  @override
  String get helpBvgBuybackWhy =>
      'Der Betrag ist im Einzahlungsjahr 100% steuerlich absetzbar. Es ist eine sehr effektive Steuerstrategie.';

  @override
  String get helpBvgBuybackWhere =>
      'Ihr Vorsorgeausweis zeigt den maximalen möglichen Einkaufsbetrag. Kontaktieren Sie Ihre Pensionskasse.';

  @override
  String get helpRetirementAgeTitle => 'Rentenalter';

  @override
  String get helpRetirementAgeExplanation =>
      'In der Schweiz liegt das Referenzalter bei 65 Jahren (AHV-21-Übergang für Frauen der Jahrgänge 1961-1963: 64,5 Jahre im 2026). Frühzeitige Pensionierung ab 58 oder Aufschub bis 70 möglich.';

  @override
  String get helpRetirementAgeWhy =>
      'Jedes Jahr Vorpensionierung reduziert Ihre Rente. Jedes Jahr Aufschub erhöht sie. Es ist eine wichtige finanzielle Entscheidung.';

  @override
  String get helpRetirementAgeWhere =>
      'Website des BSV (Bundesamt für Sozialversicherungen) oder Ihre kantonale Ausgleichskasse.';

  @override
  String get helpContribution3aMaxTitle => '3a-Obergrenze';

  @override
  String get helpContribution3aMaxExplanation =>
      'Der maximale 3a-Beitrag ist gesetzlich festgelegt. 2026 sind es CHF 7\'258 mit 2. Säule oder CHF 36\'288 ohne 2. Säule (max 20% des Nettoeinkommens).';

  @override
  String get helpContribution3aMaxWhy =>
      'Den Maximalbetrag einzuzahlen ist fast immer vorteilhaft: Sie maximieren Ihre Steuerersparnis.';

  @override
  String get helpContribution3aMaxWhere =>
      'Der Betrag wird jährlich vom BSV veröffentlicht. PocketPillar ist immer aktuell.';

  @override
  String get helpGrossIncomeTitle => 'Bruttoeinkommen';

  @override
  String get helpGrossIncomeExplanation =>
      'Ihr Jahresgehalt vor allen Abzügen (Steuern, AHV, BVG, etc.). Es ist der auf Ihrem Arbeitsvertrag angegebene Betrag.';

  @override
  String get helpGrossIncomeWhy =>
      'Es ist die Berechnungsgrundlage für Ihre Beiträge und Rentenprognosen.';

  @override
  String get helpGrossIncomeWhere =>
      'Ihr Arbeitsvertrag, Ihre monatliche Lohnabrechnung oder Ihr jährlicher Lohnausweis.';

  @override
  String get helpEffectiveReturnTitle => 'Effektive Rendite';

  @override
  String get helpEffectiveReturnExplanation =>
      'Die tatsächliche Rendite Ihrer 3a-Einzahlung unter Berücksichtigung der Steuerersparnis. Es ist wie ein sofortiger Bonus auf Ihre Investition.';

  @override
  String get helpEffectiveReturnWhy =>
      'Eine effektive Rendite von 30% bedeutet, dass Sie für CHF 7\'258 Einzahlung etwa CHF 2\'177 an Steuerersparnissen zurückbekommen.';

  @override
  String get helpEffectiveReturnWhere =>
      'Verwenden Sie den PocketPillar-Steuerrechner, um Ihre effektive Rendite je nach Kanton zu sehen.';

  @override
  String get helpAnnualContributionTitle => 'Jährlicher BVG-Beitrag';

  @override
  String get helpAnnualContributionExplanation =>
      'Das ist der Betrag, der jedes Jahr in Ihrer Pensionskasse gespart wird: Ihr Anteil UND der Ihres Arbeitgebers (er zahlt mindestens gleich viel). Es ist also nicht nur der Abzug auf Ihrer Lohnabrechnung.';

  @override
  String get helpAnnualContributionWhy =>
      'Die Projektion fügt dieses Sparen jedes Jahr bis zur Pensionierung hinzu, verzinst zum gesetzlichen Minimum von 1.25 %. Wer nur die eigene Hälfte angibt, unterschätzt das projizierte Kapital deutlich.';

  @override
  String get helpAnnualContributionWhere =>
      'Ihr jährlicher Vorsorgeausweis, Rubrik «Sparbeiträge» — Arbeitnehmer- und Arbeitgeberanteil zusammenzählen (Risikoprämien gehören nicht dazu).';

  @override
  String get helpWithdrawalTaxTitle => 'Steuer beim Kapitalbezug';

  @override
  String get helpWithdrawalTaxExplanation =>
      'Bezogenes Vorsorgekapital (3a oder Pensionskasse) wird einmalig besteuert — getrennt vom übrigen Einkommen und zu einem reduzierten Satz.';

  @override
  String get helpWithdrawalTaxWhy =>
      'Diese Steuer verringert den tatsächlich verfügbaren Betrag — deshalb zeigen wir Brutto- und geschätztes Nettokapital. Bezüge über mehrere Steuerjahre zu staffeln senkt sie oft (siehe «Gestaffelter Bezug»).';

  @override
  String get helpWithdrawalTaxWhere =>
      'Geschätzt mit den offiziellen Tarifen 2026 Ihres Kantons und Ihrer Gemeinde. Der genaue Betrag hängt von Ihrer Situation im Bezugsjahr ab.';

  @override
  String get tipMax3a2026Title => '3a-Maximum 2026';

  @override
  String get tipMax3a2026Body =>
      'Der 3a-Maximalbetrag für 2026 beträgt CHF 7\'258. Zahlen Sie ihn vor dem 31. Dezember ein, um Steuern zu sparen!';

  @override
  String get tipBvgBuybackTitle => 'BVG-Einkauf = doppelte Ersparnis';

  @override
  String get tipBvgBuybackBody =>
      'Ein BVG-Einkauf ist 100% steuerlich absetzbar UND erhöht Ihre Rente. Fragen Sie Ihre Kasse nach Ihrem Einkaufspotenzial.';

  @override
  String get tip3aTaxDeductionTitle => 'Die 3a reduziert Ihre Steuern';

  @override
  String get tip3aTaxDeductionBody =>
      'Jeder in die 3a eingezahlte Franken ist von Ihrem steuerbaren Einkommen abziehbar. Je nach Kanton kann das über 30% sofortige Rendite bedeuten!';

  @override
  String get tipStartEarlyTitle => 'Früh anfangen';

  @override
  String get tipStartEarlyBody =>
      'Mit 25 statt 35 in die 3a einzuzahlen kann Ihnen dank Zinseszinsen über CHF 100\'000 mehr bringen.';

  @override
  String get tipCompoundInterestTitle => 'Die Magie des Zinseszinses';

  @override
  String get tipCompoundInterestBody =>
      'Ihre Zinsen erzeugen selbst Zinsen. Über 30 Jahre verdoppelt eine 3a-Anlage mit 3% Rendite Ihr investiertes Kapital fast.';

  @override
  String get tipMultiple3aTitle => 'Mehrere 3a-Konten';

  @override
  String get tipMultiple3aBody =>
      'Mehrere 3a-Konten (bis zu 5) eröffnen ermöglicht gestaffelte Bezüge und reduziert die Kapitalauszahlungssteuer.';

  @override
  String get tipRetirementGapTitle => 'Die Rentenlücke';

  @override
  String get tipRetirementGapBody =>
      'Im Durchschnitt decken die 1. und 2. Säule nur 60% Ihres letzten Gehalts. Die 3a ist wesentlich, um diese Lücke zu schließen.';

  @override
  String get tip3PillarsTitle => 'Warum 3 Säulen?';

  @override
  String get tip3PillarsBody =>
      'Das Schweizer System verteilt das Risiko: der Staat (AHV), der Arbeitgeber (BVG) und Sie selbst (3a). Jeder spielt eine Rolle für Ihre finanzielle Sicherheit.';

  @override
  String get tipAvsMaxTitle => 'Maximale AHV-Rente';

  @override
  String get tipAvsMaxBody =>
      'Die maximale AHV-Rente beträgt CHF 2\'520/Monat für eine Einzelperson (2026). Auch Gutverdiener sind auf diesen Betrag begrenzt.';

  @override
  String get tipPillar2InterestTitle => 'BVG-Zinssatz';

  @override
  String get tipPillar2InterestBody =>
      'Ihr obligatorisches BVG-Kapital wird mit mindestens 1.25% pro Jahr verzinst. Manche Kassen bieten mehr auf dem überobligatorischen Teil.';

  @override
  String get tip3aWithdrawalTitle => 'Vorbezug der 3a';

  @override
  String get tip3aWithdrawalBody =>
      'Sie können Ihre 3a vor der Pensionierung beziehen, um eine Immobilie zu kaufen, sich selbstständig zu machen oder die Schweiz zu verlassen.';

  @override
  String get tipCantonTaxesTitle => 'Der Einfluss des Kantons';

  @override
  String get tipCantonTaxesBody =>
      'Die 3a-Steuerersparnis variiert stark nach Kanton. In Genf kann sie bei gleichem Einkommen doppelt so hoch sein wie in Zug.';

  @override
  String get bestmatchTitle => 'Meine ideale 3a finden';

  @override
  String get bestmatchSubtitle =>
      'Beantworten Sie einige Fragen, um die beste Säule 3a zu finden';

  @override
  String get bestmatchRiskQuestion => 'Wie möchten Sie Ihr Geld anlegen?';

  @override
  String get bestmatchRiskExplanation =>
      'Je höher die mögliche Rendite, desto mehr kann der Wert kurzfristig schwanken';

  @override
  String get bestmatchRiskConservativeTitle => 'Sicherheit zuerst';

  @override
  String get bestmatchRiskConservativeDesc =>
      'Mein Geld schwankt wenig, auch wenn es weniger einbringt';

  @override
  String get bestmatchRiskModerateTitle => 'Vorsichtig';

  @override
  String get bestmatchRiskModerateDesc =>
      'Ich akzeptiere kleine Schwankungen für eine bessere Rendite';

  @override
  String get bestmatchRiskBalancedTitle => 'Ausgewogen';

  @override
  String get bestmatchRiskBalancedDesc =>
      'Ein Mix aus Sicherheit und Rendite, am beliebtesten';

  @override
  String get bestmatchRiskGrowthTitle => 'Dynamisch';

  @override
  String get bestmatchRiskGrowthDesc =>
      'Ich strebe maximale Rendite an, vorübergehende Verluste machen mir nichts aus';

  @override
  String get bestmatchRiskAggressiveTitle => '100% Aktien';

  @override
  String get bestmatchRiskAggressiveDesc =>
      'Alles in Aktien für langfristig, ideal wenn die Rente noch weit weg ist';

  @override
  String get bestmatchRiskConservative => 'Konservativ (0-25% Aktien)';

  @override
  String get bestmatchRiskModerate => 'Moderat (25-50% Aktien)';

  @override
  String get bestmatchRiskBalanced => 'Ausgewogen (50-75% Aktien)';

  @override
  String get bestmatchRiskGrowth => 'Wachstum (75-100% Aktien)';

  @override
  String get bestmatchRiskAggressive => 'Aggressiv (100% Aktien)';

  @override
  String get bestmatchPreferences => 'Ihre Präferenzen';

  @override
  String get bestmatchMaxFee => 'Maximale Jahresgebühren';

  @override
  String get bestmatchFeeHint =>
      'Niedrige Gebühren = mehr Geld für Sie. Der Schweizer Durchschnitt liegt bei ca. 0.8%.';

  @override
  String get bestmatchEsg => 'Nachhaltige Anlage';

  @override
  String get bestmatchEsgHint =>
      'Schließt umweltverschmutzende Unternehmen, Waffen, Tabak aus';

  @override
  String get bestmatchFind => 'Die besten finden';

  @override
  String get bestmatchResultsTitle => 'Ihre besten Optionen';

  @override
  String get bestmatchNoResults => 'Keine Ergebnisse';

  @override
  String get bestmatchTryDifferent => 'Versuchen Sie es mit anderen Kriterien';

  @override
  String get bestmatchRestart => 'Neu starten';

  @override
  String get bestmatchScoreExplanation =>
      'Der Score kombiniert Gebühren, 3-Jahres-Rendite, Übereinstimmung mit Ihrem Risikoprofil und Nachhaltigkeit (ESG).';

  @override
  String get privacyLocalData =>
      'Ihre Finanzdaten werden auf gesicherten Servern in Europa (Irland) gespeichert. Sie dienen ausschliesslich der Bereitstellung des Dienstes. Biometrische Sperre und Zugangsdaten bleiben auf Ihrem Gerät.';

  @override
  String get privacyTitle => 'Datenschutzerklärung';

  @override
  String get privacySectionDataCollected => 'Erhobene Daten';

  @override
  String get privacyBodyDataCollected =>
      'PocketPillar erhebt Ihre E-Mail-Adresse, Ihre Finanzinformationen (Gehalt, Vorsorgeguthaben, Steuersituation) und die von Ihnen hochgeladenen Dokumente. Diese Daten sind für den Betrieb der App erforderlich.';

  @override
  String get privacySectionPurpose => 'Zweck der Verarbeitung';

  @override
  String get privacyBodyPurpose =>
      'Ihre Daten werden ausschließlich zur Berechnung Ihrer Vorsorgesituation, zur Generierung personalisierter Empfehlungen und zur sicheren Aufbewahrung Ihrer Vorsorgedokumente verwendet.';

  @override
  String get privacySectionStorage => 'Speicherung und Sicherheit';

  @override
  String get privacyBodyStorage =>
      'Ihr Profil und Ihre Finanzdaten werden auf gesicherten Servern in der EU (Irland) gespeichert. Zugangsdaten und Sitzungstoken bleiben im sicheren Speicher des Geräts (iOS-Keychain / Android-Keystore). Dokumente werden bei der Übertragung und im Ruhezustand verschlüsselt. Der biometrische Zugang (Face ID / Touch ID) schützt das Öffnen der App.';

  @override
  String get privacySectionSharing => 'Datenweitergabe';

  @override
  String get privacyBodySharing =>
      'PocketPillar verkauft oder vermietet Ihre persönlichen Daten niemals. Sie werden nur an technische Subunternehmer übermittelt, die für den Dienst unerlässlich sind (Hosting Supabase, EU), und niemals zu Werbezwecken.';

  @override
  String get privacySectionRights => 'Ihre Rechte (nDSG)';

  @override
  String get privacyBodyRights =>
      'Gemäß dem neuen Schweizer Datenschutzgesetz (nDSG) haben Sie das Recht, auf Ihre Daten zuzugreifen, sie zu berichtigen, zu exportieren und jederzeit deren vollständige Löschung zu verlangen.';

  @override
  String get privacySectionSecurity => 'Sicherheitsmaßnahmen';

  @override
  String get privacyBodySecurity =>
      'Sichere Authentifizierung mit Token (JWT), biometrische Sperre, verschlüsselte Speicherung der Zugangsdaten auf dem Gerät, Screenshot-Sperre auf Android, zeitlich begrenzte Download-URLs (5 Min.), Dateityp-Validierung.';

  @override
  String get privacySectionContact => 'Kontakt';

  @override
  String get privacyBodyContact =>
      'Bei Fragen zu Ihren persönlichen Daten: privacy@pocketpillar.ch';

  @override
  String get buybackTitle => 'BVG-Einkauf';

  @override
  String get buybackWhatTitle => 'Was ist das?';

  @override
  String get buybackWhatBody =>
      'Ein BVG-Einkauf ist eine freiwillige Einzahlung in Ihre Pensionskasse, um Beitragslücken zu schließen. Zum Beispiel, wenn Sie nicht immer in der Schweiz gearbeitet haben oder eine Gehaltserhöhung hatten.';

  @override
  String get buybackBenefitsTitle => 'Vorteile';

  @override
  String get buybackBenefitsBody =>
      'Der Betrag ist im Einzahlungsjahr 100% steuerlich absetzbar. Ihre zukünftige Rente steigt. Es ist eine der besten Steuerstrategien in der Schweiz.';

  @override
  String get buybackStepsTitle => 'Wie geht das?';

  @override
  String get buybackStepsBody =>
      '1. Prüfen Sie Ihren Vorsorgeausweis für den maximalen Einkaufsbetrag\n2. Kontaktieren Sie Ihre Pensionskasse\n3. Tätigen Sie die Einzahlung vor dem 31. Dezember\n4. Ziehen Sie den Betrag in Ihrer Steuererklärung ab';

  @override
  String get compareTitle => 'Vergleich';

  @override
  String get compareFees => 'Jahresgebühren';

  @override
  String get compareReturns => 'Durchschn. Rendite 3 Jahre';

  @override
  String get compareAllocation => 'Aktienanteil';

  @override
  String get compareScore => 'Score';

  @override
  String get compareFeesLabel => 'Gebühren';

  @override
  String get compareReturn3y => 'Rend. 3J';

  @override
  String get compareEsgLabel => 'Nachhaltig';

  @override
  String get compareEquity => 'Aktien';

  @override
  String get compareLowest => 'Am günstigsten';

  @override
  String get compareBestChoice => 'Beste Gesamtwahl';

  @override
  String get docTitle => 'Dokumente';

  @override
  String get docEmptyTitle => 'Keine Dokumente';

  @override
  String get docEmptyDescription =>
      'Fügen Sie Ihre Vorsorgedokumente hinzu, um sie sicher aufzubewahren';

  @override
  String get docDelete => 'Löschen';

  @override
  String get docUploadTitle => 'Dokument hinzufügen';

  @override
  String get docTypeLabel => 'Dokumenttyp';

  @override
  String get docIncludeYear => 'Jahr zuordnen';

  @override
  String get docYearLabel => 'Jahr';

  @override
  String get docChooseFile => 'Datei auswählen';

  @override
  String get docUploading => 'Wird hochgeladen...';

  @override
  String get docTypeSalarySlip => 'Lohnausweis';

  @override
  String get docTypeBvgStatement => 'BVG-Ausweis';

  @override
  String get docTypePillar3aStatement => 'Säule-3a-Auszug';

  @override
  String get docTypeTaxDeclaration => 'Steuererklärung';

  @override
  String get docTypeOther => 'Andere';

  @override
  String get docUploadSuccess => 'Dokument hinzugefügt';

  @override
  String get docDeleted => 'Dokument gelöscht';

  @override
  String get docDeleteConfirmTitle => 'Dieses Dokument löschen?';

  @override
  String get docDeleteConfirmBody => 'Diese Aktion ist endgültig.';

  @override
  String get docFileTooLarge =>
      'Die Datei überschreitet die maximale Grösse von 10 MB';

  @override
  String get docInvalidFile => 'Format nicht unterstützt (PDF, JPEG oder PNG)';

  @override
  String get docReadError => 'Datei kann nicht gelesen werden';

  @override
  String get docOpenError => 'Dokument kann nicht geöffnet werden';

  @override
  String get scenarioTitle => 'Lebensszenarien';

  @override
  String get scenarioSectionTitle =>
      'Simulieren Sie die Auswirkungen auf Ihre Rente';

  @override
  String get scenarioFooter =>
      'Diese Simulationen sind Richtwerte. Konsultieren Sie einen Berater für wichtige Entscheidungen.';

  @override
  String get scenarioMonth => 'Mt.';

  @override
  String get scenarioYear => 'Jahr';

  @override
  String get scenarioPrefillFailed =>
      'Profil nicht geladen — das Formular verwendet die Standardwerte.';

  @override
  String get scenario3aCatchupTitle => '3a-Nachkauf';

  @override
  String get scenario3aCatchupSubtitle =>
      'Holen Sie nicht eingezahlte Jahre nach (Reform 2025)';

  @override
  String get scenario3aCatchupInputSection => 'Ihre Situation';

  @override
  String get scenario3aCatchupYearsMissed => 'Jahre ohne Einzahlung';

  @override
  String get scenario3aCatchupResultSection => 'Nachkaufpotenzial';

  @override
  String get scenario3aCatchupMaxPerYear => 'Maximum pro Jahr';

  @override
  String get scenario3aCatchupTotalCatchup => 'Total möglicher Nachkauf';

  @override
  String get scenario3aCatchupTaxSaving => 'Geschätzte Steuerersparnis';

  @override
  String get scenario3aCatchupInfo =>
      'Seit 2025 können Sie bis zu 10 Jahre versäumte 3a-Beiträge nachholen. Sie müssen zuerst das laufende Jahr maximieren.';

  @override
  String get scenarioPropertyTitle => 'Immobilienkauf';

  @override
  String get scenarioPropertySubtitle =>
      'Auswirkungen des WEF-Bezugs auf Ihre Rente';

  @override
  String get scenarioPropertyInputSection => 'Beträge';

  @override
  String get scenarioPropertyBvgCapital => 'Aktuelles BVG-Kapital';

  @override
  String get scenarioPropertyWithdrawal => 'Bezugsbetrag';

  @override
  String get scenarioPropertyMaxWithdrawal => 'Max. erlaubter Bezug';

  @override
  String get scenarioPropertyEffectiveWithdrawal => 'Effektiver Bezug';

  @override
  String get scenarioPropertyImpactSection => 'Auswirkungen auf die Rente';

  @override
  String get scenarioPropertyCapitalWithout =>
      'Kapital bei Pensionierung (ohne Bezug)';

  @override
  String get scenarioPropertyCapitalWith =>
      'Kapital bei Pensionierung (mit Bezug)';

  @override
  String get scenarioPropertyPensionLoss => 'Monatlicher Rentenverlust';

  @override
  String get scenarioDivorceTitle => 'Scheidung';

  @override
  String get scenarioDivorceSubtitle =>
      'BVG-Teilung und Auswirkungen auf die Rente';

  @override
  String get scenarioDivorceMySection => 'Ihr BVG';

  @override
  String get scenarioDivorceMyCapitalMarriage => 'Kapital bei Heirat';

  @override
  String get scenarioDivorceMyCapitalNow => 'Aktuelles Kapital';

  @override
  String get scenarioDivorceSpouseSection => 'BVG des Ehepartners';

  @override
  String get scenarioDivorceSpouseCapitalMarriage => 'Kapital bei Heirat';

  @override
  String get scenarioDivorceSpouseCapitalNow => 'Aktuelles Kapital';

  @override
  String get scenarioDivorceYearsMarried => 'Ehejahre';

  @override
  String get scenarioDivorceResultSection => 'Teilungsergebnis';

  @override
  String get scenarioDivorceTotalMarriageCapital =>
      'Während der Ehe angespartes Kapital';

  @override
  String get scenarioDivorceMyShare => 'Ihr Anteil (50%)';

  @override
  String get scenarioDivorceTransfer => 'Übertragung';

  @override
  String get scenarioDivorceCapitalAfter => 'Ihr Kapital nach Scheidung';

  @override
  String get scenarioWithdrawalTitle => 'Gestaffelter Bezug';

  @override
  String get scenarioWithdrawalSubtitle =>
      'Optimieren Sie die Besteuerung Ihrer 3a-Bezüge';

  @override
  String get scenarioWithdrawalInputSection => 'Ihre Guthaben';

  @override
  String get scenarioWithdrawal3aBalance => '3a-Gesamtsaldo';

  @override
  String get scenarioWithdrawalAccounts => 'Anzahl 3a-Konten';

  @override
  String get scenarioWithdrawalPillar2Capital => 'BVG-Kapital als Kapitalbezug';

  @override
  String get scenarioWithdrawalComparison => 'Steuervergleich';

  @override
  String get scenarioWithdrawalSaving => 'Steuerersparnis';

  @override
  String get scenarioWithdrawalTip =>
      'In der Schweiz werden Kapitalbezüge progressiv besteuert. Durch Verteilung der Bezüge auf mehrere Jahre bleiben Sie in niedrigeren Steuerstufen.';

  @override
  String get scenarioDivorcePensionImpact => 'Auswirkung auf die Jahresrente';

  @override
  String get scenario3aCatchupStatusEmployed => 'Angestellt (mit 2. Säule)';

  @override
  String get scenario3aCatchupStatusSelfEmployed =>
      'Selbständig (ohne 2. Säule)';

  @override
  String get scenario3aCatchupEligibleYears => 'Nachholbare Jahre';

  @override
  String get scenario3aCatchupCurrentYearGap =>
      'Zuerst einzahlen (laufendes Jahr)';

  @override
  String get scenario3aCatchupMarginalRate => 'Geschätzter Grenzsatz';

  @override
  String get scenario3aCatchupYearlySection => 'Details pro Jahr';

  @override
  String get scenarioWithdrawalStrategyLumpSum => 'Einmalbezug';

  @override
  String scenarioWithdrawalStrategyStaggered(int years) {
    return 'Gestaffelt über $years Jahre';
  }

  @override
  String get scenarioWithdrawalBestStrategy => 'Beste Strategie';

  @override
  String get scenarioWithdrawalEffectiveRate => 'Effektiver Steuersatz';

  @override
  String get scenarioDivorceAvsImpact =>
      'Geschätzte Auswirkung auf die AHV-Rente';

  @override
  String get scenarioDivorceDisclaimer =>
      'Richtwert-Simulation der gesetzlichen BVG-Teilung (50/50 der während der Ehe angesparten Guthaben). Sie stellt keine Rechtsberatung dar.';

  @override
  String get scenarioDivorceYouReceive => 'Sie erhalten';

  @override
  String get scenarioDivorceYouPay => 'Sie zahlen';

  @override
  String get scenarioDivorceCapitalExceedsNow =>
      'Das Kapital bei Heirat darf das aktuelle Kapital nicht übersteigen';

  @override
  String get pdfTitle => 'Vorsorgebilanz PocketPillar';

  @override
  String get pdfExportButton => 'Bilanz als PDF exportieren';

  @override
  String get pdfSectionTitle => 'Exportieren';

  @override
  String get pdfAge => 'Alter';

  @override
  String get pdfSalary => 'Gehalt';

  @override
  String get pdfCanton => 'Kanton';

  @override
  String get pdfPillarsTitle => 'Ihre 3 Säulen';

  @override
  String get pdfPillar1 => '1. Säule (AHV)';

  @override
  String get pdfPillar2 => '2. Säule (BVG)';

  @override
  String get pdfPillar3a => 'Säule 3a';

  @override
  String get pdfProjectionTitle => 'Rentenprognose';

  @override
  String get pdfRetirementAge => 'Rentenalter';

  @override
  String get pdfYearsRemaining => 'Verbleibende Jahre';

  @override
  String get pdfReplacementRate => 'Ersatzquote';

  @override
  String get pdfAnnualIncome => 'Geschätztes Jahreseinkommen';

  @override
  String get pdfMonthlyIncome => 'Geschätztes Monatseinkommen';

  @override
  String get pdfTaxTitle => 'Steuerersparnis (3a)';

  @override
  String pdfTaxDetail(String amount) {
    return 'Geschätzte jährliche Ersparnis: $amount';
  }

  @override
  String get pdfRecommendationsTitle => 'Empfehlungen';

  @override
  String get pdfRecOpen3a =>
      'Eröffnen Sie eine Säule 3a, um Steuervorteile zu nutzen und Ihre Vorsorge zu verbessern.';

  @override
  String pdfRecMax3a(String amount) {
    return 'Maximieren Sie Ihren jährlichen 3a-Beitrag ($amount), um Ihre Steuerersparnis zu optimieren.';
  }

  @override
  String get pdfRecIncreaseCoverage =>
      'Ihre Ersatzquote liegt unter 60%. Erwägen Sie einen BVG-Einkauf oder eine Erhöhung Ihrer 3a-Ersparnisse.';

  @override
  String get pdfRecGoodTrack =>
      'Sie sind auf dem richtigen Weg! Sparen Sie weiterhin regelmässig.';

  @override
  String get generalSimulationDisclaimer =>
      'Unverbindliche Simulation: offizielle Tarife 2026, berechnet auf dem Bruttoeinkommen (ohne Ihre individuellen Abzüge). PocketPillar liefert Informationen, keine Anlageberatung (FIDLEG).';

  @override
  String get pdfDisclaimer =>
      'Dieses Dokument dient nur zu Informationszwecken und stellt keine Finanzberatung dar. Die Prognosen basieren auf Schätzungen und können abweichen. Konsultieren Sie einen Finanzberater für personalisierte Empfehlungen. PocketPillar © 2026.';

  @override
  String get checklistCompleted => 'erledigt';

  @override
  String get checklistAllDone => 'Alles erledigt!';

  @override
  String get checklistCardTitle => 'Jahresend-Checkliste';

  @override
  String checklistCardRemaining(int count) {
    return '$count Aktionen übrig';
  }

  @override
  String get checklistMax3aTitle => 'Säule 3a maximieren';

  @override
  String get checklistMax3aDescription =>
      'Zahlen Sie den Höchstbetrag vor dem 31. Dezember ein, um Ihre Steuern zu optimieren.';

  @override
  String checklistMax3aValue(String max) {
    return 'Maximum: $max';
  }

  @override
  String get checklistBvgBuybackTitle => 'BVG-Einkauf prüfen';

  @override
  String get checklistBvgBuybackDescription =>
      'Kontaktieren Sie Ihre Pensionskasse, um Ihr Einkaufspotenzial zu erfahren.';

  @override
  String get checklistCertificateTitle => 'Vorsorgeausweis anfordern';

  @override
  String get checklistCertificateDescription =>
      'Fordern Sie Ihren jährlichen BVG-Ausweis bei Ihrem Arbeitgeber oder Ihrer Pensionskasse an.';

  @override
  String get checklistTaxDocsTitle => 'Steuerbelege vorbereiten';

  @override
  String get checklistTaxDocsDescription =>
      'Sammeln Sie Ihre 3a-Bescheinigungen und BVG-Ausweise für Ihre Steuererklärung.';

  @override
  String get checklistUpdateProfileTitle => 'Profil aktualisieren';

  @override
  String get checklistUpdateProfileDescription =>
      'Überprüfen Sie, ob Gehalt, Alter und Situation in PocketPillar aktuell sind.';

  @override
  String get checklistPlanNextTitle => 'Nächstes Jahr planen';

  @override
  String get checklistPlanNextDescription =>
      'Erkunden Sie Szenarien, um Ihre Vorsorgestrategie für nächstes Jahr festzulegen.';

  @override
  String get coupleScenarioTitle => 'Paar-Modus';

  @override
  String get coupleScenarioSubtitle => 'Simulieren Sie Ihre Rente zu zweit';

  @override
  String get coupleSectionTitle => 'Paar';

  @override
  String get couplePartnerHas3a => 'Partner hat eine Säule 3a';

  @override
  String get coupleCalculate => 'Paar-Rente berechnen';

  @override
  String get coupleYou => 'Sie';

  @override
  String get couplePartner => 'Partner';

  @override
  String get coupleAvs => 'AHV/Monat';

  @override
  String get coupleBvg => 'BVG/Monat';

  @override
  String get couplePillar3a => 'Projiziertes 3a-Kapital';

  @override
  String get coupleTotalMonthly => 'Total/Monat';

  @override
  String get coupleCombinedTitle => 'Kombiniertes Paareinkommen';

  @override
  String get coupleCombinedMonthly => 'pro Monat (kombinierte Rente)';

  @override
  String get coupleReplacementRate => 'Kombinierte Ersatzquote';

  @override
  String get coupleAvsCapWarning =>
      'Die AHV-Plafonierung für Ehepaare (150% des Einzelmaximums) gilt. Ihre kombinierte AHV-Rente wird gekürzt.';

  @override
  String get coupleAvsCapPhasing =>
      'Die Plafonierung greift, sobald beide Renten laufen; solange nur ein Ehegatte pensioniert ist, bleibt dessen Rente ungekürzt.';

  @override
  String get coupleWithdrawalTitle => 'Optimaler Bezugsplan';

  @override
  String get coupleWithdraw3a => 'Bezug Säule 3a';

  @override
  String get coupleWithdrawBvg => 'Bezug BVG-Kapital';

  @override
  String coupleTaxEstimate(String amount) {
    return 'Geschätzte Steuer: $amount';
  }

  @override
  String get coupleFormIntro =>
      'Ihre Daten werden aus Ihrem Profil vorausgefüllt. Geben Sie die Daten Ihres Partners für die Simulation ein.';

  @override
  String get coupleReplacementIndividual => 'Ersatzquote';

  @override
  String get coupleSituationTitle => 'Ihre Situation';

  @override
  String get coupleFiscalStatus => 'Simulierte steuerliche Situation';

  @override
  String get coupleStatusMarried => 'Verheiratet';

  @override
  String get coupleStatusPartnership => 'Eingetragene Partnerschaft';

  @override
  String get coupleStatusConcubinage => 'Konkubinat';

  @override
  String get coupleTaxTitle => 'Besteuerung des Paares';

  @override
  String get coupleTaxMarriedJoint => 'Gemeinsame Besteuerung (Ehe)';

  @override
  String get coupleTaxUnmarriedSeparate => 'Getrennte Besteuerung (Konkubinat)';

  @override
  String coupleTaxCheaperMarried(String amount) {
    return 'Die Ehe spart Ihnen etwa $amount Steuern pro Jahr.';
  }

  @override
  String coupleTaxCheaperConcubinage(String amount) {
    return 'Das Konkubinat spart Ihnen etwa $amount Steuern pro Jahr.';
  }

  @override
  String get coupleTaxEqual =>
      'Ehe und Konkubinat sind steuerlich gleichwertig.';

  @override
  String get coupleTaxDisclaimer =>
      'Richtschätzung auf Basis der Bruttoeinkommen (offizielle Tarife 2026: direkte Bundessteuer, Kanton und Gemeinde).';

  @override
  String get coupleConversionRate => 'BVG-Umwandlungssatz (%)';

  @override
  String get coupleConversionRateHint =>
      '6.8 % = gesetzliches Minimum, garantiert nur auf dem obligatorischen Teil. Ihre Kasse wendet oft einen tieferen Gesamtsatz an — siehe Ihren BVG-Ausweis.';

  @override
  String get coupleWithdrawalTotalTax => 'Gesamtsteuer des Plans';

  @override
  String get coupleWithdrawalSimultaneous =>
      'Steuer bei Bezügen im selben Jahr';

  @override
  String get coupleWithdrawalSavings => 'Ersparnis dank Staffelung';

  @override
  String get coupleWithdrawalEmpty =>
      'Kein projiziertes 3a- oder BVG-Kapital: der Bezugsplan erscheint, sobald ein Kapital angegeben ist.';

  @override
  String get paywallTitle => 'PocketPillar Premium';

  @override
  String get paywallHeadline => 'Schöpfen Sie Ihr ganzes Vorsorgepotenzial aus';

  @override
  String get paywallPriceFallback => 'CHF 39/Jahr';

  @override
  String paywallPricePerYear(String price) {
    return '$price pro Jahr';
  }

  @override
  String get paywallFeaturesTitle => 'In Premium enthalten';

  @override
  String get paywallFeatureCatchup =>
      '3a-Nachzahlung: Detail Jahr für Jahr und Aktionsplan';

  @override
  String get paywallFeatureScenarios =>
      '4 erweiterte Szenarien: Paar, gestaffelter Bezug, Immobilienkauf, Scheidung';

  @override
  String get paywallFeatureOcr =>
      'Dokumenten-Scan (OCR) zum Vorausfüllen Ihres Profils';

  @override
  String get paywallFeatureRecommendations =>
      'Vollständige Empfehlungen und bester Anbieter für Ihr Profil';

  @override
  String get paywallFeaturePdf => 'PDF-Export Ihrer Vorsorgebilanz';

  @override
  String get paywallFeatureDocuments => 'Unbegrenzte Dokumente';

  @override
  String get paywallSubscribe => 'Premium freischalten';

  @override
  String get paywallRestore => 'Käufe wiederherstellen';

  @override
  String get paywallLegal =>
      'Jahresabonnement mit automatischer Verlängerung. Verwaltung und Kündigung jederzeit in den Einstellungen Ihres Stores (App Store / Google Play).';

  @override
  String get paywallUnavailableTitle => 'Kauf nicht verfügbar';

  @override
  String get paywallUnavailableBody =>
      'In-App-Käufe sind zurzeit nicht verfügbar. Versuchen Sie es später erneut — Ihre Gratis-Funktionen bleiben verfügbar.';

  @override
  String get paywallOfferingError =>
      'Das Angebot konnte nicht geladen werden. Prüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get paywallPurchaseFailed =>
      'Der Kauf wurde nicht abgeschlossen. Versuchen Sie es später erneut.';

  @override
  String get paywallPurchaseSuccess => 'Premium aktiviert — vielen Dank!';

  @override
  String get paywallRestoreSuccess => 'Abonnement wiederhergestellt!';

  @override
  String get paywallRestoreNothing =>
      'Kein Abonnement zum Wiederherstellen für dieses Konto.';

  @override
  String get paywallRestoreFailed =>
      'Die Wiederherstellung wurde nicht abgeschlossen. Versuchen Sie es später erneut.';

  @override
  String get paywallAlreadyActive => 'Ihr Premium-Abonnement ist aktiv.';

  @override
  String get settingsPremiumTitle => 'PocketPillar Premium';

  @override
  String get settingsPremiumActive => 'Abonniert';

  @override
  String settingsPremiumActiveUntil(String date) {
    return 'Abonniert — bis $date';
  }

  @override
  String get settingsPremiumInactive => 'Nicht abonniert — CHF 39/Jahr';

  @override
  String get premiumBadgeLabel => 'Premium';

  @override
  String get premiumDiscoverCta => 'Premium entdecken';

  @override
  String get premiumUpsellRecommendations =>
      'Personalisierte Empfehlungen und der vollständige Vergleich sind Teil von PocketPillar Premium.';

  @override
  String get premiumUpsellBestMatch =>
      'Die Suche nach dem idealen Anbieter ist Teil von PocketPillar Premium.';

  @override
  String get catchupUpsellTitle => 'Schalten Sie den Plan Jahr für Jahr frei';

  @override
  String get catchupUpsellBody =>
      'Mit Premium sehen Sie jedes nachholbare Jahr und Ihren detaillierten Aktionsplan.';
}
