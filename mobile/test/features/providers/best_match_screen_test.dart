import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/providers/data/provider_dtos.dart';
import 'package:pocketpillar/features/providers/data/provider_repository.dart';
import 'package:pocketpillar/features/providers/presentation/best_match_screen.dart';
import 'package:pocketpillar/features/scenarios/application/scenario_prefill.dart';

import '../../helpers/fakes.dart';

ScoredProductDto _match(String id, String provider, int score) =>
    ScoredProductDto(
      productId: id,
      providerName: provider,
      providerSlug: provider.toLowerCase(),
      productName: '$provider 3a',
      productSlug: id,
      riskLevel: 'GROWTH',
      equityAllocation: 80,
      allInFeePercent: 0.44,
      sustainableEsg: true,
      avgReturn3y: 7.5,
      score: score,
    );

void main() {
  late FakeProviderRepository repo;

  setUp(() {
    repo = FakeProviderRepository()
      ..bestMatchResults = [
        _match('m1', 'finpension', 94),
        _match('m2', 'VIAC', 91),
        _match('m3', 'Frankly', 88),
      ];
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    ScenarioPrefill prefill = const ScenarioPrefill(age: 30),
  }) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerRepositoryProvider.overrideWithValue(repo),
          scenarioPrefillProvider.overrideWith((ref) async => prefill),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BestMatchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('full flow: risk → preferences → podium + '
      'criteria explanation', (tester) async {
    await pumpScreen(tester);

    // Step 0: question + 5 illustrated options.
    expect(
      find.text('Comment souhaitez-vous placer votre argent ?'),
      findsOneWidget,
    );
    expect(find.text('Sécurité avant tout'), findsOneWidget);
    expect(find.text('Dynamique'), findsOneWidget);

    // Tap the option pre-filled based on age (30 years → GROWTH).
    await tester.tap(find.text('Dynamique'));
    await tester.pumpAndSettle();

    // Step 1: preferences (max fee 1.0% by default, ESG switch).
    expect(find.text('Vos préférences'), findsOneWidget);
    expect(find.text('1.0 %'), findsWidgets);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trouver les meilleurs'));
    await tester.pumpAndSettle();

    // Exact payload (POST /providers/best-match).
    expect(repo.lastBestMatchRiskLevel, 'GROWTH');
    expect(repo.lastPreferEsg, isTrue);
    expect(repo.lastMaxFeePercent, 1.0);

    // Step 2: top-3 podium + score + criteria explanation.
    expect(find.text('Vos meilleurs choix'), findsOneWidget);
    expect(find.text('finpension'), findsOneWidget);
    expect(find.text('VIAC'), findsOneWidget);
    expect(find.text('Frankly'), findsOneWidget);
    expect(find.text('94'), findsOneWidget);
    expect(
      find.text(
        'Le score combine les frais, le rendement sur 3 ans, '
        "l'adéquation à votre profil de risque et la durabilité (ESG).",
      ),
      findsOneWidget,
    );

    // Restart → back to step 0.
    await tester.tap(find.text('Recommencer'));
    await tester.pumpAndSettle();
    expect(
      find.text('Comment souhaitez-vous placer votre argent ?'),
      findsOneWidget,
    );
  });

  testWidgets('pre-fill based on age: 60 years → CONSERVATIVE', (tester) async {
    await pumpScreen(tester, prefill: const ScenarioPrefill(age: 60));

    // The pre-filled option is CONSERVATIVE: tapping it keeps the
    // suggested level in the payload.
    await tester.tap(find.text('Sécurité avant tout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trouver les meilleurs'));
    await tester.pumpAndSettle();

    expect(repo.lastBestMatchRiskLevel, 'CONSERVATIVE');
  });

  testWidgets('no results: empty state + restart', (tester) async {
    repo.bestMatchResults = [];
    await pumpScreen(tester);

    await tester.tap(find.text('Équilibré'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trouver les meilleurs'));
    await tester.pumpAndSettle();

    expect(find.text('Aucun résultat'), findsOneWidget);
    expect(find.text('Essayez avec des critères différents'), findsOneWidget);

    await tester.tap(find.text('Recommencer'));
    await tester.pumpAndSettle();
    expect(find.text('Vos préférences'), findsNothing);
  });

  testWidgets('network error: inline card + retry (input kept)', (
    tester,
  ) async {
    repo.failOnce = true;
    await pumpScreen(tester);

    await tester.tap(find.text('Dynamique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trouver les meilleurs'));
    await tester.pumpAndSettle();

    expect(find.text('Erreur réseau'), findsOneWidget);
    // Still on the preferences step.
    expect(find.text('Vos préférences'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Vos meilleurs choix'), findsOneWidget);
    expect(repo.calls, 2);
  });
}
