import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/scenarios/application/scenario_prefill.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_dtos.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_repository.dart';
import 'package:pocketpillar/features/scenarios/presentation/divorce_impact_screen.dart';

import '../../helpers/fakes.dart';

/// Real backend response (40 years old, 10-year marriage, assets CHF 50k→200k
/// on the user's side and CHF 30k→150k on the spouse's side): negative transfer
/// (the user pays).
const _result = DivorceImpactResultDto(
  myAccumulatedDuringMarriage: 15000000,
  spouseAccumulatedDuringMarriage: 12000000,
  totalMarriageCapital: 27000000,
  transferAmount: -1500000,
  capitalAfterDivorce: 18500000,
  projectedCapitalWithMarriage: 41851576,
  projectedCapitalAfterDivorce: 39805286,
  annualPensionWithMarriage: 2511095,
  annualPensionAfterDivorce: 2388317,
  annualPensionDifference: 122778,
  estimatedAvsImpact: 294000,
);

void main() {
  late FakeScenarioRepository repo;

  setUp(() {
    repo = FakeScenarioRepository()..divorceResult = _result;
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    ScenarioPrefill prefill = const ScenarioPrefill(),
  }) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scenarioPrefillProvider.overrideWith((ref) async => prefill),
          scenarioRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DivorceImpactScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Fills in the 4 capital amounts (the "au mariage" fields stay at 0
  /// when left empty — empty = 0).
  Future<void> fillForm(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital au mariage').first,
      '50000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital actuel').first,
      '200000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital au mariage').last,
      '30000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital actuel').last,
      '150000',
    );
  }

  testWidgets('prefill: current LPP capital on the user side', (tester) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        age: 40,
        pillar2Capital: 20000000,
        pillar2Contribution: 500000,
      ),
    );

    expect(find.text('200000'), findsOneWidget);
    expect(find.text('Votre LPP'), findsOneWidget);
    expect(find.text('LPP du conjoint'), findsOneWidget);
  });

  testWidgets(
    'calculation: split, « Vous payez » transfer, pension/AVS impact, disclaimer',
    (tester) async {
      await pumpScreen(
        tester,
        prefill: const ScenarioPrefill(age: 40, pillar2Contribution: 500000),
      );
      await fillForm(tester);

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      expect(find.text('Résultat du partage'), findsOneWidget);
      expect(find.text("CHF 270'000.00"), findsOneWidget); // marriage total
      expect(find.text("CHF 135'000.00"), findsOneWidget); // 50% share
      expect(find.text("-CHF 15'000.00"), findsOneWidget); // transfer
      expect(find.text('Vous payez'), findsOneWidget);
      expect(find.text("CHF 185'000.00"), findsOneWidget); // capital after
      expect(find.text("-CHF 1'227.78/an"), findsOneWidget); // LPP pension
      expect(find.text("-CHF 2'940.00/an"), findsOneWidget); // AVS pension
      // Neutrality: disclaimer displayed, figures without legal advice.
      expect(
        find.textContaining('ne constitue pas un conseil juridique'),
        findsOneWidget,
      );

      final payload = repo.lastPayload!;
      expect(payload['bvgCapitalAtMarriage'], 5000000);
      expect(payload['bvgCapitalNow'], 20000000);
      expect(payload['spouseBvgCapitalAtMarriage'], 3000000);
      expect(payload['spouseBvgCapitalNow'], 15000000);
      expect(payload['yearsMarried'], 10);
      expect(payload['age'], 40);
      expect(payload['annualContribution'], 500000);
    },
  );

  testWidgets('positive transfer: « Vous recevez » in green', (tester) async {
    repo.divorceResult = const DivorceImpactResultDto(
      myAccumulatedDuringMarriage: 12000000,
      spouseAccumulatedDuringMarriage: 15000000,
      totalMarriageCapital: 27000000,
      transferAmount: 1500000,
      capitalAfterDivorce: 16500000,
      projectedCapitalWithMarriage: 39805286,
      projectedCapitalAfterDivorce: 41851576,
      annualPensionWithMarriage: 2388317,
      annualPensionAfterDivorce: 2511095,
      annualPensionDifference: -122778,
      estimatedAvsImpact: 294000,
    );
    await pumpScreen(tester);
    await fillForm(tester);

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text("+CHF 15'000.00"), findsOneWidget);
    expect(find.text('Vous recevez'), findsOneWidget);
    expect(find.text("+CHF 1'227.78/an"), findsOneWidget); // pension gain
  });

  testWidgets('validation: empty current spouse capital → error, no call', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    // Required fields empty (my current capital + the spouse's).
    expect(find.text('Champ requis'), findsWidgets);
    expect(repo.calls, 0);
  });

  testWidgets('network error: inline card + retry', (tester) async {
    repo.failOnce = true;
    await pumpScreen(tester);
    await fillForm(tester);

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Erreur réseau'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Résultat du partage'), findsOneWidget);
    expect(repo.calls, 2);
  });

  testWidgets('cross-validation: capital at marriage > current capital blocks '
      'submission (per spouse)', (tester) async {
    await pumpScreen(tester);

    // Inversion on the user's side: marriage 200'000 > current 150'000.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital au mariage').first,
      '200000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital actuel').first,
      '150000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital au mariage').last,
      '30000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital actuel').last,
      '150000',
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Le capital au mariage ne peut pas dépasser le capital actuel'),
      findsOneWidget,
    );
    expect(repo.calls, 0);

    // Inversion on the spouse's side (the user's figures are consistent).
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital au mariage').first,
      '50000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital actuel').first,
      '200000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital au mariage').last,
      '300000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital actuel').last,
      '150000',
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Le capital au mariage ne peut pas dépasser le capital actuel'),
      findsOneWidget,
    );
    expect(repo.calls, 0);
  });

  testWidgets('zero impact: LPP pension and AVS lines hidden (like iOS)', (
    tester,
  ) async {
    repo.divorceResult = const DivorceImpactResultDto(
      myAccumulatedDuringMarriage: 15000000,
      spouseAccumulatedDuringMarriage: 15000000,
      totalMarriageCapital: 30000000,
      transferAmount: 0,
      capitalAfterDivorce: 20000000,
      projectedCapitalWithMarriage: 41851576,
      projectedCapitalAfterDivorce: 41851576,
      annualPensionWithMarriage: 2511095,
      annualPensionAfterDivorce: 2511095,
      annualPensionDifference: 0,
      estimatedAvsImpact: 0,
    );
    await pumpScreen(tester);
    await fillForm(tester);

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Résultat du partage'), findsOneWidget);
    // Neither a green "-CHF 0.00/an", nor a zero AVS line.
    expect(find.text('Impact sur la rente annuelle'), findsNothing);
    expect(find.text('Impact estimé sur la rente AVS'), findsNothing);
    // The split lines remain displayed.
    expect(find.text("CHF 300'000.00"), findsOneWidget);
  });
}
