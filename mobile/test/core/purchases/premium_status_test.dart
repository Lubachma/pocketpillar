import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/purchases/premium_status.dart';

void main() {
  group('PremiumStatus.fromJson', () {
    test('active block with expiry', () {
      final status = PremiumStatus.fromJson({
        'active': true,
        'expiresAt': '2027-08-10T12:00:00.000Z',
      });

      expect(status.active, isTrue);
      expect(status.expiresAt, DateTime.utc(2027, 8, 10, 12));
    });

    test('inactive block without expiry (never subscribed)', () {
      final status = PremiumStatus.fromJson({
        'active': false,
        'expiresAt': null,
      });

      expect(status.active, isFalse);
      expect(status.expiresAt, isNull);
    });

    test('missing block (backend predating the sprint) → none, no throw', () {
      expect(PremiumStatus.fromJson(null).active, isFalse);
    });

    test('malformed block → none, no throw', () {
      expect(PremiumStatus.fromJson('premium').active, isFalse);
      expect(PremiumStatus.fromJson({'active': 'oui'}).active, isFalse);
      expect(
        PremiumStatus.fromJson({'active': true, 'expiresAt': 42}).expiresAt,
        isNull,
      );
    });

    test('invalid date → expiresAt null (tryParse), active kept', () {
      final status = PremiumStatus.fromJson({
        'active': true,
        'expiresAt': 'pas-une-date',
      });

      expect(status.active, isTrue);
      expect(status.expiresAt, isNull);
    });
  });
}
