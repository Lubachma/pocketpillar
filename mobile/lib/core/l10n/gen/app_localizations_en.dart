// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PocketPillar';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String get authCancel => 'Cancel';

  @override
  String get authCheckEmail =>
      'Check your inbox to confirm your email address, then sign in';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authCreateAccount => 'Create my account';

  @override
  String get authEmail => 'Email address';

  @override
  String get authEmailInvalid => 'Invalid email address';

  @override
  String get authEmailTaken =>
      'This email address is already linked to another account';

  @override
  String get authGoToLogin => 'Go to sign in';

  @override
  String get authLoginFailed => 'Sign-in failed';

  @override
  String get authLoginSubtitle => 'Your Swiss pension, securely protected';

  @override
  String get authNoAccount => 'Don\'t have an account? Create one';

  @override
  String get authDemoBannerTitle => 'Public demo';

  @override
  String get authDemoBannerBody =>
      'Shared public demo account — everyone sees the same (fictional) data, reset every night. Don\'t enter any real personal data.';

  @override
  String get authDemoSignIn => 'Sign in with the demo account';

  @override
  String get authOr => 'or';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordMinLength => 'Password must be at least 8 characters';

  @override
  String get authPasswordRequired => 'Password required';

  @override
  String get authPasswordsMismatch => 'Passwords do not match';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignInWithApple => 'Sign in with Apple';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authSignUpFailed => 'Account creation failed';

  @override
  String get biometricLockedMessage =>
      'Authenticate to access your financial data';

  @override
  String get biometricReason => 'Unlock PocketPillar to access your data';

  @override
  String get biometricUnlock => 'Unlock';

  @override
  String get errorNetwork => 'Network error';

  @override
  String get errorSessionExpired =>
      'Your session has expired, please sign in again';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String get notificationYearEndChecklist =>
      'Don\'t forget your year-end checklist! Maximize your tax benefits before December 31.';

  @override
  String notification3aReminder(String amount) {
    return 'Remember your 3a contribution! You can contribute up to CHF $amount this year.';
  }

  @override
  String notification3aReminderContextual(String amount, int days) {
    return 'You still have CHF $amount left to contribute to your 3a before December 31 ($days days left).';
  }

  @override
  String get tabCalculator => 'Check-up';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabDocuments => 'Documents';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabProviders => 'Providers';

  @override
  String get tabScenarios => 'Scenarios';

  @override
  String get onboardingTitle => 'Welcome';

  @override
  String get checklistTitle => 'Checklist';

  @override
  String get coupleTitle => 'Couple';

  @override
  String get financialProfileTitle => 'Financial profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsBiometricLock => 'Biometric lock';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsAnnualReminders => 'Annual reminders';

  @override
  String get settingsAnnualRemindersSubtitle =>
      'Year-end checklist (December 15) and 3a contribution (November 1), at 10 a.m.';

  @override
  String get settingsSectionLearn => 'Learn';

  @override
  String get settingsUnderstandTitle => 'Understand your pension';

  @override
  String get settingsUnderstandSubtitle =>
      'The 3 pillars and how we calculate, in plain words';

  @override
  String get understandIntro =>
      'Swiss retirement planning rests on 3 pillars: the state AHV, your employer\'s pension fund and your personal 3a savings. Tap a pillar to understand its role.';

  @override
  String get understandPillarsTitle => 'The 3 pillars';

  @override
  String get understandCalcTitle => 'How do we calculate?';

  @override
  String get understandCalcIntro =>
      'Every projected amount comes from one of the rules below — 2026 legal parameters and official schedules.';

  @override
  String get understandCalcAvsTitle => 'AHV pension';

  @override
  String get understandCalcAvsBody =>
      'Estimated from your income and your contribution years projected to retirement (simplified scale 44). From 2026 the 13th pension is included (13 monthly payments per year). Your real pension depends on your exact record — order an AHV account statement to know it.';

  @override
  String get understandCalcLppTitle => 'BVG capital and pension';

  @override
  String get understandCalcLppBody =>
      'Your current capital grows every year with your savings contributions (employee + employer shares) and the 1.25% legal minimum interest. At retirement: pension = capital × conversion rate. 6.8% is the legal minimum on the mandatory part — enter your certificate\'s rate for a closer result.';

  @override
  String get understandCalc3aTitle => '3a savings';

  @override
  String get understandCalc3aBody =>
      'Your current balance is projected with your yearly contributions and the return you chose. At retirement, 3a money is withdrawn as capital (not as a pension) — so it is shown separately, with the estimated withdrawal tax.';

  @override
  String get understandCalcTaxTitle => 'Taxes';

  @override
  String get understandCalcTaxBody =>
      '3a tax savings, married-vs-cohabitation comparison, capital withdrawal tax: everything is computed with the official 2026 federal, cantonal and communal schedules — verified against the FTA\'s official calculator. Your gross income is the base (your personal deductions aren\'t known): amounts are estimates.';

  @override
  String get understandCalcLimitsTitle => 'What we don\'t model';

  @override
  String get understandCalcLimitsBody =>
      'Particular paths: divorce and AHV splitting, child-raising credits, moving to Switzerland mid-career, disability, early AHV claiming (possible from 63, with a reduction — we assume AHV paid from the chosen age), fund rates on the supra-mandatory part. PocketPillar is an estimation and information tool — not advice. For important decisions, talk to a professional.';

  @override
  String get understandMethodologyLink =>
      'Full methodology and sources (published on GitHub)';

  @override
  String get settingsNotificationsDenied =>
      'Notifications denied — enable them in the system settings to receive reminders';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteConfirmTitle => 'Delete permanently?';

  @override
  String get settingsDeleteConfirmBody =>
      'This action is irreversible: your account and all your data (financial profile, LPP and 3a accounts, documents) will be deleted.';

  @override
  String get dashboardTitle => 'PocketPillar';

  @override
  String get dashboardWelcomeHeader => 'Your pension, simplified';

  @override
  String get dashboardWelcomeSubtitle =>
      'Understand and optimize your retirement in a few minutes';

  @override
  String get dashboardCtaCheck => 'Check your retirement in 2 min';

  @override
  String get dashboardTipOfDay => 'Tip of the day';

  @override
  String dashboardSummary(int percent) {
    return 'Your pension will cover $percent% of your income';
  }

  @override
  String get dashboardScoreLabel => 'Pension health';

  @override
  String get dashboardRecOpen3a =>
      'Open a pillar 3a to save on taxes and prepare your retirement';

  @override
  String get dashboardRecLowCoverage =>
      'Your coverage rate is low. Increase your contributions for a better retirement.';

  @override
  String get dashboardRecGoodTrack =>
      'You\'re on the right track! Keep optimizing your pension plan.';

  @override
  String get dashboardActionGuided => 'Guided check-up';

  @override
  String get dashboardActionExpert => 'Expert mode';

  @override
  String get dashboardActionLearn => 'Learn more';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardStatusOnline => 'API connected';

  @override
  String get dashboardStatusOffline => 'API offline';

  @override
  String dashboardUptime(int hours) {
    return 'Online for $hours h';
  }

  @override
  String get dashboardApiVersion => 'API version';

  @override
  String get dashboardSince => 'since';

  @override
  String get dashboardGoalProgress => 'Progress toward goal';

  @override
  String get dashboardGoalReached => 'Goal reached!';

  @override
  String get dashboardRecommendedProvider => 'Recommended provider for you';

  @override
  String get dashboardGreeting => 'Hello';

  @override
  String get dashboardGreetingEvening => 'Good evening';

  @override
  String get dashboardEmptyTitle => 'Complete your profile';

  @override
  String get dashboardEmptyBody =>
      'Enter your financial situation to get your retirement projection and personalized recommendations.';

  @override
  String get dashboardEmptyCta => 'Complete my profile';

  @override
  String get dashboardSynthesisTitle => 'Your retirement projection';

  @override
  String get dashboardRecommendationsTitle => 'Recommendations';

  @override
  String get dashboardRecommendationsEmpty =>
      'Complete your profile to receive personalized recommendations.';

  @override
  String dashboardEstimatedAnnualImpact(String amount) {
    return 'Estimated impact: $amount/year';
  }

  @override
  String dashboardScoreBenchmarkTitle(int min, int max) {
    return 'Comparison with ages $min–$max';
  }

  @override
  String dashboardScoreBenchmark3a(String user, String average) {
    return 'Pillar 3a: $user (average: $average)';
  }

  @override
  String dashboardScoreBenchmarkRate(String user, String average) {
    return 'Replacement rate: $user (average: $average)';
  }

  @override
  String dashboardScoreBenchmarkBvg(String user, String average) {
    return 'BVG capital: $user (average: $average)';
  }

  @override
  String get calculatorTitle => 'Calculator';

  @override
  String get calculatorLppGap => 'BVG Gap';

  @override
  String get calculatorTaxSavings => '3a Savings';

  @override
  String get calculatorRetirement => 'Retirement';

  @override
  String get calculatorCalculate => 'Calculate';

  @override
  String get calculatorGrossIncome => 'Gross income (CHF)';

  @override
  String get calculatorAge => 'Age';

  @override
  String get calculatorCanton => 'Canton';

  @override
  String get calculatorBvgCapital => 'BVG capital (CHF)';

  @override
  String get calculatorAnnualContribution => 'Annual contribution (CHF)';

  @override
  String get calculatorTaxableIncome => 'Taxable income (CHF)';

  @override
  String get calculatorContribution3a => '3a contribution (CHF)';

  @override
  String get calculatorPillar3aBalance => '3a balance (CHF)';

  @override
  String get calculatorCoordinatedSalary => 'Coordinated salary';

  @override
  String get calculatorBvgMinContribution => 'Min. BVG contribution';

  @override
  String get calculatorProjectedCapital => 'Projected capital';

  @override
  String get calculatorProjectedPension => 'Projected pension/year';

  @override
  String get calculatorPensionGap => 'Pension gap';

  @override
  String get calculatorFederalSaving => 'Federal saving';

  @override
  String get calculatorCantonalSaving => 'Cantonal saving';

  @override
  String get calculatorCommunalSaving => 'Communal saving';

  @override
  String get calculatorTotalSaving => 'Total saving';

  @override
  String get calculatorEffectiveReturn => 'Effective return';

  @override
  String get calculatorYearsToRetirement => 'Years to retirement';

  @override
  String get calculatorProjectedPillar2 => 'Projected pillar 2 capital';

  @override
  String get calculatorProjectedPillar3a => 'Projected 3a balance';

  @override
  String get calculatorWithdrawalTax3a => 'Estimated 3a withdrawal tax';

  @override
  String get calculatorNet3aAfterTax => 'Net 3a capital after tax';

  @override
  String get calculatorAnnualRetirementIncome => 'Annual retirement income';

  @override
  String get calculatorReplacementRate => 'Replacement rate';

  @override
  String get providersTitle => '3a Providers';

  @override
  String get providersRanking => 'Ranking';

  @override
  String get providersAll => 'All providers';

  @override
  String get providersProducts => 'products';

  @override
  String get providersFilter => 'Filter';

  @override
  String get providersCompare => 'Compare';

  @override
  String get providersFees => 'Fees (%)';

  @override
  String get providersFeeComparison => 'Fee comparison';

  @override
  String providersCompareSelected(int count) {
    return 'Compare $count products';
  }

  @override
  String get providersTapToCompare => 'Tap to compare';

  @override
  String get providersFeeShort => 'Fees';

  @override
  String get providersEquityShort => 'Equity';

  @override
  String get providersReturnShort => 'Ret. 3y';

  @override
  String get providersEsgBadge => 'Sustainable';

  @override
  String get providersVisitWebsite => 'Visit website';

  @override
  String get providersWebsiteError => 'Could not open the link';

  @override
  String get providersEmpty => 'No providers available at the moment';

  @override
  String get providersDigital => 'Digital';

  @override
  String get providersCategory => 'Category';

  @override
  String get providersRiskLevel => 'Risk';

  @override
  String get providersFeesDetail => 'Fee details';

  @override
  String get providersTer => 'TER (fund fees)';

  @override
  String get providersAllInFee => 'All-in fee';

  @override
  String get providersCustodyFee => 'Custody fee';

  @override
  String get providersEntryFee => 'Entry fee';

  @override
  String get providersExitFee => 'Exit fee';

  @override
  String get providersPerformance => 'Return by year';

  @override
  String get providersPerformanceWindow => 'Last 5 years';

  @override
  String get providersCategoryPassiveIndex => 'Index fund (passive)';

  @override
  String get providersCategoryActiveManaged => 'Actively managed';

  @override
  String get providersCategoryInsurance => 'Life insurance 3a';

  @override
  String get providersCategorySavings => 'Savings account';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileAbout => 'About';

  @override
  String get profileVersion => 'Version';

  @override
  String get profileApi => 'API server';

  @override
  String get profileSectionPersonal => 'Personal information';

  @override
  String get profileSalary => 'Salary (CHF)';

  @override
  String get profileAge => 'Age';

  @override
  String get profileCanton => 'Canton';

  @override
  String get profileMunicipality => 'Municipality';

  @override
  String get profileHas3a => 'Pillar 3a';

  @override
  String get profile3aBalance => '3a balance (CHF)';

  @override
  String get profileMaritalStatus => 'Marital status';

  @override
  String get profileGoalSection => 'Goal';

  @override
  String get profileTargetRate => 'Target replacement rate';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get profileAppearanceSystem => 'System';

  @override
  String get profileAppearanceLight => 'Light';

  @override
  String get profileAppearanceDark => 'Dark';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionSecurity => 'Security';

  @override
  String get profileSettingsSubtitle =>
      'Canton, income, situation and accounts';

  @override
  String get profileSelectCanton => 'Select';

  @override
  String get profileBirthYear => 'Year of birth';

  @override
  String get profileBirthYearInvalid => 'Invalid year of birth';

  @override
  String get profileSectionSituation => 'Financial situation';

  @override
  String get profileEmploymentStatus => 'Employment status';

  @override
  String get profileEmploymentEmployed => 'Employed';

  @override
  String get profileEmploymentSelfEmployed => 'Self-employed';

  @override
  String get profileEmploymentUnemployed => 'Unemployed';

  @override
  String get profileEmploymentRetired => 'Retired';

  @override
  String get profileMaritalDivorced => 'Divorced';

  @override
  String get profileMaritalWidowed => 'Widowed';

  @override
  String get profileChildren => 'Number of children';

  @override
  String get profileChildrenInvalid => 'Invalid number of children';

  @override
  String get profileGrossAnnualIncome => 'Gross annual income (CHF)';

  @override
  String get profileNetAnnualIncome => 'Net annual income (CHF, optional)';

  @override
  String get profileFieldRequired => 'Required field';

  @override
  String get profileAmountInvalid => 'Invalid amount';

  @override
  String get profileRateInvalid => 'Invalid rate';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileSectionPillar2 => 'Pillar 2 accounts (BVG)';

  @override
  String get profileSectionPillar3a => 'Pillar 3a accounts';

  @override
  String get profileEmptyPillar2 => 'No pillar 2 account added';

  @override
  String get profileEmptyPillar3a => 'No pillar 3a account added';

  @override
  String get profilePillar2DefaultName => 'Pillar 2 account';

  @override
  String get profileAddPillar2 => 'Add a pillar 2 account';

  @override
  String get profileAddPillar3a => 'Add a pillar 3a account';

  @override
  String get profilePillar2New => 'New pillar 2 account';

  @override
  String get profilePillar2Edit => 'Edit pillar 2 account';

  @override
  String get profilePillar3aNew => 'New pillar 3a account';

  @override
  String get profilePillar3aEdit => 'Edit pillar 3a account';

  @override
  String get profileProviderName => 'Provider';

  @override
  String get profileCurrentCapital => 'Current capital (CHF)';

  @override
  String get profileConversionRate => 'Conversion rate (%)';

  @override
  String get profileAnnualContribution => 'Annual contribution (CHF)';

  @override
  String get profileAdvancedSection => 'Advanced';

  @override
  String get profileInsuredSalary => 'Insured salary (CHF)';

  @override
  String get profileCoordinationDeduction => 'Coordination deduction (CHF)';

  @override
  String get profileAnnualSupraContribution =>
      'Annual supra-obligatory contribution (CHF)';

  @override
  String get profileCurrentBalance => 'Current balance (CHF)';

  @override
  String get profileInterestRate => 'Interest rate / return (%)';

  @override
  String get profileAccountType => 'Account type';

  @override
  String get profileAccountTypeBank => 'Bank';

  @override
  String get profileAccountTypeInsurance => 'Insurance';

  @override
  String get profileVestedBenefits => 'Vested benefits account';

  @override
  String get profileDeleteAccountTitle => 'Delete this account?';

  @override
  String get profileDeleteAccountBody => 'This action is permanent.';

  @override
  String get profileAccountSaved => 'Account saved';

  @override
  String get profileAccountDeleted => 'Account deleted';

  @override
  String get ocrScanSalaryButton => 'Scan a salary certificate';

  @override
  String get ocrScanLppButton => 'Scan an LPP statement';

  @override
  String get ocrScanSalaryTitle => 'Salary certificate';

  @override
  String get ocrScanLppTitle => 'LPP statement';

  @override
  String get ocrSourceCamera => 'Take a photo';

  @override
  String get ocrSourceGallery => 'Choose an image';

  @override
  String get ocrScanning => 'Scanning document…';

  @override
  String get ocrNoTextFound =>
      'No text detected in the image. Try again with a sharper photo.';

  @override
  String get ocrNoValuesFound =>
      'No values recognized on this document. You can try again with another photo.';

  @override
  String get ocrProposalTitle => 'Detected values';

  @override
  String get ocrProposalBody =>
      'Review and adjust the values before applying them.';

  @override
  String get ocrPrivacyNote =>
      'On-device scanning: the image never leaves your device.';

  @override
  String get ocrApply => 'Apply';

  @override
  String get ocrScanError => 'Scanning failed. Try again with a sharper photo.';

  @override
  String get ocrApplied => 'Fields prefilled — review and save';

  @override
  String get onboardingPillarsTitle => 'Your retirement rests on 3 pillars';

  @override
  String get onboardingPillarsDesc =>
      'The Swiss pension system is unique worldwide. Discover how it works.';

  @override
  String get onboardingDetailsTitle => 'How does it work?';

  @override
  String get onboardingDetailsDesc =>
      'Each pillar plays a different role in your retirement';

  @override
  String get onboardingP1Title => '1st pillar (OASI)';

  @override
  String get onboardingP1Desc =>
      'Mandatory basic pension, funded by your salary contributions';

  @override
  String get onboardingP2Title => '2nd pillar (BVG)';

  @override
  String get onboardingP2Desc =>
      'Occupational pension through your employer, accumulated capital';

  @override
  String get onboardingP3aTitle => 'Pillar 3a';

  @override
  String get onboardingP3aDesc =>
      'Voluntary savings with tax benefits, you decide';

  @override
  String get onboardingFeaturesTitle => 'PocketPillar helps you...';

  @override
  String get onboardingFeaturesDesc =>
      'Everything you need for your pension planning';

  @override
  String get onboardingFeatureScore => 'Assess your pension health';

  @override
  String get onboardingFeatureSimulate => 'Simulate your retirement in detail';

  @override
  String get onboardingFeatureCompare => 'Compare 3a providers';

  @override
  String get onboardingFeatureTips => 'Get personalized tips';

  @override
  String get onboardingReadyTitle => 'Let\'s go!';

  @override
  String get onboardingReadyDesc =>
      'It takes 2 minutes. Find out where your pension stands.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingReplay => 'Replay introduction';

  @override
  String get onboardingWelcomeTitle => 'Welcome to PocketPillar';

  @override
  String get onboardingWelcomeDesc =>
      'Optimize your Swiss pension. Simulate, compare, and maximize your 2nd and 3rd pillars.';

  @override
  String get onboardingCalculatorTitle => 'Smart calculators';

  @override
  String get onboardingCalculatorDesc =>
      'Analyze your BVG gap, calculate your 3a tax savings by canton, and project your retirement.';

  @override
  String get onboardingProvidersTitle => 'Compare providers';

  @override
  String get onboardingProvidersDesc =>
      'VIAC, Frankly, finpension and more. Find the pillar 3a with the best fees and returns.';

  @override
  String get pillar1Short => '1st pillar';

  @override
  String get pillar1Name => 'OASI / DI';

  @override
  String get pillar2Short => '2nd pillar';

  @override
  String get pillar2Name => 'BVG / Pension fund';

  @override
  String get pillar3aShort => 'Pillar 3a';

  @override
  String get pillar3aName => 'Private pension';

  @override
  String get guidedTitle => 'Your check-up';

  @override
  String get guidedResultsTitle => 'Your results';

  @override
  String get guidedSalaryTitle => 'What is your annual salary?';

  @override
  String get guidedSalarySubtitle => 'Gross salary before deductions';

  @override
  String get guidedAgeTitle => 'How old are you?';

  @override
  String get guidedAgeSubtitle =>
      'Your age influences your contributions and projections';

  @override
  String get guidedAgeYears => 'years old';

  @override
  String get guidedCantonTitle => 'Where do you live?';

  @override
  String get guidedCantonSubtitle => 'Tax rates vary by canton';

  @override
  String get guided3aTitle => 'Do you have a pillar 3a?';

  @override
  String get guided3aSubtitle =>
      'Pillar 3a is your personal savings with tax benefits';

  @override
  String get guided3aQuestion => 'Do you save in a 3a?';

  @override
  String get guided3aBalance => 'Approximate balance';

  @override
  String get guidedYes => 'Yes';

  @override
  String get guidedNo => 'No';

  @override
  String get guidedNext => 'Next';

  @override
  String get guidedBack => 'Back';

  @override
  String get guidedSeeResults => 'See my results';

  @override
  String get guidedMaritalTitle => 'What is your marital status?';

  @override
  String get guidedMaritalSubtitle =>
      'Your status influences your tax calculation';

  @override
  String get guidedMaritalSingle => 'Single';

  @override
  String get guidedMaritalMarried => 'Married';

  @override
  String get guidedMaritalPartnership => 'Registered partnership';

  @override
  String get guidedSituationTitle => 'Your situation';

  @override
  String get guidedSituationSubtitle => 'Age, canton and marital status';

  @override
  String get guidedPillar2Title => 'Your 2nd pillar (BVG)';

  @override
  String get guidedPillar2Subtitle =>
      'Capital and contributions of your pension fund — see your pension certificate';

  @override
  String guidedStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String resultsSummaryPhrase(int percent) {
    return 'Your pension will cover $percent% of your current income';
  }

  @override
  String resultsPensionMonthly(String amount) {
    return 'That\'s about $amount per month';
  }

  @override
  String get resultsYourPillars => 'Your 3 pillars';

  @override
  String get resultsReplacementRate => 'Replacement rate';

  @override
  String get resultsYearsToRetirement => 'Years to retirement';

  @override
  String get resultsHowCalculated => 'How are these numbers calculated?';

  @override
  String get resultsTaxSavings => 'Tax savings';

  @override
  String get resultsAnnualSavings => 'savings per year';

  @override
  String resultsEffectiveReturn(String rate) {
    return 'Effective return: $rate%';
  }

  @override
  String get resultsWhatToDo => 'What to do now?';

  @override
  String get resultsRecOpen3a =>
      'Open a pillar 3a to save on taxes and prepare your retirement';

  @override
  String resultsRecMax3a(String amount) {
    return 'Contribute the maximum of $amount to 3a to optimize your taxes';
  }

  @override
  String resultsRecTaxSaving(String amount) {
    return 'You save $amount in taxes per year thanks to 3a';
  }

  @override
  String get resultsRecIncreaseCoverage =>
      'Your coverage is below 60%. Consider a BVG buyback or increase your 3a contributions.';

  @override
  String get resultsRecBvgBuyback =>
      'A BVG buyback could close your pension gap and reduce your taxes';

  @override
  String get resultsAboveAverage => 'Above average for your age';

  @override
  String get resultsBelowAverage => 'Below average for your age';

  @override
  String get resultsNearAverage => 'Average for your age';

  @override
  String get resultsCompareToggle => 'Compare with/without 3a';

  @override
  String get resultsCompareWith3a => 'With 3a (per month)';

  @override
  String get resultsCompareWithout3a => 'Without 3a (per month)';

  @override
  String get resultsDeltaLabel => 'Difference';

  @override
  String get resultsApproximateBadge => 'Approximate estimate (offline)';

  @override
  String get cantonPickerTitle => 'Choose a canton';

  @override
  String get cantonPickerSearch => 'Search for a canton';

  @override
  String get municipalityPickerTitle => 'Choose a municipality';

  @override
  String get municipalityPickerSearch => 'Search for a municipality';

  @override
  String get municipalityCantonalAverageOption =>
      'Cantonal average (municipality not listed)';

  @override
  String get municipalityPickerEmpty =>
      'No municipalities covered for this canton — the cantonal average is used.';

  @override
  String get municipalityPickerNoResults => 'No results';

  @override
  String get municipalityPickerError => 'Could not load municipalities';

  @override
  String get municipalitySelectCantonFirst => 'Choose a canton first';

  @override
  String get helpSectionWhat => 'What is it?';

  @override
  String get helpSectionWhy => 'Why does it matter?';

  @override
  String get helpSectionWhere => 'Where to find this info?';

  @override
  String get helpPillarSystemTitle => '3 pillar system';

  @override
  String get helpPillarSystemExplanation =>
      'Switzerland organizes retirement in 3 levels: a basic pension (OASI), occupational pension (BVG), and private savings (3a). Together, they aim to maintain your standard of living.';

  @override
  String get helpPillarSystemWhy =>
      'Understanding this system helps you identify what you can optimize for your retirement.';

  @override
  String get helpPillarSystemWhere =>
      'Your salary certificate and annual pension statement detail your contributions.';

  @override
  String get helpPillar1AvsTitle => 'OASI (1st pillar)';

  @override
  String get helpPillar1AvsExplanation =>
      'OASI is the basic pension everyone receives at retirement. It\'s funded by your salary contributions (deducted automatically) and your employer\'s contributions.';

  @override
  String get helpPillar1AvsWhy =>
      'OASI alone only covers about 40% of your last salary. That\'s why the 2nd and 3rd pillars are essential.';

  @override
  String get helpPillar1AvsWhere =>
      'Request an OASI account statement from your cantonal compensation office website.';

  @override
  String get helpPillar2BvgTitle => 'BVG / 2nd pillar';

  @override
  String get helpPillar2BvgExplanation =>
      'Occupational pension is mandatory savings managed by your employer. You and your employer contribute monthly. This capital accumulates and is paid out at retirement.';

  @override
  String get helpPillar2BvgWhy =>
      'It\'s often the largest amount in your retirement. Check your annual pension certificate to know your capital.';

  @override
  String get helpPillar2BvgWhere =>
      'Your annual pension certificate, sent by your employer\'s pension fund.';

  @override
  String get helpPillar3aTitle => 'Pillar 3a';

  @override
  String get helpPillar3aExplanation =>
      'Pillar 3a is voluntary savings you manage yourself. You choose your provider, amount, and investment type. The money is locked until retirement (with exceptions).';

  @override
  String get helpPillar3aWhy =>
      'Every franc contributed to 3a is tax-deductible. It\'s the simplest way to pay less tax while preparing for retirement.';

  @override
  String get helpPillar3aWhere =>
      'Log in to your 3a provider\'s website (bank or app) to see your balance.';

  @override
  String get helpCoordinatedSalaryTitle => 'Coordinated salary';

  @override
  String get helpCoordinatedSalaryExplanation =>
      'It\'s the portion of your salary on which your BVG contributions are calculated. A fixed amount (coordination deduction) is subtracted from your gross salary.';

  @override
  String get helpCoordinatedSalaryWhy =>
      'The higher it is, the larger your contributions and your future pension will be.';

  @override
  String get helpCoordinatedSalaryWhere =>
      'Shown on your annual BVG pension certificate.';

  @override
  String get helpConversionRateTitle => 'Conversion rate';

  @override
  String get helpConversionRateExplanation =>
      'This percentage converts your BVG capital into an annual pension. For example, with 6.8% and CHF 500,000 capital, you receive CHF 34,000 per year.';

  @override
  String get helpConversionRateWhy =>
      'A higher rate = a better pension. The legal minimum is 6.8%, but funds can apply a lower rate on the non-mandatory portion.';

  @override
  String get helpConversionRateWhere =>
      'Shown on your annual pension certificate or your pension fund\'s regulations.';

  @override
  String get helpBvgCapitalTitle => 'BVG capital';

  @override
  String get helpBvgCapitalExplanation =>
      'This is the money accumulated in your pension fund (2nd pillar). Your and your employer\'s contributions add up monthly, plus interest.';

  @override
  String get helpBvgCapitalWhy =>
      'It\'s usually your largest asset. It directly determines your pension amount at retirement.';

  @override
  String get helpBvgCapitalWhere =>
      'Your annual pension certificate, section \'retirement assets\'.';

  @override
  String get helpReplacementRateTitle => 'Replacement rate';

  @override
  String get helpReplacementRateExplanation =>
      'The percentage of your last salary you\'ll receive in retirement. For example, 65% means if you earn CHF 100,000, your pension will be about CHF 65,000 per year.';

  @override
  String get helpReplacementRateWhy =>
      'The goal is typically 60-80%. Below 60%, your standard of living may drop significantly in retirement.';

  @override
  String get helpReplacementRateWhere =>
      'PocketPillar calculates it for you from your data. You can also ask your pension fund.';

  @override
  String get helpPensionGapTitle => 'Pension gap';

  @override
  String get helpPensionGapExplanation =>
      'The difference between the pension you should receive by law and what you\'ll actually receive. If your employer contributes the legal minimum, the gap may be zero.';

  @override
  String get helpPensionGapWhy =>
      'A positive gap means you\'re below the legal minimum and could indicate an issue with your contributions.';

  @override
  String get helpPensionGapWhere =>
      'Compare your pension certificate with BVG minimums, or use the PocketPillar calculator.';

  @override
  String get helpTaxSavings3aTitle => '3a tax savings';

  @override
  String get helpTaxSavings3aExplanation =>
      'Every franc contributed to your 3a reduces your taxable income. Depending on your canton and income, you can save between CHF 1,500 and CHF 3,000 in taxes per year.';

  @override
  String get helpTaxSavings3aWhy =>
      'It\'s money you keep instead of giving to the tax office. The more you earn, the greater the savings.';

  @override
  String get helpTaxSavings3aWhere =>
      'Use PocketPillar\'s tax calculator by selecting your canton.';

  @override
  String get helpBvgBuybackTitle => 'BVG buyback';

  @override
  String get helpBvgBuybackExplanation =>
      'A voluntary payment into your 2nd pillar to fill contribution gaps. For example, if you didn\'t work in Switzerland for a few years.';

  @override
  String get helpBvgBuybackWhy =>
      'The amount is 100% tax-deductible in the year of payment. It\'s a very effective tax strategy.';

  @override
  String get helpBvgBuybackWhere =>
      'Your pension certificate shows the maximum possible buyback amount. Contact your pension fund.';

  @override
  String get helpRetirementAgeTitle => 'Retirement age';

  @override
  String get helpRetirementAgeExplanation =>
      'In Switzerland, the reference retirement age is 65 (AHV 21 transition for women born 1961-1963: 64.5 years in 2026). You can take early retirement from 58 or defer until 70.';

  @override
  String get helpRetirementAgeWhy =>
      'Each year of early retirement reduces your pension. Each year of deferral increases it. It\'s an important financial decision.';

  @override
  String get helpRetirementAgeWhere =>
      'FSIO website (Federal Social Insurance Office) or your cantonal compensation office.';

  @override
  String get helpContribution3aMaxTitle => '3a maximum';

  @override
  String get helpContribution3aMaxExplanation =>
      'The maximum 3a contribution is set by law. In 2026, it\'s CHF 7,258 with a 2nd pillar, or CHF 36,288 without (max 20% of net income).';

  @override
  String get helpContribution3aMaxWhy =>
      'Contributing the maximum is almost always beneficial: you maximize your tax savings.';

  @override
  String get helpContribution3aMaxWhere =>
      'The amount is published annually by the FSIO. PocketPillar is always up to date.';

  @override
  String get helpGrossIncomeTitle => 'Gross income';

  @override
  String get helpGrossIncomeExplanation =>
      'Your annual salary before any deductions (taxes, OASI, BVG, etc.). It\'s the amount shown on your employment contract.';

  @override
  String get helpGrossIncomeWhy =>
      'It\'s the basis for calculating your contributions and retirement projections.';

  @override
  String get helpGrossIncomeWhere =>
      'Your employment contract, monthly payslip, or annual salary certificate.';

  @override
  String get helpEffectiveReturnTitle => 'Effective return';

  @override
  String get helpEffectiveReturnExplanation =>
      'The actual return on your 3a contribution, accounting for tax savings. It\'s like an immediate bonus on your investment.';

  @override
  String get helpEffectiveReturnWhy =>
      'An effective return of 30% means for CHF 7,258 contributed, you get back about CHF 2,177 in tax savings.';

  @override
  String get helpEffectiveReturnWhere =>
      'Use PocketPillar\'s tax calculator to see your effective return based on your canton.';

  @override
  String get helpAnnualContributionTitle => 'Annual BVG contribution';

  @override
  String get helpAnnualContributionExplanation =>
      'This is the amount saved into your pension fund each year: your share AND your employer\'s (they pay at least as much as you). So it is not just the deduction you see on your payslip.';

  @override
  String get helpAnnualContributionWhy =>
      'The projection adds these savings every year until retirement, compounded at the 1.25% legal minimum interest. Entering only your own half strongly understates your projected capital.';

  @override
  String get helpAnnualContributionWhere =>
      'Your annual pension certificate, under “savings contributions” — add up the employee and employer shares (risk premiums don\'t count).';

  @override
  String get helpWithdrawalTaxTitle => 'Capital withdrawal tax';

  @override
  String get helpWithdrawalTaxExplanation =>
      'Pension capital you withdraw (3a or pension fund) is taxed once, separately from your other income and at a reduced rate.';

  @override
  String get helpWithdrawalTaxWhy =>
      'This tax reduces what you actually receive — that\'s why we show both the gross capital and the estimated net. Spreading withdrawals over several tax years often lowers it (see “Staggered withdrawal”).';

  @override
  String get helpWithdrawalTaxWhere =>
      'Estimated with your canton\'s and municipality\'s official 2026 schedules. The exact amount depends on your situation in the withdrawal year.';

  @override
  String get helpPensionScoreTitle => 'Pension score';

  @override
  String get helpPensionScoreExplanation =>
      'A mark out of 100 summarising your retirement readiness: replacement rate (40 pts), 3a savings (30 pts) and time left to act (30 pts).';

  @override
  String get helpPensionScoreWhy =>
      'It shows at a glance where you stand and what weighs most. The age-bracket comparison uses indicative orders of magnitude (not official statistics) — a reference point, not a target.';

  @override
  String get helpPensionScoreWhere =>
      'Computed by PocketPillar from your profile; it updates as soon as you change your data.';

  @override
  String get tipMax3a2026Title => '3a maximum 2026';

  @override
  String get tipMax3a2026Body =>
      'The 3a maximum for 2026 is CHF 7,258. Contribute before December 31 to save on your taxes!';

  @override
  String get tipBvgBuybackTitle => 'BVG buyback = double savings';

  @override
  String get tipBvgBuybackBody =>
      'A BVG buyback is 100% tax-deductible AND increases your pension. Ask your fund about your buyback potential.';

  @override
  String get tip3aTaxDeductionTitle => '3a reduces your taxes';

  @override
  String get tip3aTaxDeductionBody =>
      'Every franc contributed to 3a is deductible from your taxable income. Depending on your canton, that can mean over 30% immediate return!';

  @override
  String get tipStartEarlyTitle => 'Start early';

  @override
  String get tipStartEarlyBody =>
      'Starting 3a savings at 25 instead of 35 can earn you over CHF 100,000 more thanks to compound interest.';

  @override
  String get tipCompoundInterestTitle => 'The magic of compound interest';

  @override
  String get tipCompoundInterestBody =>
      'Your interest earns interest too. Over 30 years, a 3a investment at 3% return nearly doubles your invested capital.';

  @override
  String get tipMultiple3aTitle => 'Multiple 3a accounts';

  @override
  String get tipMultiple3aBody =>
      'Opening multiple 3a accounts (up to 5) allows staggered withdrawals and reduces capital withdrawal tax.';

  @override
  String get tipRetirementGapTitle => 'The retirement gap';

  @override
  String get tipRetirementGapBody =>
      'On average, the 1st and 2nd pillars only cover 60% of your last salary. 3a is essential to close this gap.';

  @override
  String get tip3PillarsTitle => 'Why 3 pillars?';

  @override
  String get tip3PillarsBody =>
      'The Swiss system spreads risk: the state (OASI), the employer (BVG), and yourself (3a). Each plays a role in your financial security.';

  @override
  String get tipAvsMaxTitle => 'Maximum OASI pension';

  @override
  String get tipAvsMaxBody =>
      'The maximum OASI pension is CHF 2,520/month for a single person (2026). Even high earners are capped at this amount.';

  @override
  String get tipPillar2InterestTitle => 'BVG interest rate';

  @override
  String get tipPillar2InterestBody =>
      'Your mandatory BVG capital earns at least 1.25% per year. Some funds offer more on the non-mandatory portion.';

  @override
  String get tip3aWithdrawalTitle => 'Early 3a withdrawal';

  @override
  String get tip3aWithdrawalBody =>
      'You can withdraw your 3a before retirement to buy a home, become self-employed, or leave Switzerland.';

  @override
  String get tipCantonTaxesTitle => 'The canton impact';

  @override
  String get tipCantonTaxesBody =>
      'The 3a tax savings vary enormously by canton. In Geneva, it can be 2x higher than in Zug on the same income.';

  @override
  String get bestmatchTitle => 'Find my ideal 3a';

  @override
  String get bestmatchSubtitle =>
      'Answer a few questions to find the best pillar 3a';

  @override
  String get bestmatchRiskQuestion =>
      'How would you like to invest your money?';

  @override
  String get bestmatchRiskExplanation =>
      'The higher the potential return, the more the value can fluctuate in the short term';

  @override
  String get bestmatchRiskConservativeTitle => 'Safety first';

  @override
  String get bestmatchRiskConservativeDesc =>
      'My money stays stable, even if it earns less';

  @override
  String get bestmatchRiskModerateTitle => 'Cautious';

  @override
  String get bestmatchRiskModerateDesc =>
      'I accept small fluctuations for better returns';

  @override
  String get bestmatchRiskBalancedTitle => 'Balanced';

  @override
  String get bestmatchRiskBalancedDesc =>
      'A mix of safety and returns, the most popular choice';

  @override
  String get bestmatchRiskGrowthTitle => 'Dynamic';

  @override
  String get bestmatchRiskGrowthDesc =>
      'I aim for maximum returns, temporary dips don\'t worry me';

  @override
  String get bestmatchRiskAggressiveTitle => '100% equities';

  @override
  String get bestmatchRiskAggressiveDesc =>
      'All in stocks for the long term, ideal if retirement is far away';

  @override
  String get bestmatchRiskConservative => 'Conservative (0-25% equities)';

  @override
  String get bestmatchRiskModerate => 'Moderate (25-50% equities)';

  @override
  String get bestmatchRiskBalanced => 'Balanced (50-75% equities)';

  @override
  String get bestmatchRiskGrowth => 'Growth (75-100% equities)';

  @override
  String get bestmatchRiskAggressive => 'Aggressive (100% equities)';

  @override
  String get bestmatchPreferences => 'Your preferences';

  @override
  String get bestmatchMaxFee => 'Maximum annual fees';

  @override
  String get bestmatchFeeHint =>
      'Lower fees = more money for you. The Swiss average is about 0.8%.';

  @override
  String get bestmatchEsg => 'Sustainable investing';

  @override
  String get bestmatchEsgHint =>
      'Excludes polluting companies, weapons, tobacco';

  @override
  String get bestmatchFind => 'Find the best';

  @override
  String get bestmatchResultsTitle => 'Your best choices';

  @override
  String get bestmatchNoResults => 'No results';

  @override
  String get bestmatchTryDifferent => 'Try with different criteria';

  @override
  String get bestmatchRestart => 'Start over';

  @override
  String get bestmatchScoreExplanation =>
      'The score combines fees, 3-year return, fit with your risk profile and sustainability (ESG).';

  @override
  String get privacyLocalData =>
      'Your financial data is stored on secure servers in Europe (Ireland). It is used only to provide the service. Biometric lock and credentials stay on your device.';

  @override
  String get privacyTitle => 'Privacy policy';

  @override
  String get privacySectionDataCollected => 'Data collected';

  @override
  String get privacyBodyDataCollected =>
      'PocketPillar collects your email address, financial information (salary, pension assets, tax situation), and documents you upload. This data is necessary for the app to function.';

  @override
  String get privacySectionPurpose => 'Purpose of processing';

  @override
  String get privacyBodyPurpose =>
      'Your data is used exclusively to calculate your pension situation, generate personalized recommendations, and securely store your pension documents.';

  @override
  String get privacySectionStorage => 'Storage and security';

  @override
  String get privacyBodyStorage =>
      'Your profile and financial data are stored on secure servers in the EU (Ireland). Credentials and session tokens stay in the device\'s secure storage (iOS Keychain / Android Keystore). Documents are encrypted in transit and at rest. Biometric access (Face ID / Touch ID) protects app opening.';

  @override
  String get privacySectionSharing => 'Data sharing';

  @override
  String get privacyBodySharing =>
      'PocketPillar never sells or rents your personal data. It is only transmitted to the technical subcontractors essential to the service (Supabase hosting, EU) and never for advertising purposes.';

  @override
  String get privacySectionRights => 'Your rights (nDSG)';

  @override
  String get privacyBodyRights =>
      'Under the new Swiss Data Protection Act (nDSG), you have the right to access, rectify, export, and request complete deletion of your data at any time.';

  @override
  String get privacySectionSecurity => 'Security measures';

  @override
  String get privacyBodySecurity =>
      'Secure token-based authentication (JWT), biometric lock, encrypted on-device credential storage, screenshot blocking on Android, time-limited download URLs (5 min), file type validation.';

  @override
  String get privacySectionContact => 'Contact';

  @override
  String get privacyBodyContact =>
      'For any questions about your personal data: privacy@pocketpillar.ch';

  @override
  String get buybackTitle => 'BVG Buyback';

  @override
  String get buybackWhatTitle => 'What is it?';

  @override
  String get buybackWhatBody =>
      'A BVG buyback is a voluntary payment into your pension fund to fill contribution gaps. For example, if you haven\'t always worked in Switzerland or had a salary increase.';

  @override
  String get buybackBenefitsTitle => 'Benefits';

  @override
  String get buybackBenefitsBody =>
      'The amount is 100% tax-deductible in the year of payment. Your future pension increases. It\'s one of the best tax strategies in Switzerland.';

  @override
  String get buybackStepsTitle => 'How to proceed?';

  @override
  String get buybackStepsBody =>
      '1. Check your pension certificate for the maximum buyback amount\n2. Contact your pension fund\n3. Make the payment before December 31\n4. Deduct the amount from your tax return';

  @override
  String get compareTitle => 'Comparison';

  @override
  String get compareFees => 'Annual fees';

  @override
  String get compareReturns => 'Average return 3 years';

  @override
  String get compareAllocation => 'Equity share';

  @override
  String get compareScore => 'Score';

  @override
  String get compareFeesLabel => 'Fees';

  @override
  String get compareReturn3y => 'Ret. 3y';

  @override
  String get compareEsgLabel => 'Sustain.';

  @override
  String get compareEquity => 'Equity';

  @override
  String get compareLowest => 'Lowest';

  @override
  String get compareBestChoice => 'Best overall choice';

  @override
  String get docTitle => 'Documents';

  @override
  String get docEmptyTitle => 'No documents';

  @override
  String get docEmptyDescription =>
      'Add your pension documents to keep them safe';

  @override
  String get docDelete => 'Delete';

  @override
  String get docUploadTitle => 'Add a document';

  @override
  String get docTypeLabel => 'Document type';

  @override
  String get docIncludeYear => 'Associate a year';

  @override
  String get docYearLabel => 'Year';

  @override
  String get docChooseFile => 'Choose a file';

  @override
  String get docUploading => 'Uploading...';

  @override
  String get docTypeSalarySlip => 'Salary certificate';

  @override
  String get docTypeBvgStatement => 'BVG/LPP statement';

  @override
  String get docTypePillar3aStatement => 'Pillar 3a statement';

  @override
  String get docTypeTaxDeclaration => 'Tax declaration';

  @override
  String get docTypeOther => 'Other';

  @override
  String get docUploadSuccess => 'Document added';

  @override
  String get docDeleted => 'Document deleted';

  @override
  String get docDeleteConfirmTitle => 'Delete this document?';

  @override
  String get docDeleteConfirmBody => 'This action is permanent.';

  @override
  String get docFileTooLarge => 'The file exceeds the maximum size of 10 MB';

  @override
  String get docInvalidFile => 'Unsupported format (PDF, JPEG or PNG)';

  @override
  String get docReadError => 'Unable to read the file';

  @override
  String get docOpenError => 'Unable to open the document';

  @override
  String get scenarioTitle => 'Life scenarios';

  @override
  String get scenarioSectionTitle => 'Simulate the impact on your retirement';

  @override
  String get scenarioFooter =>
      'These simulations are indicative. Consult an advisor for important decisions.';

  @override
  String get scenarioMonth => 'mo';

  @override
  String get scenarioYear => 'yr';

  @override
  String get scenarioPrefillFailed =>
      'Profile not loaded — the form uses default values.';

  @override
  String get scenario3aCatchupTitle => '3a catch-up';

  @override
  String get scenario3aCatchupSubtitle =>
      'Catch up on years you didn\'t contribute (2025 reform)';

  @override
  String get scenario3aCatchupInputSection => 'Your situation';

  @override
  String get scenario3aCatchupYearsMissed => 'Years without contribution';

  @override
  String get scenario3aCatchupResultSection => 'Catch-up potential';

  @override
  String get scenario3aCatchupMaxPerYear => 'Maximum per year';

  @override
  String get scenario3aCatchupTotalCatchup => 'Total possible catch-up';

  @override
  String get scenario3aCatchupTaxSaving => 'Estimated tax saving';

  @override
  String get scenario3aCatchupInfo =>
      'Since 2025, you can catch up on up to 10 years of missed 3a contributions. You must first maximize the current year.';

  @override
  String get scenarioPropertyTitle => 'Property purchase';

  @override
  String get scenarioPropertySubtitle =>
      'Impact of EPL withdrawal on your pension';

  @override
  String get scenarioPropertyInputSection => 'Amounts';

  @override
  String get scenarioPropertyBvgCapital => 'Current BVG capital';

  @override
  String get scenarioPropertyWithdrawal => 'Withdrawal amount';

  @override
  String get scenarioPropertyMaxWithdrawal => 'Max. allowed withdrawal';

  @override
  String get scenarioPropertyEffectiveWithdrawal => 'Effective withdrawal';

  @override
  String get scenarioPropertyImpactSection => 'Impact on retirement';

  @override
  String get scenarioPropertyCapitalWithout =>
      'Capital at retirement (no withdrawal)';

  @override
  String get scenarioPropertyCapitalWith =>
      'Capital at retirement (with withdrawal)';

  @override
  String get scenarioPropertyPensionLoss => 'Monthly pension loss';

  @override
  String get scenarioDivorceTitle => 'Divorce';

  @override
  String get scenarioDivorceSubtitle => 'LPP splitting and pension impact';

  @override
  String get scenarioDivorceMySection => 'Your BVG';

  @override
  String get scenarioDivorceMyCapitalMarriage => 'Capital at marriage';

  @override
  String get scenarioDivorceMyCapitalNow => 'Current capital';

  @override
  String get scenarioDivorceSpouseSection => 'Spouse\'s BVG';

  @override
  String get scenarioDivorceSpouseCapitalMarriage => 'Capital at marriage';

  @override
  String get scenarioDivorceSpouseCapitalNow => 'Current capital';

  @override
  String get scenarioDivorceYearsMarried => 'Years married';

  @override
  String get scenarioDivorceResultSection => 'Splitting result';

  @override
  String get scenarioDivorceTotalMarriageCapital =>
      'Capital accumulated during marriage';

  @override
  String get scenarioDivorceMyShare => 'Your share (50%)';

  @override
  String get scenarioDivorceTransfer => 'Transfer';

  @override
  String get scenarioDivorceCapitalAfter => 'Your capital after divorce';

  @override
  String get scenarioWithdrawalTitle => 'Staggered withdrawal';

  @override
  String get scenarioWithdrawalSubtitle =>
      'Optimize the tax on your 3a withdrawals';

  @override
  String get scenarioWithdrawalInputSection => 'Your assets';

  @override
  String get scenarioWithdrawal3aBalance => 'Total 3a balance';

  @override
  String get scenarioWithdrawalAccounts => 'Number of 3a accounts';

  @override
  String get scenarioWithdrawalPillar2Capital => 'BVG capital (if withdrawing)';

  @override
  String get scenarioWithdrawalComparison => 'Tax comparison';

  @override
  String get scenarioWithdrawalSaving => 'Tax saving';

  @override
  String get scenarioWithdrawalTip =>
      'In Switzerland, capital withdrawals are taxed at progressive rates. Spreading withdrawals over multiple years keeps you in lower tax brackets.';

  @override
  String get scenarioDivorcePensionImpact => 'Impact on annual pension';

  @override
  String get scenario3aCatchupStatusEmployed => 'Employed (with 2nd pillar)';

  @override
  String get scenario3aCatchupStatusSelfEmployed =>
      'Self-employed (no 2nd pillar)';

  @override
  String get scenario3aCatchupEligibleYears => 'Eligible years';

  @override
  String get scenario3aCatchupCurrentYearGap =>
      'Contribute first (current year)';

  @override
  String get scenario3aCatchupMarginalRate => 'Estimated marginal rate';

  @override
  String get scenario3aCatchupYearlySection => 'Year-by-year detail';

  @override
  String get scenarioWithdrawalStrategyLumpSum => 'Lump sum';

  @override
  String scenarioWithdrawalStrategyStaggered(int years) {
    return 'Staggered over $years years';
  }

  @override
  String get scenarioWithdrawalBestStrategy => 'Best strategy';

  @override
  String get scenarioWithdrawalEffectiveRate => 'Effective tax rate';

  @override
  String get scenarioDivorceAvsImpact => 'Estimated AVS pension impact';

  @override
  String get scenarioDivorceDisclaimer =>
      'Indicative simulation of the legal BVG split (50/50 of assets accumulated during the marriage). It does not constitute legal advice.';

  @override
  String get scenarioDivorceYouReceive => 'You receive';

  @override
  String get scenarioDivorceYouPay => 'You pay';

  @override
  String get scenarioDivorceCapitalExceedsNow =>
      'Capital at marriage cannot exceed current capital';

  @override
  String get pdfTitle => 'PocketPillar Pension Report';

  @override
  String get pdfExportButton => 'Export PDF report';

  @override
  String get pdfSectionTitle => 'Export';

  @override
  String get pdfAge => 'Age';

  @override
  String get pdfSalary => 'Salary';

  @override
  String get pdfCanton => 'Canton';

  @override
  String get pdfPillarsTitle => 'Your 3 pillars';

  @override
  String get pdfPillar1 => 'Pillar 1 (AHV)';

  @override
  String get pdfPillar2 => 'Pillar 2 (BVG)';

  @override
  String get pdfPillar3a => 'Pillar 3a';

  @override
  String get pdfProjectionTitle => 'Retirement projection';

  @override
  String get pdfRetirementAge => 'Retirement age';

  @override
  String get pdfYearsRemaining => 'Years remaining';

  @override
  String get pdfReplacementRate => 'Replacement rate';

  @override
  String get pdfAnnualIncome => 'Estimated annual income';

  @override
  String get pdfMonthlyIncome => 'Estimated monthly income';

  @override
  String get pdfTaxTitle => 'Tax savings (3a)';

  @override
  String pdfTaxDetail(String amount) {
    return 'Estimated annual savings: $amount';
  }

  @override
  String get pdfRecommendationsTitle => 'Recommendations';

  @override
  String get pdfRecOpen3a =>
      'Open a pillar 3a to benefit from tax advantages and improve your pension.';

  @override
  String pdfRecMax3a(String amount) {
    return 'Maximize your annual 3a contribution ($amount) to optimize your tax savings.';
  }

  @override
  String get pdfRecIncreaseCoverage =>
      'Your replacement rate is below 60%. Consider a BVG buyback or increasing your 3a savings.';

  @override
  String get pdfRecGoodTrack =>
      'You\'re on the right track! Keep saving regularly.';

  @override
  String get generalSimulationDisclaimer =>
      'Indicative simulation: official 2026 schedules, computed on gross income (without your individual deductions). PocketPillar provides information, not investment advice.';

  @override
  String get pdfDisclaimer =>
      'This document is for informational purposes only and does not constitute financial advice. Projections are based on estimates and may vary. Consult a financial advisor for personalized recommendations. PocketPillar © 2026.';

  @override
  String get checklistCompleted => 'completed';

  @override
  String get checklistAllDone => 'All done!';

  @override
  String get checklistCardTitle => 'Year-end checklist';

  @override
  String checklistCardRemaining(int count) {
    return '$count actions remaining';
  }

  @override
  String get checklistMax3aTitle => 'Maximize pillar 3a';

  @override
  String get checklistMax3aDescription =>
      'Contribute the maximum amount before December 31 to optimize your taxes.';

  @override
  String checklistMax3aValue(String max) {
    return 'Maximum: $max';
  }

  @override
  String get checklistBvgBuybackTitle => 'Check BVG buyback';

  @override
  String get checklistBvgBuybackDescription =>
      'Contact your pension fund to learn about your buyback potential.';

  @override
  String get checklistCertificateTitle => 'Request pension certificate';

  @override
  String get checklistCertificateDescription =>
      'Request your annual BVG certificate from your employer or pension fund.';

  @override
  String get checklistTaxDocsTitle => 'Prepare tax documents';

  @override
  String get checklistTaxDocsDescription =>
      'Gather your 3a certificates and BVG statements for your tax return.';

  @override
  String get checklistUpdateProfileTitle => 'Update profile';

  @override
  String get checklistUpdateProfileDescription =>
      'Check that your salary, age and situation are up to date in PocketPillar.';

  @override
  String get checklistPlanNextTitle => 'Plan next year';

  @override
  String get checklistPlanNextDescription =>
      'Explore scenarios to define your pension strategy for next year.';

  @override
  String get coupleScenarioTitle => 'Couple Mode';

  @override
  String get coupleScenarioSubtitle => 'Simulate your retirement as a couple';

  @override
  String get coupleSectionTitle => 'Couple';

  @override
  String get couplePartnerHas3a => 'Partner has pillar 3a';

  @override
  String get coupleCalculate => 'Calculate couple retirement';

  @override
  String get coupleYou => 'You';

  @override
  String get couplePartner => 'Partner';

  @override
  String get coupleAvs => 'AHV/month';

  @override
  String get coupleBvg => 'BVG/month';

  @override
  String get couplePillar3a => 'Projected 3a capital';

  @override
  String get coupleTotalMonthly => 'Total/month';

  @override
  String get coupleCombinedTitle => 'Combined couple income';

  @override
  String get coupleCombinedMonthly => 'per month (combined pension)';

  @override
  String get coupleReplacementRate => 'Combined replacement rate';

  @override
  String get coupleAvsCapWarning =>
      'The couple AVS cap (150% of individual maximum) applies. Your combined AVS pension is reduced.';

  @override
  String get coupleAvsCapPhasing =>
      'The cap applies once both pensions are paid; while only one spouse is retired, that pension stays uncapped.';

  @override
  String get coupleWithdrawalTitle => 'Optimal withdrawal plan';

  @override
  String get coupleWithdraw3a => 'Pillar 3a withdrawal';

  @override
  String get coupleWithdrawBvg => 'BVG capital withdrawal';

  @override
  String coupleTaxEstimate(String amount) {
    return 'Estimated tax: $amount';
  }

  @override
  String get coupleFormIntro =>
      'Your details are pre-filled from your profile. Enter your partner\'s details to run the simulation.';

  @override
  String get coupleReplacementIndividual => 'Replacement rate';

  @override
  String get coupleSituationTitle => 'Your situation';

  @override
  String get coupleFiscalStatus => 'Simulated tax situation';

  @override
  String get coupleStatusMarried => 'Married';

  @override
  String get coupleStatusPartnership => 'Registered partnership';

  @override
  String get coupleStatusConcubinage => 'Cohabitation';

  @override
  String get coupleTaxTitle => 'Couple taxation';

  @override
  String get coupleTaxMarriedJoint => 'Joint taxation (marriage)';

  @override
  String get coupleTaxUnmarriedSeparate => 'Separate taxation (cohabitation)';

  @override
  String coupleTaxCheaperMarried(String amount) {
    return 'Marriage saves you about $amount in taxes per year.';
  }

  @override
  String coupleTaxCheaperConcubinage(String amount) {
    return 'Cohabitation saves you about $amount in taxes per year.';
  }

  @override
  String get coupleTaxEqual => 'Marriage and cohabitation are tax-equivalent.';

  @override
  String get coupleTaxDisclaimer =>
      'Indicative estimate based on gross incomes (official 2026 schedules: direct federal, cantonal and communal).';

  @override
  String get coupleConversionRate => 'BVG conversion rate (%)';

  @override
  String get coupleConversionRateHint =>
      '6.8% = legal minimum, guaranteed on the mandatory part only. Pension funds often apply a lower blended rate — see your BVG certificate.';

  @override
  String get coupleTimelineTitle => 'Retirement timeline';

  @override
  String get coupleTimelineYouRetire => 'You retire';

  @override
  String get coupleTimelinePartnerRetires => 'Your partner retires';

  @override
  String get coupleTimelineBothRetired => 'Both pensions are running';

  @override
  String coupleTimelineAges(int age1, int age2) {
    return 'You $age1 · Partner $age2';
  }

  @override
  String get coupleTimelineCapBadge => 'AVS cap applied';

  @override
  String get coupleTimelineFullBadge => 'Full pension';

  @override
  String coupleTimelineHouseholdMonthly(String amount) {
    return 'Couple income/month: $amount';
  }

  @override
  String get coupleWithdrawalTotalTax => 'Total plan tax';

  @override
  String get coupleWithdrawalSimultaneous => 'Tax if withdrawn the same year';

  @override
  String get coupleWithdrawalSavings => 'Savings from staggering';

  @override
  String get coupleWithdrawalEmpty =>
      'No projected 3a or BVG capital: the withdrawal plan will appear once a capital is entered.';

  @override
  String get paywallTitle => 'PocketPillar Premium';

  @override
  String get paywallHeadline => 'Unlock your full pension potential';

  @override
  String get paywallPriceFallback => 'CHF 39/year';

  @override
  String paywallPricePerYear(String price) {
    return '$price per year';
  }

  @override
  String get paywallFeaturesTitle => 'Included in Premium';

  @override
  String get paywallFeatureCatchup =>
      '3a catch-up: year-by-year detail and action plan';

  @override
  String get paywallFeatureScenarios =>
      '4 advanced scenarios: couple, staggered withdrawal, property purchase, divorce';

  @override
  String get paywallFeatureOcr =>
      'Document scanning (OCR) to prefill your profile';

  @override
  String get paywallFeatureRecommendations =>
      'Full recommendations and best-match provider for your profile';

  @override
  String get paywallFeaturePdf => 'PDF export of your pension report';

  @override
  String get paywallFeatureDocuments => 'Unlimited documents';

  @override
  String get paywallSubscribe => 'Unlock Premium';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallLegal =>
      'Annual subscription, renews automatically. Manage or cancel anytime in your store settings (App Store / Google Play).';

  @override
  String get paywallUnavailableTitle => 'Purchase unavailable';

  @override
  String get paywallUnavailableBody =>
      'In-app purchase is currently unavailable. Try again later — your free features remain available.';

  @override
  String get paywallOfferingError =>
      'Could not load the offer. Check your connection and try again.';

  @override
  String get paywallPurchaseFailed =>
      'The purchase did not complete. Please try again later.';

  @override
  String get paywallPurchaseSuccess => 'Premium activated — thank you!';

  @override
  String get paywallRestoreSuccess => 'Subscription restored!';

  @override
  String get paywallRestoreNothing =>
      'No subscription to restore for this account.';

  @override
  String get paywallRestoreFailed =>
      'Restore did not complete. Please try again later.';

  @override
  String get paywallAlreadyActive => 'Your Premium subscription is active.';

  @override
  String get settingsPremiumTitle => 'PocketPillar Premium';

  @override
  String get settingsPremiumActive => 'Subscribed';

  @override
  String settingsPremiumActiveUntil(String date) {
    return 'Subscribed — until $date';
  }

  @override
  String get settingsPremiumInactive => 'Not subscribed — CHF 39/year';

  @override
  String get premiumBadgeLabel => 'Premium';

  @override
  String get premiumDiscoverCta => 'Discover Premium';

  @override
  String get premiumUpsellRecommendations =>
      'Personalized recommendations and the full comparison are part of PocketPillar Premium.';

  @override
  String get premiumUpsellBestMatch =>
      'Finding your ideal provider is part of PocketPillar Premium.';

  @override
  String get catchupUpsellTitle => 'Unlock the year-by-year plan';

  @override
  String get catchupUpsellBody =>
      'With Premium, see every catch-up year and your detailed action plan.';
}
