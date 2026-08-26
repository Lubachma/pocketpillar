import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/utils/swiss_pension.dart';

/// Shared pillar 3a rules (OPP3 art. 7, 2026 values — parity with the
/// backend helper `pillar3aMaxContribution`). Amounts in **centimes**.
void main() {
  group('pillar3aMaxContributionFor', () {
    test('with 2nd pillar: 7\'258 regardless of income', () {
      expect(
        pillar3aMaxContributionFor(hasSecondPillar: true, incomeCentimes: 0),
        725800,
      );
      expect(
        pillar3aMaxContributionFor(
          hasSecondPillar: true,
          incomeCentimes: 30000000,
        ),
        725800,
      );
    });

    test('without 2nd pillar: 20% of income under the legal cap', () {
      // CHF 100'000 → CHF 20'000; CHF 50'000 → CHF 10'000.
      expect(
        pillar3aMaxContributionFor(
          hasSecondPillar: false,
          incomeCentimes: 10000000,
        ),
        2000000,
      );
      expect(
        pillar3aMaxContributionFor(
          hasSecondPillar: false,
          incomeCentimes: 5000000,
        ),
        1000000,
      );
    });

    test('without 2nd pillar: legal cap 36\'288 once 20% exceeds it', () {
      // CHF 300'000 → 20% = 60'000 → 36'288; exact boundary CHF 181'440.
      expect(
        pillar3aMaxContributionFor(
          hasSecondPillar: false,
          incomeCentimes: 30000000,
        ),
        3628800,
      );
      expect(
        pillar3aMaxContributionFor(
          hasSecondPillar: false,
          incomeCentimes: 18144000,
        ),
        3628800,
      );
    });

    test(
      'truncation to the lower centime (parity with backend Math.floor)',
      () {
        // CHF 100'000.03 → 20% = CHF 20'000.006 → CHF 20'000.00.
        expect(
          pillar3aMaxContributionFor(
            hasSecondPillar: false,
            incomeCentimes: 10000003,
          ),
          2000000,
        );
      },
    );

    test('never negative', () {
      expect(
        pillar3aMaxContributionFor(hasSecondPillar: false, incomeCentimes: 0),
        0,
      );
      expect(
        pillar3aMaxContributionFor(
          hasSecondPillar: false,
          incomeCentimes: -500000,
        ),
        0,
      );
    });
  });

  group('hasSecondPillarFor (batch 12 review)', () {
    test('EMPLOYED → true, even without a declared LPP account', () {
      expect(
        hasSecondPillarFor(
          employmentStatus: 'EMPLOYED',
          hasPillar2Account: false,
        ),
        isTrue,
      );
    });

    test('SELF_EMPLOYED with LPP account (optional) → true', () {
      // OPP3 art. 7: affiliated with a pension fund → small cap 7'258.
      expect(
        hasSecondPillarFor(
          employmentStatus: 'SELF_EMPLOYED',
          hasPillar2Account: true,
        ),
        isTrue,
      );
    });

    test('SELF_EMPLOYED without LPP account → false (20% rule)', () {
      expect(
        hasSecondPillarFor(
          employmentStatus: 'SELF_EMPLOYED',
          hasPillar2Account: false,
        ),
        isFalse,
      );
    });

    test('UNEMPLOYED / RETIRED: only an LPP account unlocks the small cap', () {
      // Backend parity (`EMPLOYED || LPP accounts`) — a vested benefits
      // account or a declared optional pension fund → 7'258.
      for (final status in ['UNEMPLOYED', 'RETIRED']) {
        expect(
          hasSecondPillarFor(employmentStatus: status, hasPillar2Account: true),
          isTrue,
        );
        expect(
          hasSecondPillarFor(
            employmentStatus: status,
            hasPillar2Account: false,
          ),
          isFalse,
        );
      }
    });

    test('unknown status (no profile) without account → false', () {
      expect(
        hasSecondPillarFor(employmentStatus: null, hasPillar2Account: false),
        isFalse,
      );
    });
  });

  group('pillar3aIncomeBaseFor', () {
    test('declared net income takes priority', () {
      expect(
        pillar3aIncomeBaseFor(
          grossAnnualIncomeCentimes: 9500000,
          netAnnualIncomeCentimes: 8000000,
        ),
        8000000,
      );
    });

    test('falls back to gross when net is missing', () {
      expect(
        pillar3aIncomeBaseFor(grossAnnualIncomeCentimes: 9500000),
        9500000,
      );
    });
  });

  group('pillar3aMaxForProfile', () {
    test('self-employed without a fund: 20% of declared net', () {
      // Net CHF 80'000 → cap CHF 16'000 (not 20% of gross 95'000).
      expect(
        pillar3aMaxForProfile(
          employmentStatus: 'SELF_EMPLOYED',
          hasPillar2Account: false,
          grossAnnualIncomeCentimes: 9500000,
          netAnnualIncomeCentimes: 8000000,
        ),
        1600000,
      );
    });

    test('self-employed with optional LPP: 7\'258', () {
      expect(
        pillar3aMaxForProfile(
          employmentStatus: 'SELF_EMPLOYED',
          hasPillar2Account: true,
          grossAnnualIncomeCentimes: 30000000,
        ),
        725800,
      );
    });
  });
}
