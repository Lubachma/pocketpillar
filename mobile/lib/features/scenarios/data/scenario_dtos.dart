/// Scenario DTOs — shapes verified against
/// `src/modules/calculator/calculator.types.ts` (`Pillar3aCatchupResult`,
/// `PropertyPurchaseResult`, `DivorceImpactResult`) and
/// `staggered-withdrawal.ts` (`StaggeredWithdrawalResult`): the
/// handlers return the raw interfaces, with no envelope.
///
/// All amounts are in **centimes** (contract §1).
library;

/// One row of `yearDetails` (`POST /calculator/3a-catchup`).
class Catchup3aYearDetailDto {
  const Catchup3aYearDetailDto({
    required this.year,
    required this.maxContribution,
    required this.actualContribution,
    required this.gap,
  });

  final int year;

  /// The year's 3a cap, in centimes.
  final int maxContribution;

  /// Payment actually made that year, in centimes.
  final int actualContribution;

  /// Amount catchable for the year, in centimes.
  final int gap;

  factory Catchup3aYearDetailDto.fromJson(Map<String, dynamic> json) =>
      Catchup3aYearDetailDto(
        year: (json['year'] as num).toInt(),
        maxContribution: (json['maxContribution'] as num).toInt(),
        actualContribution: (json['actualContribution'] as num).toInt(),
        gap: (json['gap'] as num).toInt(),
      );
}

/// Response from `POST /calculator/3a-catchup`.
class Catchup3aResultDto {
  const Catchup3aResultDto({
    required this.maxPerYear,
    required this.eligibleYears,
    required this.yearDetails,
    required this.totalCatchupPotential,
    required this.currentYearGap,
    required this.mustMaxCurrentYearFirst,
    required this.estimatedTaxSavings,
    required this.estimatedMarginalRate,
    this.premiumRequired = false,
  });

  /// Applicable annual cap (with/without 2nd pillar), in centimes.
  final int maxPerYear;

  /// Number of eligible retroactive years (≤ requested years, capped
  /// by the 2025 reform on the backend side).
  final int eligibleYears;

  /// Detail of years with a gap > 0 (can be empty).
  final List<Catchup3aYearDetailDto> yearDetails;

  /// Total catchable, in centimes.
  final int totalCatchupPotential;

  /// Remaining to pay in for the current year, in centimes.
  final int currentYearGap;

  /// True if the current year isn't maxed out yet (it must be paid
  /// in first — reform rule).
  final bool mustMaxCurrentYearFirst;

  /// Estimated tax savings (flat marginal rate), in centimes.
  final int estimatedTaxSavings;

  /// Marginal rate used by the backend, in whole percent (25/30/35).
  final int estimatedMarginalRate;

  /// Free preview (contract §11): true for an anonymous/free call —
  /// totals are still served but `yearDetails` is emptied; the screen
  /// then shows the "year-by-year plan" upsell card toward the
  /// paywall. Absent (older backend) → false.
  final bool premiumRequired;

  factory Catchup3aResultDto.fromJson(Map<String, dynamic> json) =>
      Catchup3aResultDto(
        maxPerYear: (json['maxPerYear'] as num).toInt(),
        eligibleYears: (json['eligibleYears'] as num).toInt(),
        yearDetails: [
          for (final item in json['yearDetails'] as List<dynamic>? ?? [])
            Catchup3aYearDetailDto.fromJson(item as Map<String, dynamic>),
        ],
        totalCatchupPotential: (json['totalCatchupPotential'] as num).toInt(),
        currentYearGap: (json['currentYearGap'] as num).toInt(),
        mustMaxCurrentYearFirst: json['mustMaxCurrentYearFirst'] as bool,
        estimatedTaxSavings: (json['estimatedTaxSavings'] as num).toInt(),
        estimatedMarginalRate: (json['estimatedMarginalRate'] as num).toInt(),
        premiumRequired: json['premiumRequired'] as bool? ?? false,
      );
}

/// A withdrawal strategy (`POST /calculator/staggered-withdrawal`) —
/// `label` is either `lump_sum` or `stagger_<N>_years` (format
/// guaranteed by the backend).
class WithdrawalStrategyDto {
  const WithdrawalStrategyDto({
    required this.label,
    required this.years,
    required this.totalTax,
    required this.effectiveTaxRate,
  });

