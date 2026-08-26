import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketpillar/app/routes.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/calculator/application/guided_calculator_controller.dart';
import 'package:pocketpillar/features/calculator/data/calculator_dtos.dart';
import 'package:pocketpillar/features/calculator/data/calculator_payloads.dart';
import 'package:pocketpillar/features/calculator/data/calculator_repository.dart';
import 'package:pocketpillar/features/calculator/presentation/calculator_screen.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:pocketpillar/features/financial_profile/data/municipality.dart';

import '../../helpers/fakes.dart';

/// Mock profile repository: canned data, configurable one-off failure.
class FakeFinancialProfileRepository extends FinancialProfileRepository {
  FakeFinancialProfileRepository() : super(FakeApiClient());

  ProfileBaseData? baseData;
  List<Pillar2AccountDto> pillar2Accounts = [];
  List<Pillar3aAccountDto> pillar3aAccounts = [];

  /// Municipalities served to the Commune picker in the situation step.
  List<MunicipalityInfo> municipalities = [];

  bool failLoadOnce = false;
  int loadCalls = 0;

  @override
  Future<ProfileBaseData> loadBase() async {
    final call = ++loadCalls;
    if (failLoadOnce && call == 1) throw const NetworkException();
    return baseData!;
  }

  @override
  Future<List<Pillar2AccountDto>> fetchPillar2Accounts() async =>
      pillar2Accounts;

  @override
  Future<List<Pillar3aAccountDto>> fetchPillar3aAccounts() async =>
      pillar3aAccounts;

  @override
  Future<List<MunicipalityInfo>> fetchMunicipalities(String canton) async =>
      municipalities;
}

/// Mock calculator repository: canned results, configurable one-off
/// failure to test the retry.
class FakeCalculatorRepository extends CalculatorRepository {
  FakeCalculatorRepository() : super(FakeApiClient());

  CalculatorResults? results;
  GuidedCalculatorInput? lastInput;
  bool failOnce = false;
  int calls = 0;

