import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocketpillar/app/app.dart';
import 'package:pocketpillar/core/api/api_client.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/notifications/notification_service.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/core/utils/clock.dart';
import 'package:pocketpillar/features/calculator/application/guided_calculator_controller.dart';
import 'package:pocketpillar/features/calculator/data/calculator_dtos.dart';
import 'package:pocketpillar/features/calculator/data/calculator_payloads.dart';
import 'package:pocketpillar/features/calculator/data/calculator_repository.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_dtos.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_repository.dart';
import 'package:pocketpillar/features/documents/data/document_repository.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart'
    as fp;
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:pocketpillar/features/providers/data/provider_repository.dart';
import 'package:pocketpillar/features/settings/data/account_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/fakes.dart';

/// Fake profile repository (pre-fills the guided Bilan) — same spirit as
/// the one in `test/features/calculator/calculator_screen_test.dart`.
class FakeFinancialProfileRepository extends FinancialProfileRepository {
  FakeFinancialProfileRepository() : super(FakeApiClient());

  fp.ProfileBaseData? baseData;
  List<fp.Pillar2AccountDto> pillar2Accounts = [];
  List<fp.Pillar3aAccountDto> pillar3aAccounts = [];

  @override
  Future<fp.ProfileBaseData> loadBase() async => baseData!;

  @override
  Future<List<fp.Pillar2AccountDto>> fetchPillar2Accounts() async =>
      pillar2Accounts;

  @override
  Future<List<fp.Pillar3aAccountDto>> fetchPillar3aAccounts() async =>
      pillar3aAccounts;
}

/// Fake calculator repository: canned results, last input recorded.
class FakeCalculatorRepository extends CalculatorRepository {
  FakeCalculatorRepository() : super(FakeApiClient());

  CalculatorResults? results;
  GuidedCalculatorInput? lastInput;

  @override
  Future<CalculatorResults> calculateAll(GuidedCalculatorInput input) async {
    lastInput = input;
    return results!;
  }
}

const _retirement = RetirementResultDto(
  yearsToRetirement: 30,
  projectedPillar2Capital: 50000000,
  projectedPillar3aBalance: 8000000,
  annualPillar2Pension: 3000000,
  estimatedAnnualAvsPension: 2352000,
  pillar3aAsLumpSum: 8000000,
  totalAnnualRetirementIncome: 5352000,
  replacementRate: 63.0,
  yearByYearProjection: [
    YearProjectionDto(
      year: 2027,
      age: 36,
      pillar2Capital: 2100000,
      pillar3aBalance: 1758000,
      totalCapital: 3858000,
    ),
    YearProjectionDto(
      year: 2028,
      age: 37,
      pillar2Capital: 2206250,
      pillar3aBalance: 2536074,
      totalCapital: 4742324,
    ),
  ],
);

const _taxSavings = TaxSavingsResultDto(
  federalTaxSaving: 85000,
  cantonalTaxSaving: 90000,
  communalTaxSaving: 45000,
  totalTaxSaving: 220000,
  effectiveReturnRate: 30.31,
  maxContribution: 725800,
  isAtMax: true,
);

const _lppGap = LppGapResultDto(
  coordinatedSalary: 6800000,
  bvgMinContribution: 612000,
  contributionGap: 112000,
  projectedBvgMinCapital: 42000000,
  projectedActualCapital: 38000000,
  capitalGap: 4000000,
  projectedMinAnnualPension: 2520000,
  projectedActualAnnualPension: 2280000,
  pensionGap: 240000,
);

DashboardData _dashboardData() => const DashboardData(
  user: UserDto(
    id: 'u-1',
    email: 'user@example.ch',
    canton: 'VD',
    birthYear: 1991,
    replacementRateGoal: 70,
  ),
  profile: FinancialProfileDto(
    employmentStatus: 'EMPLOYED',
    maritalStatus: 'SINGLE',
    numberOfChildren: 0,
    grossAnnualIncome: 8500000,
  ),
  pillar2Accounts: [
    Pillar2AccountDto(
      id: 'p2-1',
      currentCapital: 2000000,
      annualBvgContribution: 500000,
    ),
  ],
  pillar3aAccounts: [
    Pillar3aAccountDto(
      id: 'p3-1',
      providerName: 'VIAC',
      currentBalance: 1000000,
      annualContribution: 700000,
    ),
  ],
  projection: RetirementProjectionDto(
    yearsToRetirement: 30,
    projectedPillar2Capital: 50000000,
    projectedPillar3aBalance: 8000000,
    annualPillar2Pension: 3000000,
    estimatedAnnualAvsPension: 2352000,
    totalAnnualRetirementIncome: 5352000,
    replacementRate: 63,
  ),
);

