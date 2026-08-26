import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/utils/currency.dart';

void main() {
  group('formatChf', () {
    test('formats with the Swiss apostrophe and two decimals', () {
      expect(formatChf(123456789), "CHF 1'234'567.89");
      expect(formatChf(9500000), "CHF 95'000.00");
      expect(formatChf(100000), "CHF 1'000.00");
      expect(formatChf(100000000000), "CHF 1'000'000'000.00");
    });

    test('amounts without a separator', () {
      expect(formatChf(0), 'CHF 0.00');
      expect(formatChf(5), 'CHF 0.05');
      expect(formatChf(95), 'CHF 0.95');
      expect(formatChf(99999), 'CHF 999.99');
    });

    test('negative amounts', () {
      expect(formatChf(-123400), "-CHF 1'234.00");
      expect(formatChf(-50), '-CHF 0.50');
    });

    test('without a currency symbol', () {
      expect(formatChf(123456789, withCurrency: false), "1'234'567.89");
      expect(formatChf(0, withCurrency: false), '0.00');
    });
  });

  group('centimesToChfInput', () {
    test('centimes → CHF input without symbol or separator', () {
      expect(centimesToChfInput(9500000), '95000');
      expect(centimesToChfInput(123456789), '1234567.89');
      expect(centimesToChfInput(0), '0');
      expect(centimesToChfInput(50), '0.5');
      expect(centimesToChfInput(5), '0.05');
      expect(centimesToChfInput(-123400), '-1234');
    });
  });

  group('parseChfToCentimes', () {
    test('CHF input → centimes (Swiss separators accepted)', () {
      expect(parseChfToCentimes('95000'), 9500000);
      expect(parseChfToCentimes("95'000"), 9500000);
      expect(parseChfToCentimes('1234.56'), 123456);
      expect(parseChfToCentimes('1 234,56'), 123456);
      expect(parseChfToCentimes(' 85000 '), 8500000);
    });

    test('invalid input → null', () {
      expect(parseChfToCentimes(''), isNull);
      expect(parseChfToCentimes('   '), isNull);
      expect(parseChfToCentimes('abc'), isNull);
      expect(parseChfToCentimes('12.34.56'), isNull);
    });

    test('non-finite values → null (isFinite guard, no crash)', () {
      // tryParse accepts them; round() would throw UnsupportedError.
      expect(parseChfToCentimes('Infinity'), isNull);
      expect(parseChfToCentimes('NaN'), isNull);
      expect(parseChfToCentimes('-Infinity'), isNull);
    });

    test('finite scientific notation: no crash (bounded by the '
        'validators)', () {
      // 1e300 × 100 saturates the VM int64 without throwing.
      expect(parseChfToCentimes('1e300'), isNotNull);
    });

    test('typographic thousands separators accepted', () {
      expect(parseChfToCentimes('95\u2019000'), 9500000); // U+2019
      expect(parseChfToCentimes('95\u00A0000'), 9500000); // U+00A0
      expect(parseChfToCentimes('95\u202F000'), 9500000); // U+202F
    });

    test('round trip centimes → input → centimes (exact)', () {
      for (final centimes in [0, 5, 50, 95, 8500000, 123456789, -123400]) {
        expect(parseChfToCentimes(centimesToChfInput(centimes)), centimes);
      }
    });
  });
}
