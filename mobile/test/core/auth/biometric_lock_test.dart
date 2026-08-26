import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/auth/biometric_lock.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpLock(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: BiometricLock(child: Scaffold(body: Text('Contenu sensible'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

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
