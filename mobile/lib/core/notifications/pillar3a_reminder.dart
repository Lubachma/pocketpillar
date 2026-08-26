import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/swiss_pension.dart';
import 'notification_service.dart';

/// Context for the contextual 3a reminder (batch 7 — contextual calendar
/// alerts, TODO §5): remaining amount to pay in and days before 12/31,
/// computed from the financial profile.
///
/// The amount is frozen at scheduling time (a local notification's body
/// is static) and refreshed on every startup / rescheduling; the days
/// are computed from the reminder's **delivery date** — deterministic
/// (batch 7 review).
class Pillar3aReminderContext {
  const Pillar3aReminderContext({
    required this.remainingCentimes,
    required this.daysUntilYearEnd,
  });

  /// Remaining amount to pay in for the current year, in centimes (≥ 0).
  final int remainingCentimes;

  /// Days between the reminder's delivery (Nov 1st) and 12/31 — 60,
  /// independent of the scheduling instant.
  final int daysUntilYearEnd;
}

/// Remaining to pay in = applicable ceiling − sum of declared annual
/// contributions (null = 0), clamped to ≥ 0 (contributions beyond the
/// ceiling → 0).
///
/// [hasSecondPillar] is resolved by the caller via `hasSecondPillarFor`
/// (`EMPLOYED` status **or** existing LPP account — a self-employed
/// person with voluntary LPP correctly falls back to 7,258, OPP3 art. 7,
/// batch 12 review); [incomeCentimes] (basis: declared net, otherwise
/// gross — `pillar3aIncomeBaseFor`) is only used without a 2nd pillar
/// (the 20% rule).
int pillar3aRemainingCentimes({
  required bool hasSecondPillar,
  required int incomeCentimes,
  required List<int?> annualContributions,
}) {
  final contributed = annualContributions.fold<int>(
    0,
    (sum, contribution) => sum + (contribution ?? 0),
  );
  final remaining =
      pillar3aMaxContributionFor(
        hasSecondPillar: hasSecondPillar,
        incomeCentimes: incomeCentimes,
      ) -
      contributed;
  return remaining < 0 ? 0 : remaining;
}

/// Next delivery date of the 3a reminder (November 1st —
/// `LocalNotificationService.pillar3aReminder*`, iOS parity) from [now].
/// The date alone is enough: the delivery time (10:00) doesn't change
/// the day count.
DateTime pillar3aReminderDeliveryDate(DateTime now) {
  final thisYear = DateTime(
    now.year,
    LocalNotificationService.pillar3aReminderMonth,
    LocalNotificationService.pillar3aReminderDay,
  );
  return now.isBefore(thisYear)
      ? thisYear
      : DateTime(
          now.year + 1,
          LocalNotificationService.pillar3aReminderMonth,
          LocalNotificationService.pillar3aReminderDay,
        );
}

/// Days between [from] (reference date — the reminder's delivery, not
/// the scheduling instant, batch 7 review) and 12/31 of the same year
/// (0 on 12/31 itself, never negative).
int daysUntilYearEnd(DateTime from) {
  final day = DateTime(from.year, from.month, from.day);
  final remaining = DateTime(from.year, 12, 31).difference(day).inDays;
  return remaining < 0 ? 0 : remaining;
}

/// Factory for the 3a context of annual reminders — null by default
/// (generic body). Overridden in `main()`: the data comes from the
/// financial profile (a feature, which core doesn't know about) —
/// injection, same pattern as `notificationServiceProvider`.
final pillar3aReminderContextLoaderProvider =
    Provider<Future<Pillar3aReminderContext?> Function()?>((ref) => null);
