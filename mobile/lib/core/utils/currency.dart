// Amount formatting.
//
// The API expresses all amounts in **centimes** of CHF
// (see `docs/api-contract.md` §1): it's the only unit accepted here.

/// Formats an amount in centimes with the Swiss apostrophe as thousands
/// separator and two decimals.
///
/// ```dart
/// formatChf(123456789) // 'CHF 1'234'567.89'
/// formatChf(9500000)   // 'CHF 95'000.00'
/// formatChf(-123400)   // '-CHF 1'234.00'
/// ```
String formatChf(int centimes, {bool withCurrency = true}) {
  final negative = centimes < 0;
  final absolute = centimes.abs();
  final francs = absolute ~/ 100;
  final cents = (absolute % 100).toString().padLeft(2, '0');
  final amount = '${_groupThousands(francs)}.$cents';
  final sign = negative ? '-' : '';
  return withCurrency ? '${sign}CHF $amount' : '$sign$amount';
}

String _groupThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write("'");
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Formats an amount in centimes **rounded to the franc**, without
/// decimals or a currency symbol — compact label interpolated in
/// notifications (parity with iOS's "7'258").
///
/// ```dart
/// formatChfFrancs(300000) // "3'000"
/// formatChfFrancs(725850) // "7'259" (arrondi)
/// ```
String formatChfFrancs(int centimes) =>
    _groupThousands((centimes / 100).round());

/// Converts centimes into an editable CHF string (without symbol or
/// thousands separator) — to pre-fill an input field.
///
/// ```dart
/// centimesToChfInput(9500000)   // '95000'
/// centimesToChfInput(123456789) // '1234567.89'
/// centimesToChfInput(-123400)   // '-1234'
/// ```
String centimesToChfInput(int centimes) {
  final negative = centimes < 0;
  final absolute = centimes.abs();
  final francs = absolute ~/ 100;
  final cents = absolute % 100;
  final sign = negative ? '-' : '';
  if (cents == 0) return '$sign$francs';
  final centsDigits = cents.toString().padLeft(2, '0');
  // No superfluous zero: 50 centimes → '.5', 5 centimes → '.05'.
  final trimmed = centsDigits.endsWith('0')
      ? centsDigits.substring(0, 1)
      : centsDigits;
  return '$sign$francs.$trimmed';
}

/// Parses free-form CHF input into centimes. Accepts the straight or
/// typographic apostrophe (U+2019), space, non-breaking space (U+00A0),
/// and narrow no-break space (U+202F) as thousands separators, and dot
/// or comma as decimal separator. Returns `null` if the input isn't a
/// finite number.
///
/// ```dart
/// parseChfToCentimes("95'000")   // 9500000
/// parseChfToCentimes('1234.56')  // 123456
/// parseChfToCentimes('1 234,56') // 123456
/// parseChfToCentimes('abc')      // null
/// parseChfToCentimes('Infinity') // null (garde isFinite)
/// ```
int? parseChfToCentimes(String input) {
  final cleaned = input
      .trim()
      .replaceAll("'", '')
      .replaceAll('\u2019', '')
      .replaceAll(' ', '')
      .replaceAll('\u00A0', '')
      .replaceAll('\u202F', '')
      .replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  // tryParse accepts 'Infinity'/'NaN': round() would throw UnsupportedError.
  if (value == null || !value.isFinite) return null;
  return (value * 100).round();
}
