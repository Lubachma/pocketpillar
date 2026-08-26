import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/app/app.dart';
import 'package:pocketpillar/core/notifications/notification_service.dart';
import 'package:pocketpillar/core/notifications/pillar3a_reminder.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  Future<SharedPreferences> mockPrefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  testWidgets('first launch without a session → pre-login onboarding', (
    tester,
  ) async {
    final prefs = await mockPrefs({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Votre retraite repose sur 3 piliers'), findsOneWidget);
  });

  testWidgets('onboarding already seen, no session → login screen', (
    tester,
  ) async {
    final prefs = await mockPrefs({'hasSeenOnboarding': true});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('reminders enabled + 3a context: contextual rescheduling '
      'after the 1st frame, without blocking startup (review batch 7)', (
    tester,
  ) async {
    final prefs = await mockPrefs({
      'hasSeenOnboarding': true,
      'annualRemindersEnabled': true,
    });
    final notifications = FakeNotificationService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(notifications),
          pillar3aReminderContextLoaderProvider.overrideWithValue(
            () async => const Pillar3aReminderContext(
              remainingCentimes: 300000,
              daysUntilYearEnd: 60,
            ),
          ),
        ],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The screen is rendered (startup not blocked) AND the context
    // has been rescheduled in the background.
    expect(find.text('Se connecter'), findsOneWidget);
    expect(notifications.scheduleCalls, 1);
    expect(notifications.lastPillar3aBody, contains("CHF 3'000"));
    expect(notifications.lastPillar3aBody, contains('60 jours restants'));
  });

  testWidgets('reminders enabled without context: no rescheduling — '
      'main()’s generic schedule remains correct', (tester) async {
    final prefs = await mockPrefs({
      'hasSeenOnboarding': true,
      'annualRemindersEnabled': true,
    });
    final notifications = FakeNotificationService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(notifications),
          // Factory absent (default null) → silent graceful fallback.
        ],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
    expect(notifications.scheduleCalls, 0);
  });
}
