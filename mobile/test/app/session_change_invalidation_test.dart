import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/app/app.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/features/financial_profile/application/financial_profile_providers.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:pocketpillar/features/dashboard/application/dashboard_providers.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_repository.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_dtos.dart';
import 'package:pocketpillar/features/documents/application/documents_providers.dart';
import 'package:pocketpillar/features/documents/data/document_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fakes.dart';

/// Fake auth with a controllable session: emits a session, a new token
/// (same user), or null (simulates the `signOut` triggered by
/// `onAuthExpired` after a 401, or a logout).
class _ControllableAuthRepository extends FakeAuthRepository {
  _ControllableAuthRepository() : _current = buildFakeSession();

  final StreamController<Session?> _controller =
      StreamController<Session?>.broadcast();
  Session? _current;

  @override
  Session? get currentSession => _current;

  @override
  String? get currentEmail => _current?.user.email;

  @override
  Stream<Session?> get sessionChanges async* {
    yield _current;
    yield* _controller.stream;
  }

  void emitSession(Session? session) {
    _current = session;
    _controller.add(session);
  }
}

void main() {
  testWidgets('session → null (401): the profile aggregate is invalidated '
      '(no cross-account leak); a token refresh invalidates nothing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();
    final auth = _ControllableAuthRepository();
    final profiles = CountingFakeFinancialProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          financialProfileRepositoryProvider.overrideWithValue(profiles),
        ],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PocketPillarApp)),
    );
    // Keeps the aggregate alive the way a screen watching it would.
    final sub = container.listen(profileAggregateProvider, (_, _) {});
    addTearDown(sub.close);

    await container.read(profileAggregateProvider.future);
    expect(profiles.loadBaseCalls, 1);

    // Token refresh: new Session instance, same user.id
    // → no invalidation (no refetch).
    auth.emitSession(buildFakeSession());
    await tester.pumpAndSettle();
    expect(profiles.loadBaseCalls, 1);

    // 401 → signOut: the session becomes null → aggregate invalidated, so
    // reloaded (the next account won't see this data).
    auth.emitSession(null);
    await tester.pumpAndSettle();
    expect(profiles.loadBaseCalls, 2);
  });

  testWidgets('session change also resets dashboard, recommendations, score '
      'and documents (cross-account leak, review 08.2026)', (tester) async {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();
    final auth = _ControllableAuthRepository();
    final profiles = CountingFakeFinancialProfileRepository();
    final dashboard = FakeDashboardRepository()
      ..data = const DashboardData(
        user: UserDto(
          id: 'u-1',
          email: 'user@example.ch',
          birthYear: 1991,
          replacementRateGoal: 70,
        ),
      );
    final documents = FakeDocumentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          financialProfileRepositoryProvider.overrideWithValue(profiles),
          dashboardRepositoryProvider.overrideWithValue(dashboard),
          documentRepositoryProvider.overrideWithValue(documents),
        ],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PocketPillarApp)),
    );
    // Keep all four alive the way open screens would (they are
    // non-autoDispose: user A's data survives in the SAME run otherwise).
    final subs = [
      container.listen(dashboardProvider, (_, _) {}),
      container.listen(recommendationsProvider, (_, _) {}),
      container.listen(scoreProvider, (_, _) {}),
      container.listen(documentsProvider, (_, _) {}),
    ];
    for (final sub in subs) {
      addTearDown(sub.close);
    }

    await container.read(dashboardProvider.future);
    await container.read(recommendationsProvider.future);
    await container.read(scoreProvider.future);
    await container.read(documentsProvider.future);
    expect(dashboard.loadCalls, 1);
    expect(dashboard.recommendationsCalls, 1);
    expect(dashboard.scoreCalls, 1);
    expect(documents.listCalls, 1);

    // Token refresh (same user): nothing refetches.
    auth.emitSession(buildFakeSession());
    await tester.pumpAndSettle();
    expect(dashboard.loadCalls, 1);
    expect(documents.listCalls, 1);

    // Sign-out: user B must never see user A's cached data.
    auth.emitSession(null);
    await tester.pumpAndSettle();
    expect(dashboard.loadCalls, 2);
    expect(dashboard.recommendationsCalls, 2);
    expect(dashboard.scoreCalls, 2);
    expect(documents.listCalls, 2);
  });
}
