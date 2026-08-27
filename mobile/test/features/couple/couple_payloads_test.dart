import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/couple/data/couple_payloads.dart';

void main() {
  const input = CoupleSpouseInput(
    age: 40,
    grossAnnualIncome: 9500000,
    pillar2Capital: 2000000,
    pillar2Contribution: 500000,
    hasPillar3a: true,
    pillar3aBalance: 1000000,
  );

  test('spouse payload: exact keys, centimes unchanged', () {
    final payload = buildCoupleSpousePayload(input);

    expect(payload, {
      'currentAge': 40,
      'retirementAge': 65,
      'grossAnnualIncome': 9500000,
      'currentPillar2Capital': 2000000,
      'annualPillar2Contribution': 500000,
      'currentPillar3aBalance': 1000000,
      // 3a cap "with 2nd pillar" (guided calculator assumption).
      'annualPillar3aContribution': 725800,
      // No conversionRate key: unset → backend legal default (6.8%).
    });
  });

  test('conversion rate forwarded when typed, omitted when unknown', () {
    final withRate = buildCoupleSpousePayload(
      const CoupleSpouseInput(
        age: 40,
        grossAnnualIncome: 9500000,
        pillar2Capital: 2000000,
        pillar2Contribution: 500000,
        hasPillar3a: true,
        pillar3aBalance: 1000000,
        conversionRate: 5.4,
      ),
    );
    expect(withRate['conversionRate'], 5.4);

    // Unset → the key is absent (backend applies the 6.8% legal minimum,
    // guaranteed on the mandatory part only — practitioner review 08.2026).
    expect(buildCoupleSpousePayload(input).containsKey('conversionRate'), isFalse);
  });

  test('without 3a: balance and 3a contribution are zero', () {
    final payload = buildCoupleSpousePayload(
      const CoupleSpouseInput(
        age: 35,
        grossAnnualIncome: 6000000,
        pillar2Capital: 0,
        pillar2Contribution: 0,
        hasPillar3a: false,
        pillar3aBalance: 1000000, // ignored
      ),
    );

    expect(payload['currentPillar3aBalance'], 0);
    expect(payload['annualPillar3aContribution'], 0);
  });

  test('3a without 2nd pillar: contribution at the self-employed cap (20% of '
      'income, batch 12)', () {
    // Income CHF 60'000 → 20% = CHF 12'000 (< 36'288).
    final payload = buildCoupleSpousePayload(
      const CoupleSpouseInput(
        age: 35,
        grossAnnualIncome: 6000000,
        pillar2Capital: 0,
        pillar2Contribution: 0,
        hasPillar3a: true,
        pillar3aBalance: 500000,
      ),
    );

    expect(payload['currentPillar3aBalance'], 500000);
    expect(payload['annualPillar3aContribution'], 1200000);
  });

  test('3a without 2nd pillar: legal cap 36\'288 from CHF 181\'440 of '
      'income', () {
    // Income CHF 300'000 → 20% = CHF 60'000 → capped at 36'288.
    final payload = buildCoupleSpousePayload(
      const CoupleSpouseInput(
        age: 35,
        grossAnnualIncome: 30000000,
        pillar2Capital: 0,
        pillar2Contribution: 0,
        hasPillar3a: true,
        pillar3aBalance: 500000,
      ),
    );

    expect(payload['annualPillar3aContribution'], 3628800);
  });

  test('2nd pillar deducted from contribution alone (zero capital)', () {
    final payload = buildCoupleSpousePayload(
      const CoupleSpouseInput(
        age: 35,
        grossAnnualIncome: 6000000,
        pillar2Capital: 0,
        pillar2Contribution: 300000,
        hasPillar3a: true,
        pillar3aBalance: 0,
      ),
    );

    expect(payload['annualPillar3aContribution'], 725800);
  });

  test('couple payload: canton, marital status and two nested spouses', () {
    final payload = buildCoupleSimulationPayload(
      person1: input,
      person2: const CoupleSpouseInput(
        age: 35,
        grossAnnualIncome: 6000000,
        pillar2Capital: 0,
        pillar2Contribution: 0,
        hasPillar3a: false,
        pillar3aBalance: 0,
      ),
      canton: 'ZH',
      maritalStatus: 'CONCUBINAGE',
    );

    expect(payload['canton'], 'ZH');
    expect(payload['maritalStatus'], 'CONCUBINAGE');
    expect(payload['person1'], buildCoupleSpousePayload(input));
    expect((payload['person2'] as Map<String, dynamic>)['currentAge'], 35);
  });

  test(
    'couple payload: municipality included if provided, omitted otherwise',
    () {
      const partner = CoupleSpouseInput(
        age: 35,
        grossAnnualIncome: 6000000,
        pillar2Capital: 0,
        pillar2Contribution: 0,
        hasPillar3a: false,
        pillar3aBalance: 0,
      );

      final withMunicipality = buildCoupleSimulationPayload(
        person1: input,
        person2: partner,
        canton: 'ZH',
        municipality: 'Adliswil',
        maritalStatus: 'MARRIED',
      );
      expect(withMunicipality['municipality'], 'Adliswil');

      final without = buildCoupleSimulationPayload(
        person1: input,
        person2: partner,
        canton: 'ZH',
        maritalStatus: 'MARRIED',
      );
      // Without a municipality: the key is omitted (server-side falls back to the cantonal average).
      expect(without.containsKey('municipality'), isFalse);
    },
  );
}
