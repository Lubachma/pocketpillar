/// Dashboard DTOs — shapes verified against `src/modules/`
/// (user, financial-profile, calculator, recommendation).
///
/// All amounts are in **centimes** (contract §1).
library;

/// `GET /users/me` → `{ id, email, canton, birthYear, replacementRateGoal, createdAt }`.
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    this.canton,
    this.birthYear,
    required this.replacementRateGoal,
  });

  final String id;
  final String email;
  final String? canton;
  final int? birthYear;

  /// Replacement rate target (50–100, default 70).
  final int replacementRateGoal;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: json['id'] as String,
    email: json['email'] as String,
    canton: json['canton'] as String?,
    birthYear: (json['birthYear'] as num?)?.toInt(),
    replacementRateGoal: (json['replacementRateGoal'] as num?)?.toInt() ?? 70,
  );
}

/// `GET /financial-profile` (404 while the resource doesn't exist).
class FinancialProfileDto {
  const FinancialProfileDto({
    required this.employmentStatus,
    required this.maritalStatus,
    required this.numberOfChildren,
    required this.grossAnnualIncome,
    this.netAnnualIncome,
  });

  final String employmentStatus;
  final String maritalStatus;
  final int numberOfChildren;

  /// Gross annual income, in centimes.
  final int grossAnnualIncome;

  /// Net annual income, in centimes (null if not provided) — priority
  /// basis for the 3a 20% rule (`pillar3aIncomeBaseFor`,
  /// reviewed in batch 12: the checklist thus uses the same rule as the
  /// annual reminder).
  final int? netAnnualIncome;

  factory FinancialProfileDto.fromJson(Map<String, dynamic> json) =>
      FinancialProfileDto(
        employmentStatus: json['employmentStatus'] as String,
        maritalStatus: json['maritalStatus'] as String,
        numberOfChildren: (json['numberOfChildren'] as num?)?.toInt() ?? 0,
        grossAnnualIncome: (json['grossAnnualIncome'] as num).toInt(),
        netAnnualIncome: (json['netAnnualIncome'] as num?)?.toInt(),
      );
}

/// Item from `GET /financial-profile/pillar2` (list, never 404).
class Pillar2AccountDto {
  const Pillar2AccountDto({
    required this.id,
    required this.currentCapital,
    this.annualBvgContribution,
  });

  final String id;

  /// Current LPP capital, in centimes.
  final int currentCapital;

  /// Annual LPP contribution, in centimes (null if unknown).
  final int? annualBvgContribution;

  factory Pillar2AccountDto.fromJson(Map<String, dynamic> json) =>
      Pillar2AccountDto(
        id: json['id'] as String,
        currentCapital: (json['currentCapital'] as num).toInt(),
        annualBvgContribution: (json['annualBvgContribution'] as num?)?.toInt(),
      );
}

/// Item from `GET /financial-profile/pillar3a` (list, never 404).
class Pillar3aAccountDto {
  const Pillar3aAccountDto({
    required this.id,
    required this.providerName,
    required this.currentBalance,
    this.annualContribution,
  });

  final String id;
  final String providerName;

  /// Current 3a balance, in centimes.
  final int currentBalance;

  /// Annual contribution, in centimes (null if unknown).
  final int? annualContribution;

  factory Pillar3aAccountDto.fromJson(Map<String, dynamic> json) =>
      Pillar3aAccountDto(
        id: json['id'] as String,
        providerName: json['providerName'] as String,
        currentBalance: (json['currentBalance'] as num).toInt(),
        annualContribution: (json['annualContribution'] as num?)?.toInt(),
      );
}

/// Response from `POST /calculator/retirement` (retirement projection).
///
/// Business rule (contract §7): 3a is **excluded** from retirement income —
/// `totalAnnualRetirementIncome = AVS pension + LPP pension`.
class RetirementProjectionDto {
  const RetirementProjectionDto({
    required this.yearsToRetirement,
    required this.projectedPillar2Capital,
    required this.projectedPillar3aBalance,
    required this.annualPillar2Pension,
    required this.estimatedAnnualAvsPension,
    required this.totalAnnualRetirementIncome,
    required this.replacementRate,
  });

