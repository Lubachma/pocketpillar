import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/locale_provider.dart';
import 'package:pocketpillar/core/notifications/notification_service.dart';
import 'package:pocketpillar/core/notifications/pillar3a_reminder.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeNotificationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = FakeNotificationService();
  });

  ProviderContainer buildContainer({
    Future<Pillar3aReminderContext?> Function()? pillar3aContextLoader,
  }) {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(service),
        if (pillar3aContextLoader != null)
          pillar3aReminderContextLoaderProvider.overrideWithValue(
            pillar3aContextLoader,
          ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('setLocale: state updated and choice persisted', () async {
    final container = buildContainer();
    expect(container.read(localeProvider).languageCode, 'fr');

    await container.read(localeProvider.notifier).setLocale(const Locale('de'));

    expect(container.read(localeProvider).languageCode, 'de');
    // Re-read from prefs via a fresh repository (real persistence).
    expect(PreferencesRepository(prefs).locale?.languageCode, 'de');
    // Reminders disabled: no rescheduling.
    expect(service.scheduleCalls, 0);
  });

  test('reminders enabled: language change → immediate '
      'rescheduling in the new language', () async {
    await PreferencesRepository(prefs).setAnnualRemindersEnabled(true);
    final container = buildContainer();

    await container.read(localeProvider.notifier).setLocale(const Locale('de'));

    expect(service.scheduleCalls, 1);
    expect(service.lastYearEndChecklistBody, contains('Jahresend-Checkliste'));
    expect(service.lastPillar3aBody, contains("7'258"));

    // Back to French: rescheduled in French.
    await container.read(localeProvider.notifier).setLocale(const Locale('fr'));
    expect(service.scheduleCalls, 2);
    expect(
      service.lastYearEndChecklistBody,
      contains("checklist de fin d'année"),
    );
  });

  test(
    'reminders enabled + pillar 3a context: language change → '
    'contextual body rescheduled in the new language (batch 7 review #3)',
    () async {
      await PreferencesRepository(prefs).setAnnualRemindersEnabled(true);
      final container = buildContainer(
        pillar3aContextLoader: () async => const Pillar3aReminderContext(
          remainingCentimes: 300000,
          daysUntilYearEnd: 60,
        ),
      );

      await container
          .read(localeProvider.notifier)
          .setLocale(const Locale('de'));

      expect(service.scheduleCalls, 1);
      // Real remaining amount and days, in German.
      expect(service.lastPillar3aBody, contains("CHF 3'000"));
      expect(service.lastPillar3aBody, contains('noch 60 Tage'));
      expect(service.lastPillar3aBody, isNot(contains('bis zu')));
    },
  );
}
