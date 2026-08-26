import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/core/theme/app_colors.dart';
import 'package:pocketpillar/core/theme/components/app_card.dart';
import 'package:pocketpillar/core/theme/components/score_badge.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_dtos.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_repository.dart';
import 'package:pocketpillar/features/dashboard/presentation/widgets/score_card.dart';

import '../../helpers/fakes.dart';

PensionScoreDto _scoreDto({int score = 87}) => PensionScoreDto(
  score: score,
  breakdown: const [
    ScoreBreakdownItemDto(
      criterion: 'REPLACEMENT_RATE',
      label: 'Taux de remplacement',
      points: 32,
      maxPoints: 40,
    ),
    ScoreBreakdownItemDto(
      criterion: 'PILLAR_3A',
      label: 'Épargne 3a',
      points: 30,
      maxPoints: 30,
    ),
    ScoreBreakdownItemDto(
      criterion: 'AGE_AWARENESS',
      label: 'Horizon retraite',
      points: 25,
      maxPoints: 30,
    ),
  ],
  benchmark: const ScoreBenchmarkDto(
    bracketMinAge: 35,
    bracketMaxAge: 39,
    averagePillar3aBalance: 4800000,
    averageReplacementRate: 58,
    averageBvgCapital: 12000000,
    userPillar3aBalance: 4800000,
    userReplacementRate: 65,
    userBvgCapital: 12000000,
  ),
);

void main() {
  late FakeDashboardRepository repository;

  setUp(() => repository = FakeDashboardRepository());

  Future<void> pumpScoreCard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ScoreCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ScoreBadge — iOS color thresholds', () {
    Future<void> pumpBadge(WidgetTester tester, int score) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ScoreBadge(score: score))),
      );
    }

    Color ringColor(WidgetTester tester) {
      final indicator = tester.widget<CircularProgressIndicator>(
        find.descendant(
          of: find.byType(ScoreBadge),
          matching: find.byType(CircularProgressIndicator),
        ),
      );
      return (indicator.valueColor! as AlwaysStoppedAnimation<Color?>).value!;
    }

    testWidgets('≥ 70 → green', (tester) async {
      await pumpBadge(tester, 70);
      expect(ringColor(tester), AppColors.positive);
    });

    testWidgets('≥ 40 → orange', (tester) async {
      await pumpBadge(tester, 40);
      expect(ringColor(tester), AppColors.warning);
    });

    testWidgets('< 40 → red', (tester) async {
      await pumpBadge(tester, 39);
      expect(ringColor(tester), AppColors.negative);
    });
  });

  group('ScoreCard', () {
    testWidgets('score displayed: ring, breakdown and benchmark', (
      tester,
    ) async {
      repository.score = _scoreDto();
      await pumpScoreCard(tester);

      expect(find.text('Santé prévoyance'), findsOneWidget);
      expect(find.text('87'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);

      // Breakdown (labels localized by the backend).
      expect(find.text('Taux de remplacement'), findsOneWidget);
      expect(find.text('32/40'), findsOneWidget);
      expect(find.text('Épargne 3a'), findsOneWidget);
      expect(find.text('30/30'), findsOneWidget);
      expect(find.text('Horizon retraite'), findsOneWidget);
      expect(find.text('25/30'), findsOneWidget);

      // Comparison to the age bracket.
      expect(find.text('Comparaison avec les 35–39 ans'), findsOneWidget);
      expect(
        find.text('Taux de remplacement : 65 % (moyenne : 58 %)'),
        findsOneWidget,
      );
      expect(
        find.text("Pilier 3a : CHF 48'000.00 (moyenne : CHF 48'000.00)"),
        findsOneWidget,
      );
      expect(
        find.text("Capital LPP : CHF 120'000.00 (moyenne : CHF 120'000.00)"),
        findsOneWidget,
      );
    });

    testWidgets('422 (null score) → card hidden', (tester) async {
      repository.score = null; // 422 mapped to null by the repository.
      await pumpScoreCard(tester);

      expect(find.text('Santé prévoyance'), findsNothing);
      expect(find.byType(AppCard), findsNothing);
    });

    testWidgets('benchmark hidden outside age bracket (null bracket)', (
      tester,
    ) async {
      final dto = _scoreDto();
      repository.score = PensionScoreDto(
        score: dto.score,
        breakdown: dto.breakdown,
        benchmark: ScoreBenchmarkDto(
          averagePillar3aBalance: dto.benchmark.averagePillar3aBalance,
          averageReplacementRate: dto.benchmark.averageReplacementRate,
          averageBvgCapital: dto.benchmark.averageBvgCapital,
          userPillar3aBalance: dto.benchmark.userPillar3aBalance,
          userReplacementRate: dto.benchmark.userReplacementRate,
          userBvgCapital: dto.benchmark.userBvgCapital,
        ),
      );
      await pumpScoreCard(tester);

      // The score stays displayed, not the comparison.
      expect(find.text('Santé prévoyance'), findsOneWidget);
      expect(find.textContaining('Comparaison avec'), findsNothing);
    });

    testWidgets('network error: message + retry scoped to the card', (
      tester,
    ) async {
      repository.score = _scoreDto();
      repository.failScoreOnce = true;
      await pumpScoreCard(tester);

      expect(find.text('Erreur réseau'), findsOneWidget);
      expect(find.text('Santé prévoyance'), findsNothing);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Santé prévoyance'), findsOneWidget);
      expect(repository.scoreCalls, 2);
    });
  });
}
