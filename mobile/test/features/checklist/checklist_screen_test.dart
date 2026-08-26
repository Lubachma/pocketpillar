import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketpillar/app/routes.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/core/utils/clock.dart';
import 'package:pocketpillar/features/checklist/presentation/checklist_screen.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_dtos.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_repository.dart';
import 'package:pocketpillar/features/financial_profile/application/financial_profile_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

DashboardData _data({
  required bool hasPillar3a,
  FinancialProfileDto? profile,
  List<Pillar2AccountDto> pillar2Accounts = const [],
}) => DashboardData(
  user: const UserDto(
    id: 'u-1',
    email: 'user@example.ch',
    birthYear: 1991,
    replacementRateGoal: 70,
  ),
  profile: profile,
  pillar2Accounts: pillar2Accounts,
  pillar3aAccounts: hasPillar3a
      ? const [
          Pillar3aAccountDto(
            id: 'p3-1',
            providerName: 'VIAC',
            currentBalance: 100000,
            annualContribution: 70000,
          ),
        ]
      : const [],
);

void main() {
  late FakeDashboardRepository repository;
  late SharedPreferences prefs;
  late DateTime now;

  setUp(() async {
    repository = FakeDashboardRepository();
    // Off-season by default (August): the screen stays accessible (iOS
    // parity — no season guard on `YearEndChecklistView`).
    now = DateTime(2026, 8, 5, 10);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Pre-fills the persisted checked items for the current year.
  Future<void> seedCompleted(List<String> ids) async {
    SharedPreferences.setMockInitialValues({
      'checklist.${now.year}.completed': ids,
    });
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> pumpChecklist(
    WidgetTester tester, {
    required bool hasPillar3a,
    FinancialProfileDto? profile,
    List<Pillar2AccountDto> pillar2Accounts = const [],
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    repository.data = _data(
      hasPillar3a: hasPillar3a,
      profile: profile,
      pillar2Accounts: pillar2Accounts,
    );
    final router = GoRouter(
      initialLocation: Routes.checklist,
      routes: [
        GoRoute(
          path: Routes.checklist,
          builder: (_, _) => const ChecklistScreen(),
        ),
        GoRoute(
          path: Routes.scenarios,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Écran Scénarios'))),
        ),
        GoRoute(
          path: Routes.documents,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Écran Documents'))),
        ),
        GoRoute(
          path: Routes.settingsProfile,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Écran Profil'))),
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
          clockProvider.overrideWithValue(() => now),
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

  testWidgets('with 3a: 6 items, ring 0/6, max 3a value displayed', (
    tester,
  ) async {
    await pumpChecklist(tester, hasPillar3a: true);

    expect(find.text('Maximiser le pilier 3a'), findsOneWidget);
    expect(find.text('Vérifier le rachat LPP'), findsOneWidget);
    expect(find.text('Demander le certificat de prévoyance'), findsOneWidget);
    expect(find.text('Préparer les justificatifs fiscaux'), findsOneWidget);
    expect(find.text('Mettre à jour le profil'), findsOneWidget);
    expect(find.text("Planifier l'année suivante"), findsOneWidget);

    expect(find.text('0/6'), findsOneWidget);
    expect(find.text('complétés'), findsOneWidget);
    // Value line for the max_3a item (employee cap, iOS parity).
    expect(find.text("Maximum : CHF 7'258.00"), findsOneWidget);
    expect(find.text('Tout est fait !'), findsNothing);
  });

  testWidgets('self-employed profile: max 3a = 20% of income (batch 12)', (
    tester,
  ) async {
    // SELF_EMPLOYED with no LPP account, gross income CHF 95'000 (net not
    // provided → base = gross) → 20% cap = CHF 19'000.
    await pumpChecklist(
      tester,
      hasPillar3a: true,
      profile: const FinancialProfileDto(
        employmentStatus: 'SELF_EMPLOYED',
        maritalStatus: 'SINGLE',
        numberOfChildren: 0,
        grossAnnualIncome: 9500000,
      ),
    );

    expect(find.text("Maximum : CHF 19'000.00"), findsOneWidget);
    expect(find.text("Maximum : CHF 7'258.00"), findsNothing);
  });

  testWidgets(
    'self-employed profile: declared net income is the base for the 20%',
    (tester) async {
      // SELF_EMPLOYED, gross CHF 95'000, net CHF 80'000 → cap CHF 16'000
      // (same rule as the annual reminder — batch 12 review).
      await pumpChecklist(
        tester,
        hasPillar3a: true,
        profile: const FinancialProfileDto(
          employmentStatus: 'SELF_EMPLOYED',
          maritalStatus: 'SINGLE',
          numberOfChildren: 0,
          grossAnnualIncome: 9500000,
          netAnnualIncome: 8000000,
        ),
      );

      expect(find.text("Maximum : CHF 16'000.00"), findsOneWidget);
    },
  );

  testWidgets('self-employed profile with LPP account (optional): max 3a = '
      '7\'258 (batch 12 review)', (tester) async {
    // SELF_EMPLOYED but affiliated with a pension fund → small cap, the
    // 20% rule doesn't apply (OPP3 art. 7).
    await pumpChecklist(
      tester,
      hasPillar3a: true,
      profile: const FinancialProfileDto(
        employmentStatus: 'SELF_EMPLOYED',
        maritalStatus: 'SINGLE',
        numberOfChildren: 0,
        grossAnnualIncome: 30000000,
      ),
      pillar2Accounts: const [
        Pillar2AccountDto(id: 'l-1', currentCapital: 5000000),
      ],
    );

    expect(find.text("Maximum : CHF 7'258.00"), findsOneWidget);
    expect(find.text("Maximum : CHF 36'288.00"), findsNothing);
  });

  testWidgets('employed profile: max 3a = 7\'258 (income has no effect)', (
    tester,
  ) async {
    await pumpChecklist(
      tester,
      hasPillar3a: true,
      profile: const FinancialProfileDto(
        employmentStatus: 'EMPLOYED',
        maritalStatus: 'SINGLE',
        numberOfChildren: 0,
        grossAnnualIncome: 30000000,
      ),
    );

    expect(find.text("Maximum : CHF 7'258.00"), findsOneWidget);
  });

  testWidgets('without 3a: "max 3a" filtered out (5 items, ring 0/5)', (
    tester,
  ) async {
    await pumpChecklist(tester, hasPillar3a: false);

    expect(find.text('Maximiser le pilier 3a'), findsNothing);
    expect(find.text('Vérifier le rachat LPP'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('checking: ring updated, persistence, unchecking', (
    tester,
  ) async {
    await pumpChecklist(tester, hasPillar3a: true);

    // Item with no target tab: checking only, no navigation.
    await tester.tap(find.text('Vérifier le rachat LPP'));
    await tester.pumpAndSettle();
    expect(find.text('1/6'), findsOneWidget);
    expect(prefs.getStringList('checklist.2026.completed'), ['bvg_buyback']);
    expect(find.text('Écran Documents'), findsNothing);

    await tester.tap(find.text('Vérifier le rachat LPP'));
    await tester.pumpAndSettle();
    expect(find.text('0/6'), findsOneWidget);
    expect(prefs.getStringList('checklist.2026.completed'), isEmpty);
  });

  testWidgets('all checked: ring 6/6 + "Tout est fait !"', (tester) async {
    await seedCompleted([
      'max_3a',
      'bvg_buyback',
      'request_certificate',
      'tax_documents',
      'update_profile',
      'plan_next_year',
    ]);
    await pumpChecklist(tester, hasPillar3a: true);

    expect(find.text('6/6'), findsOneWidget);
    expect(find.text('Tout est fait !'), findsOneWidget);
  });

  testWidgets(
    'navigation: unchecked item with target → target tab, item checked',
    (tester) async {
      await pumpChecklist(tester, hasPillar3a: true);

      await tester.tap(find.text('Préparer les justificatifs fiscaux'));
      await tester.pumpAndSettle();

      expect(find.text('Écran Documents'), findsOneWidget);
      expect(prefs.getStringList('checklist.2026.completed'), [
        'tax_documents',
      ]);
    },
  );

  testWidgets(
    'navigation: unchecking an item with a target does not navigate',
    (tester) async {
      await seedCompleted(['tax_documents']);
      await pumpChecklist(tester, hasPillar3a: true);

      await tester.tap(find.text('Préparer les justificatifs fiscaux'));
      await tester.pumpAndSettle();

      // Fixed inverted iOS condition: unchecking stays on the screen.
      expect(find.text('Écran Documents'), findsNothing);
      expect(find.text('0/6'), findsOneWidget);
      expect(prefs.getStringList('checklist.2026.completed'), isEmpty);
    },
  );

  testWidgets('navigation: Profile and Scenarios targets', (tester) async {
    await pumpChecklist(tester, hasPillar3a: true);

    await tester.tap(find.text('Mettre à jour le profil'));
    await tester.pumpAndSettle();
    expect(find.text('Écran Profil'), findsOneWidget);
    expect(prefs.getStringList('checklist.2026.completed'), ['update_profile']);
  });

  testWidgets('navigation: Plan → Scenarios', (tester) async {
    await pumpChecklist(tester, hasPillar3a: true);

    await tester.tap(find.text("Planifier l'année suivante"));
    await tester.pumpAndSettle();
    expect(find.text('Écran Scénarios'), findsOneWidget);
    expect(prefs.getStringList('checklist.2026.completed'), ['plan_next_year']);
  });

  testWidgets('off-season: screen accessible as-is (iOS parity)', (
    tester,
  ) async {
    // August (off-season Oct–Jan): no guard, no note.
    now = DateTime(2026, 8, 5, 10);
    await pumpChecklist(tester, hasPillar3a: true);

    expect(find.text('0/6'), findsOneWidget);
    expect(find.text('Maximiser le pilier 3a'), findsOneWidget);
  });

  testWidgets('in season: same screen (season only gates the card)', (
    tester,
  ) async {
    now = DateTime(2026, 11, 15, 10);
    await pumpChecklist(tester, hasPillar3a: true);

    expect(find.text('0/6'), findsOneWidget);
    expect(find.text('Maximiser le pilier 3a'), findsOneWidget);
  });
}
