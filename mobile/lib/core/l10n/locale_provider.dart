import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/annual_reminders.dart';
import '../notifications/notification_service.dart';
import '../notifications/pillar3a_reminder.dart';
import '../storage/preferences.dart';
import '../utils/debug_log.dart';

/// Locale courante de l'app.
///
/// Défaut : français (parité iOS). Le choix fait dans les Paramètres est
/// persisté (shared_preferences) et relu au démarrage ; utilisé aussi pour
/// l'en-tête `Accept-Language` des appels API.
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
    // Rappels annuels activés : replanifiés immédiatement dans la nouvelle
    // langue (sinon ils garderaient l'ancienne jusqu'au prochain démarrage).
    try {
      // Contexte 3a (batch 7) : résolu via la fabrique injectée dans
      // main() — null (ou absente) → corps générique.
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
      // Canal plateforme indisponible : la langue change quand même, les
      // rappels seront replanifiés au prochain démarrage.
      debugLog('Rappels non replanifiés au changement de langue : $e');
    }
  }
}
