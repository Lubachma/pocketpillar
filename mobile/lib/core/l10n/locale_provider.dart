import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/annual_reminders.dart';
import '../notifications/notification_service.dart';
import '../notifications/pillar3a_reminder.dart';
import '../storage/preferences.dart';
import '../utils/debug_log.dart';

/// Current app locale.
///
/// Default: French. The choice made in Settings is persisted
/// (shared_preferences) and read back at startup; also used for the
/// `Accept-Language` header of API calls.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() =>
      ref.watch(preferencesRepositoryProvider).locale ?? const Locale('fr');

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setLocale(locale);
    // Annual reminders enabled: rescheduled immediately in the new
    // language (otherwise they would keep the old one until next startup).
    try {
      // 3a context: resolved via the factory injected in main() —
      // null (or absent) → generic body.
      final loadPillar3aContext = ref.read(
        pillar3aReminderContextLoaderProvider,
      );
      await rescheduleAnnualRemindersForLocale(
        service: ref.read(notificationServiceProvider),
        prefs: prefs,
        locale: locale,
        pillar3aContext: await loadPillar3aContext?.call(),
      );
    } on Object catch (e) {
      // Platform channel unavailable: the language still changes; the
      // reminders will be rescheduled at next startup.
      debugLog('Reminders not rescheduled on language change: $e');
    }
  }
}
