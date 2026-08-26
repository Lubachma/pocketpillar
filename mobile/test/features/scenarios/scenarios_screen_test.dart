import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketpillar/app/routes.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/core/purchases/premium_status.dart';
import 'package:pocketpillar/features/financial_profile/application/financial_profile_providers.dart';
import 'package:pocketpillar/features/scenarios/presentation/scenarios_screen.dart';

import '../../helpers/fakes.dart';

void main() {
  Future<GoRouter> pumpHub(
    WidgetTester tester, {
    bool premium = true,
  }) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: Routes.scenarios,
      routes: [
        GoRoute(
          path: Routes.scenarios,
          builder: (_, _) => const ScenariosScreen(),
          routes: [
            GoRoute(
              path: 'couple',
              builder: (_, _) => Scaffold(
                appBar: AppBar(),
                body: const Text('ROUTE couple'),
              ),
            ),
            GoRoute(
              path: 'catchup-3a',
              builder: (_, _) => Scaffold(
                appBar: AppBar(),
                body: const Text('ROUTE catchup-3a'),
              ),
            ),
            GoRoute(
              path: 'staggered-withdrawal',
              builder: (_, _) => Scaffold(
                appBar: AppBar(),
                body: const Text('ROUTE staggered'),
              ),
            ),
            GoRoute(
              path: 'property-purchase',
              builder: (_, _) => Scaffold(
                appBar: AppBar(),
                body: const Text('ROUTE property'),
              ),
            ),
            GoRoute(
              path: 'divorce-impact',
              builder: (_, _) => Scaffold(
                appBar: AppBar(),
                body: const Text('ROUTE divorce'),
              ),
            ),
          ],
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
          // Premium status via the users/me aggregate (§11) — never a
          // real request in the tests.
          profileAggregateProvider.overrideWith(
            () => FakeProfileAggregateNotifier(
              buildFakeProfileAggregate(
                premium: premium
                    ? PremiumStatus(
                        active: true,
                        expiresAt: DateTime.utc(2027, 8, 10),
                      )
                    : PremiumStatus.none,
              ),
            ),
          ),
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
    return router;
  }

  testWidgets('hub: title, 5 localized cards and warning', (
    tester,
  ) async {
    await pumpHub(tester);

    expect(find.text('Scénarios de vie'), findsOneWidget);
    expect(find.text('Mode Couple'), findsOneWidget);
    expect(find.text('Rattrapage 3a'), findsOneWidget);
    expect(find.text('Retrait échelonné'), findsOneWidget);
    expect(find.text('Achat immobilier'), findsOneWidget);
    expect(find.text('Divorce'), findsOneWidget);
    expect(
      find.text(
        'Ces simulations sont indicatives. Consultez un conseiller pour '
        'des décisions importantes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('premium hub: navigation to the 5 sub-routes, no '
      'lock', (tester) async {
    final router = await pumpHub(tester);

    expect(find.byIcon(Icons.lock_outline), findsNothing);

    final cases = [
      ('Mode Couple', 'ROUTE couple'),
      ('Rattrapage 3a', 'ROUTE catchup-3a'),
      ('Retrait échelonné', 'ROUTE staggered'),
      ('Achat immobilier', 'ROUTE property'),
      ('Divorce', 'ROUTE divorce'),
    ];
    for (final (title, marker) in cases) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text(marker), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Scénarios de vie'), findsOneWidget);
    }
  });

  testWidgets('non-premium hub: lock on the 4 Premium scenarios, '
      'tapping opens the paywall (contract §11)', (tester) async {
    final router = await pumpHub(tester, premium: false);

    // 4 locked scenarios (couple, staggered withdrawal, property
    // purchase, divorce) — catch-up 3a remains open.
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(4));

    for (final title in [
      'Mode Couple',
      'Retrait échelonné',
      'Achat immobilier',
      'Divorce',
    ]) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text('ROUTE paywall'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }

    // Catch-up 3a (free preview) navigates normally.
    await tester.tap(find.text('Rattrapage 3a'));
    await tester.pumpAndSettle();
    expect(find.text('ROUTE catchup-3a'), findsOneWidget);
  });
}
