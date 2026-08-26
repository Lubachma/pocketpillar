import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/providers/application/providers_providers.dart';
import 'package:pocketpillar/features/providers/data/provider_dtos.dart';
import 'package:pocketpillar/features/providers/data/provider_repository.dart';
import 'package:pocketpillar/features/providers/presentation/providers_screen.dart';

import '../../helpers/fakes.dart';

const _catalogue = [
  ProviderDto(
    id: 'p1',
    slug: 'ubs',
    name: 'UBS',
    website: 'https://ubs.com',
    isDigital: false,
    products: [],
  ),
  ProviderDto(
    id: 'p2',
    slug: 'postfinance',
    name: 'PostFinance',
    isDigital: true,
    products: [],
  ),
];

ScoredProductDto _scored(
  String id,
  String provider,
  String product,
  int score,
) => ScoredProductDto(
  productId: id,
  providerName: provider,
  providerSlug: provider.toLowerCase(),
  productName: product,
  productSlug: product.toLowerCase(),
  riskLevel: 'GROWTH',
  equityAllocation: 80,
  allInFeePercent: 0.44,
  sustainableEsg: false,
  avgReturn3y: 7.5,
  score: score,
);

final _scoredList = [
  _scored('s1', 'VIAC', 'Global 100', 92),
  _scored('s2', 'finpension', 'Equity 100', 90),
  _scored('s3', 'Frankly', 'Strong 85', 85),
  _scored('s4', 'Swisscanto', 'BVG 3 75', 70),
];

void main() {
  late FakeProviderRepository repo;

  setUp(() {
    repo = FakeProviderRepository()
      ..providers = _catalogue
      ..scored = _scoredList;
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [providerRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProvidersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('list: best match CTA, scored ranking and catalog', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Prestataires 3a'), findsOneWidget);
    // CTA best match.
    expect(find.text('Trouver mon 3a idéal'), findsOneWidget);
    // Ranking (GROWTH risk by default — iOS default).
    expect(find.text('Classement'), findsOneWidget);
    expect(find.text('Global 100'), findsOneWidget);
    expect(find.text('92'), findsOneWidget); // score badge
    expect(find.text('0.44 %'), findsWidgets);
    expect(find.text('80 %'), findsWidgets);
    expect(repo.lastCompareRiskLevel, 'GROWTH');
    // Catalog (Digital badge on the online provider).
    expect(find.text('Tous les prestataires'), findsOneWidget);
    expect(find.text('UBS'), findsOneWidget);
    expect(find.text('PostFinance'), findsOneWidget);
    expect(find.text('Digital'), findsOneWidget);
  });

  testWidgets('risk filter: the menu reloads the ranking', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Équilibré'));
    await tester.pumpAndSettle();

    expect(repo.lastCompareRiskLevel, 'BALANCED');
  });

  testWidgets('selection: compare button appears from 2 products, cap at 3', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Comparer 2 produits'), findsNothing);

    await tester.tap(find.text('Global 100'));
    await tester.pumpAndSettle();
    expect(find.text('Comparer 2 produits'), findsNothing);

    await tester.tap(find.text('Equity 100'));
    await tester.pumpAndSettle();
    expect(find.text('Comparer 2 produits'), findsOneWidget);

    await tester.tap(find.text('Strong 85'));
    await tester.pumpAndSettle();
    expect(find.text('Comparer 3 produits'), findsOneWidget);

    // 4th product: selection is capped at 3.
    await tester.tap(find.text('BVG 3 75'));
    await tester.pumpAndSettle();
    expect(find.text('Comparer 3 produits'), findsOneWidget);

    // Deselection possible.
    await tester.tap(find.text('Strong 85'));
    await tester.pumpAndSettle();
    expect(find.text('Comparer 2 produits'), findsOneWidget);
  });

  testWidgets('changing the filter resets the selection', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Global 100'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Equity 100'));
    await tester.pumpAndSettle();
    expect(find.text('Comparer 2 produits'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prudent'));
    await tester.pumpAndSettle();

    expect(repo.lastCompareRiskLevel, 'MODERATE');
    expect(find.text('Comparer 2 produits'), findsNothing);
  });

  testWidgets('network error: error state + retry reloads', (tester) async {
    repo.error = const NetworkException();
    await pumpScreen(tester);

    expect(find.text('Erreur réseau'), findsOneWidget);
    expect(find.text('Classement'), findsNothing);

    repo.error = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Classement'), findsOneWidget);
  });

  testWidgets('empty catalog: dedicated empty state', (tester) async {
    repo.providers = [];
    await pumpScreen(tester);

    expect(
      find.text('Aucun prestataire disponible pour le moment'),
      findsOneWidget,
    );
    // The ranking stays displayed (independent endpoint).
    expect(find.text('Classement'), findsOneWidget);
  });

  // I8 (full review 2026-08): targeted rebuilds on selection.

  testWidgets('selection: only the tapped tile toggles its icon', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(4));

    await tester.tap(find.text('Global 100'));
    await tester.pumpAndSettle();

    // Only one tile checked; the others are visually unchanged.
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(3));
  });

  testWidgets('targeted select(): rebuild only when its own selection '
      'toggles (build counter)', (tester) async {
    var buildsP1 = 0;
    var buildsP2 = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Same pattern as the screen's tiles.
                Consumer(
                  builder: (context, ref, _) {
                    buildsP1++;
                    ref.watch(
                      compareSelectionProvider.select((s) => s.contains('p1')),
                    );
                    return const SizedBox();
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    buildsP2++;
                    ref.watch(
                      compareSelectionProvider.select((s) => s.contains('p2')),
                    );
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect((buildsP1, buildsP2), (1, 1));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    );

    // Selecting p1: only the p1 watcher rebuilds.
    container.read(compareSelectionProvider.notifier).state = {'p1'};
    await tester.pump();
    expect((buildsP1, buildsP2), (2, 1));

    // Also selecting p2: only the p2 watcher rebuilds.
    container.read(compareSelectionProvider.notifier).state = {'p1', 'p2'};
    await tester.pump();
    expect((buildsP1, buildsP2), (2, 2));

    // New set, same derived booleans: no rebuild despite the
    // StateProvider notification.
    container.read(compareSelectionProvider.notifier).state = {'p2', 'p1'};
    await tester.pump();
    expect((buildsP1, buildsP2), (2, 2));
  });
}
