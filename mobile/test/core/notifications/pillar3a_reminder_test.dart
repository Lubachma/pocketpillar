import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/core/notifications/annual_reminders.dart';
import 'package:pocketpillar/core/notifications/pillar3a_reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pillar3aRemainingCentimes', () {
    test('with 2nd pillar: cap 7\'258 − contributions (income ignored)', () {
      // 725'800 − 425'800 ct = 300'000 ct (CHF 3'000).
      expect(
        pillar3aRemainingCentimes(
          hasSecondPillar: true,
          incomeCentimes: 9500000,
          annualContributions: [425800],
        ),
        300000,
      );
    });

    test('multiple accounts summed, null contributions ignored', () {
      expect(
        pillar3aRemainingCentimes(
          hasSecondPillar: true,
          incomeCentimes: 9500000,
          annualContributions: [100000, null, 25800],
        ),
        600000, // CHF 6'000 remaining
      );
    });

    test('clamped to 0 when payments exceed the cap', () {
      expect(
        pillar3aRemainingCentimes(
          hasSecondPillar: true,
          incomeCentimes: 9500000,
          annualContributions: [800000],
        ),
        0,
      );
    });

    test('without 2nd pillar: cap = 20% of income (OPP3 art. 7)', () {
      // Income CHF 150'000 → cap 20% = CHF 30'000;
      // 3'000'000 − 628'800 ct = 2'371'200 ct (CHF 23'712).
      expect(
        pillar3aRemainingCentimes(
          hasSecondPillar: false,
          incomeCentimes: 15000000,
          annualContributions: [628800],
        ),
        2371200,
      );
    });

    test('without 2nd pillar: legal cap 36\'288 once 20% of income '
        'exceeds it', () {
      // Income CHF 300'000 → 20% = CHF 60'000 → capped at 36'288;
      // 3'628'800 − 628'800 ct = 3'000'000 ct (CHF 30'000).
      expect(
        pillar3aRemainingCentimes(
          hasSecondPillar: false,
          incomeCentimes: 30000000,
          annualContributions: [628800],
        ),
        3000000,
      );
    });

    test('no contribution: full cap remaining', () {
      expect(
        pillar3aRemainingCentimes(
          hasSecondPillar: true,
          incomeCentimes: 9500000,
          annualContributions: [],
        ),
        725800,
      );
    });
  });

  group('daysUntilYearEnd (injectable clock)', () {
    test('November 1 → 60 days before 12/31', () {
      expect(daysUntilYearEnd(DateTime(2026, 11, 1)), 60);
    });

    test('December 15 → 16 days', () {
      expect(daysUntilYearEnd(DateTime(2026, 12, 15)), 16);
    });

    test('December 31 → 0 (never negative)', () {
      expect(daysUntilYearEnd(DateTime(2026, 12, 31)), 0);
      // The time is ignored (comparison is on dates).
      expect(daysUntilYearEnd(DateTime(2026, 12, 31, 23, 59)), 0);
    });

    test('January 1 → 364 (non-leap year)', () {
      expect(daysUntilYearEnd(DateTime(2026, 1, 1)), 364);
    });
  });

  group(
    'pillar 3a reminder delivery (batch 7 review — deterministic days)',
    () {
      test('next November 1 from September', () {
        expect(
          pillar3aReminderDeliveryDate(DateTime(2026, 9, 10)),
          DateTime(2026, 11, 1),
        );
      });

      test('November 1 reached or passed → next November 1', () {
        expect(
          pillar3aReminderDeliveryDate(DateTime(2026, 11, 1)),
          DateTime(2027, 11, 1),
        );
        expect(
          pillar3aReminderDeliveryDate(DateTime(2026, 12, 26)),
          DateTime(2027, 11, 1),
        );
      });

      test('displayed days calculated from delivery, not '
          'scheduling: opened in September → 60', () {
        // Before the fix, scheduling in September displayed
        // ~80 days; the reference is delivery (Nov. 1).
        final days = daysUntilYearEnd(
          pillar3aReminderDeliveryDate(DateTime(2026, 9, 10)),
        );
        expect(days, 60);
      });
    },
  );

  group('pillar3aReminderBody', () {
    late AppLocalizations l10n;

    setUp(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    });

    test('without context → generic body at the cap (fallback)', () {
      expect(pillar3aReminderBody(l10n, null), contains("7'258"));
    });

    test('with context → real remaining amount and days', () {
      final body = pillar3aReminderBody(
        l10n,
        const Pillar3aReminderContext(
          remainingCentimes: 300000,
          daysUntilYearEnd: 60,
        ),
      );
      expect(body, contains("CHF 3'000"));
      expect(body, contains('60 jours restants'));
      expect(body, isNot(contains("jusqu'à")));
    });

    test('remaining 0 → "CHF 0" (pillar 3a already maxed out)', () {
      final body = pillar3aReminderBody(
        l10n,
        const Pillar3aReminderContext(
          remainingCentimes: 0,
          daysUntilYearEnd: 60,
        ),
      );
      expect(body, contains('CHF 0'));
    });
  });
}
