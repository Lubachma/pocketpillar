/// Fastify backend API configuration.
///
/// The base URL is injected at build time:
/// `--dart-define=API_BASE_URL=https://api.exemple.ch`
/// Default: http://localhost:3000 (local backend).
/// On the Android emulator, use http://10.0.2.2:3000 to reach the
/// host machine's localhost.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