  /// `lump_sum` | `stagger_<N>_years`.
  final String label;

  /// Withdrawal schedule (year → amount in centimes).
  final List<WithdrawalYearDto> years;

  /// Total tax for the strategy, in centimes.
  final int totalTax;

  /// Effective tax rate in percent (e.g. `8.25` = 8.25%).
  final double effectiveTaxRate;

  factory WithdrawalStrategyDto.fromJson(Map<String, dynamic> json) =>
      WithdrawalStrategyDto(
        label: json['label'] as String,
        years: [
          for (final item in json['years'] as List<dynamic>? ?? [])
            WithdrawalYearDto.fromJson(item as Map<String, dynamic>),
        ],
        totalTax: (json['totalTax'] as num).toInt(),
        effectiveTaxRate: (json['effectiveTaxRate'] as num).toDouble(),
      );
}

/// A planned withdrawal (calendar year + amount in centimes).
class WithdrawalYearDto {
  const WithdrawalYearDto({required this.year, required this.amount});

  final int year;

  /// Amount withdrawn that year, in centimes.
  final int amount;

  factory WithdrawalYearDto.fromJson(Map<String, dynamic> json) =>
      WithdrawalYearDto(
        year: (json['year'] as num).toInt(),
        amount: (json['amount'] as num).toInt(),
      );
}

/// Response from `POST /calculator/staggered-withdrawal` — actual
/// federal tax scales on the backend side (corrected rules), not
/// iOS's simplified 6/8/10% scale.
class StaggeredWithdrawalResultDto {
  const StaggeredWithdrawalResultDto({
    required this.strategies,
    required this.bestStrategy,
    required this.taxSavingsVsLumpSum,
  });

  /// 1 to 3 strategies (lump-sum withdrawal always present; staggered
  /// ones depend on the number of accounts and years before
  /// retirement).
  final List<WithdrawalStrategyDto> strategies;

  /// `label` of the least-taxed strategy (in case of a tie, the
  /// simplest one — backend decision).
  final String bestStrategy;

  /// Savings vs. lump-sum withdrawal, in centimes (0 if the lump-sum
  /// withdrawal is the best strategy).
  final int taxSavingsVsLumpSum;

  factory StaggeredWithdrawalResultDto.fromJson(Map<String, dynamic> json) =>
      StaggeredWithdrawalResultDto(
        strategies: [
          for (final item in json['strategies'] as List<dynamic>? ?? [])
            WithdrawalStrategyDto.fromJson(item as Map<String, dynamic>),
        ],
        bestStrategy: json['bestStrategy'] as String,
        taxSavingsVsLumpSum: (json['taxSavingsVsLumpSum'] as num).toInt(),
      );
}

/// Response from `POST /calculator/property-purchase` (EPL).
class PropertyPurchaseResultDto {
  const PropertyPurchaseResultDto({
    required this.maxWithdrawal,
    required this.effectiveWithdrawal,
    required this.capitalAtRetirementWithout,
    required this.capitalAtRetirementWith,
    required this.capitalLostAtRetirement,
    required this.annualPensionWithout,
    required this.annualPensionWith,
    required this.annualPensionLoss,
    required this.monthlyPensionLoss,
  });

  /// Maximum authorized withdrawal (100% under 50, otherwise max(assets
  /// at 50, half of current assets)), in centimes.
  final int maxWithdrawal;

  /// Withdrawal actually applied (`min(requested, maxWithdrawal)`), in
  /// centimes.
  final int effectiveWithdrawal;

  /// Projected LPP capital at retirement without withdrawal, in centimes.
  final int capitalAtRetirementWithout;

  /// Projected LPP capital at retirement with withdrawal, in centimes.
  final int capitalAtRetirementWith;

  /// Capital lost at retirement (withdrawal + compound interest), in
  /// centimes.
  final int capitalLostAtRetirement;

  /// Annual pension without withdrawal, in centimes.
  final int annualPensionWithout;

  /// Annual pension with withdrawal, in centimes.
  final int annualPensionWith;

  /// Annual pension loss, in centimes.
  final int annualPensionLoss;

