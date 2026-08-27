/// Building the couple payload — pure function (tested without network).
///
/// A single `POST /calculator/couple` call (batch 6): each spouse is
/// described by the inputs of an individual retirement projection, with
/// the guided calculator's assumptions (constants shared from
/// `calculator_payloads.dart` — annual 3a contribution = applicable cap).
/// Amounts in **centimes** (contract §1).
library;

import '../../calculator/data/calculator_payloads.dart';

/// A spouse's input — amounts in **centimes** (the CHF → centimes
/// conversion happens at field validation, never here).
class CoupleSpouseInput {
  const CoupleSpouseInput({
    required this.age,
    required this.grossAnnualIncome,
    required this.pillar2Capital,
    required this.pillar2Contribution,
    required this.hasPillar3a,
    required this.pillar3aBalance,
    this.conversionRate,
  });

  /// Age ([calculatorMinAge]–[calculatorMaxAge], wizard bounds).
  final int age;

  /// Gross annual income, in centimes (> 0).
  final int grossAnnualIncome;

  /// Current LPP capital, in centimes (≥ 0).
  final int pillar2Capital;

  /// Annual LPP contribution, in centimes (≥ 0).
  final int pillar2Contribution;

  final bool hasPillar3a;

  /// Current 3a balance, in centimes (≥ 0, ignored if [hasPillar3a] is false).
  final int pillar3aBalance;

  /// LPP conversion rate in percent (from the BVG certificate) — null: the
  /// backend applies the 6.8% legal minimum, which is only guaranteed on the
  /// mandatory part (practitioner review 08.2026: funds often apply a lower
  /// blended rate on the full capital).
  final double? conversionRate;
}

/// Per-spouse payload (inputs for a retirement projection).
///
/// Assumptions carried over from the guided flow (`buildCalculatorPayloads`):
/// annual 3a contribution = applicable cap when a 3a is declared
/// (7'258 with a 2nd pillar, otherwise min(36'288, 20% of gross income) —
/// OPP3 art. 7, batch 12); `estimatedAvsPension`, interest rate and
/// 3a return left at the backend's defaults (no business constant
/// duplicated client-side). The conversion rate is forwarded when the user
/// typed their certificate's rate, omitted otherwise.
Map<String, dynamic> buildCoupleSpousePayload(CoupleSpouseInput input) {
  final hasSecondPillar =
      input.pillar2Capital > 0 || input.pillar2Contribution > 0;
  final pillar3aBalance = input.hasPillar3a ? input.pillar3aBalance : 0;
  final pillar3aContribution = input.hasPillar3a
      ? pillar3aMaxContributionFor(
          hasSecondPillar: hasSecondPillar,
          incomeCentimes: input.grossAnnualIncome,
        )
      : 0;

  return <String, dynamic>{
    'currentAge': input.age,
    'retirementAge': calculatorRetirementAge,
    'grossAnnualIncome': input.grossAnnualIncome,
    'currentPillar2Capital': input.pillar2Capital,
    'annualPillar2Contribution': input.pillar2Contribution,
    'currentPillar3aBalance': pillar3aBalance,
    'annualPillar3aContribution': pillar3aContribution,
    // Certificate conversion rate — omitted when unknown (backend default
    // 6.8% = legal minimum on the mandatory part).
    'conversionRate': ?input.conversionRate,
  };
}

/// Full payload for `POST /calculator/couple`.
///
/// [maritalStatus]: `MARRIED | REGISTERED_PARTNERSHIP | CONCUBINAGE` —
/// the tax and the couple AVS cap change based on marital status (contract
/// §7); the canton is shared by the couple (taxation at the shared residence).
Map<String, dynamic> buildCoupleSimulationPayload({
  required CoupleSpouseInput person1,
  required CoupleSpouseInput person2,
  required String canton,
  String? municipality,
  required String maritalStatus,
}) {
  return <String, dynamic>{
    'canton': canton,
    'municipality': ?municipality,
    'maritalStatus': maritalStatus,
    'person1': buildCoupleSpousePayload(person1),
    'person2': buildCoupleSpousePayload(person2),
  };
}
