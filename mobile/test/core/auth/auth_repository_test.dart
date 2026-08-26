import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// "No session" guards added after the 401 → refresh → signOut → refetch
/// storm observed in dev bypass (journal 2026-08-07): without a session,
/// we must never call `refreshSession()` (throws
/// `AuthSessionMissingException`) nor `signOut()` (emits an auth event
/// that re-invalidates the providers and restarts the loop).
void main() {
  group('AuthRepository — guards without a session', () {
    test('null client: refreshAccessToken → null, '
        'signOutIfAuthenticated no-op', () async {
      final repo = AuthRepository(null);

      expect(await repo.refreshAccessToken(), isNull);
      await repo.signOutIfAuthenticated();
    });

    test('client configured without a session: refreshAccessToken → null '
        'without calling refreshSession', () async {
      // Real client but never initialized: no persisted session.
      // If the guard didn't short-circuit, refreshSession() would throw
      // AuthSessionMissingException.
      final client = SupabaseClient('http://127.0.0.1:9', 'cle-anon-de-test');
      addTearDown(client.dispose);
      final repo = AuthRepository(client);

      expect(client.auth.currentSession, isNull);
      expect(await repo.refreshAccessToken(), isNull);
    });

    test('client configured without a session: signOutIfAuthenticated '
        'emits no auth event', () async {
      final client = SupabaseClient('http://127.0.0.1:9', 'cle-anon-de-test');
      addTearDown(client.dispose);
      final repo = AuthRepository(client);

      final events = <AuthChangeEvent>[];
      final sub = client.auth.onAuthStateChange.listen(
        (data) => events.add(data.event),
      );
      addTearDown(sub.cancel);

      await repo.signOutIfAuthenticated();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(events, isEmpty);
    });
  });
}
