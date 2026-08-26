import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/providers/data/provider_dtos.dart';
import 'package:pocketpillar/features/providers/presentation/compare_screen.dart';

ScoredProductDto _product({
  required String id,
  required String provider,
  required String product,
  required double fee,
  required int equity,
  required int score,
  double? return3y,
  bool esg = false,
}) => ScoredProductDto(
  productId: id,
  providerName: provider,
  providerSlug: provider.toLowerCase(),
  productName: product,
  productSlug: product.toLowerCase(),
  riskLevel: 'GROWTH',
  equityAllocation: equity,
  allInFeePercent: fee,
  sustainableEsg: esg,
  avgReturn3y: return3y,
  score: score,
);

void main() {
  final products = [
    _product(
      id: 'a',
      provider: 'finpension',
      product: 'Equity 100',
      fee: 0.39,
      equity: 99,
      score: 92,
      return3y: 14.3,
    ),
    _product(
      id: 'b',
      provider: 'UBS',
      product: 'Vitainvest 75',
      fee: 1.39,
      equity: 75,
      score: 48,
      return3y: -1.2,
      esg: true,
    ),
    _product(
      id: 'c',
      provider: 'BCV',
      product: 'Compte 3a',
      fee: 0,
      equity: 0,
      score: 60,
    ),
  ];

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompareScreen(products: products),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('headers, detail table and verdict', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Comparaison'), findsOneWidget);
    // Headers: providers + scores (the name also appears in the
    // comparison bars).
    expect(find.text('finpension'), findsWidgets);
    expect(find.text('UBS'), findsWidgets);
    expect(find.text('92/100'), findsOneWidget);
    // Sections.
    expect(find.text('Frais annuels'), findsOneWidget);
    expect(find.text('Rendement moyen 3 ans'), findsOneWidget);
    expect(find.text('Part en actions'), findsOneWidget);
    // Table: the cheapest (BCV account has 0 fees), zero return → "—".
    expect(find.text('Le moins cher'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('99 %'), findsWidgets);
    // Verdict: best score = finpension (92).
    expect(find.text('Meilleur choix global'), findsOneWidget);
    expect(find.text('finpension — Equity 100'), findsOneWidget);
  });

  testWidgets('no return data: section hidden', (tester) async {
    final noReturns = [
      for (final p in products)
        ScoredProductDto(
          productId: p.productId,
          providerName: p.providerName,
          providerSlug: p.providerSlug,
          productName: p.productName,
          productSlug: p.productSlug,
          riskLevel: p.riskLevel,
          equityAllocation: p.equityAllocation,
          allInFeePercent: p.allInFeePercent,
          sustainableEsg: p.sustainableEsg,
          score: p.score,
        ),
    ];
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompareScreen(products: noReturns),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rendement moyen 3 ans'), findsNothing);
    expect(find.text('Frais annuels'), findsOneWidget);
  });
}
