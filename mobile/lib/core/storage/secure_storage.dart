import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/debug_log.dart';

/// Encrypted storage (iOS Keychain / values encrypted with a
/// non-exportable Keystore key on Android).
///
/// Used for the Supabase session ([SecureSessionLocalStorage], S2) and as
/// a foundation for future secrets (disk cache for degraded offline
/// mode). Non-sensitive preferences (biometrics, language, onboarding)
/// stay in shared_preferences — see `preferences.dart`.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// supabase_flutter's `LocalStorage` backed by [FlutterSecureStorage] (S2,
/// full review 2026-08): the session — including the refresh token — is
/// no longer persisted in plain text in SharedPreferences.
///
/// Per platform:
/// - **Android**: app backup is disabled in the manifest
///   (`android:allowBackup="false"` + `dataExtractionRules` excluding
///   prefs and files, see `android/app/src/main/AndroidManifest.xml`).
///   The plugin's values are encrypted with a **non-exportable** Keystore
///   key: restoring on another device would produce unreadable data, so
///   nothing needed to be left backed up anyway.
/// - **iOS**: nothing to configure. The Keychain isn't included in the
///   app sandbox backup (no Auto Backup / `NSUserDefaults` equivalent to
///   exclude via a manifest) and the plugin's default accessibility
///   forbids reading while the device is locked.
///
/// Migration (first launch after the update): a session written by the
/// old `SharedPreferencesLocalStorage` under the same key is copied into
/// encrypted storage then erased from SharedPreferences ([initialize]).
/// If the copy fails (platform channel unavailable...), the legacy key
/// is kept to retry on the next launch and `hasAccessToken` returns
/// false in the meantime: the user is simply sent back to sign-in —
/// clean sign-out, never a crash at startup.
class SecureSessionLocalStorage extends LocalStorage {
  SecureSessionLocalStorage({
    required this.persistSessionKey,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  /// Session persistence key — same derivation as supabase_flutter's
  /// default storage (`sb-<first host label>-auth-token`), essential
  /// for finding the legacy session.
  final String persistSessionKey;

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(persistSessionKey);
    if (legacy == null) return;
    try {
      await _storage.write(key: persistSessionKey, value: legacy);
    } on Object catch (e) {
      // See the class doc: failure → clean sign-out, the legacy key
      // stays in place for another attempt.
      debugLog('Migration de la session Supabase vers le Keychain : $e');
      return;
    }
    await prefs.remove(persistSessionKey);
  }

  @override
  Future<bool> hasAccessToken() async =>
      await _storage.read(key: persistSessionKey) != null;

  @override
  Future<String?> accessToken() => _storage.read(key: persistSessionKey);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: persistSessionKey, value: persistSessionString);
}
