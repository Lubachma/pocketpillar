import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketpillar/app/app.dart';
import 'package:pocketpillar/app/routes.dart';
import 'package:pocketpillar/app/splash_screen.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/features/auth/presentation/login_screen.dart';
import 'package:pocketpillar/features/dashboard/presentation/dashboard_screen.dart';
import 'package:pocketpillar/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pocketpillar/features/scenarios/presentation/scenarios_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fakes.dart';

/// Session whose first emission is suspended until [gate]:
/// simulates re-reading the persisted session at startup.
class GatedAuthRepository extends FakeAuthRepository {
  final gate = Completer<Session?>();

  @override
  Stream<Session?> get sessionChanges async* {
    yield await gate.future;
  }
}

/// Starts signed out; the session is emitted when `signInWithPassword`
/// succeeds (real login happening in the test).
class SignInEmittingAuthRepository extends FakeAuthRepository {
  final _controller = StreamController<Session?>.broadcast();
  Session? _current;

  @override
  Stream<Session?> get sessionChanges async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await super.signInWithPassword(email: email, password: password);
    _current = buildFakeSession();
    _controller.add(_current);
  }
}

void main() {
  testWidgets('splash: no dashboard flash while the session is being '
      're-read, then /login for a signed-out user', (tester) async {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();
    final auth = GatedAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pump();

    // Session not re-read yet: neutral splash, nothing else.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);

    // Session re-read: none → login (the dashboard is never shown).
    auth.gate.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets('deep link at first launch: target kept through '
      'onboarding and login', (tester) async {
    SharedPreferences.setMockInitialValues({}); // onboarding never seen
    final prefs = await SharedPreferences.getInstance();
    final auth = SignInEmittingAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();

    // First launch → onboarding.
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // Incoming deep link to a protected route during onboarding.
    final context = tester.element(find.byType(OnboardingScreen));
    GoRouter.of(context).go(Routes.scenarios);
    await tester.pumpAndSettle();

    // Still held on onboarding (target remembered in `from`).
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(ScenariosScreen), findsNothing);

    // Onboarding finished → login, with `from` passed along.
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // Login → back to the original target, not the dashboard.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse e-mail'),
      'user@example.ch',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'motdepasse123',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.byType(ScenariosScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets('protocol-relative from (//evil.com): ignored, back to the '
      'dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(SignedInFakeAuthRepository()),
        ],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Signed in, a public route with a protocol-relative `from` must
    // not be followed: rejected → defaults to dashboard (never an external target).
    final context = tester.element(find.byType(DashboardScreen));
    GoRouter.of(context).go(
      Uri(path: Routes.login, queryParameters: {'from': '//evil.com'})
          .toString(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
