/// DTOs for the `POST /calculator/couple` response (batch 6) — shapes
/// verified against `src/modules/calculator/couple-simulation.ts`.
///
/// Since batch 6, **everything** is calculated server-side (backend = source
/// of truth): per-spouse projections, couple AVS cap 150%, married vs
/// unmarried tax estimate and coordinated withdrawal plan. This file only
/// parses — no business rule is duplicated here (the AVS cap,
/// applied client-side before batch 6, now comes from the server,
/// constant `SWISS_PENSION.AVS_MAX_COUPLE_ANNUAL_PENSION`).
///
/// All amounts are in **centimes** (contract §1).
library;

import '../../calculator/data/calculator_dtos.dart';

/// Breakdown of an annual tax scenario (joint or
/// separate taxation), in centimes.
class CoupleTaxBreakdownDto {
  const CoupleTaxBreakdownDto({
    required this.federalTax,
    required this.cantonalTax,
    required this.communalTax,
    required this.totalTax,
  });

  final int federalTax;
  final int cantonalTax;
  final int communalTax;
  final int totalTax;

  factory CoupleTaxBreakdownDto.fromJson(Map<String, dynamic> json) =>
      CoupleTaxBreakdownDto(
        federalTax: (json['federalTax'] as num).toInt(),
        cantonalTax: (json['cantonalTax'] as num).toInt(),
        communalTax: (json['communalTax'] as num).toInt(),
        totalTax: (json['totalTax'] as num).toInt(),
      );
}

/// Couple tax estimate: joint taxation (marriage / registered
/// partnership) vs separate (concubinage). The comparison is always
/// provided, regardless of the marital status simulated.
class CoupleTaxEstimateDto {
  const CoupleTaxEstimateDto({
    required this.married,
    required this.unmarried,
    required this.annualDifference,
    required this.cheaperStatus,
  });

  final CoupleTaxBreakdownDto married;
  final CoupleTaxBreakdownDto unmarried;

  /// `married.totalTax − unmarried.totalTax`, in centimes/year (> 0 = marriage
  /// costs more — "marriage penalty").
  final int annualDifference;

  /// `MARRIED | CONCUBINAGE | EQUAL`.
  final String cheaperStatus;

  factory CoupleTaxEstimateDto.fromJson(Map<String, dynamic> json) =>
      CoupleTaxEstimateDto(
        married: CoupleTaxBreakdownDto.fromJson(
          json['married'] as Map<String, dynamic>,
        ),
        unmarried: CoupleTaxBreakdownDto.fromJson(
          json['unmarried'] as Map<String, dynamic>,
        ),
        annualDifference: (json['annualDifference'] as num).toInt(),
        cheaperStatus: json['cheaperStatus'] as String,
      );
}

/// A withdrawal from the coordinated plan (tax-year anti-collision).
class CoupleWithdrawalStepDto {
  const CoupleWithdrawalStepDto({
    required this.year,
    required this.spouse,
    required this.pillar,
    required this.amount,
    required this.estimatedTax,
  });

  /// Calendar year of the withdrawal.
  final int year;

  /// `person1` ("You") or `person2` ("Partner").
  final String spouse;

  /// `pillar3a` or `pillar2` (LPP capital).
  final String pillar;

  /// Capital withdrawn (projected at retirement), in centimes.
  final int amount;

  /// Estimated tax on the withdrawal, in centimes.
  final int estimatedTax;

  factory CoupleWithdrawalStepDto.fromJson(Map<String, dynamic> json) =>
      CoupleWithdrawalStepDto(
        year: (json['year'] as num).toInt(),
        spouse: json['spouse'] as String,
        pillar: json['pillar'] as String,
        amount: (json['amount'] as num).toInt(),
        estimatedTax: (json['estimatedTax'] as num).toInt(),
      );
}