  final int yearsToRetirement;

  /// Projected LPP capital at retirement, in centimes.
  final int projectedPillar2Capital;

  /// Projected 3a capital (withdrawn as a lump sum), in centimes.
  final int projectedPillar3aBalance;

  /// Projected annual LPP pension, in centimes (capital × conversion
  /// rate — displayed by the 2nd pillar card, iOS parity).
  final int annualPillar2Pension;

  /// Estimated annual AVS pension, in centimes.
  final int estimatedAnnualAvsPension;

  /// Annual income at retirement (AVS + LPP), in centimes.
  final int totalAnnualRetirementIncome;

  /// Replacement rate in percent (e.g. `37.0` = 37%).
  final double replacementRate;

  factory RetirementProjectionDto.fromJson(
    Map<String, dynamic> json,
  ) => RetirementProjectionDto(
    yearsToRetirement: (json['yearsToRetirement'] as num).toInt(),
    projectedPillar2Capital: (json['projectedPillar2Capital'] as num).toInt(),
    projectedPillar3aBalance: (json['projectedPillar3aBalance'] as num).toInt(),
    annualPillar2Pension: (json['annualPillar2Pension'] as num).toInt(),
    estimatedAnnualAvsPension: (json['estimatedAnnualAvsPension'] as num)
        .toInt(),
    totalAnnualRetirementIncome: (json['totalAnnualRetirementIncome'] as num)
        .toInt(),
    replacementRate: (json['replacementRate'] as num).toDouble(),
  );
}

/// Item from `GET /recommendations` — title and description are already
/// localized by the backend (`Accept-Language`).
class RecommendationDto {
  const RecommendationDto({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.estimatedAnnualImpact,
  });

  /// `OPEN_FIRST_3A | MAX_3A_CONTRIBUTION | PROVIDER_SWITCH |
  /// BVG_VOLUNTARY_PURCHASE | OPEN_ADDITIONAL_3A`.
  final String type;

  /// `HIGH | MEDIUM | LOW`.
  final String priority;

  final String title;
  final String description;

  /// Estimated annual impact, in centimes.
  final int estimatedAnnualImpact;

  factory RecommendationDto.fromJson(Map<String, dynamic> json) =>
      RecommendationDto(
        type: json['type'] as String,
        priority: json['priority'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        estimatedAnnualImpact:
            (json['estimatedAnnualImpact'] as num?)?.toInt() ?? 0,
      );
}

/// Response from `GET /recommendations`.
class RecommendationResultDto {
  const RecommendationResultDto({required this.recommendations});

  final List<RecommendationDto> recommendations;

  factory RecommendationResultDto.fromJson(Map<String, dynamic> json) =>
      RecommendationResultDto(
        recommendations: [
          for (final item in json['recommendations'] as List<dynamic>? ?? [])
            RecommendationDto.fromJson(item as Map<String, dynamic>),
        ],
      );
}

/// Item from `PensionScoreDto.breakdown` — label already localized by the
/// backend (`Accept-Language`).
class ScoreBreakdownItemDto {
  const ScoreBreakdownItemDto({
    required this.criterion,
    required this.label,
    required this.points,
    required this.maxPoints,
  });

  /// `REPLACEMENT_RATE | PILLAR_3A | AGE_AWARENESS`.
  final String criterion;
  final String label;
  final int points;
  final int maxPoints;

