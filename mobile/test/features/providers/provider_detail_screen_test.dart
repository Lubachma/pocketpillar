import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/providers/data/provider_dtos.dart';
import 'package:pocketpillar/features/providers/data/provider_repository.dart';
import 'package:pocketpillar/features/providers/presentation/provider_detail_screen.dart';

import '../../helpers/fakes.dart';

const _detail = ProviderDto(
  id: 'p1',
  slug: 'viac',
  name: 'VIAC',
  description: 'Pilier 3a digital avec fonds indiciels',
  website: 'https://viac.ch',
  isDigital: true,
  products: [
    ProviderProductDto(
      id: 'pr1',
      name: 'VIAC Global 100',
      slug: 'viac-global-100',
      investmentCategory: 'PASSIVE_INDEX',
      riskLevel: 'AGGRESSIVE',
      equityAllocation: 97,
      sustainableEsg: false,
      fees: ProductFeeDto(
        terPercent: 0,
        custodyFeePercent: 0.1,
        allInFeePercent: 0.44,
        entryFeePercent: 0,
        exitFeePercent: 0,
      ),
      performanceHistory: [
        ProductPerformanceDto(year: 2025, returnPercent: 8.5),
        ProductPerformanceDto(year: 2024, returnPercent: 18.2),
        ProductPerformanceDto(year: 2022, returnPercent: -17.8),
      ],
    ),
    ProviderProductDto(
      id: 'pr2',
      name: 'VIAC Global 20',
      slug: 'viac-global-20',
      investmentCategory: 'PASSIVE_INDEX',
      riskLevel: 'CONSERVATIVE',
      equityAllocation: 20,
      sustainableEsg: true,
      fees: ProductFeeDto(
        terPercent: 0,
        allInFeePercent: 0.36,
        entryFeePercent: 0,
        exitFeePercent: 0,
      ),
    ),
  ],
);

void main() {
  late FakeProviderRepository repo;

  setUp(() {
    repo = FakeProviderRepository()..detail = _detail;
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
          home: const ProviderDetailScreen(slug: 'viac'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('full sheet: description, products, detailed fees, '
      'performance by year', (tester) async {
    await pumpScreen(tester);

    expect(repo.lastSlug, 'viac');
    // AppBar + description + website link.
    expect(find.text('VIAC'), findsOneWidget);
    expect(find.text('Pilier 3a digital avec fonds indiciels'), findsOneWidget);
    expect(find.text('Visiter le site web'), findsOneWidget);
    // Products: risk + ESG badges, category, equity share (the name
    // also appears in the fee comparison bars).
    expect(find.text('VIAC Global 100'), findsWidgets);
    expect(find.text('100% actions'), findsOneWidget); // badge AGGRESSIVE
    expect(find.text('Sécurité avant tout'), findsOneWidget); // CONSERVATIVE
    expect(find.text('Risque'), findsNWidgets(2)); // label on both cards
    expect(find.text('Durable'), findsOneWidget); // ESG badge on 2nd product
    expect(find.text('Fonds indiciel (passif)'), findsNWidgets(2));
    expect(find.text('97 %'), findsOneWidget);
    // Detailed fees (fund 100: custody fee filled in) — the
    // all-in value also appears in the fee bars.
    expect(find.text('Détail des frais'), findsNWidgets(2));
    expect(find.text('Frais tout compris'), findsNWidgets(2));
    expect(find.text('0.44 %'), findsWidgets);
    expect(find.text('Frais de garde'), findsOneWidget);
    expect(find.text('0.10 %'), findsOneWidget);
    // Performance history (2025/2024 positive, 2022 negative).
    expect(find.text('Rendement par année'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('8.5 %'), findsOneWidget);
    expect(find.text('-17.8 %'), findsOneWidget);
    // Only 3 years → no window label (nothing is truncated).
    expect(find.text('5 dernières années'), findsNothing);
    // Fee comparison (2 products with fees).
    expect(find.text('Comparaison des frais'), findsOneWidget);
  });

  testWidgets('history capped at 5 years (backend take: 5): window '
      'label shown', (tester) async {
    repo.detail = const ProviderDto(
      id: 'p1',
      slug: 'viac',
      name: 'VIAC',
      isDigital: true,
      products: [
        ProviderProductDto(
          id: 'pr1',
          name: 'VIAC Global 100',
          slug: 'viac-global-100',
          investmentCategory: 'PASSIVE_INDEX',
          riskLevel: 'AGGRESSIVE',
          equityAllocation: 97,
          sustainableEsg: false,
          performanceHistory: [
            ProductPerformanceDto(year: 2025, returnPercent: 8.5),
            ProductPerformanceDto(year: 2024, returnPercent: 18.2),
            ProductPerformanceDto(year: 2023, returnPercent: 4.1),
            ProductPerformanceDto(year: 2022, returnPercent: -17.8),
            ProductPerformanceDto(year: 2021, returnPercent: 12.3),
          ],
        ),
      ],
    );
    await pumpScreen(tester);

    expect(find.text('Rendement par année'), findsOneWidget);
    expect(find.text('5 dernières années'), findsOneWidget);
  });

  testWidgets('404: "not found" state, no error card', (tester) async {
    repo.detailNotFound = true;
    await pumpScreen(tester);

    expect(
      find.text('Aucun prestataire disponible pour le moment'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('network error: error card + retry', (tester) async {
    repo.error = const NetworkException();
    await pumpScreen(tester);

    expect(find.text('Erreur réseau'), findsOneWidget);

    repo.error = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('VIAC Global 100'), findsWidgets);
  });
}
