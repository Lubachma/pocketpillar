import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/gen/app_localizations.dart';
import '../storage/preferences.dart';
import '../utils/currency.dart';
import '../utils/swiss_pension.dart';
import 'notification_service.dart';
import 'pillar3a_reminder.dart';

/// Label for the 3a ceiling (with 2nd pillar) interpolated into the
/// reminder's generic body — **derived** from `pillar3aMaxWithPillar2`
/// ("7,258" — parity with iOS `SwissPensionConstants.max3aFrancs`; batch
/// 7 review, no more hardcoded constant).
final String pillar3aMaxReminderLabel = formatChfFrancs(pillar3aMaxWithPillar2);

/// Annual reminders enabled (persisted in settings, reread at
/// startup). Default: false — explicit opt-in via the Settings toggle
/// (iOS used to schedule as usage went along).
final annualRemindersEnabledProvider =
    NotifierProvider<AnnualRemindersEnabledNotifier, bool>(
      AnnualRemindersEnabledNotifier.new,
    );

class AnnualRemindersEnabledNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(preferencesRepositoryProvider).annualRemindersEnabled;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref
        .read(preferencesRepositoryProvider)
        .setAnnualRemindersEnabled(enabled);
  }
}

/// On startup: reschedules the reminders with the current locale's
/// labels if the user has enabled them (no-op otherwise). Rescheduling
/// refreshes the notifications' language.
///
/// [pillar3aContext]: 3a remaining amount computed from the profile
/// (batch 7) — null → generic body with the ceiling (graceful fallback).
Future<void> syncAnnualRemindersAtStartup({
  required NotificationService service,
  required PreferencesRepository prefs,
  required AppLocalizations l10n,
  Pillar3aReminderContext? pillar3aContext,
}) async {
  if (!prefs.annualRemindersEnabled) return;
  await service.scheduleAnnualReminders(
    yearEndChecklistBody: l10n.notificationYearEndChecklist,
    pillar3aBody: pillar3aReminderBody(l10n, pillar3aContext),
  );
}

/// Language change: immediately reschedules the reminders in the new
/// locale if the user has enabled them (no-op otherwise) — otherwise
/// they'd keep the old language until the next startup.
Future<void> rescheduleAnnualRemindersForLocale({
  required NotificationService service,
  required PreferencesRepository prefs,
  required Locale locale,
  Pillar3aReminderContext? pillar3aContext,
}) async {
  if (!prefs.annualRemindersEnabled) return;
  final l10n = await AppLocalizations.delegate.load(locale);
  await service.scheduleAnnualReminders(
    yearEndChecklistBody: l10n.notificationYearEndChecklist,
    pillar3aBody: pillar3aReminderBody(l10n, pillar3aContext),
  );
}

/// Body of the 3a reminder: contextual when the profile could be read
/// ("You still have CHF 3,000 left to pay in...", batch 7), generic
/// otherwise (ceiling "7,258" — historical behavior, graceful fallback).
String pillar3aReminderBody(
  AppLocalizations l10n,
  Pillar3aReminderContext? context,
) {
  if (context == null) {
    return l10n.notification3aReminder(pillar3aMaxReminderLabel);
  }
  return l10n.notification3aReminderContextual(
    formatChfFrancs(context.remainingCentimes),
    context.daysUntilYearEnd,
  );
}
