/// Calculator DTOs — shapes verified against
/// `src/modules/calculator/calculator.types.ts` (handlers return the
/// raw interfaces, no envelope) and `retirement-projection.ts`.
///
/// All amounts are in **centimes** (contract §1).
library;

/// Response from `POST /calculator/lpp-gap`.
class LppGapResultDto {
  const LppGapResultDto({
    required this.coordinatedSalary,
    required this.bvgMinContribution,
    required this.contributionGap,
    required this.projectedBvgMinCapital,
    required this.projectedActualCapital,
    required this.capitalGap,
    required this.projectedMinAnnualPension,
    required this.projectedActualAnnualPension,
    required this.pensionGap,
  });

  /// Coordinated salary, in centimes.
  final int coordinatedSalary;

  /// Minimum annual LPP contribution, in centimes.
  final int bvgMinContribution;

  /// Annual contribution gap (clamped ≥ 0 by the backend), in centimes.
  final int contributionGap;

  /// Minimum projected capital at retirement, in centimes.
  final int projectedBvgMinCapital;

  /// Actual projected capital at retirement, in centimes.
  final int projectedActualCapital;

  /// Capital gap at retirement (≥ 0), in centimes.
  final int capitalGap;

  /// Minimum projected annual pension, in centimes.
  final int projectedMinAnnualPension;

  /// Actual projected annual pension, in centimes.
  final int projectedActualAnnualPension;

  /// Annual pension gap (≥ 0; positive = below minimum), in centimes.
  final int pensionGap;

  factory LppGapResultDto.fromJson(Map<String, dynamic> json) =>
      LppGapResultDto(
        coordinatedSalary: (json['coordinatedSalary'] as num).toInt(),
        bvgMinContribution: (json['bvgMinContribution'] as num).toInt(),
        contributionGap: (json['contributionGap'] as num).toInt(),
        projectedBvgMinCapital: (json['projectedBvgMinCapital'] as num)
            .toInt(),
        projectedActualCapital: (json['projectedActualCapital'] as num)
            .toInt(),
        capitalGap: (json['capitalGap'] as num).toInt(),
        projectedMinAnnualPension: (json['projectedMinAnnualPension'] as num)
            .toInt(),
        projectedActualAnnualPension:
            (json['projectedActualAnnualPension'] as num).toInt(),
        pensionGap: (json['pensionGap'] as num).toInt(),
      );
}

/// Response from `POST /calculator/tax-savings`.
class TaxSavingsResultDto {
  const TaxSavingsResultDto({
    required this.federalTaxSaving,
    required this.cantonalTaxSaving,
    required this.communalTaxSaving,
    required this.totalTaxSaving,
    required this.effectiveReturnRate,
    required this.maxContribution,
    required this.isAtMax,
  });

  /// Federal tax saving, in centimes.
  final int federalTaxSaving;

  /// Cantonal tax saving, in centimes.
  final int cantonalTaxSaving;

  /// Communal tax saving, in centimes.
  final int communalTaxSaving;

  /// Total annual saving, in centimes.
  final int totalTaxSaving;

  /// Effective return rate of the contribution in percent (e.g. `30.5` = 30.5%).
  final double effectiveReturnRate;

  /// Maximum applicable 3a contribution, in centimes.
  final int maxContribution;

  /// True if the requested contribution reaches the cap.
  final bool isAtMax;

  factory TaxSavingsResultDto.fromJson(Map<String, dynamic> json) =>
      TaxSavingsResultDto(
        federalTaxSaving: (json['federalTaxSaving'] as num).toInt(),
        cantonalTaxSaving: (json['cantonalTaxSaving'] as num).toInt(),
        communalTaxSaving: (json['communalTaxSaving'] as num).toInt(),
        totalTaxSaving: (json['totalTaxSaving'] as num).toInt(),
        effectiveReturnRate: (json['effectiveReturnRate'] as num).toDouble(),
        maxContribution: (json['maxContribution'] as num).toInt(),
        isAtMax: json['isAtMax'] as bool,
      );
}

