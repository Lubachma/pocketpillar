/// Building the payloads for the 3 calculators from the guided flow's
/// input — pure function (tested without network).
///
/// Bounds aligned with the Zod schemas
/// (`src/modules/calculator/calculator.schema.ts`); amounts in
/// **centimes** (contract §1).
library;

import '../../../core/utils/swiss_pension.dart';

// The 3a caps live in core (shared with the annual reminders,
// batch 7) — re-exported here for legacy consumers.
export '../../../core/utils/swiss_pension.dart'
    show
        pillar3aMaxWithPillar2,
        pillar3aMaxWithoutPillar2,
        pillar3aMaxContributionFor;

/// Reference retirement age (backend schema default; must be
/// strictly greater than age, hence the wizard's upper bound of 64).
const int calculatorRetirementAge = 65;

/// Minimum wizard age (lower bound of `/calculator/retirement`).
const int calculatorMinAge = 18;

/// Maximum wizard age: `retirementAge > age` required by the schema.
const int calculatorMaxAge = calculatorRetirementAge - 1;

/// Minimum age for `/calculator/lpp-gap` (lower bound of the Zod schema) —
/// below it, the call is skipped and the gap card is not shown.
const int lppGapMinAge = 25;

/// Guided flow input — amounts in **centimes** (the CHF → centimes
/// conversion happens at field validation, never here).
class GuidedCalculatorInput {
  const GuidedCalculatorInput({
    required this.age,
    required this.canton,
    this.municipality,
    required this.maritalStatus,
    required this.grossAnnualIncome,
    required this.pillar2Capital,
    required this.pillar2Contribution,
    required this.hasPillar3a,
    required this.pillar3aBalance,
  });

  /// Age (18–64, wizard bounds).
  final int age;

  /// 2-letter canton code (`VD`, `ZH`, …).
  final String canton;

  /// Municipality of residence — null: the backend applies the cantonal
  /// average (actual communal multiplier if the municipality is covered).
  final String? municipality;

  /// `SINGLE | MARRIED | REGISTERED_PARTNERSHIP | DIVORCED | WIDOWED`.
  final String maritalStatus;

  /// Gross annual income, in centimes (> 0).
  final int grossAnnualIncome;

  /// Current LPP capital, in centimes (≥ 0).
  final int pillar2Capital;

  /// Annual LPP contribution, in centimes (≥ 0).
  final int pillar2Contribution;

  final bool hasPillar3a;

  /// Current 3a balance, in centimes (≥ 0, ignored if [hasPillar3a] is false).
  final int pillar3aBalance;

  /// 2nd pillar inferred from input: non-zero capital or contribution.
  bool get hasSecondPillar => pillar2Capital > 0 || pillar2Contribution > 0;

  /// Applicable 3a cap, in centimes: 7'258 with a 2nd pillar, otherwise
  /// min(36'288, 20% of gross income — proxy for net income from
  /// employment, since the wizard only collects gross; OPP3 art. 7).
  int get pillar3aMaxContribution => pillar3aMaxContributionFor(
    hasSecondPillar: hasSecondPillar,
    incomeCentimes: grossAnnualIncome,
  );
}

/// JSON payloads ready to post. [lppGap] is null when age is under
/// [lppGapMinAge] (the schema would reject the call with a 400).
class CalculatorPayloads {
  const CalculatorPayloads({
    required this.retirement,
    required this.taxSavings,
    this.lppGap,
  });

  final Map<String, dynamic> retirement;
  final Map<String, dynamic> taxSavings;
  final Map<String, dynamic>? lppGap;
}

/// Builds the payloads for the 3 calculators.
///
/// Assumptions (parity with iOS's `GuidedCalculatorViewModel`):
/// - annual 3a contribution = applicable cap when a 3a is declared;
/// - 3a tax contribution = applicable cap (the backend caps it
///   anyway and returns `maxContribution` / `isAtMax`);
/// - `estimatedAvsPension`, interest rate, 3a return and conversion
///   rate left at the backend's defaults (no business constants
///   duplicated client-side).
CalculatorPayloads buildCalculatorPayloads(GuidedCalculatorInput input) {
  final pillar3aBalance = input.hasPillar3a ? input.pillar3aBalance : 0;
  final pillar3aContribution = input.hasPillar3a
      ? input.pillar3aMaxContribution
      : 0;

  return CalculatorPayloads(
    retirement: <String, dynamic>{
      'currentAge': input.age,
      'retirementAge': calculatorRetirementAge,
      'grossAnnualIncome': input.grossAnnualIncome,
      'currentPillar2Capital': input.pillar2Capital,
      'annualPillar2Contribution': input.pillar2Contribution,
      'currentPillar3aBalance': pillar3aBalance,
      'annualPillar3aContribution': pillar3aContribution,
      // Canton + marital status → the backend adds the estimated tax on the
      // 3a lump-sum withdrawal (official FTA 2026 tables — practitioner
      // review 08.2026).
      'canton': input.canton,
      'municipality': ?input.municipality,
      'maritalStatus': input.maritalStatus,
    },
    taxSavings: <String, dynamic>{
      'canton': input.canton,
      'municipality': ?input.municipality,
      'taxableIncome': input.grossAnnualIncome,
      'contribution': input.pillar3aMaxContribution,
      'maritalStatus': input.maritalStatus,
      'churchTax': false,
      'hasSecondPillar': input.hasSecondPillar,
    },
    lppGap: input.age >= lppGapMinAge
        ? <String, dynamic>{
            'grossAnnualIncome': input.grossAnnualIncome,
            'age': input.age,
            'retirementAge': calculatorRetirementAge,
            'currentBvgCapital': input.pillar2Capital,
            'actualAnnualContribution': input.pillar2Contribution,
          }
        : null,
  );
}
