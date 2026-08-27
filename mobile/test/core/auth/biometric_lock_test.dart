import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/auth/biometric_lock.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';

import '../../helpers/fakes.dart';

/// Stubbed prompt: scripted answers, no platform channel.
class _StubBiometricService extends BiometricService {
  _StubBiometricService(this.answers);

  final List<bool> answers;
  int calls = 0;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return answers.removeAt(0);
  }
}

/// Signed out at launch (first emission: null); [logIn] then emits a
/// session, like a real password login mid-run.
class _LateLoginFakeAuthRepository extends FakeAuthRepository {
  final StreamController<Session?> _controller =
      StreamController<Session?>.broadcast();

  @override
  Stream<Session?> get sessionChanges async* {
    yield null;
    yield* _controller.stream;
  }

  void logIn() => _controller.add(buildFakeSession(email: 'user@example.ch'));
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpLock(
    WidgetTester tester, {
    BiometricService? service,
    AuthRepository? auth,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(
            auth ?? FakeAuthRepository(),
          ),
          if (service != null)
            biometricServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BiometricLock(child: Scaffold(body: Text('Contenu sensible'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(BiometricLock)));

  testWidgets('COLD START with a session: the lock arms immediately '
      '(review 08.2026 — it only armed on background return before)', (
    tester,
  ) async {
    // Toggle ON by default + persisted session: a kill/relaunch must not
    // land straight on the financial data.
    final service = _StubBiometricService([false]);
    await pumpLock(
      tester,
      service: service,
      auth: SignedInFakeAuthRepository(),
    );

    // Prompt fired on launch and was denied → the lock screen stays up
    // (the child remains in the Stack, so we assert the lock state).
    expect(service.calls, 1);
    expect(containerOf(tester).read(biometricLockedProvider), isTrue);
  });

  testWidgets('cold start: successful prompt unlocks the content', (
    tester,
  ) async {
    final service = _StubBiometricService([true]);
    await pumpLock(
      tester,
      service: service,
      auth: SignedInFakeAuthRepository(),
    );

    expect(service.calls, 1);
    expect(containerOf(tester).read(biometricLockedProvider), isFalse);
    expect(find.text('Contenu sensible'), findsOneWidget);
  });

  testWidgets('cold start with the toggle OFF: no lock, no prompt', (
    tester,
  ) async {
    await prefs.setBool('biometricLockEnabled', false);
    final service = _StubBiometricService([]);
    await pumpLock(
      tester,
      service: service,
      auth: SignedInFakeAuthRepository(),
    );

    expect(service.calls, 0);
    expect(containerOf(tester).read(biometricLockedProvider), isFalse);
  });

  testWidgets('fresh login mid-run: no lock, no prompt (the user just '
      'proved who they are — regression caught by the app suites)', (
    tester,
  ) async {
    final service = _StubBiometricService([]);
    final auth = _LateLoginFakeAuthRepository();
    await pumpLock(tester, service: service, auth: auth);

    auth.logIn();
    await tester.pumpAndSettle();

    expect(service.calls, 0);
    expect(containerOf(tester).read(biometricLockedProvider), isFalse);
    expect(find.text('Contenu sensible'), findsOneWidget);
  });

  testWidgets('multitasking overlay: inactive (iOS app-switcher) → shown, '
      'resumed → removed', (tester) async {
    await pumpLock(tester);
    expect(find.text('Contenu sensible'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
    expect(find.text('Contenu sensible'), findsOneWidget);
  });

  testWidgets('multitasking overlay: paused (Android background) → shown, '
      'resumed → removed without lock (< 60 s)', (tester) async {
    await pumpLock(tester);

    // Real backgrounding sequence: resumed → inactive →
    // hidden → paused (AppLifecycleListener only emits valid
    // transitions).
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
    // Quick return: the biometric lock did not trigger.
    expect(find.text('Contenu sensible'), findsOneWidget);
  });
}
