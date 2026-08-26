import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/core/notifications/annual_reminders.dart';
import 'package:pocketpillar/core/notifications/notification_service.dart';
import 'package:pocketpillar/core/notifications/pillar3a_reminder.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PreferencesRepository repository;
  late FakeNotificationService service;
  late AppLocalizations l10n;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = PreferencesRepository(prefs);
    service = FakeNotificationService();
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  test('startup: reminders disabled → no scheduling', () async {
    await syncAnnualRemindersAtStartup(
      service: service,
      prefs: repository,
      l10n: l10n,
    );
    expect(service.scheduleCalls, 0);
  });

  test(
    'startup: reminders enabled → rescheduled with localized bodies',
    () async {
      await repository.setAnnualRemindersEnabled(true);
      await syncAnnualRemindersAtStartup(
        service: service,
        prefs: repository,
        l10n: l10n,
      );
      expect(service.scheduleCalls, 1);
      expect(
        service.lastYearEndChecklistBody,
        contains('checklist de fin d\'année'),
      );
      // Pillar 3a cap interpolated (parity with iOS max3aFrancs = 7'258).
      expect(service.lastPillar3aBody, contains("7'258"));
    },
  );

  test(
    'startup: pillar 3a context provided → contextual body (batch 7)',
    () async {
      await repository.setAnnualRemindersEnabled(true);
      await syncAnnualRemindersAtStartup(
        service: service,
        prefs: repository,
        l10n: l10n,
        pillar3aContext: const Pillar3aReminderContext(
          remainingCentimes: 300000,
          daysUntilYearEnd: 60,
        ),
      );
      expect(service.scheduleCalls, 1);
      // Real remaining amount + days, instead of the generic cap.
      expect(service.lastPillar3aBody, contains("CHF 3'000"));
      expect(service.lastPillar3aBody, contains('60 jours restants'));
      expect(service.lastPillar3aBody, isNot(contains("jusqu'à")));
    },
  );

  test('persisted toggle: defaults to false, enable/disable', () async {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(annualRemindersEnabledProvider), false);

    await container
        .read(annualRemindersEnabledProvider.notifier)
        .setEnabled(true);
    expect(container.read(annualRemindersEnabledProvider), true);
    // Re-read from prefs via a fresh repository (real persistence).
    expect(PreferencesRepository(prefs).annualRemindersEnabled, true);

    await container
        .read(annualRemindersEnabledProvider.notifier)
        .setEnabled(false);
    expect(container.read(annualRemindersEnabledProvider), false);
    expect(PreferencesRepository(prefs).annualRemindersEnabled, false);
  });

  group('scheduling dates (iOS parity)', () {
    setUp(() {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Zurich'));
    });

    test('constants: December 15 and November 1 at 10:00', () {
      expect(LocalNotificationService.yearEndReminderMonth, 12);
      expect(LocalNotificationService.yearEndReminderDay, 15);
      expect(LocalNotificationService.pillar3aReminderMonth, 11);
      expect(LocalNotificationService.pillar3aReminderDay, 1);
      expect(LocalNotificationService.reminderHour, 10);
    });

    test('next occurrence: exact month/day/hour, in the future', () {
      final now = tz.TZDateTime.now(tz.local);
      final yearEnd = LocalNotificationService.nextInstanceOf(
        month: LocalNotificationService.yearEndReminderMonth,
        day: LocalNotificationService.yearEndReminderDay,
      );
      expect(yearEnd.month, 12);
      expect(yearEnd.day, 15);
      expect(yearEnd.hour, 10);
      expect(yearEnd.minute, 0);
      expect(yearEnd.isAfter(now), isTrue);
      // Never more than one year in the future.
      expect([now.year, now.year + 1].contains(yearEnd.year), isTrue);
    });
  });
}