  /// Monthly pension loss, in centimes.
  final int monthlyPensionLoss;

  factory PropertyPurchaseResultDto.fromJson(Map<String, dynamic> json) =>
      PropertyPurchaseResultDto(
        maxWithdrawal: (json['maxWithdrawal'] as num).toInt(),
        effectiveWithdrawal: (json['effectiveWithdrawal'] as num).toInt(),
        capitalAtRetirementWithout:
            (json['capitalAtRetirementWithout'] as num).toInt(),
        capitalAtRetirementWith: (json['capitalAtRetirementWith'] as num)
            .toInt(),
        capitalLostAtRetirement: (json['capitalLostAtRetirement'] as num)
            .toInt(),
        annualPensionWithout: (json['annualPensionWithout'] as num).toInt(),
        annualPensionWith: (json['annualPensionWith'] as num).toInt(),
        annualPensionLoss: (json['annualPensionLoss'] as num).toInt(),
        monthlyPensionLoss: (json['monthlyPensionLoss'] as num).toInt(),
      );
}

/// Response from `POST /calculator/divorce-impact`.
class DivorceImpactResultDto {
  const DivorceImpactResultDto({
    required this.myAccumulatedDuringMarriage,
    required this.spouseAccumulatedDuringMarriage,
    required this.totalMarriageCapital,
    required this.transferAmount,
    required this.capitalAfterDivorce,
    required this.projectedCapitalWithMarriage,
    required this.projectedCapitalAfterDivorce,
    required this.annualPensionWithMarriage,
    required this.annualPensionAfterDivorce,
    required this.annualPensionDifference,
    required this.estimatedAvsImpact,
  });

  /// LPP assets accumulated during the marriage (user), in centimes.
  final int myAccumulatedDuringMarriage;

  /// LPP assets accumulated during the marriage (spouse), in centimes.
  final int spouseAccumulatedDuringMarriage;

  /// Total assets accumulated during the marriage, in centimes.
  final int totalMarriageCapital;

  /// Transfer amount, in centimes — **positive = to receive**,
  /// negative = to pay (50/50 split).
  final int transferAmount;

  /// User's LPP capital after divorce, in centimes.
  final int capitalAfterDivorce;

  /// Projected capital at retirement without divorce, in centimes.
  final int projectedCapitalWithMarriage;

  /// Projected capital at retirement after divorce, in centimes.
  final int projectedCapitalAfterDivorce;

  /// Annual pension without divorce, in centimes.
  final int annualPensionWithMarriage;

  /// Annual pension after divorce, in centimes.
  final int annualPensionAfterDivorce;

  /// Annual pension difference (positive = loss), in centimes.
  final int annualPensionDifference;

  /// Estimated impact on the AVS pension (splitting), in centimes/year.
  final int estimatedAvsImpact;

  /// User's 50% share of the marriage's assets, in centimes —
  /// derived (`myAccumulated + transfer`), not returned as-is by
  /// the backend.
  int get myShare => myAccumulatedDuringMarriage + transferAmount;

  factory DivorceImpactResultDto.fromJson(Map<String, dynamic> json) =>
      DivorceImpactResultDto(
        myAccumulatedDuringMarriage:
            (json['myAccumulatedDuringMarriage'] as num).toInt(),
        spouseAccumulatedDuringMarriage:
            (json['spouseAccumulatedDuringMarriage'] as num).toInt(),
        totalMarriageCapital: (json['totalMarriageCapital'] as num).toInt(),
        transferAmount: (json['transferAmount'] as num).toInt(),
        capitalAfterDivorce: (json['capitalAfterDivorce'] as num).toInt(),
        projectedCapitalWithMarriage:
            (json['projectedCapitalWithMarriage'] as num).toInt(),
        projectedCapitalAfterDivorce:
            (json['projectedCapitalAfterDivorce'] as num).toInt(),
        annualPensionWithMarriage: (json['annualPensionWithMarriage'] as num)
            .toInt(),
        annualPensionAfterDivorce: (json['annualPensionAfterDivorce'] as num)
            .toInt(),
        annualPensionDifference: (json['annualPensionDifference'] as num)
            .toInt(),
        estimatedAvsImpact: (json['estimatedAvsImpact'] as num).toInt(),
      );
}
