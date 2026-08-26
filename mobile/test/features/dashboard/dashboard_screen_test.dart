import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketpillar/app/routes.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/core/utils/clock.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_dtos.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_repository.dart';
import 'package:pocketpillar/features/dashboard/presentation/dashboard_screen.dart';
import 'package:pocketpillar/features/financial_profile/application/financial_profile_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

DashboardData _emptyProfileData() => const DashboardData(
  user: UserDto(
    id: 'u-1',
    email: 'user@example.ch',
    birthYear: 1991,
    replacementRateGoal: 70,
  ),
);

DashboardData _fullData() {
  final currentYear = DateTime.now().year;
  return DashboardData(
    user: UserDto(
      id: 'u-1',
      email: 'user@example.ch',
      canton: 'VD',
      birthYear: currentYear - 35,
      replacementRateGoal: 70,
    ),
    profile: const FinancialProfileDto(
      employmentStatus: 'EMPLOYED',
      maritalStatus: 'SINGLE',
      numberOfChildren: 0,
      grossAnnualIncome: 8500000,
    ),
    pillar2Accounts: const [
      Pillar2AccountDto(
        id: 'p2-1',
        currentCapital: 2000000,
        annualBvgContribution: 500000,
      ),
    ],
    pillar3aAccounts: const [
      Pillar3aAccountDto(
        id: 'p3-1',
        providerName: 'VIAC',
        currentBalance: 1000000,
        annualContribution: 700000,
      ),
    ],
    projection: const RetirementProjectionDto(
      yearsToRetirement: 30,
      projectedPillar2Capital: 50000000,
      projectedPillar3aBalance: 8000000,
      annualPillar2Pension: 3000000,
      estimatedAnnualAvsPension: 2352000,
      totalAnnualRetirementIncome: 5352000,
      replacementRate: 63,
    ),
  );
}

RecommendationResultDto _recommendations(int count) =>
    RecommendationResultDto(
      recommendations: [
        for (var i = 0; i < count; i++)
          RecommendationDto(
            type: 'MAX_3A_CONTRIBUTION',
            priority: 'HIGH',
            title: 'Reco ${String.fromCharCode(65 + i)}',
            description: 'Description ${String.fromCharCode(65 + i)}',
            estimatedAnnualImpact: 215000,
          ),
      ],
    );

