import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/auth/supabase_config.dart';
import 'package:pocketpillar/core/storage/secure_storage.dart';

void main() {
  group('SupabaseConfig.authOptionsFor', () {
    test(
      'web: default browser storage (localStorage null → SharedPreferences)',
      () {
        final options = SupabaseConfig.authOptionsFor(isWeb: true);

        expect(options.localStorage, isNull);
      },
    );

    test('native: encrypted persisted session (SecureSessionLocalStorage)', () {
      final options = SupabaseConfig.authOptionsFor(isWeb: false);

      expect(options.localStorage, isA<SecureSessionLocalStorage>());
    });
  });
}
