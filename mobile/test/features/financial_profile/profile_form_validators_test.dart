import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/financial_profile/presentation/profile_form_validators.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  group('validatePercentField', () {
    test('valid values and bounds', () {
      expect(validatePercentField(l10n, '', min: 0, max: 100), isNull);
      expect(validatePercentField(l10n, '6.8', min: 0, max: 100), isNull);
      expect(validatePercentField(l10n, '6,8', min: 0, max: 100), isNull);
      expect(validatePercentField(l10n, '101', min: 0, max: 100), isNotNull);
      expect(validatePercentField(l10n, '-1', min: 0, max: 100), isNotNull);
    });

    test('NaN and Infinity rejected (NaN comparisons always false)', () {
      expect(validatePercentField(l10n, 'NaN', min: 0, max: 100), isNotNull);
      expect(
        validatePercentField(l10n, 'Infinity', min: 0, max: 100),
        isNotNull,
      );
      expect(
        validatePercentField(l10n, '-Infinity', min: -50, max: 100),
        isNotNull,
      );
    });
  });

  group('tryParsePercentField', () {
    test('parses common formats', () {
      expect(tryParsePercentField(''), isNull);
      expect(tryParsePercentField('6.8'), 6.8);
      expect(tryParsePercentField('6,8'), 6.8);
    });

    test('NaN and Infinity → null', () {
      expect(tryParsePercentField('NaN'), isNull);
      expect(tryParsePercentField('Infinity'), isNull);
      expect(tryParsePercentField('-Infinity'), isNull);
    });
  });

  group('validateMoneyField', () {
    test('backend upper bound (int4 max centimes = CHF 21 474 836.47)', () {
      expect(validateMoneyField(l10n, '21474836.47', required: true), isNull);
      expect(
        validateMoneyField(l10n, '21474836.48', required: true),
        isNotNull,
      );
      expect(validateMoneyField(l10n, '1000000000', required: true), isNotNull);
      // Scientific notation: finite but out of range → rejected.
      expect(validateMoneyField(l10n, '1e300', required: true), isNotNull);
    });
  });
}