void main() {
  late FakeDashboardRepository repository;
  late SharedPreferences prefs;

  /// Fixed clock outside checklist season (August), 10am → 'Bonjour'.
  DateTime fixedNow = DateTime(2026, 8, 5, 10);

  setUp(() async {
    repository = FakeDashboardRepository();
    fixedNow = DateTime(2026, 8, 5, 10);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Tall viewport: all the list content is built (no
  /// lazy-loading), the assertions don't need to scroll.
  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: Routes.dashboard,
      routes: [
        GoRoute(
          path: Routes.dashboard,
          builder: (_, _) => const DashboardScreen(),
        ),
        GoRoute(
          path: Routes.settings,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Paramètres'))),
        ),
        GoRoute(
          path: Routes.settingsProfile,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Profil financier'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dashboardRepositoryProvider.overrideWithValue(repository),
          profileAggregateProvider.overrideWith(
            () => FakeProfileAggregateNotifier(buildFakeProfileAggregate()),
          ),
          clockProvider.overrideWithValue(() => fixedNow),
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
  }

  testWidgets('empty state (initial 404): invitation + CTA to the profile',
      (tester) async {
    repository.data = _emptyProfileData();
    await pumpDashboard(tester);

    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.text('Complétez votre profil'), findsOneWidget);
    expect(find.text('Conseil du jour'), findsOneWidget);

    // Non-blocking CTA to the financial profile screen (phase 3.3).
    await tester.tap(find.text('Compléter mon profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil financier'), findsOneWidget);
  });

  testWidgets('loaded: summary, pillars and top 3 recommendations',
      (tester) async {
    repository.data = _fullData();
    repository.recommendations = _recommendations(4);
    await pumpDashboard(tester);

    // Summary card: rate + goal.
    expect(find.text('Votre projection retraite'), findsOneWidget);
    expect(find.text('63 %'), findsOneWidget);
    expect(find.text('63 % / 70 %'), findsOneWidget);
    expect(
      find.text('Votre pension couvrira 63% de votre revenu'),
      findsOneWidget,
    );

    // Pillars (centimes → formatted CHF; LPP = projected pension, iOS parity).
    expect(find.text("CHF 30'000.00"), findsOneWidget); // LPP pension/year
    expect(find.text("CHF 10'000.00"), findsOneWidget); // 3a balance

    // Top 3 only, with formatted impact.
    expect(find.text('Recommandations'), findsOneWidget);
    expect(find.text('Reco A'), findsOneWidget);
    expect(find.text('Reco C'), findsOneWidget);
    expect(find.text('Reco D'), findsNothing);
    expect(find.text("Impact estimé : CHF 2'150.00/an"), findsNWidgets(3));
  });

  testWidgets('OPEN_ADDITIONAL_3A recommendation: dedicated icon displayed',
      (tester) async {
    repository.data = _fullData();
    repository.recommendations = const RecommendationResultDto(
      recommendations: [
        RecommendationDto(
          type: 'OPEN_ADDITIONAL_3A',
          priority: 'MEDIUM',
          title: 'Ouvrir un compte 3a supplémentaire',
          description: 'Échelonnez les retraits pour lisser la progressivité.',
          estimatedAnnualImpact: 0,
        ),
      ],
    );
    await pumpDashboard(tester);

    expect(
      find.text('Ouvrir un compte 3a supplémentaire'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.call_split), findsOneWidget);
    // Zero annual impact → no 'Impact estimé' line (one-time withdrawal).
    expect(find.textContaining('Impact estimé'), findsNothing);
  });

  testWidgets('network error: message + retry reloads the dashboard',
      (tester) async {
    repository.data = _fullData();
    repository.recommendations = _recommendations(1);
    repository.failLoadOnce = true;
    await pumpDashboard(tester);

    expect(find.text('Erreur réseau'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Votre projection retraite'), findsOneWidget);
    expect(repository.loadCalls, 2);
  });

  testWidgets('422 recommendations: empty section state, screen loaded',
      (tester) async {
    repository.data = _fullData();
    repository.recommendations = null; // 422 mapped to null by the repository.
    await pumpDashboard(tester);

    expect(find.text('Votre projection retraite'), findsOneWidget);
    expect(
      find.text(
        'Complétez votre profil pour recevoir des recommandations '
        'personnalisées.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('recommendations error: retry scoped to the section',
      (tester) async {
    repository.data = _fullData();
    repository.recommendations = _recommendations(1);
    repository.failRecommendationsOnce = true;
    await pumpDashboard(tester);

    // The rest of the screen stays displayed.
    expect(find.text('Votre projection retraite'), findsOneWidget);
    expect(find.text('Erreur réseau'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Reco A'), findsOneWidget);
    // The section retry doesn't reload the main dashboard.
    expect(repository.loadCalls, 1);
    expect(repository.recommendationsCalls, 2);
  });

  testWidgets('checklist season: card displayed with remaining actions',
      (tester) async {
    fixedNow = DateTime(2026, 10, 15, 10);
    repository.data = _fullData();
    repository.recommendations = _recommendations(0);
    await pumpDashboard(tester);

    expect(find.text("Checklist fin d'année"), findsOneWidget);
    // 6 applicable items (the user has a 3a), none checked.
    expect(find.text('6 actions restantes'), findsOneWidget);
  });

  testWidgets('outside season: no checklist card', (tester) async {
    repository.data = _fullData();
    repository.recommendations = _recommendations(0);
    await pumpDashboard(tester);

    expect(find.text("Checklist fin d'année"), findsNothing);
  });

  testWidgets('score card displayed when GET /score responds', (tester) async {
    repository.data = _fullData();
    repository.recommendations = _recommendations(0);
    repository.score = const PensionScoreDto(
      score: 87,
      breakdown: [
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
      benchmark: ScoreBenchmarkDto(
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
    await pumpDashboard(tester);

    expect(find.text('Santé prévoyance'), findsOneWidget);
    expect(find.text('87'), findsOneWidget);
    expect(find.text('Votre projection retraite'), findsOneWidget);
  });

  testWidgets('422 score → card hidden, rest of the dashboard intact', (
    tester,
  ) async {
    repository.data = _fullData();
    repository.recommendations = _recommendations(1);
    repository.score = null; // 422 mapped to null by the repository.
    await pumpDashboard(tester);

    expect(find.text('Santé prévoyance'), findsNothing);
    expect(find.text('Votre projection retraite'), findsOneWidget);
    expect(find.text('Reco A'), findsOneWidget);
  });
}