  factory ScoreBreakdownItemDto.fromJson(Map<String, dynamic> json) =>
      ScoreBreakdownItemDto(
        criterion: json['criterion'] as String,
        label: json['label'] as String,
        points: (json['points'] as num).toInt(),
        maxPoints: (json['maxPoints'] as num).toInt(),
      );
}

/// Age bracket benchmark + the user's values that were used
/// for the calculation (contract §8 bis). Amounts in centimes.
class ScoreBenchmarkDto {
  const ScoreBenchmarkDto({
    this.bracketMinAge,
    this.bracketMaxAge,
    required this.averagePillar3aBalance,
    required this.averageReplacementRate,
    required this.averageBvgCapital,
    required this.userPillar3aBalance,
    required this.userReplacementRate,
    required this.userBvgCapital,
  });

  /// Age bracket (null outside 25–65 — backend-side fallback averages).
  final int? bracketMinAge;
  final int? bracketMaxAge;

  final int averagePillar3aBalance;

  /// Average replacement rate for the bracket, in percent.
  final double averageReplacementRate;
  final int averageBvgCapital;

  final int userPillar3aBalance;
  final double userReplacementRate;
  final int userBvgCapital;

  bool get hasBracket => bracketMinAge != null && bracketMaxAge != null;

  factory ScoreBenchmarkDto.fromJson(Map<String, dynamic> json) {
    final bracket = json['bracket'] as Map<String, dynamic>?;
    return ScoreBenchmarkDto(
      bracketMinAge: (bracket?['minAge'] as num?)?.toInt(),
      bracketMaxAge: (bracket?['maxAge'] as num?)?.toInt(),
      averagePillar3aBalance: (json['averagePillar3aBalance'] as num).toInt(),
      averageReplacementRate: (json['averageReplacementRate'] as num)
          .toDouble(),
      averageBvgCapital: (json['averageBvgCapital'] as num).toInt(),
      userPillar3aBalance: (json['userPillar3aBalance'] as num).toInt(),
      userReplacementRate: (json['userReplacementRate'] as num).toDouble(),
      userBvgCapital: (json['userBvgCapital'] as num).toInt(),
    );
  }
}

/// Response from `GET /score` (contract §8 bis): pension score /100,
/// breakdown by criterion and age bracket benchmark.
class PensionScoreDto {
  const PensionScoreDto({
    required this.score,
    required this.breakdown,
    required this.benchmark,
  });

  /// Score 0–100 (sum of criteria, clamped).
  final int score;
  final List<ScoreBreakdownItemDto> breakdown;
  final ScoreBenchmarkDto benchmark;

  factory PensionScoreDto.fromJson(Map<String, dynamic> json) =>
      PensionScoreDto(
        score: (json['score'] as num).toInt(),
        breakdown: [
          for (final item in json['breakdown'] as List<dynamic>? ?? [])
            ScoreBreakdownItemDto.fromJson(item as Map<String, dynamic>),
        ],
        benchmark: ScoreBenchmarkDto.fromJson(
          json['benchmark'] as Map<String, dynamic>,
        ),
      );
}

/// Aggregate consumed by the screen: user, financial profile (null if
/// 404 — never created), accounts and retirement projection (null if the
/// calculation isn't possible: missing birthYear or age outside 18–64).
class DashboardData {
  const DashboardData({
    required this.user,
    this.profile,
    this.pillar2Accounts = const [],
    this.pillar3aAccounts = const [],
    this.projection,
  });

  final UserDto user;

  /// Null when `GET /financial-profile` responds with 404 (contract §4).
  final FinancialProfileDto? profile;

  final List<Pillar2AccountDto> pillar2Accounts;
  final List<Pillar3aAccountDto> pillar3aAccounts;

  /// Retirement projection, null if not calculable.
  final RetirementProjectionDto? projection;

  bool get hasProfile => profile != null;

  bool get hasPillar3a => pillar3aAccounts.isNotEmpty;

  /// Sum of LPP capitals, in centimes.
  int get totalPillar2Capital =>
      pillar2Accounts.fold(0, (sum, a) => sum + a.currentCapital);

  /// Sum of 3a balances, in centimes.
  int get totalPillar3aBalance =>
      pillar3aAccounts.fold(0, (sum, a) => sum + a.currentBalance);
}
