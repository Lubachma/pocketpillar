/// Financial profile DTOs — shapes verified against
/// `src/modules/financial-profile/` (handler + Zod schemas) and
/// `src/modules/user/user.schema.ts`.
///
/// All amounts are in **centimes** (contract §1) — CHF input is
/// converted by the repository, never exposed here.
library;

import '../../../core/purchases/premium_status.dart';

/// `GET /financial-profile` (404 while the resource doesn't exist yet —
/// contract §4). Unlike the dashboard's lightweight DTO, this version
/// is complete (edit form).
class FinancialProfileDto {
  const FinancialProfileDto({
    required this.id,
    required this.employmentStatus,
    required this.maritalStatus,
    required this.numberOfChildren,
    required this.grossAnnualIncome,
    this.netAnnualIncome,
  });

  final String id;

  /// `EMPLOYED | SELF_EMPLOYED | UNEMPLOYED | RETIRED`.
  final String employmentStatus;

  /// `SINGLE | MARRIED | REGISTERED_PARTNERSHIP | DIVORCED | WIDOWED`.
  final String maritalStatus;

  final int numberOfChildren;

  /// Gross annual income, in centimes.
  final int grossAnnualIncome;

  /// Net annual income, in centimes (null if not provided).
  final int? netAnnualIncome;

  factory FinancialProfileDto.fromJson(Map<String, dynamic> json) =>
      FinancialProfileDto(
        id: json['id'] as String,
        employmentStatus: json['employmentStatus'] as String,
        maritalStatus: json['maritalStatus'] as String,
        numberOfChildren: (json['numberOfChildren'] as num?)?.toInt() ?? 0,
        grossAnnualIncome: (json['grossAnnualIncome'] as num).toInt(),
        netAnnualIncome: (json['netAnnualIncome'] as num?)?.toInt(),
      );
}

/// Element of `GET /financial-profile/pillar2` (list, never 404).
///
/// All optional monetary fields from the backend schema are parsed
/// (round-trip), even though the form only exposes a subset of them.
class Pillar2AccountDto {
  const Pillar2AccountDto({
    required this.id,
    this.providerName,
    required this.currentCapital,
    this.projectedCapitalAtRetirement,
    this.conversionRate,
    this.insuredSalary,
    this.coordinationDeduction,
    this.annualBvgContribution,
    this.annualSupraContribution,
    required this.isVestedBenefits,
  });

  final String id;
  final String? providerName;

  /// Current LPP capital, in centimes.
  final int currentCapital;

  /// Projected capital at retirement, in centimes.
  final int? projectedCapitalAtRetirement;

  /// Conversion rate in percent (e.g. `6.8` = 6.8%).
  final double? conversionRate;

  /// Insured salary, in centimes.
  final int? insuredSalary;

  /// Coordination deduction, in centimes.
  final int? coordinationDeduction;

  /// Annual LPP contribution, in centimes.
  final int? annualBvgContribution;

  /// Annual supra-mandatory contribution, in centimes.
  final int? annualSupraContribution;

  /// Vested benefits account (as opposed to an active pension fund).
  final bool isVestedBenefits;

  factory Pillar2AccountDto.fromJson(Map<String, dynamic> json) =>
      Pillar2AccountDto(
        id: json['id'] as String,
        providerName: json['providerName'] as String?,
        currentCapital: (json['currentCapital'] as num).toInt(),
        projectedCapitalAtRetirement:
            (json['projectedCapitalAtRetirement'] as num?)?.toInt(),
        conversionRate: (json['conversionRate'] as num?)?.toDouble(),
        insuredSalary: (json['insuredSalary'] as num?)?.toInt(),
        coordinationDeduction: (json['coordinationDeduction'] as num?)?.toInt(),
        annualBvgContribution: (json['annualBvgContribution'] as num?)?.toInt(),
        annualSupraContribution: (json['annualSupraContribution'] as num?)
            ?.toInt(),
        isVestedBenefits: json['isVestedBenefits'] as bool? ?? false,
      );
}

/// Element of `GET /financial-profile/pillar3a` (list, never 404).
class Pillar3aAccountDto {
  const Pillar3aAccountDto({
    required this.id,
    required this.providerName,
    required this.accountType,
    required this.currentBalance,
    this.annualContribution,
    this.interestRateOrReturn,
  });

  final String id;
  final String providerName;

  /// `BANK | INSURANCE`.
  final String accountType;

  /// Current 3a balance, in centimes.
  final int currentBalance;

  /// Annual payment, in centimes (null if unknown).
  final int? annualContribution;

  /// Interest rate or return in percent (e.g. `1.5` = 1.5%).
  final double? interestRateOrReturn;

  factory Pillar3aAccountDto.fromJson(Map<String, dynamic> json) =>
      Pillar3aAccountDto(
        id: json['id'] as String,
        providerName: json['providerName'] as String,
        accountType: json['accountType'] as String,
        currentBalance: (json['currentBalance'] as num).toInt(),
        annualContribution: (json['annualContribution'] as num?)?.toInt(),
        interestRateOrReturn: (json['interestRateOrReturn'] as num?)
            ?.toDouble(),
      );
}

/// Profile screen aggregate: user + financial profile (null on
/// initial 404 → form in creation mode).
class ProfileBaseData {
  const ProfileBaseData({
    required this.userId,
    required this.email,
    this.canton,
    this.municipality,
    this.birthYear,
    required this.replacementRateGoal,
    this.premium = PremiumStatus.none,
    this.profile,
    required this.loadedAt,
  });

  final String userId;
  final String email;

  /// 2-letter canton code (`VD`), null if never provided.
  final String? canton;

  /// Municipality of residence (actual municipal multiplier on the
  /// calculator side), null if never provided → cantonal average.
  final String? municipality;

  final int? birthYear;

  /// Replacement rate goal (50–100, default 70).
  final int replacementRateGoal;

  /// `premium` block from `users/me` (contract §11) — source of truth
  /// for the displayed subscription status.
  final PremiumStatus premium;

  /// Null while `GET /financial-profile` responds 404 (contract §4).
  final FinancialProfileDto? profile;

  /// Load timestamp — used as the form's key to reset it when the
  /// data is reloaded.
  final DateTime loadedAt;

  bool get hasProfile => profile != null;
}

/// Shared profile aggregate (I9, full review 2026-08): `users/me` +
/// `financial-profile` + LPP/3a accounts, loaded **once** and consumed
/// by the dashboard, the profile screen, the scenarios, and the
/// calculator — each of which used to fetch the same 4 endpoints on
/// its own.
///
/// `profile` null = initial 404 (profile never created), normal state.
class ProfileAggregate {
  const ProfileAggregate({
    required this.base,
    this.pillar2Accounts = const [],
    this.pillar3aAccounts = const [],
  });

  final ProfileBaseData base;

  final List<Pillar2AccountDto> pillar2Accounts;
  final List<Pillar3aAccountDto> pillar3aAccounts;
}