RecommendationResultDto _recommendations() => const RecommendationResultDto(
  recommendations: [
    RecommendationDto(
      type: 'MAX_3A_CONTRIBUTION',
      priority: 'HIGH',
      title: 'Reco A',
      description: 'Description A',
      estimatedAnnualImpact: 215000,
    ),
  ],
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository auth;
  late FakeDashboardRepository dashboardRepo;
  late FakeFinancialProfileRepository profileRepo;
  late FakeCalculatorRepository calcRepo;

  /// Fixed clock: 2026, 10am → birthYear 1991 = 35 years old, "Bonjour".
  final fixedNow = DateTime(2026, 8, 5, 10);

  setUp(() {
    auth = FakeAuthRepository();
    dashboardRepo = FakeDashboardRepository()
      ..data = _dashboardData()
      ..recommendations = _recommendations();
    profileRepo = FakeFinancialProfileRepository()
      ..baseData = fp.ProfileBaseData(
        userId: 'u-1',
        email: 'user@example.ch',
        canton: 'VD',
        birthYear: 1991,
        replacementRateGoal: 70,
        loadedAt: fixedNow,
      );
    calcRepo = FakeCalculatorRepository()
      ..results = const CalculatorResults(
        retirement: _retirement,
        taxSavings: _taxSavings,
        lppGap: _lppGap,
      );
  });

  /// Pumps the real app (`PocketPillarApp` + real router) with all
  /// infrastructure providers mocked — no backend/Supabase reachable.
  /// Tall viewport: the ListViews build all their content, taps
  /// don't need to scroll (as in the widget tests).
  Future<void> pumpApp(
    WidgetTester tester, {
    required Map<String, Object> initialPrefs,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          apiClientProvider.overrideWithValue(FakeApiClient()),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
          dashboardRepositoryProvider.overrideWithValue(dashboardRepo),
          financialProfileRepositoryProvider.overrideWithValue(profileRepo),
          calculatorRepositoryProvider.overrideWithValue(calcRepo),
          calculatorClockProvider.overrideWithValue(() => fixedNow),
          clockProvider.overrideWithValue(() => fixedNow),
          providerRepositoryProvider.overrideWithValue(
            FakeProviderRepository(),
          ),
          documentRepositoryProvider.overrideWithValue(
            FakeDocumentRepository(),
          ),
          accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
        ],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'critical flow: onboarding → dev login → dashboard → '
    'guided Bilan → results',
    (tester) async {
      // First launch (onboarding never seen), FR locale.
      await pumpApp(tester, initialPrefs: {'appLocale': 'fr'});

      // Onboarding — 4 pages.
      expect(
        find.text('Votre retraite repose sur 3 piliers'),
        findsOneWidget,
      );
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Comment ça marche ?'), findsOneWidget);
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('PocketPillar vous aide à...'), findsOneWidget);
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text("C'est parti !"), findsOneWidget);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      // Login → developer bypass (debug, Supabase not configured).
      expect(find.text('Se connecter'), findsOneWidget);
      await tester.tap(find.text('Dev Login'));
      await tester.pumpAndSettle();

      // Dashboard fed by the fake repository.
      expect(find.text('Votre projection retraite'), findsOneWidget);

      // Bilan tab → 4-step wizard.
      await tester.tap(find.text('Bilan'));
      await tester.pumpAndSettle();
      expect(find.text('Votre situation'), findsOneWidget);
      expect(find.text('Étape 1 sur 4'), findsOneWidget);
      expect(find.text('35'), findsOneWidget); // pre-filled age (1991)

      await tester.tap(find.text('Suivant')); // situation → income
      await tester.pumpAndSettle();
      expect(find.text('Quel est votre salaire annuel ?'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Revenu brut (CHF)'),
        "95'000",
      );
      await tester.tap(find.text('Suivant')); // income → 2nd pillar
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant')); // 2nd pillar → 3a
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voir mes résultats'));
      await tester.pumpAndSettle();

      // Results from the fake calculator.
      expect(find.text('Vos résultats'), findsOneWidget);
      expect(
        find.text('Votre pension couvrira 63% de votre revenu actuel'),
        findsOneWidget,
      );
      expect(find.text('Vos 3 piliers'), findsOneWidget);
      expect(find.text('Économies fiscales'), findsOneWidget);
      expect(find.text('Écart LPP'), findsOneWidget);

      // The payload was built from the input (CHF → centimes).
      expect(calcRepo.lastInput, isNotNull);
      expect(calcRepo.lastInput!.grossAnnualIncome, 9500000);
      expect(calcRepo.lastInput!.age, 35);
    },
  );

  testWidgets('navigation across the 6 tabs', (tester) async {
    // Onboarding already seen → starts directly on /login.
    await pumpApp(
      tester,
      initialPrefs: {'appLocale': 'fr', 'hasSeenOnboarding': true},
    );
    expect(find.text('Se connecter'), findsOneWidget);
    await tester.tap(find.text('Dev Login'));
    await tester.pumpAndSettle();
    expect(find.text('Votre projection retraite'), findsOneWidget);

    await tester.tap(find.text('Bilan'));
    await tester.pumpAndSettle();
    expect(find.text('Votre situation'), findsOneWidget);

    await tester.tap(find.text('Scénarios'));
    await tester.pumpAndSettle();
    expect(find.text('Scénarios de vie'), findsOneWidget);

    await tester.tap(find.text('Prestataires'));
    await tester.pumpAndSettle();
    expect(find.text('Prestataires 3a'), findsOneWidget);

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun document'), findsOneWidget);

    await tester.tap(find.text('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.text('Verrouillage biométrique'), findsOneWidget);

    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Votre projection retraite'), findsOneWidget);
  });
}
