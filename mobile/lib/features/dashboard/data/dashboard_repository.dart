import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../financial_profile/data/financial_profile_dtos.dart'
    show ProfileAggregate;
import 'dashboard_dtos.dart';

/// Dashboard repository: composes a [DashboardData] from
/// the shared profile aggregate (I9, full review 2026-08 — deliberate
/// cross-feature exception, like the calculator and the scenarios) and
/// only calls the endpoints specific to it.
///
/// - `GET /financial-profile` responds with **404** while the profile doesn't exist
///   (contract §4) → [DashboardData.profile] null, empty state on the screen.
/// - `POST /calculator/retirement` is only called if the projection is
///   calculable (profile + known `birthYear`, age within 18–64).
///   `estimatedAvsPension` is left at the backend's default (dynamic:
///   income-based estimate, simplified scale 44 — contract §7): no
///   AVS formula duplicated client-side (single source of truth).
/// - `GET /recommendations` responds with **422** if the profile is incomplete →
///   `null` (empty state for the section, not an error).
class DashboardRepository {
  DashboardRepository(this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ApiClient _api;

  /// Injectable clock (age calculation) — overridable in tests.
  final DateTime Function() _now;

  /// Reference retirement age (aligned with the backend,
  /// `SWISS_PENSION.RETIREMENT_AGE_MEN`).
  static const int retirementAge = 65;

  /// Composes the dashboard aggregate from the shared profile aggregate
  /// (I9 deduplication: the 4 profile endpoints are no longer refetched here)
  /// — only `POST /calculator/retirement` is still called, when the projection
  /// is calculable. The dashboard's "lightweight" DTOs are rebuilt
  /// from the profile's full DTOs.
  Future<DashboardData> loadFrom(ProfileAggregate aggregate) async {
    final base = aggregate.base;
    final user = UserDto(
      id: base.userId,
      email: base.email,
      canton: base.canton,
      birthYear: base.birthYear,
      replacementRateGoal: base.replacementRateGoal,
    );
    // The profile's 404 is a normal state (first access), not an error.
    final baseProfile = base.profile;
    if (baseProfile == null) return DashboardData(user: user);

    final profile = FinancialProfileDto(
      employmentStatus: baseProfile.employmentStatus,
      maritalStatus: baseProfile.maritalStatus,
      numberOfChildren: baseProfile.numberOfChildren,
      grossAnnualIncome: baseProfile.grossAnnualIncome,
      netAnnualIncome: baseProfile.netAnnualIncome,
    );
    final pillar2 = [
      for (final a in aggregate.pillar2Accounts)
        Pillar2AccountDto(
          id: a.id,
          currentCapital: a.currentCapital,
          annualBvgContribution: a.annualBvgContribution,
        ),
    ];
    final pillar3a = [
      for (final a in aggregate.pillar3aAccounts)
        Pillar3aAccountDto(
          id: a.id,
          providerName: a.providerName,
          currentBalance: a.currentBalance,
          annualContribution: a.annualContribution,
        ),
    ];

    return DashboardData(
      user: user,
      profile: profile,
      pillar2Accounts: pillar2,
      pillar3aAccounts: pillar3a,
      projection: await _fetchProjectionOrNull(
        user,
        profile,
        pillar2,
        pillar3a,
      ),
    );
  }

  /// Personalized recommendations; `null` when the backend responds with 422
  /// (incomplete profile: missing canton / birth year / financial
  /// profile, contract §2).
  Future<RecommendationResultDto?> loadRecommendations() async {
    try {
      final response = await _api.get('/recommendations');
      return RecommendationResultDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 422) return null;
      rethrow;
    }
  }

  /// Pension score /100 + age benchmark; `null` when the backend
  /// responds with 422 (incomplete profile, contract §8 bis — the card is then
  /// hidden, no error state).
  Future<PensionScoreDto?> loadScore() async {
    try {
      final response = await _api.get('/score');
      return PensionScoreDto.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 422) return null;
      rethrow;
    }
  }

  /// Projection via `POST /calculator/retirement`; null if the birth
  /// year is unknown or if age is outside the 18–64 bounds (the
  /// backend schema requires `retirementAge` — here 65 — strictly
  /// greater than age).
  Future<RetirementProjectionDto?> _fetchProjectionOrNull(
    UserDto user,
    FinancialProfileDto profile,
    List<Pillar2AccountDto> pillar2,
    List<Pillar3aAccountDto> pillar3a,
  ) async {
    final birthYear = user.birthYear;
    if (birthYear == null) return null;
    final age = _now().year - birthYear;
    if (age < 18 || age >= retirementAge) return null;

    final response = await _api.post(
      '/calculator/retirement',
      data: <String, dynamic>{
        'currentAge': age,
        'retirementAge': retirementAge,
        'grossAnnualIncome': profile.grossAnnualIncome,
        'currentPillar2Capital': pillar2.fold<int>(
          0,
          (sum, a) => sum + a.currentCapital,
        ),
        'annualPillar2Contribution': pillar2.fold<int>(
          0,
          (sum, a) => sum + (a.annualBvgContribution ?? 0),
        ),
        'currentPillar3aBalance': pillar3a.fold<int>(
          0,
          (sum, a) => sum + a.currentBalance,
        ),
        'annualPillar3aContribution': pillar3a.fold<int>(
          0,
          (sum, a) => sum + (a.annualContribution ?? 0),
        ),
      },
    );
    return RetirementProjectionDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);
