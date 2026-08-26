import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/storage/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S2 (full review 2026-08): the Supabase session (refresh token) lives
/// in encrypted storage, no longer in plaintext SharedPreferences.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const sessionKey = 'sb-projet-test-auth-token';

  /// Contents of the simulated "encrypted storage" (mocked method channel).
  final secureStore = <String, String>{};

  /// Simulates a broken platform channel (write that throws).
  var failWrites = false;

  setUp(() {
    secureStore.clear();
    failWrites = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = call.arguments as Map<dynamic, dynamic>;
          final key = args['key'] as String;
          switch (call.method) {
            case 'write':
              if (failWrites) {
                throw PlatformException(code: 'unavailable');
              }
              secureStore[key] = args['value'] as String;
              return null;
            case 'read':
              return secureStore[key];
            case 'delete':
              secureStore.remove(key);
              return null;
            case 'containsKey':
              return secureStore.containsKey(key);
            default:
              throw UnimplementedError(call.method);
          }
        });
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('persistSession / hasAccessToken / accessToken (round trip)', () async {
    final storage = SecureSessionLocalStorage(persistSessionKey: sessionKey);
    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);

    await storage.persistSession('{"accessToken":"a","refreshToken":"r"}');

    expect(await storage.hasAccessToken(), isTrue);
    expect(
      await storage.accessToken(),
      '{"accessToken":"a","refreshToken":"r"}',
    );
  });

  test('removePersistedSession clears the session', () async {
    final storage = SecureSessionLocalStorage(persistSessionKey: sessionKey);
    await storage.initialize();
    await storage.persistSession('{"accessToken":"a"}');

    await storage.removePersistedSession();

    expect(await storage.hasAccessToken(), isFalse);
    expect(secureStore, isEmpty);
  });

  test('migration: a session inherited from SharedPreferences is moved '
      'to encrypted storage then cleared from plaintext storage', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sessionKey, '{"accessToken":"legacy"}');

    final storage = SecureSessionLocalStorage(persistSessionKey: sessionKey);
    await storage.initialize();

    // Copied into encrypted storage…
    expect(secureStore[sessionKey], '{"accessToken":"legacy"}');
    expect(await storage.accessToken(), '{"accessToken":"legacy"}');
    // …and removed from SharedPreferences.
    expect(prefs.getString(sessionKey), isNull);
  });

  test('without an inherited session, initialize touches nothing', () async {
    final storage = SecureSessionLocalStorage(persistSessionKey: sessionKey);
    await storage.initialize();

    expect(secureStore, isEmpty);
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('copy failure: inherited key kept (retried on next '
      'launch), session not visible → clean re-login', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sessionKey, '{"accessToken":"legacy"}');
    failWrites = true;

    final storage = SecureSessionLocalStorage(persistSessionKey: sessionKey);
    await storage.initialize(); // does not throw

    expect(secureStore, isEmpty);
    expect(await storage.hasAccessToken(), isFalse);
    expect(prefs.getString(sessionKey), '{"accessToken":"legacy"}');
  });
}
