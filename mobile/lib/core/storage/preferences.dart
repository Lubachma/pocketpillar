import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared instance, initialized in `main()` (overridden in tests).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider doit être surchargé dans main()',
  ),
);

/// Non-sensitive user preferences, persisted via shared_preferences.
///
/// (Secrets — tokens, financial data — go into
/// `flutter_secure_storage`, see `secure_storage.dart`.)
class PreferencesRepository {
  PreferencesRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyHasSeenOnboarding = 'hasSeenOnboarding';
  static const String _keyBiometricLockEnabled = 'biometricLockEnabled';
  static const String _keyLocale = 'appLocale';
  static const String _keyAnnualRemindersEnabled = 'annualRemindersEnabled';

  /// Pre-login onboarding already shown (default: false).
  bool get hasSeenOnboarding => _prefs.getBool(_keyHasSeenOnboarding) ?? false;

  Future<void> setHasSeenOnboarding() =>
      _prefs.setBool(_keyHasSeenOnboarding, true);

  /// Biometric lock enabled (default: true, phase 2 baseline parity).
  bool get biometricLockEnabled =>
      _prefs.getBool(_keyBiometricLockEnabled) ?? true;

  Future<void> setBiometricLockEnabled(bool enabled) =>
      _prefs.setBool(_keyBiometricLockEnabled, enabled);

  /// Annual reminders (local notifications) enabled — opt-in, default
  /// false (phase 3.10).
  bool get annualRemindersEnabled =>
      _prefs.getBool(_keyAnnualRemindersEnabled) ?? false;

  Future<void> setAnnualRemindersEnabled(bool enabled) =>
      _prefs.setBool(_keyAnnualRemindersEnabled, enabled);

  /// Locale chosen in settings, null if never set.
  Locale? get locale {
    final code = _prefs.getString(_keyLocale);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale locale) =>
      _prefs.setString(_keyLocale, locale.languageCode);

  /// Year-end checklist key — same format as the iOS app
  /// (`checklist.<year>.completed`).
  static String _keyChecklistCompleted(int year) => 'checklist.$year.completed';

  /// Ids of checked items for the given year (empty by default).
  List<String> getCompletedChecklistItems(int year) =>
      _prefs.getStringList(_keyChecklistCompleted(year)) ?? const [];

  Future<void> setCompletedChecklistItems(int year, List<String> ids) =>
      _prefs.setStringList(_keyChecklistCompleted(year), ids);
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(ref.watch(sharedPreferencesProvider)),
);

/// True when the pre-login onboarding has been seen (persisted).
final hasSeenOnboardingProvider =
    NotifierProvider<HasSeenOnboardingNotifier, bool>(
      HasSeenOnboardingNotifier.new,
    );

class HasSeenOnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesRepositoryProvider).hasSeenOnboarding;

  /// Marks onboarding as seen and persists the flag.
  Future<void> complete() async {
    state = true;
    await ref.read(preferencesRepositoryProvider).setHasSeenOnboarding();
  }
}
