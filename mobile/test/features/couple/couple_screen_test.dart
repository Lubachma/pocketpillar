import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/couple/data/couple_repository.dart';
import 'package:pocketpillar/features/couple/data/couple_result.dart';
import 'package:pocketpillar/features/couple/presentation/couple_screen.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:pocketpillar/features/financial_profile/data/municipality.dart';
import 'package:pocketpillar/features/scenarios/application/scenario_prefill.dart';

import '../../helpers/fakes.dart';
import 'couple_fixtures.dart';

/// Standard result: no AVS cap, withdrawal plan 2048–2051.
final _result = syntheticCoupleResult();

/// Synthetic result at the AVS couple cap (150%).
final _cappedResult = CoupleResult.fromJson(coupleCappedResponseJson());

const _prefill = ScenarioPrefill(
  age: 40,
  canton: 'VD',
  maritalStatus: 'MARRIED',
  grossAnnualIncome: 9500000,
  pillar2Capital: 2000000,
  pillar2Contribution: 500000,
  pillar3aBalance: 1000000,
  pillar3aAccountCount: 1,
);

void main() {
  late FakeCoupleRepository repo;
  late FakeFinancialProfileRepository profileRepo;

  setUp(() {
    repo = FakeCoupleRepository()..result = _result;
    // Municipalities served to the picker (the simulation doesn't re-fetch them).
    profileRepo = FakeFinancialProfileRepository()
      ..municipalities = const [
        MunicipalityInfo(name: 'Adliswil', multiplier: 104),
        MunicipalityInfo(name: 'Zurich', multiplier: 119),
      ];
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    ScenarioPrefill prefill = const ScenarioPrefill(),
  }) async {
    tester.view.physicalSize = const Size(800, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scenarioPrefillProvider.overrideWith((ref) async => prefill),
          coupleRepositoryProvider.overrideWithValue(repo),
          financialProfileRepositoryProvider.overrideWithValue(profileRepo),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CoupleScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('pre-fill of spouse 1 and the situation', (tester) async {
    await pumpScreen(tester, prefill: _prefill);

    expect(find.text('95000'), findsOneWidget); // gross income
    expect(find.text('20000'), findsOneWidget); // LPP capital
    expect(find.text('5000'), findsOneWidget); // LPP contribution
    expect(find.text('10000'), findsOneWidget); // 3a balance (switch enabled)
    expect(find.text('40'), findsWidgets); // age (slider)
    // Situation: canton and marital status from the profile.
    expect(find.text('Vaud (VD)'), findsOneWidget);
    expect(find.text('Marié·e·s'), findsOneWidget);
    // The partner stays free-entry (default iOS age).
    expect(find.text('35'), findsOneWidget);
  });

  testWidgets('validation: empty partner income → error, no call', (
    tester,
  ) async {
    await pumpScreen(tester, prefill: _prefill);

    await tester.tap(find.text('Calculer la retraite du couple'));
    await tester.pumpAndSettle();

    expect(find.text('Champ requis'), findsOneWidget);
    expect(repo.calls, 0);
  });

  testWidgets('calculation: inputs + situation sent, server sections', (
    tester,
  ) async {
    await pumpScreen(tester, prefill: _prefill);

    // Partner: income + 3a (switch then balance).
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut (CHF)').last,
      '60000',
    );
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Le partenaire a un 3e pilier'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Solde 3a (CHF)').last,
      '25000',
    );

    await tester.tap(find.text('Calculer la retraite du couple'));
    await tester.pumpAndSettle();

    // Inputs sent in centimes (spouse 1 pre-filled, spouse 2).
    final person1 = repo.lastPerson1!;
    expect(person1.age, 40);
    expect(person1.grossAnnualIncome, 9500000);
    expect(person1.pillar2Capital, 2000000);
    expect(person1.pillar2Contribution, 500000);
    expect(person1.hasPillar3a, isTrue);
    expect(person1.pillar3aBalance, 1000000);
    final person2 = repo.lastPerson2!;
    expect(person2.age, 35);
    expect(person2.grossAnnualIncome, 6000000);
    expect(person2.hasPillar3a, isTrue);
    expect(person2.pillar3aBalance, 2500000);
    // Tax situation sent (VD / married profile).
    expect(repo.lastCanton, 'VD');
    expect(repo.lastMaritalStatus, 'MARRIED');

    // Combined summary (9'152'000/year → 7'626,66/month; rate 59%).
    expect(find.text('Revenu combiné du couple'), findsOneWidget);
    expect(find.text("CHF 7'626.66"), findsOneWidget);
    expect(find.text('Taux de remplacement combiné'), findsOneWidget);
    expect(find.text('59 %'), findsOneWidget);

    // Side-by-side comparison (individual amounts).
    expect(find.text('AVS/mois'), findsOneWidget);
    expect(find.text("CHF 1'960.00"), findsOneWidget);
    expect(find.text("CHF 1'500.00"), findsOneWidget);
    expect(find.text("CHF 2'500.00"), findsOneWidget);
    expect(find.text("CHF 80'000.00"), findsOneWidget);
    expect(find.text('63 %'), findsOneWidget);
    expect(find.text('58 %'), findsOneWidget);
    expect(find.text('Total/mois'), findsOneWidget);
    expect(find.text("CHF 4'460.00"), findsOneWidget);
    expect(find.text("CHF 3'166.66"), findsOneWidget);

    // Couple tax: joint vs. separate taxation + conclusion.
    expect(find.text('Fiscalité du couple'), findsOneWidget);
    expect(find.text('Imposition commune (mariage)'), findsOneWidget);
    expect(find.text("CHF 25'811.99/an"), findsOneWidget);
    expect(find.text('Imposition séparée (concubinage)'), findsOneWidget);
    expect(find.text("CHF 20'014.65/an"), findsOneWidget);
    expect(
      find.text(
        "Le concubinage vous fait économiser environ CHF 5'797.34 "
        "d'impôts par an.",
      ),
      findsOneWidget,
    );

    // Coordinated withdrawal plan: years, amounts, taxes, savings.
    expect(find.text('Plan de retrait optimal'), findsOneWidget);
    expect(find.text('2048'), findsOneWidget);
    expect(find.text('2051'), findsOneWidget);
    expect(find.text("CHF 300'000.00"), findsOneWidget);
    expect(find.text("CHF 500'000.00"), findsOneWidget);
    expect(find.text('Impôt estimé : CHF 9\'929.12'), findsOneWidget);
    expect(find.text('Impôt total du plan'), findsOneWidget);
    expect(find.text("CHF 67'124.50"), findsOneWidget);
    expect(find.text('Impôt si retraits la même année'), findsOneWidget);
    expect(find.text("CHF 93'056.63"), findsOneWidget);
    expect(find.text('Économie grâce à l\'échelonnement'), findsOneWidget);
    expect(find.text("CHF 25'932.13"), findsOneWidget);

    // The "Bientôt disponible" card is gone (batch 6).
    expect(find.text('Bientôt disponible'), findsNothing);
  });

  testWidgets('AVS couple cap reached → warning shown', (tester) async {
    repo.result = _cappedResult;
    await pumpScreen(tester, prefill: _prefill);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut (CHF)').last,
      '95000',
    );
    await tester.tap(find.text('Calculer la retraite du couple'));
    await tester.pumpAndSettle();

    expect(find.textContaining('plafond AVS couple'), findsOneWidget);
    // Capped combined income: 44'100 + 30'000 + 20'000 = 94'100/year.
    expect(find.text("CHF 7'841.66"), findsOneWidget);
  });

  testWidgets('empty plan → explicit message', (tester) async {
    repo.result = CoupleResult.fromJson(coupleEmptyPlanResponseJson());
    await pumpScreen(tester, prefill: _prefill);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut (CHF)').last,
      '60000',
    );
    await tester.tap(find.text('Calculer la retraite du couple'));
    await tester.pumpAndSettle();

    expect(find.text('Plan de retrait optimal'), findsOneWidget);
    expect(find.textContaining('Aucun capital 3a ou LPP'), findsOneWidget);
  });

  testWidgets('network error: inline card + retry', (tester) async {
    repo.failOnce = true;
    await pumpScreen(tester, prefill: _prefill);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut (CHF)').last,
      '60000',
    );
    await tester.tap(find.text('Calculer la retraite du couple'));
    await tester.pumpAndSettle();

    expect(find.text('Erreur réseau'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Revenu combiné du couple'), findsOneWidget);
    expect(repo.calls, 2);
  });

  testWidgets('municipality: pre-filled, reset on canton change, '
      'selection sent to the simulation', (tester) async {
    await pumpScreen(
      tester,
      prefill: const ScenarioPrefill(
        age: 40,
        canton: 'VD',
        municipality: 'Lausanne',
        maritalStatus: 'MARRIED',
        grossAnnualIncome: 9500000,
      ),
    );

    // Municipality tile pre-filled from the profile.
    expect(find.text('Lausanne'), findsOneWidget);

    // Changing canton (dropdown) → the municipality is reset.
    await tester.tap(find.text('Vaud (VD)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zurich (ZH)').last);
    await tester.pumpAndSettle();
    expect(find.text('Lausanne'), findsNothing);
    expect(find.text('Moyenne cantonale (commune non listée)'), findsOneWidget);

    // New municipality chosen via the picker (current canton ZH).
    await tester.tap(find.text('Commune'));
    await tester.pumpAndSettle();
    expect(profileRepo.lastMunicipalitiesCanton, 'ZH');
    await tester.tap(find.text('Adliswil'));
    await tester.pumpAndSettle();
    expect(find.text('Adliswil'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut (CHF)').last,
      '60000',
    );
    await tester.tap(find.text('Calculer la retraite du couple'));
    await tester.pumpAndSettle();

    expect(repo.lastCanton, 'ZH');
    expect(repo.lastMunicipality, 'Adliswil');

    // Deselecting via the "moyenne cantonale" option → municipality absent from
    // the next simulation.
    await tester.tap(find.text('Adliswil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moyenne cantonale (commune non listée)'));
    await tester.pumpAndSettle();
    expect(find.text('Adliswil'), findsNothing);

    await tester.tap(find.text('Calculer la retraite du couple'));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(repo.lastMunicipality, isNull);
  });
}
