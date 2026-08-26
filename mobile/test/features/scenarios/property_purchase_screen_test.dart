import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/scenarios/application/scenario_prefill.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_dtos.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_repository.dart';
import 'package:pocketpillar/features/scenarios/presentation/property_purchase_screen.dart';

import '../../helpers/fakes.dart';

/// Real backend response (40 years old, capital CHF 200'000, withdrawal
/// CHF 50'000, contribution CHF 5'000/year).
const _result = PropertyPurchaseResultDto(
  maxWithdrawal: 20000000,
  effectiveWithdrawal: 5000000,
  capitalAtRetirementWithout: 41851576,
  capitalAtRetirementWith: 35030613,
  capitalLostAtRetirement: 6820963,
  annualPensionWithout: 2511095,
  annualPensionWith: 2101837,
  annualPensionLoss: 409258,
  monthlyPensionLoss: 34105,
);

void main() {
  late FakeScenarioRepository repo;

  setUp(() {
    repo = FakeScenarioRepository()..propertyResult = _result;
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
          home: const PropertyPurchaseScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prefill: LPP capital and age from the profile', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        age: 40,
        pillar2Capital: 20000000,
        pillar2Contribution: 500000,
      ),
    );

    expect(find.text('200000'), findsOneWidget);
    expect(find.text('40'), findsWidgets); // age (slider value)
  });

  testWidgets('calculation: impact displayed, payload in centimes', (tester) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        age: 40,
        pillar2Capital: 20000000,
        pillar2Contribution: 500000,
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Montant du retrait'),
      '50000',
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Impact sur la retraite'), findsOneWidget);
    expect(find.text("CHF 200'000.00"), findsOneWidget); // max withdrawal
    expect(find.text("CHF 50'000.00"), findsOneWidget); // effective withdrawal
    expect(find.text("CHF 418'515.76"), findsOneWidget); // capital without
    expect(find.text("CHF 350'306.13"), findsOneWidget); // capital with
    expect(find.text('-CHF 341.05/mois'), findsOneWidget); // pension loss
    // LSFin disclaimer displayed with the results.
    expect(
      find.text(
        'Simulation indicative basée sur des barèmes simplifiés. '
        "PocketPillar fournit de l'information, pas du conseil en "
        'placement (LSFin).',
      ),
      findsOneWidget,
    );

    final payload = repo.lastPayload!;
    expect(payload['age'], 40);
    expect(payload['currentBvgCapital'], 20000000);
    expect(payload['withdrawalAmount'], 5000000);
    expect(payload['annualContribution'], 500000);
    expect(payload['retirementAge'], 65);
  });

  testWidgets('validation: empty withdrawal → error, no call', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(pillar2Capital: 20000000),
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Champ requis'), findsOneWidget);
    expect(repo.calls, 0);
  });

  testWidgets(
    'error 400 EPL: localized message from the backend, form intact, retry',
    (tester) async {
      repo.error = const ApiException(
        "Le retrait minimum pour un EPL est de CHF 20'000",
        statusCode: 400,
      );
      await pumpScreen(
        tester,
        prefill: const ScenarioPrefill(pillar2Capital: 20000000),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Montant du retrait'),
        '5000', // below the legal minimum of CHF 20'000
      );

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      // Backend message displayed as-is, form preserved.
      expect(
        find.text("Le retrait minimum pour un EPL est de CHF 20'000"),
        findsOneWidget,
      );
      expect(find.text('Montants'), findsOneWidget);
      expect(find.text('5000'), findsOneWidget);

      // The user corrects the amount then retries.
      repo.error = null;
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Montant du retrait'),
        '50000',
      );
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Impact sur la retraite'), findsOneWidget);
      expect(repo.calls, 2);
      expect(repo.lastPayload!['withdrawalAmount'], 5000000);
    },
  );
}
