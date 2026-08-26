import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/app/app.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/core/utils/clock.dart';
import 'package:pocketpillar/features/checklist/presentation/checklist_screen.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_dtos.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_repository.dart';
import 'package:pocketpillar/features/dashboard/presentation/dashboard_screen.dart';
import 'package:pocketpillar/features/financial_profile/application/financial_profile_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

/// End-to-end flow with the real providers (only the repositories are
/// mocked): the dashboard's checklist card and the checking screen
/// watch the same `checklistCompletedIdsProvider` — the ring must be
/// up to date on return.
void main() {
  testWidgets('integration: dashboard card → checklist → checking → '
      'return → ring updated', (tester) async {
    // In season (October–January): the checklist card is shown.
    final fixedNow = DateTime(2026, 11, 15, 10);
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();

    final dashboard = FakeDashboardRepository()
      ..data = DashboardData(
        user: UserDto(
          id: 'u-1',
          email: 'user@example.ch',
          canton: 'VD',
          birthYear: fixedNow.year - 35,
          replacementRateGoal: 70,
        ),
        profile: const FinancialProfileDto(
          employmentStatus: 'EMPLOYED',
          maritalStatus: 'SINGLE',
          numberOfChildren: 0,
          grossAnnualIncome: 8500000,
        ),
        pillar3aAccounts: const [
          Pillar3aAccountDto(
            id: 'p3-1',
            providerName: 'VIAC',
            currentBalance: 1000000,
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
      )
      ..recommendations = const RecommendationResultDto(recommendations: []);

    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(SignedInFakeAuthRepository()),
          dashboardRepositoryProvider.overrideWithValue(dashboard),
          profileAggregateProvider.overrideWith(
            () => FakeProfileAggregateNotifier(buildFakeProfileAggregate()),
          ),
          clockProvider.overrideWithValue(() => fixedNow),
        ],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Dashboard: checklist card, 6 applicable items (existing 3a),
    // none checked.
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text("Checklist fin d'année"), findsOneWidget);
    expect(find.text('6 actions restantes'), findsOneWidget);

    // Tap the card → checklist screen.
    await tester.tap(find.text("Checklist fin d'année"));
    await tester.pumpAndSettle();
    expect(find.byType(ChecklistScreen), findsOneWidget);
    expect(find.text('0/6'), findsOneWidget);

    // Checking an item without navigation (no target tab).
    await tester.tap(find.text('Vérifier le rachat LPP'));
    await tester.pumpAndSettle();
    expect(find.text('1/6'), findsOneWidget);

    // Back to the dashboard: ring and counter up to date.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('5 actions restantes'), findsOneWidget);
    final rings = tester.widgetList<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(
      rings.any(
        (ring) => ring.value != null && (ring.value! - 1 / 6).abs() < 1e-9,
      ),
      isTrue,
    );
  });
}
