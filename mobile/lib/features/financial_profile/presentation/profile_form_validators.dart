import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/utils/currency.dart';

/// Financial profile form validators — localized messages, aligned
/// with the backend Zod schemas' bounds
/// (`src/modules/financial-profile/financial-profile.schema.ts`,
/// `src/modules/user/user.schema.ts`).

/// Backend upper bound: 10¹¹ centimes = CHF 1 billion.
const int maxMoneyCentimes = 100000000000;

/// Input CHF amount → centimes, or null if empty/invalid (negative
/// included: inline validation can be short-circuited when the field
/// is outside the tree — collapsed "advanced" section of the LPP sheet).
int? tryParseMoneyField(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final centimes = parseChfToCentimes(text);
  if (centimes == null || centimes < 0) return null;
  return centimes;
}

/// Validates a CHF amount field. [required]: the field can't be empty.
/// Returns the localized error message, or null if valid.
String? validateMoneyField(
  AppLocalizations l10n,
  String? value, {
  required bool required,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return required ? l10n.profileFieldRequired : null;
  final centimes = parseChfToCentimes(text);
  if (centimes == null || centimes < 0 || centimes > maxMoneyCentimes) {
    return l10n.profileAmountInvalid;
  }
  return null;
}

/// Validates an optional bounded percentage (e.g. conversion rate
/// 0–100, 3a return −50–100).
String? validatePercentField(
  AppLocalizations l10n,
  String? value, {
  required double min,
  required double max,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final rate = double.tryParse(text.replaceAll(',', '.'));
  // tryParse accepts 'NaN'/'Infinity': comparisons are false with NaN,
  // and bounds are crossed with Infinity.
  if (rate == null || !rate.isFinite || rate < min || rate > max) {
    return l10n.profileRateInvalid;
  }
  return null;
}

/// Validates the birth year: optional, but if provided an integer
/// between 1930 and the current year − 16 (bound from the `users/me`
/// schema).
String? validateBirthYearField(AppLocalizations l10n, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final year = int.tryParse(text);
  if (year == null || year < 1930 || year > DateTime.now().year - 16) {
    return l10n.profileBirthYearInvalid;
  }
  return null;
}

/// Validates the number of children: integer ≥ 0 (required, default 0).
String? validateChildrenField(AppLocalizations l10n, String? value) {
  final text = value?.trim() ?? '';
  final children = int.tryParse(text);
  if (text.isEmpty || children == null || children < 0) {
    return l10n.profileChildrenInvalid;
  }
  return null;
}

/// Parses an input percentage ("6.8" or "6,8") — null if empty,
/// invalid, or non-finite ('NaN', 'Infinity').
double? tryParsePercentField(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final rate = double.tryParse(text.replaceAll(',', '.'));
  if (rate == null || !rate.isFinite) return null;
  return rate;
}
