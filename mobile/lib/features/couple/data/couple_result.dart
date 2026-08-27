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

  factory CoupleWithdrawalPlanDto.fromJson(
    Map<String, dynamic> json,
  ) => CoupleWithdrawalPlanDto(
    steps: [
      for (final item in json['steps'] as List<dynamic>? ?? [])
        CoupleWithdrawalStepDto.fromJson(item as Map<String, dynamic>),
    ],
    totalEstimatedTax: (json['totalEstimatedTax'] as num).toInt(),
    simultaneousEstimatedTax: (json['simultaneousEstimatedTax'] as num).toInt(),
    taxSavingsVsSimultaneous: (json['taxSavingsVsSimultaneous'] as num).toInt(),
  );
}

/// Per-spouse income AFTER the couple AVS cap — the cap reduction is
/// allocated pro rata to the two pensions server-side (LAVS art. 35 al. 3);
/// equals the raw projection when the cap doesn't apply. Use THIS for the
/// per-person display (practitioner review 08.2026: uncapped per-person rows
/// next to a capped total read as a bug).
class CouplePersonIncomeDto {
  const CouplePersonIncomeDto({
    required this.avsAnnual,
    required this.pillar2Annual,
    required this.totalAnnual,
    required this.replacementRate,
  });

  /// Capped AVS share, in centimes/year.
  final int avsAnnual;

  /// LPP pension, in centimes/year.
  final int pillar2Annual;

  /// avsAnnual + pillar2Annual, in centimes/year.
  final int totalAnnual;

  /// vs this spouse's OWN gross income, in percent.
  final double replacementRate;

  factory CouplePersonIncomeDto.fromJson(Map<String, dynamic> json) =>
      CouplePersonIncomeDto(
        avsAnnual: (json['avsAnnual'] as num).toInt(),
        pillar2Annual: (json['pillar2Annual'] as num).toInt(),
        totalAnnual: (json['totalAnnual'] as num).toInt(),
        replacementRate: (json['replacementRate'] as num).toDouble(),
      );
}

/// One dated phase of the couple's retirement (Argo-style timeline,
/// chantier 08.2026): with an age gap, the earlier-retired spouse draws a
/// FULL pension until the second retirement (LAVS art. 35 caps only once
/// both pensions run); the final phase is open-ended and equals the
/// headline combined figures. Amounts in centimes/year.
class CoupleTimelinePhaseDto {
  const CoupleTimelinePhaseDto({
    required this.startYear,
    required this.endYear,
    required this.person1Age,
    required this.person2Age,
    required this.person1Retired,
    required this.person2Retired,
    required this.person1AvsAnnual,
    required this.person2AvsAnnual,
    required this.person1Pillar2Annual,
    required this.person2Pillar2Annual,
    required this.person1TotalAnnual,
    required this.person2TotalAnnual,
    required this.avsCapApplied,
    required this.combinedAnnual,
  });

  final int startYear;

  /// Exclusive end year — null for the final, open-ended phase.
  final int? endYear;
  final int person1Age;
  final int person2Age;
  final bool person1Retired;
  final bool person2Retired;
  final int person1AvsAnnual;
  final int person2AvsAnnual;
  final int person1Pillar2Annual;
  final int person2Pillar2Annual;
  final int person1TotalAnnual;
  final int person2TotalAnnual;
  final bool avsCapApplied;
  final int combinedAnnual;

  factory CoupleTimelinePhaseDto.fromJson(Map<String, dynamic> json) =>
      CoupleTimelinePhaseDto(
        startYear: (json['startYear'] as num).toInt(),
        endYear: (json['endYear'] as num?)?.toInt(),
        person1Age: (json['person1Age'] as num).toInt(),
        person2Age: (json['person2Age'] as num).toInt(),
        person1Retired: json['person1Retired'] as bool,
        person2Retired: json['person2Retired'] as bool,
        person1AvsAnnual: (json['person1AvsAnnual'] as num).toInt(),
        person2AvsAnnual: (json['person2AvsAnnual'] as num).toInt(),
        person1Pillar2Annual: (json['person1Pillar2Annual'] as num).toInt(),
        person2Pillar2Annual: (json['person2Pillar2Annual'] as num).toInt(),
        person1TotalAnnual: (json['person1TotalAnnual'] as num).toInt(),
        person2TotalAnnual: (json['person2TotalAnnual'] as num).toInt(),
        avsCapApplied: json['avsCapApplied'] as bool,
        combinedAnnual: (json['combinedAnnual'] as num).toInt(),
      );
}

/// Result of the couple simulation (`POST /calculator/couple`).
class CoupleResult {
  const CoupleResult({
    required this.person1,
    required this.person2,
    required this.person1Income,
    required this.person2Income,
    required this.combinedAvsAnnualRaw,
    required this.combinedAvsAnnual,
    required this.avsCapApplied,
    required this.avsCapAnnual,
    required this.combinedTotalAnnualIncome,
    required this.combinedReplacementRate,
    required this.timeline,
    required this.taxEstimate,
    required this.withdrawalPlan,
  });

  /// Retirement projection for "You" (shape of `/calculator/retirement`).
  final RetirementResultDto person1;

  /// Retirement projection for the "Partner".
  final RetirementResultDto person2;

  /// "You" income after the couple cap — display source for per-person rows.
  final CouplePersonIncomeDto person1Income;

  /// "Partner" income after the couple cap.
  final CouplePersonIncomeDto person2Income;

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

  /// Dated retirement phases, chronological (1 without an age gap, else 2).
  final List<CoupleTimelinePhaseDto> timeline;

  final CoupleTaxEstimateDto taxEstimate;
  final CoupleWithdrawalPlanDto withdrawalPlan;

  factory CoupleResult.fromJson(Map<String, dynamic> json) => CoupleResult(
    person1: RetirementResultDto.fromJson(
      json['person1'] as Map<String, dynamic>,
    ),
    person2: RetirementResultDto.fromJson(
      json['person2'] as Map<String, dynamic>,
    ),
    person1Income: CouplePersonIncomeDto.fromJson(
      json['person1Income'] as Map<String, dynamic>,
    ),
    person2Income: CouplePersonIncomeDto.fromJson(
      json['person2Income'] as Map<String, dynamic>,
    ),
    combinedAvsAnnualRaw: (json['combinedAvsAnnualRaw'] as num).toInt(),
    combinedAvsAnnual: (json['combinedAvsAnnual'] as num).toInt(),
    avsCapApplied: json['avsCapApplied'] as bool,
    avsCapAnnual: (json['avsCapAnnual'] as num).toInt(),
    combinedTotalAnnualIncome: (json['combinedTotalAnnualIncome'] as num)
        .toInt(),
    combinedReplacementRate: (json['combinedReplacementRate'] as num)
        .toDouble(),
    timeline: [
      for (final item in json['timeline'] as List<dynamic>? ?? [])
        CoupleTimelinePhaseDto.fromJson(item as Map<String, dynamic>),
    ],
    taxEstimate: CoupleTaxEstimateDto.fromJson(
      json['taxEstimate'] as Map<String, dynamic>,
    ),
    withdrawalPlan: CoupleWithdrawalPlanDto.fromJson(
      json['withdrawalPlan'] as Map<String, dynamic>,
    ),
  );
}
