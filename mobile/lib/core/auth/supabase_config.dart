import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../storage/secure_storage.dart';

/// Initialization and access to the Supabase client.
///
/// Credentials are injected at build time:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// (never a real value in the repo, see mobile/README.md).
///
/// Without configuration (tests, first dev launch), the client is `null`:
/// the app still starts and shows the login screen.
///
/// The session (refresh token) is persisted in encrypted storage via
/// [SecureSessionLocalStorage] (S2) on native platforms; on web, the
/// SDK's default browser storage is used (see [authOptionsFor]).
abstract final class SupabaseConfig {
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool _initialized = false;

  /// The dart-defines are present (initialization possible).
  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized || !isConfigured) return;
    await Supabase.initialize(
      url: _url,
      publishableKey: _anonKey,
      authOptions: authOptionsFor(isWeb: kIsWeb),
    );
    _initialized = true;
  }

  /// Session storage depending on the platform:
  /// - **web**: `supabase_flutter`'s default browser storage
  ///   (SharedPreferences → localStorage) — no simulated "secure
  ///   storage", and `detectSessionInUri` handles email confirmation
  ///   links;
  /// - **native**: session (refresh token) encrypted via Keychain/Keystore
  ///   through [SecureSessionLocalStorage] (S2, full review 2026-08).
  @visibleForTesting
  static FlutterAuthClientOptions authOptionsFor({required bool isWeb}) {
    if (isWeb) return const FlutterAuthClientOptions();
    return FlutterAuthClientOptions(
      localStorage: SecureSessionLocalStorage(
        persistSessionKey: _persistSessionKey,
      ),
    );
  }

  /// Same derivation as the default `SharedPreferencesLocalStorage`'s
  /// key (`sb-<first host label>-auth-token`, see `Supabase.
  /// initialize`) — required to migrate a legacy session.
  static String get _persistSessionKey =>
      'sb-${Uri.parse(_url).host.split('.').first}-auth-token';

  /// Supabase client, or null if not configured.
  static SupabaseClient? get clientOrNull =>
      _initialized ? Supabase.instance.client : null;
}