/// One year of `yearByYearProjection` (`POST /calculator/retirement`).
class YearProjectionDto {
  const YearProjectionDto({
    required this.year,
    required this.age,
    required this.pillar2Capital,
    required this.pillar3aBalance,
    required this.totalCapital,
  });

  final int year;
  final int age;

  /// Projected LPP capital at year end, in centimes.
  final int pillar2Capital;

  /// Projected 3a balance at year end, in centimes.
  final int pillar3aBalance;

  /// `pillar2Capital + pillar3aBalance`, in centimes.
  final int totalCapital;

  factory YearProjectionDto.fromJson(Map<String, dynamic> json) =>
      YearProjectionDto(
        year: (json['year'] as num).toInt(),
        age: (json['age'] as num).toInt(),
        pillar2Capital: (json['pillar2Capital'] as num).toInt(),
        pillar3aBalance: (json['pillar3aBalance'] as num).toInt(),
        totalCapital: (json['totalCapital'] as num).toInt(),
      );
}

/// Response from `POST /calculator/retirement` — full version (the dashboard
/// DTO is lighter: no year-by-year projection).
///
/// Business rule (contract §7): 3a is **excluded** from retirement income —
/// `totalAnnualRetirementIncome = AVS pension + LPP pension`, 3a is withdrawn
/// as a lump sum (`pillar3aAsLumpSum`).
class RetirementResultDto {
  const RetirementResultDto({
    required this.yearsToRetirement,
    required this.projectedPillar2Capital,
    required this.projectedPillar3aBalance,
    required this.annualPillar2Pension,
    required this.estimatedAnnualAvsPension,
    required this.pillar3aAsLumpSum,
    required this.totalAnnualRetirementIncome,
    required this.replacementRate,
    required this.yearByYearProjection,
  });

  final int yearsToRetirement;

  /// Projected LPP capital at retirement, in centimes.
  final int projectedPillar2Capital;

  /// Projected 3a capital at retirement, in centimes.
  final int projectedPillar3aBalance;

  /// Annual LPP pension (capital × conversion rate), in centimes.
  final int annualPillar2Pension;

  /// Estimated annual AVS pension, in centimes.
  final int estimatedAnnualAvsPension;

  /// 3a capital withdrawn as a lump sum (= `projectedPillar3aBalance`), in
  /// centimes.
  final int pillar3aAsLumpSum;

  /// Annual income at retirement (AVS + LPP), in centimes.
  final int totalAnnualRetirementIncome;

  /// Replacement rate in percent (e.g. `63.0` = 63%).
  final double replacementRate;

  /// Year-by-year projection until retirement (never empty:
  /// `yearsToRetirement` ≥ 1 guaranteed by the schema).
  final List<YearProjectionDto> yearByYearProjection;

  factory RetirementResultDto.fromJson(Map<String, dynamic> json) =>
      RetirementResultDto(
        yearsToRetirement: (json['yearsToRetirement'] as num).toInt(),
        projectedPillar2Capital: (json['projectedPillar2Capital'] as num)
            .toInt(),
        projectedPillar3aBalance: (json['projectedPillar3aBalance'] as num)
            .toInt(),
        annualPillar2Pension: (json['annualPillar2Pension'] as num).toInt(),
        estimatedAnnualAvsPension: (json['estimatedAnnualAvsPension'] as num)
            .toInt(),
        pillar3aAsLumpSum: (json['pillar3aAsLumpSum'] as num).toInt(),
        totalAnnualRetirementIncome:
            (json['totalAnnualRetirementIncome'] as num).toInt(),
        replacementRate: (json['replacementRate'] as num).toDouble(),
        yearByYearProjection: [
          for (final item
              in json['yearByYearProjection'] as List<dynamic>? ?? [])
            YearProjectionDto.fromJson(item as Map<String, dynamic>),
        ],
      );
}
