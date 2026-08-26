import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/app/app.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/features/financial_profile/application/financial_profile_providers.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
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
      '(no cross-account leak); a token refresh invalidates nothing',
      (tester) async {
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
}
