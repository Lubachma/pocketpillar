import 'package:flutter/foundation.dart';

/// RevenueCat configuration (in-app purchases).
///
/// The **public** SDK keys are injected at build time:
/// `--dart-define=REVENUECAT_API_KEY_IOS=... --dart-define=REVENUECAT_API_KEY_ANDROID=...`
/// (never a real value in the repo, like SUPABASE_*).
///
/// Without a key for the current platform (RevenueCat project not yet
/// created — phase 1b-accounts), the app works fully: the SDK is
/// **never** configured and the paywall shows the "purchase
/// unavailable" state. No crash possible from a missing key.
abstract final class PurchasesConfig {
  static const String _iosApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
  );
  static const String _androidApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
  );

  /// RevenueCat hosted purchase link (Web Purchase Link — web only):
  /// `--dart-define=REVENUECAT_WEB_PURCHASE_LINK=https://pay.revenuecat.com/...`
  /// Empty = web purchases unavailable (informational paywall).
  static const String webPurchaseLinkUrl = String.fromEnvironment(
    'REVENUECAT_WEB_PURCHASE_LINK',
  );

  /// SDK key for the current platform, or null if missing ("purchases
  /// unavailable" mode). `defaultTargetPlatform` rather than
  /// `Platform.isIOS`: overridable in tests, no dart:io.
  static String? get apiKeyOrNull {
    final key = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => _iosApiKey,
      TargetPlatform.android => _androidApiKey,
      _ => '',
    };
    return key.isEmpty ? null : key;
  }

  /// An SDK key exists for this platform.
  static bool get isConfigured => apiKeyOrNull != null;
}
