import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The app's local notifications — a thin abstraction above
/// `flutter_local_notifications`, designed to be mocked in tests.
///
/// Parity with iOS `NotificationService.swift`: two recurring annual
/// reminders at 10:00 —
/// - year-end checklist on **December 15**;
/// - 3a contribution (with ceiling) on **November 1**.
abstract class NotificationService {
  /// Initializes the plugin (channels, timezone). Idempotent.
  Future<void> initialize();

  /// Requests permission to show notifications (Android 13+ /
  /// iOS). Called when the toggle is enabled, never before.
  Future<bool> requestPermission();

  /// Schedules (or reschedules — idempotent) the two annual reminders
  /// with the already-localized bodies.
  Future<void> scheduleAnnualReminders({
    required String yearEndChecklistBody,
    required String pillar3aBody,
  });

  /// Cancels both annual reminders.
  Future<void> cancelAnnualReminders();
}

/// Implementation on top of `flutter_local_notifications` + `timezone`.
class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Integer ids for the reminders (the iOS String ids
  /// `reminder.yearend.checklist` / `reminder.3a.annual` don't exist on
  /// the plugin side).
  static const int yearEndReminderId = 1;
  static const int pillar3aReminderId = 2;

  /// Reminder dates — parity with iOS `NotificationService.swift` (both
  /// at 10:00). Exposed for tests.
  static const int yearEndReminderMonth = 12;
  static const int yearEndReminderDay = 15;
  static const int pillar3aReminderMonth = 11;
  static const int pillar3aReminderDay = 1;
  static const int reminderHour = 10;

  /// Android channel for the reminders (created on first scheduling).
  static const String _channelId = 'annual_reminders';

  /// 100% Swiss app: reminders fire at 10:00 Zurich time.
  static const String _localTimezone = 'Europe/Zurich';

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_localTimezone));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // iOS permissions deferred to the toggle (requestPermission).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      // Null before Android 13: no runtime permission → granted.
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      // Like iOS: alert + sound (no badge).
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    // Platform without a dedicated implementation: nothing to request.
    return true;
  }

  @override
  Future<void> scheduleAnnualReminders({
    required String yearEndChecklistBody,
    required String pillar3aBody,
  }) async {
    await initialize();
    // zonedSchedule replaces any existing notification at the same id:
    // rescheduling is idempotent (replaces iOS's anti-double-scheduling
    // flags).
    await _plugin.zonedSchedule(
      id: yearEndReminderId,
      title: 'PocketPillar',
      body: yearEndChecklistBody,
      scheduledDate: nextInstanceOf(
        month: yearEndReminderMonth,
        day: yearEndReminderDay,
      ),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Annual recurrence (month + day + hour), like iOS's
      // UNCalendarNotificationTrigger.
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
    await _plugin.zonedSchedule(
      id: pillar3aReminderId,
      title: 'PocketPillar',
      body: pillar3aBody,
      scheduledDate: nextInstanceOf(
        month: pillar3aReminderMonth,
        day: pillar3aReminderDay,
      ),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  @override
  Future<void> cancelAnnualReminders() async {
    // Guaranteed init: cancellation must be able to follow an account
    // DELETE or a toggle OFF without prior scheduling in the session.
    await initialize();
    await _plugin.cancel(id: yearEndReminderId);
    await _plugin.cancel(id: pillar3aReminderId);
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Rappels annuels',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Next occurrence of the month/day at [reminderHour] (next year
  /// if this year's date has already passed).
  @visibleForTesting
  static tz.TZDateTime nextInstanceOf({required int month, required int day}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, month, day, reminderHour);
    if (!scheduled.isAfter(now)) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.year + 1,
        month,
        day,
        reminderHour,
      );
    }
    return scheduled;
  }
}

/// Notification service (overridden in `main()` and tests).
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => LocalNotificationService(),
);
