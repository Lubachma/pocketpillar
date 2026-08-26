import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_payloads.dart';

/// Payload builders for the 4 scenarios: centimes unchanged, bounds
/// aligned with the Zod schemas, optional keys omitted (backend
/// defaults).
void main() {
  group('constants (Zod schema bounds)', () {
    test('retirement 65, age 25–64, catch-up 10, accounts 5, marriage 50', () {
      expect(scenarioRetirementAge, 65);
      expect(scenarioMinAge, 25);
      expect(scenarioMaxAge, 64); // retirementAge > age
      expect(catchupMaxYears, 10);
      expect(staggeredMaxAccounts, 5);
      expect(divorceMaxYearsMarried, 50);
    });
  });

  group('buildCatchup3aPayload', () {
    test('centimes unchanged, currentYear/pastContributions omitted', () {
      final payload = buildCatchup3aPayload(
        yearsMissed: 3,
        hasSecondPillar: false,
        taxableIncome: 9500050, // CHF 95'000.50
      );

      expect(payload, {
        'yearsSinceFirstEligible': 3,
        'hasSecondPillar': false,
        'taxableIncome': 9500050,
      });
      expect(payload.containsKey('currentYear'), isFalse);
      expect(payload.containsKey('pastContributions'), isFalse);
    });
  });

  group('buildStaggeredWithdrawalPayload', () {
    test('full payload, retirementAge 65', () {
      final payload = buildStaggeredWithdrawalPayload(
        canton: 'VD',
        totalPillar3aBalance: 15000001,
        numberOfAccounts: 3,
        currentAge: 60,
        maritalStatus: 'SINGLE',
        pillar2AsCapital: 20000000,
      );

      expect(payload, {
        'canton': 'VD',
        'totalPillar3aBalance': 15000001,
        'numberOfAccounts': 3,
        'retirementAge': 65,
        'currentAge': 60,
        'maritalStatus': 'SINGLE',
        'pillar2AsCapital': 20000000,
      });
    });
  });

  group('mapMaritalStatusForWithdrawal', () {
    test('MARRIED and REGISTERED_PARTNERSHIP → MARRIED (marital tax scale)', () {
      expect(mapMaritalStatusForWithdrawal('MARRIED'), 'MARRIED');
      expect(mapMaritalStatusForWithdrawal('REGISTERED_PARTNERSHIP'), 'MARRIED');
    });

    test('SINGLE, DIVORCED, WIDOWED → SINGLE', () {
      expect(mapMaritalStatusForWithdrawal('SINGLE'), 'SINGLE');
      expect(mapMaritalStatusForWithdrawal('DIVORCED'), 'SINGLE');
      expect(mapMaritalStatusForWithdrawal('WIDOWED'), 'SINGLE');
    });
  });

  group('buildPropertyPurchasePayload', () {
    test('full payload, bvgCapitalAtAge50 omitted (backend fallback)', () {
      final payload = buildPropertyPurchasePayload(
        age: 40,
        currentBvgCapital: 20000000,
        withdrawalAmount: 5000000,
        annualContribution: 500000,
      );

      expect(payload, {
        'age': 40,
        'retirementAge': 65,
        'currentBvgCapital': 20000000,
        'withdrawalAmount': 5000000,
        'annualContribution': 500000,
      });
      expect(payload.containsKey('bvgCapitalAtAge50'), isFalse);
    });
  });

  group('buildDivorceImpactPayload', () {
    test('full payload, retirementAge 65', () {
      final payload = buildDivorceImpactPayload(
        age: 40,
        bvgCapitalAtMarriage: 5000000,
        bvgCapitalNow: 20000000,
        spouseBvgCapitalAtMarriage: 3000000,
        spouseBvgCapitalNow: 15000000,
        yearsMarried: 10,
        annualContribution: 500000,
      );

      expect(payload, {
        'age': 40,
        'retirementAge': 65,
        'bvgCapitalAtMarriage': 5000000,
        'bvgCapitalNow': 20000000,
        'spouseBvgCapitalAtMarriage': 3000000,
        'spouseBvgCapitalNow': 15000000,
        'yearsMarried': 10,
        'annualContribution': 500000,
      });
    });
  });
}
