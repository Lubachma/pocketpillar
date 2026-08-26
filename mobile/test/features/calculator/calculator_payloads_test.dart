import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/calculator/data/calculator_payloads.dart';

/// Building payloads (amounts in centimes, Zod bounds) from
/// the guided flow input.
void main() {
  const base = GuidedCalculatorInput(
    age: 35,
    canton: 'VD',
    maritalStatus: 'SINGLE',
    grossAnnualIncome: 9500000, // CHF 95'000
    pillar2Capital: 2000000, // CHF 20'000
    pillar2Contribution: 500000, // CHF 5'000
    hasPillar3a: true,
    pillar3aBalance: 1000000, // CHF 10'000
  );

  group('payload retirement', () {
    test('amounts in centimes, backend defaults left aside', () {
      final payloads = buildCalculatorPayloads(base);

      expect(payloads.retirement, {
        'currentAge': 35,
        'retirementAge': 65,
        'grossAnnualIncome': 9500000,
        'currentPillar2Capital': 2000000,
        'annualPillar2Contribution': 500000,
        'currentPillar3aBalance': 1000000,
        // Assumed 3a cap (iOS parity): 7'258 with 2nd pillar.
        'annualPillar3aContribution': 725800,
      });
    });

    test('without 3a: balance and annual contribution at 0', () {
      final payloads = buildCalculatorPayloads(
        const GuidedCalculatorInput(
          age: 35,
          canton: 'VD',
          maritalStatus: 'MARRIED',
          grossAnnualIncome: 9500000,
          pillar2Capital: 2000000,
          pillar2Contribution: 500000,
          hasPillar3a: false,
          pillar3aBalance: 1000000, // ignored
        ),
      );

      expect(payloads.retirement['currentPillar3aBalance'], 0);
      expect(payloads.retirement['annualPillar3aContribution'], 0);
    });
  });

  group('payload tax-savings', () {
    test('with 2nd pillar: cap 7\'258, REGISTERED_PARTNERSHIP kept', () {
      final payloads = buildCalculatorPayloads(base);

      expect(payloads.taxSavings, {
        'canton': 'VD',
        'taxableIncome': 9500000,
        'contribution': 725800,
        'maritalStatus': 'SINGLE',
        'churchTax': false,
        'hasSecondPillar': true,
      });
    });

    test('without 2nd pillar: independent cap = 20% of income (OPP3 rule '
        'art. 7, batch 12)', () {
      // Income CHF 120'000 → 20% = CHF 24'000 (< 36'288).
      final payloads = buildCalculatorPayloads(
        const GuidedCalculatorInput(
          age: 40,
          canton: 'ZH',
          maritalStatus: 'REGISTERED_PARTNERSHIP',
          grossAnnualIncome: 12000000,
          pillar2Capital: 0,
          pillar2Contribution: 0,
          hasPillar3a: true,
          pillar3aBalance: 0,
        ),
      );

      expect(payloads.taxSavings['contribution'], 2400000);
      expect(payloads.taxSavings['hasSecondPillar'], false);
      expect(payloads.taxSavings['maritalStatus'], 'REGISTERED_PARTNERSHIP');
      // The assumed 3a contribution follows the same cap.
      expect(payloads.retirement['annualPillar3aContribution'], 2400000);
    });

    test('without 2nd pillar: legal cap 36\'288 once 20% of income '
        'exceeds it', () {
      // Income CHF 300'000 → 20% = CHF 60'000 → capped at 36'288.
      final payloads = buildCalculatorPayloads(
        const GuidedCalculatorInput(
          age: 40,
          canton: 'ZH',
          maritalStatus: 'SINGLE',
          grossAnnualIncome: 30000000,
          pillar2Capital: 0,
          pillar2Contribution: 0,
          hasPillar3a: true,
          pillar3aBalance: 0,
        ),
      );

      expect(payloads.taxSavings['contribution'], 3628800);
      expect(payloads.retirement['annualPillar3aContribution'], 3628800);
    });

    test('2nd pillar derived from contribution alone (capital 0)', () {
      final payloads = buildCalculatorPayloads(
        const GuidedCalculatorInput(
          age: 30,
          canton: 'GE',
          maritalStatus: 'SINGLE',
          grossAnnualIncome: 8000000,
          pillar2Capital: 0,
          pillar2Contribution: 400000,
          hasPillar3a: false,
          pillar3aBalance: 0,
        ),
      );

      expect(payloads.taxSavings['hasSecondPillar'], true);
      expect(payloads.taxSavings['contribution'], 725800);
    });

    test('municipality provided → included; absent → key omitted '
        '(server-side cantonal average)', () {
      final withMunicipality = buildCalculatorPayloads(
        const GuidedCalculatorInput(
          age: 35,
          canton: 'ZH',
          municipality: 'Adliswil',
          maritalStatus: 'SINGLE',
          grossAnnualIncome: 9500000,
          pillar2Capital: 2000000,
          pillar2Contribution: 500000,
          hasPillar3a: true,
          pillar3aBalance: 1000000,
        ),
      );
      expect(withMunicipality.taxSavings['municipality'], 'Adliswil');

      // Without a municipality: the key is omitted from the body (falls
      // back to cantonal average).
      expect(
        buildCalculatorPayloads(base).taxSavings.containsKey('municipality'),
        isFalse,
      );
    });
  });

  group('payload lpp-gap', () {
    test('present from age 25 (Zod lower bound)', () {
      final payloads = buildCalculatorPayloads(base);

      expect(payloads.lppGap, {
        'grossAnnualIncome': 9500000,
        'age': 35,
        'retirementAge': 65,
        'currentBvgCapital': 2000000,
        'actualAnnualContribution': 500000,
      });
    });

    test('omitted under 25 (the schema would reject with 400)', () {
      GuidedCalculatorInput atAge(int age) => GuidedCalculatorInput(
        age: age,
        canton: base.canton,
        maritalStatus: base.maritalStatus,
        grossAnnualIncome: base.grossAnnualIncome,
        pillar2Capital: base.pillar2Capital,
        pillar2Contribution: base.pillar2Contribution,
        hasPillar3a: base.hasPillar3a,
        pillar3aBalance: base.pillar3aBalance,
      );

      expect(buildCalculatorPayloads(atAge(24)).lppGap, isNull);
      expect(buildCalculatorPayloads(atAge(25)).lppGap, isNotNull);
    });
  });
}
