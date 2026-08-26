import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/app/app.dart';
import 'package:pocketpillar/core/api/api_client.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/features/auth/presentation/register_screen.dart';
import 'package:pocketpillar/features/dashboard/presentation/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fakes.dart';

/// Reproduces the real race: Supabase emits the session as soon as `signUp`
/// resolves, **before** the `POST /auth/register` response.
class SessionEmittingAuthRepository extends FakeAuthRepository {
  final _controller = StreamController<Session?>.broadcast();
  Session? _current;

  @override
  Stream<Session?> get sessionChanges async* {
    yield _current;
    yield* _controller.stream;
  }

  void _emit(Session? session) {
    _current = session;
    _controller.add(session);
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    // The session is emitted here, before the backend responds (race).
    _emit(_fakeSession);
    return const SignUpResult.withSession(
      AuthIdentity(userId: 'supa-123', email: 'user@example.ch'),
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _emit(null);
  }
}

/// Blocks the `POST /auth/register` until [gate]: gives the router
/// time to react to the emitted session while the backend hasn't
/// responded yet (otherwise the session events collapse into the same
/// microtask flush and the race isn't observable).
class Blocking409ApiClient extends FakeApiClient {
  final gate = Completer<void>();

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    postCalls.add((path: path, data: data));
    await gate.future;
    throw const ApiException('Conflit', statusCode: 409);
  }
}

final _fakeSession = Session(
  accessToken: 'fake-token',
  tokenType: 'bearer',
  user: const User(
    id: 'supa-123',
    appMetadata: {},
    userMetadata: null,
    aud: 'authenticated',
    createdAt: '2026-08-05T00:00:00.000Z',
  ),
);

void main() {
  testWidgets(
    'integration: 409 on register — redirect held back, message visible, '
    'back to login',
    (tester) async {
      SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
      final prefs = await SharedPreferences.getInstance();
      final auth = SessionEmittingAuthRepository();
      final api = Blocking409ApiClient();

      // Real routerProvider (PocketPillarApp); only the repositories are
      // mocked. authServiceProvider rebuilds itself on these overrides.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authRepositoryProvider.overrideWithValue(auth),
            apiClientProvider.overrideWithValue(api),
          ],
          child: const PocketPillarApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Onboarding already seen → login. Push /register.
      expect(find.text('Adresse e-mail'), findsOneWidget);
      await tester.ensureVisible(
        find.text('Pas encore de compte ? Créer un compte'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pas encore de compte ? Créer un compte'));
      await tester.pumpAndSettle();
      expect(find.text('Créer mon compte'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'user@example.ch',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'motdepasse123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
        'motdepasse123',
      );
      await tester.tap(find.text('Créer mon compte'));

      // Let signUp resolve, the session be emitted, and the redirect
      // be evaluated/built — the backend hasn't responded yet.
      await tester.pump();
      await tester.pump();

      // STATE DURING THE RACE: the session already exists but the register
      // backend call is in flight — the flag must hold back navigation.
      expect(api.postCalls, hasLength(1));
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // The backend responds 409.
      api.gate.complete();
      await tester.pumpAndSettle();

      expect(auth.signOutCalls, 1);
      expect(
        find.text('Cette adresse e-mail est déjà liée à un autre compte'),
        findsOneWidget,
      );
      expect(find.byType(DashboardScreen), findsNothing);

      // Back to login (pushed route → back).
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Se connecter'), findsOneWidget);
    },
  );
}
