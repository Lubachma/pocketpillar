import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared demo account credentials, shown on the login screen.
class DemoLoginConfig {
  const DemoLoginConfig({required this.email, required this.password});

  final String email;
  final String password;
}

/// Public demo mode (portfolio showcase) — enabled at build time:
/// `--dart-define=DEMO_MODE=true --dart-define=DEMO_EMAIL=...
/// --dart-define=DEMO_PASSWORD=...`
///
/// The embedded password is public by nature (shared account, fake
/// data reset every night) — same injection logic as
/// `PurchasesConfig`: without the defines, the app is strictly unchanged.
abstract final class DemoConfig {
  static const bool enabled = bool.fromEnvironment('DEMO_MODE');
  static const String _email = String.fromEnvironment('DEMO_EMAIL');
  static const String _password = String.fromEnvironment('DEMO_PASSWORD');

  static DemoLoginConfig? get loginOrNull =>
      enabled && _email.isNotEmpty && _password.isNotEmpty
      ? const DemoLoginConfig(email: _email, password: _password)
      : null;
}

/// Overridable in tests; null = demo mode inactive.
final demoLoginConfigProvider = Provider<DemoLoginConfig?>(
  (_) => DemoConfig.loginOrNull,
);
