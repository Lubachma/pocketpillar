import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketpillar/app/routes.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/scenarios/application/scenario_prefill.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_dtos.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_repository.dart';
import 'package:pocketpillar/features/scenarios/presentation/catchup_3a_screen.dart';

import '../../helpers/fakes.dart';

const _result = Catchup3aResultDto(
  maxPerYear: 725800,
  eligibleYears: 1,
  yearDetails: [
    Catchup3aYearDetailDto(
      year: 2025,
      maxContribution: 725800,
      actualContribution: 0,
      gap: 725800,
    ),
  ],
  totalCatchupPotential: 725800,
  currentYearGap: 725800,
  mustMaxCurrentYearFirst: true,
  estimatedTaxSavings: 217740,
  estimatedMarginalRate: 30,
);

void main() {
  late FakeScenarioRepository repo;

  setUp(() {
    repo = FakeScenarioRepository()..catchupResult = _result;
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    ScenarioPrefill prefill = const ScenarioPrefill(),
    bool failPrefillOnce = false,
  }) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var prefillCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scenarioPrefillProvider.overrideWith((ref) async {
            if (failPrefillOnce && ++prefillCalls == 1) {
              throw const NetworkException();
            }
            return prefill;
          }),
          scenarioRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Catchup3aScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prefill: income from profile, employed status', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        employmentStatus: 'EMPLOYED',
        grossAnnualIncome: 9500000,
      ),
    );

    expect(find.text('95000'), findsOneWidget);
    // Form, CTA and info card displayed.
    expect(find.text('Votre situation'), findsOneWidget);
    expect(find.text('Calculer'), findsOneWidget);
    expect(find.text('Salarié·e (avec 2e pilier)'), findsOneWidget);
  });

  testWidgets('calculation: results displayed, payload in centimes', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        employmentStatus: 'EMPLOYED',
        grossAnnualIncome: 9500000,
      ),
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Potentiel de rattrapage'), findsOneWidget);
    expect(find.text("CHF 7'258.00"), findsWidgets); // total, max, gap…
    expect(find.text('~ CHF 2\'177.40'), findsOneWidget); // estimated savings
    expect(find.text('30 %'), findsOneWidget); // marginal rate
    expect(find.text('Détail par année'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
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
    expect(payload['taxableIncome'], 9500000);
    expect(payload['hasSecondPillar'], isTrue);
    expect(payload['yearsSinceFirstEligible'], 1);
  });

  testWidgets('self-employed status: hasSecondPillar false in the payload', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        employmentStatus: 'SELF_EMPLOYED',
        grossAnnualIncome: 9500000,
      ),
    );

    // The self-employed prefill preselects the segment without 2nd pillar.
    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(repo.lastPayload!['hasSecondPillar'], isFalse);
  });

  testWidgets('status without 2nd pillar (UNEMPLOYED): hasSecondPillar false', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        employmentStatus: 'UNEMPLOYED',
        grossAnnualIncome: 9500000,
      ),
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(repo.lastPayload!['hasSecondPillar'], isFalse);
  });

  testWidgets('validation: empty income → localized error, no call', (
    tester,
  ) async {
    await pumpScreen(tester); // no prefill: empty income

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Champ requis'), findsOneWidget);
    expect(repo.calls, 0);
  });

  testWidgets('network error: inline card + retry relaunches the calculation', (
    tester,
  ) async {
    repo.failOnce = true;
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(grossAnnualIncome: 9500000),
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Erreur réseau'), findsOneWidget);
    // The form remains visible (input preserved).
    expect(find.text('Votre situation'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Potentiel de rattrapage'), findsOneWidget);
    expect(repo.calls, 2);
  });

  testWidgets('free preview (premiumRequired, contract §11): totals '
      'displayed, no year-by-year detail, upsell card → paywall', (
    tester,
  ) async {
    // "Honest preview" response: totals served, yearDetails emptied.
    repo.catchupResult = const Catchup3aResultDto(
      maxPerYear: 725800,
      eligibleYears: 3,
      yearDetails: [],
      totalCatchupPotential: 2177400,
      currentYearGap: 725800,
      mustMaxCurrentYearFirst: true,
      estimatedTaxSavings: 653220,
      estimatedMarginalRate: 30,
      premiumRequired: true,
    );
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: Routes.scenarioCatchup3a,
      routes: [
        GoRoute(
          path: Routes.scenarioCatchup3a,
          builder: (_, _) => const Catchup3aScreen(),
        ),
        GoRoute(
          path: Routes.paywall,
          builder: (_, _) => Scaffold(
            appBar: AppBar(),
            body: const Text('ROUTE paywall'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scenarioPrefillProvider.overrideWith(
            (ref) async => const ScenarioPrefill(
              employmentStatus: 'EMPLOYED',
              grossAnnualIncome: 9500000,
            ),
          ),
          scenarioRepositoryProvider.overrideWithValue(repo),
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

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    // The free preview totals remain displayed.
    expect(find.text('Potentiel de rattrapage'), findsOneWidget);
    expect(find.text("CHF 21'774.00"), findsOneWidget); // total
    expect(find.text('~ CHF 6\'532.20'), findsOneWidget); // savings
    // No year-by-year plan…
    expect(find.text('Détail par année'), findsNothing);
    // …but the upsell card with the CTA to the paywall.
    expect(find.text('Débloquez le plan année par année'), findsOneWidget);
    expect(
      find.text(
        'Avec Premium, visualisez chaque année rattrapable et votre plan '
        'd\'action détaillé.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Découvrir Premium'));
    await tester.pumpAndSettle();
    expect(find.text('ROUTE paywall'), findsOneWidget);
  });

  testWidgets('premium result (premiumRequired false): no upsell '
      'card, year-by-year detail displayed', (tester) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        employmentStatus: 'EMPLOYED',
        grossAnnualIncome: 9500000,
      ),
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Détail par année'), findsOneWidget);
    expect(find.text('Débloquez le plan année par année'), findsNothing);
    expect(find.text('Découvrir Premium'), findsNothing);
  });

  testWidgets('prefill error: non-blocking banner, form usable '
      'with defaults, retry reloads', (
    tester,
  ) async {
    await pumpScreen(tester, failPrefillOnce: true);

    // Banner displayed, form present (no error screen).
    expect(
      find.text(
        'Profil non chargé — le formulaire utilise les valeurs par défaut.',
      ),
      findsOneWidget,
    );
    expect(find.text('Votre situation'), findsOneWidget);

    // The form is usable with the default values: manual
    // income entry, calculation succeeds.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu imposable (CHF)'),
      '95000',
    );
    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();
    expect(find.text('Potentiel de rattrapage'), findsOneWidget);
    expect(repo.calls, 1);

    // The banner retry reloads the prefill (success on the 2nd call).
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Profil non chargé'), findsNothing);
  });
}
