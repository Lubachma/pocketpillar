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
import 'package:pocketpillar/features/scenarios/presentation/staggered_withdrawal_screen.dart';

import '../../helpers/fakes.dart';

/// Real backend response (VD, 3a CHF 150'000, 3 accounts, 60 years old,
/// SINGLE, LPP CHF 200'000): 3 strategies, best = 3 years.
const _result = StaggeredWithdrawalResultDto(
  strategies: [
    WithdrawalStrategyDto(
      label: 'lump_sum',
      years: [WithdrawalYearDto(year: 2031, amount: 35000000)],
      totalTax: 2493820,
      effectiveTaxRate: 7.13,
    ),
    WithdrawalStrategyDto(
      label: 'stagger_2_years',
      years: [
        WithdrawalYearDto(year: 2030, amount: 17500000),
        WithdrawalYearDto(year: 2031, amount: 17500000),
      ],
      totalTax: 1729112,
      effectiveTaxRate: 4.94,
    ),
    WithdrawalStrategyDto(
      label: 'stagger_3_years',
      years: [
        WithdrawalYearDto(year: 2029, amount: 11666667),
        WithdrawalYearDto(year: 2030, amount: 11666667),
        WithdrawalYearDto(year: 2031, amount: 11666666),
      ],
      totalTax: 1310595,
      effectiveTaxRate: 3.74,
    ),
  ],
  bestStrategy: 'stagger_3_years',
  taxSavingsVsLumpSum: 1183225,
);

void main() {
  late FakeScenarioRepository repo;

  setUp(() {
    repo = FakeScenarioRepository()..staggeredResult = _result;
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
          home: const StaggeredWithdrawalScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prefill: 3a/LPP balances and number of accounts', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        age: 60,
        canton: 'VD',
        maritalStatus: 'MARRIED',
        pillar2Capital: 20000000,
        pillar3aBalance: 15000000,
        pillar3aAccountCount: 3,
      ),
    );

    expect(find.text('150000'), findsOneWidget); // 3a balance
    expect(find.text('200000'), findsOneWidget); // LPP capital
    expect(find.text('3'), findsWidgets); // number of accounts (slider)
  });

  testWidgets('calculation: 3 strategies, best one highlighted, savings', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        age: 60,
        canton: 'VD',
        maritalStatus: 'REGISTERED_PARTNERSHIP',
        pillar3aBalance: 15000000,
        pillar3aAccountCount: 3,
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital LPP en capital (si retrait)'),
      '200000',
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Comparaison fiscale'), findsOneWidget);
    expect(find.text('Retrait unique'), findsOneWidget);
    expect(find.text('Échelonné sur 2 ans'), findsOneWidget);
    expect(find.text('Échelonné sur 3 ans'), findsOneWidget);
    // Badge only on the backend's bestStrategy.
    expect(find.text('Meilleure stratégie'), findsOneWidget);
    expect(find.text("CHF 24'938.20"), findsOneWidget); // lump sum tax
    expect(find.text("CHF 13'105.95"), findsOneWidget); // 3-year tax
    expect(find.text("CHF 11'832.25"), findsOneWidget); // savings
    // LSFin disclaimer displayed with the results.
    expect(
      find.text(
        'Simulation indicative : barèmes officiels 2026, calculée sur le '
        'revenu brut (sans vos déductions individuelles). PocketPillar '
        "fournit de l'information, pas du conseil en placement (LSFin).",
      ),
      findsOneWidget,
    );

    // Marital status mapping: REGISTERED_PARTNERSHIP → MARRIED (backend's
    // real marital tax scale).
    final payload = repo.lastPayload!;
    expect(payload['maritalStatus'], 'MARRIED');
    expect(payload['totalPillar3aBalance'], 15000000);
    expect(payload['pillar2AsCapital'], 20000000);
    expect(payload['numberOfAccounts'], 3);
    expect(payload['currentAge'], 60);
    expect(payload['canton'], 'VD');
  });

  testWidgets('no profile: defaults VD / 40 years old / SINGLE', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Solde total 3a'),
      '150000',
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    final payload = repo.lastPayload!;
    expect(payload['canton'], 'VD');
    expect(payload['currentAge'], 40);
    expect(payload['maritalStatus'], 'SINGLE');
  });

  testWidgets('validation: empty 3a balance → error, no call', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Champ requis'), findsOneWidget);
    expect(repo.calls, 0);
  });

  testWidgets('network error: inline card + retry', (tester) async {
    repo.failOnce = true;
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(pillar3aBalance: 15000000),
    );

    await tester.tap(find.text('Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('Erreur réseau'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Comparaison fiscale'), findsOneWidget);
    expect(repo.calls, 2);
  });

  testWidgets('402 (subscription expired on the backend): paywall open, '
      'no error card, input preserved (contract §11)', (tester) async {
    repo.error = const PremiumRequiredException('Abonnement requis');
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: Routes.scenarioStaggeredWithdrawal,
      routes: [
        GoRoute(
          path: Routes.scenarioStaggeredWithdrawal,
          builder: (_, _) => const StaggeredWithdrawalScreen(),
        ),
        GoRoute(
          path: Routes.paywall,
          builder: (_, _) =>
              Scaffold(appBar: AppBar(), body: const Text('ROUTE paywall')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scenarioPrefillProvider.overrideWith(
            (ref) async => const ScenarioPrefill(pillar3aBalance: 15000000),
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

    // Paywall open, no error card.
    expect(find.text('ROUTE paywall'), findsOneWidget);
    expect(find.text('Abonnement requis'), findsNothing);

    // Back: the form is intact (input preserved).
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('150000'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });
}