/// Coordinated withdrawal plan between the two spouses.
class CoupleWithdrawalPlanDto {
  const CoupleWithdrawalPlanDto({
    required this.steps,
    required this.totalEstimatedTax,
    required this.simultaneousEstimatedTax,
    required this.taxSavingsVsSimultaneous,
  });

  /// Staggered withdrawals, sorted by year (empty if no capital).
  final List<CoupleWithdrawalStepDto> steps;

  /// Total tax of the staggered plan, in centimes.
  final int totalEstimatedTax;

  /// Tax if everything were withdrawn in the same year, in centimes.
  final int simultaneousEstimatedTax;

  /// Savings from staggering vs a simultaneous withdrawal, in centimes.
  final int taxSavingsVsSimultaneous;

  factory CoupleWithdrawalPlanDto.fromJson(Map<String, dynamic> json) =>
      CoupleWithdrawalPlanDto(
        steps: [
          for (final item in json['steps'] as List<dynamic>? ?? [])
            CoupleWithdrawalStepDto.fromJson(item as Map<String, dynamic>),
        ],
        totalEstimatedTax: (json['totalEstimatedTax'] as num).toInt(),
        simultaneousEstimatedTax:
            (json['simultaneousEstimatedTax'] as num).toInt(),
        taxSavingsVsSimultaneous:
            (json['taxSavingsVsSimultaneous'] as num).toInt(),
      );
}

/// Result of the couple simulation (`POST /calculator/couple`).
class CoupleResult {
  const CoupleResult({
    required this.person1,
    required this.person2,
    required this.combinedAvsAnnualRaw,
    required this.combinedAvsAnnual,
    required this.avsCapApplied,
    required this.avsCapAnnual,
    required this.combinedTotalAnnualIncome,
    required this.combinedReplacementRate,
    required this.taxEstimate,
    required this.withdrawalPlan,
  });

  /// Retirement projection for "You" (shape of `/calculator/retirement`).
  final RetirementResultDto person1;

  /// Retirement projection for the "Partner".
  final RetirementResultDto person2;

  /// Gross sum of both AVS pensions, before the cap, in centimes/year.
  final int combinedAvsAnnualRaw;

  /// Combined AVS pension after any couple cap, in centimes/year.
  final int combinedAvsAnnual;

  /// True if the 150% couple AVS cap applies (married/registered
  /// partnership only — unmarried couples keep two full pensions, LAVS art. 35).
  final bool avsCapApplied;

  /// Legal cap applied (CHF 45'360/year in 2026), in centimes.
  final int avsCapAnnual;

  /// Combined annual income at retirement (capped AVS + LPP pensions),
  /// in centimes.
  final int combinedTotalAnnualIncome;

  /// Combined replacement rate in percent.
  final double combinedReplacementRate;

  final CoupleTaxEstimateDto taxEstimate;
  final CoupleWithdrawalPlanDto withdrawalPlan;

  factory CoupleResult.fromJson(Map<String, dynamic> json) => CoupleResult(
    person1: RetirementResultDto.fromJson(
      json['person1'] as Map<String, dynamic>,
    ),
    person2: RetirementResultDto.fromJson(
      json['person2'] as Map<String, dynamic>,
    ),
    combinedAvsAnnualRaw: (json['combinedAvsAnnualRaw'] as num).toInt(),
    combinedAvsAnnual: (json['combinedAvsAnnual'] as num).toInt(),
    avsCapApplied: json['avsCapApplied'] as bool,
    avsCapAnnual: (json['avsCapAnnual'] as num).toInt(),
    combinedTotalAnnualIncome:
        (json['combinedTotalAnnualIncome'] as num).toInt(),
    combinedReplacementRate:
        (json['combinedReplacementRate'] as num).toDouble(),
    taxEstimate: CoupleTaxEstimateDto.fromJson(
      json['taxEstimate'] as Map<String, dynamic>,
    ),
    withdrawalPlan: CoupleWithdrawalPlanDto.fromJson(
      json['withdrawalPlan'] as Map<String, dynamic>,
    ),
  );
}