  @override
  Future<CalculatorResults> calculateAll(GuidedCalculatorInput input) async {
    lastInput = input;
    final call = ++calls;
    if (failOnce && call == 1) throw const NetworkException();
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

CalculatorResults _results({bool withLppGap = true}) => CalculatorResults(
  retirement: _retirement,
  taxSavings: _taxSavings,
  lppGap: withLppGap ? _lppGap : null,
);

void main() {
  late FakeFinancialProfileRepository profileRepo;
  late FakeCalculatorRepository calcRepo;

  /// Fixed clock: 2026 → birthYear 1991 = 35 years old, 2008 = 18.
  final fixedNow = DateTime(2026, 8, 5);

  ProfileBaseData baseData({int birthYear = 1991, bool withProfile = false}) =>
      ProfileBaseData(
        userId: 'u-1',
        email: 'user@example.ch',
        canton: 'VD',
        birthYear: birthYear,
        replacementRateGoal: 70,
        profile: withProfile
            ? const FinancialProfileDto(
                id: 'fp-1',
                employmentStatus: 'EMPLOYED',
                maritalStatus: 'MARRIED',
                numberOfChildren: 0,
                grossAnnualIncome: 9500000,
              )
            : null,
        loadedAt: fixedNow,
      );

  setUp(() {
    profileRepo = FakeFinancialProfileRepository();
    calcRepo = FakeCalculatorRepository();
    profileRepo.baseData = baseData();
    calcRepo.results = _results();
  });

  /// Tall viewport: the ListViews build all their content, so
  /// assertions don't need to scroll.
  Future<void> pumpCalculator(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: Routes.calculator,
      routes: [
        GoRoute(
          path: Routes.calculator,
          builder: (_, _) => const CalculatorScreen(),
        ),
        GoRoute(
          path: Routes.providers,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Prestataires'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financialProfileRepositoryProvider.overrideWithValue(profileRepo),
          calculatorRepositoryProvider.overrideWithValue(calcRepo),
          calculatorClockProvider.overrideWithValue(() => fixedNow),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Walks the wizard through to the results. [income] is entered as-is
  /// (CHF, never centimes).
  Future<void> completeWizard(
    WidgetTester tester, {
    String income = "95'000",
  }) async {
    await tester.tap(find.text('Suivant')); // situation → income
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut (CHF)'),
      income,
    );
    await tester.tap(find.text('Suivant')); // income → 2nd pillar
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant')); // 2nd pillar → 3a
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir mes résultats'));
    await tester.pumpAndSettle();
  }

  testWidgets('wizard navigation: steps, calculation, and results shown', (
    tester,
  ) async {
    await pumpCalculator(tester);

    // Step 1 — situation (pre-filled: age 35 via birthYear 1991, VD).
    expect(find.text('Votre situation'), findsOneWidget);
    expect(find.text('Étape 1 sur 4'), findsOneWidget);
    expect(find.text('35'), findsOneWidget);

    await completeWizard(tester);

    // Results: AppBar title + summary + sections.
    expect(find.text('Vos résultats'), findsOneWidget);
    expect(
      find.text('Votre pension couvrira 63% de votre revenu actuel'),
      findsOneWidget,
    );
    expect(find.text('Vos 3 piliers'), findsOneWidget);
    expect(find.text('Projection retraite'), findsOneWidget);
    expect(find.text('Économies fiscales'), findsOneWidget);
    expect(find.text("CHF 2'200.00"), findsOneWidget); // total savings
    expect(find.text('Écart LPP'), findsOneWidget);
    expect(find.text('Que faire maintenant ?'), findsOneWidget);
    expect(find.text('Exporter le bilan PDF'), findsOneWidget);

    // Payload built from the input (centimes).
    final input = calcRepo.lastInput!;
    expect(input.age, 35);
    expect(input.canton, 'VD');
    expect(input.grossAnnualIncome, 9500000);
    expect(input.hasPillar3a, isFalse);
  });

  testWidgets('situation step: Commune tile, selection passed to the '
      'calculation', (tester) async {
    profileRepo.municipalities = const [
      MunicipalityInfo(name: 'Échallens', multiplier: 78),
      MunicipalityInfo(name: 'Lausanne', multiplier: 79.5),
    ];
    await pumpCalculator(tester);

    // Tile below the canton tile: cantonal average as long as nothing
    // is selected.
    expect(find.text('Commune'), findsOneWidget);
    expect(find.text('Moyenne cantonale (commune non listée)'), findsOneWidget);

    await tester.tap(find.text('Commune'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lausanne'));
    await tester.pumpAndSettle();
    expect(find.text('Lausanne'), findsOneWidget);

    await completeWizard(tester);
    expect(calcRepo.lastInput!.municipality, 'Lausanne');
  });

  testWidgets('situation step: the « moyenne cantonale » option deselects '
      'the chosen municipality', (tester) async {
    profileRepo.municipalities = const [
      MunicipalityInfo(name: 'Échallens', multiplier: 78),
      MunicipalityInfo(name: 'Lausanne', multiplier: 79.5),
    ];
    await pumpCalculator(tester);

    await tester.tap(find.text('Commune'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lausanne'));
    await tester.pumpAndSettle();
    expect(find.text('Lausanne'), findsOneWidget);

    // Explicit deselection via the « moyenne cantonale » option.
    await tester.tap(find.text('Lausanne'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moyenne cantonale (commune non listée)'));
    await tester.pumpAndSettle();
    expect(find.text('Lausanne'), findsNothing);

    await completeWizard(tester);
    expect(calcRepo.lastInput!.municipality, isNull);
  });

  testWidgets('validation: empty income blocks the step, no API call', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(find.text('Suivant')); // situation → income
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant')); // no input
    await tester.pumpAndSettle();

    expect(find.text('Champ requis'), findsOneWidget);
    // Still on the income step.
    expect(find.text('Quel est votre salaire annuel ?'), findsOneWidget);
    expect(calcRepo.calls, 0);
  });

  testWidgets('validation: invalid amount blocked', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut (CHF)'),
      'abc',
    );
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(find.text('Montant invalide'), findsOneWidget);
    expect(calcRepo.calls, 0);
  });

  testWidgets('profile pre-fill: income, LPP/3a accounts, and 3a « Oui »', (
    tester,
  ) async {
    profileRepo.baseData = baseData(withProfile: true);
    profileRepo.pillar2Accounts = const [
      Pillar2AccountDto(
        id: 'p2-1',
        currentCapital: 2000000,
        annualBvgContribution: 500000,
        isVestedBenefits: false,
      ),
    ];
    profileRepo.pillar3aAccounts = const [
      Pillar3aAccountDto(
        id: 'p3-1',
        providerName: 'VIAC',
        accountType: 'BANK',
        currentBalance: 1000000,
      ),
    ];
    await pumpCalculator(tester);

    // Pre-filled income (CHF, no centimes exposed).
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('95000'), findsOneWidget);

    // 2nd pillar pre-filled (account sums).
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('20000'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget);

    // 3a pre-filled.
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('10000'), findsOneWidget);

    await tester.tap(find.text('Voir mes résultats'));
    await tester.pumpAndSettle();

    final input = calcRepo.lastInput!;
    expect(input.grossAnnualIncome, 9500000);
    expect(input.maritalStatus, 'MARRIED');
    expect(input.pillar2Capital, 2000000);
    expect(input.pillar2Contribution, 500000);
    expect(input.hasPillar3a, isTrue);
    expect(input.pillar3aBalance, 1000000);
  });

  testWidgets(
    'calculation error: message + retry relaunches the calculations',
    (tester) async {
      calcRepo.failOnce = true;
      await pumpCalculator(tester);

      await completeWizard(tester);

      expect(find.text('Erreur réseau'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Vos résultats'), findsOneWidget);
      expect(calcRepo.calls, 2);
    },
  );

  testWidgets('pre-fill error: message + retry', (tester) async {
    profileRepo.failLoadOnce = true;
    await pumpCalculator(tester);

    expect(find.text('Erreur réseau'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Votre situation'), findsOneWidget);
    expect(profileRepo.loadCalls, 2);
  });

  testWidgets('age < 25: no Écart LPP card', (tester) async {
    profileRepo.baseData = baseData(birthYear: 2008); // 18 in 2026
    calcRepo.results = _results(withLppGap: false);
    await pumpCalculator(tester);

    await completeWizard(tester);

    expect(find.text('Vos résultats'), findsOneWidget);
    expect(find.text('Écart LPP'), findsNothing);
    expect(calcRepo.lastInput!.age, 18);
  });

  testWidgets('LPP buy-in recommendation → educational sheet', (tester) async {
    await pumpCalculator(tester);

    await completeWizard(tester);

    expect(find.text('Écart LPP'), findsOneWidget);
    await tester.tap(
      find.text(
        'Un rachat LPP pourrait combler votre écart de rente et réduire '
        'vos impôts',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rachat LPP'), findsWidgets);
    expect(find.text('Avantages'), findsOneWidget);
    expect(find.text('Comment faire ?'), findsOneWidget);
  });

  testWidgets('contextual help: tooltip on gross income', (tester) async {
    await pumpCalculator(tester);

    await tester.tap(find.text('Suivant')); // → income
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Revenu brut'), findsOneWidget);
    expect(find.text("C'est quoi ?"), findsOneWidget);
    expect(find.text("Pourquoi c'est important ?"), findsOneWidget);
    expect(find.text('Où trouver cette info ?'), findsOneWidget);
  });

  testWidgets('restart: back to the wizard, inputs kept', (tester) async {
    await pumpCalculator(tester);

    await completeWizard(tester);
    expect(find.text('Vos résultats'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.restart_alt));
    await tester.pumpAndSettle();

    expect(find.text('Votre situation'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    // The entered income is kept (like the iOS restart()).
    expect(find.text('95000'), findsOneWidget);
  });
}
