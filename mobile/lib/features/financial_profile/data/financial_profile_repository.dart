import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/purchases/premium_status.dart';
import 'financial_profile_dtos.dart';
import 'municipality.dart';

/// Financial profile repository — `user` and `financial-profile`
/// endpoints from the contract (`docs/api-contract.md` §3/§4/§6).
///
/// - `GET /financial-profile` responds **404** while the profile
///   doesn't exist yet → [ProfileBaseData.profile] null, form in
///   creation mode. The first `PUT` creates the resource (201),
///   subsequent ones update it (200) — the client always sends the
///   form's full body.
/// - Null fields are **omitted** from bodies: the backend's Zod
///   `.optional()` schema rejects explicit `null`s. Consequence
///   (logged in the journal): a previously set optional field can't be
///   "cleared" via the API. Exception: `municipality` in
///   `PATCH /users/me`, where an explicit `null` clears the saved
///   municipality (see [updateUser]).
class FinancialProfileRepository {
  FinancialProfileRepository(this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ApiClient _api;

  /// Injectable clock (load timestamp, municipalities cache) — tests.
  final DateTime Function() _now;

  /// In-memory cache of municipalities per canton (I7, full review
  /// 2026-08): the sheet used to re-download them on every open. TTL
  /// 24h — municipal multipliers only change between tax years.
  final Map<String, ({List<MunicipalityInfo> items, DateTime fetchedAt})>
  _municipalitiesCache = {};

  /// Validity duration of the municipalities cache.
  static const Duration municipalitiesCacheTtl = Duration(hours: 24);

  /// User + financial profile in parallel; a 404 on the profile is a
  /// normal state (first access), not an error.
  Future<ProfileBaseData> loadBase() async {
    final results = await Future.wait([_fetchUser(), fetchProfileOrNull()]);
    final user = results[0] as _UserMe;
    return ProfileBaseData(
      userId: user.id,
      email: user.email,
      canton: user.canton,
      municipality: user.municipality,
      birthYear: user.birthYear,
      replacementRateGoal: user.replacementRateGoal,
      premium: user.premium,
      profile: results[1] as FinancialProfileDto?,
      loadedAt: _now(),
    );
  }

  /// Full aggregate (I9): [loadBase] + LPP/3a accounts. Consumed via
  /// `profileAggregateProvider` — called directly, it would refetch on
  /// every call (no cache here, the provider is the source of truth).
  Future<ProfileAggregate> loadAggregate() async {
    final base = await loadBase();
    final accounts = await Future.wait([
      fetchPillar2Accounts(),
      fetchPillar3aAccounts(),
    ]);
    return ProfileAggregate(
      base: base,
      pillar2Accounts: accounts[0] as List<Pillar2AccountDto>,
      pillar3aAccounts: accounts[1] as List<Pillar3aAccountDto>,
    );
  }

  /// `PATCH /users/me` — only non-null fields are sent, except for the
  /// municipality: [clearMunicipality] sends an **explicit** `null`
  /// (accepted by the backend) to clear the saved value — necessary
  /// because the "omit null" convention would otherwise make clearing
  /// it impossible.
  Future<void> updateUser({
    String? canton,
    int? birthYear,
    int? replacementRateGoal,
    String? municipality,
    bool clearMunicipality = false,
  }) async {
    await _api.patch(
      '/users/me',
      data: <String, dynamic>{
        'canton': ?canton,
        'birthYear': ?birthYear,
        'replacementRateGoal': ?replacementRateGoal,
        if (clearMunicipality)
          'municipality': null
        else
          'municipality': ?municipality,
      },
    );
  }

  /// `GET /calculator/municipalities?canton=…` (public endpoint) —
  /// covered municipalities of the canton, sorted alphabetically. Empty
  /// list when the canton has no covered municipality (the calculator
  /// then uses the cantonal average).
  ///
  /// Response served from the in-memory cache per canton as long as
  /// it's younger than [municipalitiesCacheTtl] (I7); only successes
  /// are cached.
  Future<List<MunicipalityInfo>> fetchMunicipalities(String canton) async {
    final cached = _municipalitiesCache[canton];
    if (cached != null &&
        _now().difference(cached.fetchedAt) < municipalitiesCacheTtl) {
      return cached.items;
    }
    final response = await _api.get(
      '/calculator/municipalities',
      queryParameters: {'canton': canton},
    );
    final items = [
      for (final item in response.data as List<dynamic>)
        MunicipalityInfo.fromJson(item as Map<String, dynamic>),
    ];
    _municipalitiesCache[canton] = (items: items, fetchedAt: _now());
    return items;
  }

  /// `PUT /financial-profile` — creates (201) or updates (200) the
  /// profile. Amounts in **centimes**.
  Future<FinancialProfileDto> upsertProfile({
    required String employmentStatus,
    required String maritalStatus,
    required int numberOfChildren,
    required int grossAnnualIncome,
    int? netAnnualIncome,
  }) async {
    final response = await _api.put(
      '/financial-profile',
      data: <String, dynamic>{
        'employmentStatus': employmentStatus,
        'maritalStatus': maritalStatus,
        'numberOfChildren': numberOfChildren,
        'grossAnnualIncome': grossAnnualIncome,
        'netAnnualIncome': ?netAnnualIncome,
      },
    );
    return FinancialProfileDto.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Pillar 2 (1:N) ────────────────────────────────────────────────

  Future<List<Pillar2AccountDto>> fetchPillar2Accounts() async {
    final response = await _api.get('/financial-profile/pillar2');
    return [
      for (final item in response.data as List<dynamic>)
        Pillar2AccountDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// `POST /financial-profile/pillar2` (201). Amounts in centimes.
  Future<Pillar2AccountDto> createPillar2Account({
    String? providerName,
    required int currentCapital,
    double? conversionRate,
    int? insuredSalary,
    int? coordinationDeduction,
    int? annualBvgContribution,
    int? annualSupraContribution,
    required bool isVestedBenefits,
  }) async {
    final response = await _api.post(
      '/financial-profile/pillar2',
      data: <String, dynamic>{
        'providerName': ?providerName,
        'currentCapital': currentCapital,
        'conversionRate': ?conversionRate,
        'insuredSalary': ?insuredSalary,
        'coordinationDeduction': ?coordinationDeduction,
        'annualBvgContribution': ?annualBvgContribution,
        'annualSupraContribution': ?annualSupraContribution,
        'isVestedBenefits': isVestedBenefits,
      },
    );
    return Pillar2AccountDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PATCH /financial-profile/pillar2/:id` — partial, null fields omitted.
  Future<Pillar2AccountDto> updatePillar2Account(
    String id, {
    String? providerName,
    int? currentCapital,
    double? conversionRate,
    int? insuredSalary,
    int? coordinationDeduction,
    int? annualBvgContribution,
    int? annualSupraContribution,
    bool? isVestedBenefits,
  }) async {
    final response = await _api.patch(
      '/financial-profile/pillar2/$id',
      data: <String, dynamic>{
        'providerName': ?providerName,
        'currentCapital': ?currentCapital,
        'conversionRate': ?conversionRate,
        'insuredSalary': ?insuredSalary,
        'coordinationDeduction': ?coordinationDeduction,
        'annualBvgContribution': ?annualBvgContribution,
        'annualSupraContribution': ?annualSupraContribution,
        'isVestedBenefits': ?isVestedBenefits,
      },
    );
    return Pillar2AccountDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /financial-profile/pillar2/:id` (204).
  Future<void> deletePillar2Account(String id) async {
    await _api.delete('/financial-profile/pillar2/$id');
  }

  // ─── Pillar 3a (1:N) ───────────────────────────────────────────────

  Future<List<Pillar3aAccountDto>> fetchPillar3aAccounts() async {
    final response = await _api.get('/financial-profile/pillar3a');
    return [
      for (final item in response.data as List<dynamic>)
        Pillar3aAccountDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// `POST /financial-profile/pillar3a` (201). Amounts in centimes.
  Future<Pillar3aAccountDto> createPillar3aAccount({
    required String providerName,
    required String accountType,
    required int currentBalance,
    int? annualContribution,
    double? interestRateOrReturn,
  }) async {
    final response = await _api.post(
      '/financial-profile/pillar3a',
      data: <String, dynamic>{
        'providerName': providerName,
        'accountType': accountType,
        'currentBalance': currentBalance,
        'annualContribution': ?annualContribution,
        'interestRateOrReturn': ?interestRateOrReturn,
      },
    );
    return Pillar3aAccountDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PATCH /financial-profile/pillar3a/:id` — partial, null fields omitted.
  Future<Pillar3aAccountDto> updatePillar3aAccount(
    String id, {
    String? providerName,
    String? accountType,
    int? currentBalance,
    int? annualContribution,
    double? interestRateOrReturn,
  }) async {
    final response = await _api.patch(
      '/financial-profile/pillar3a/$id',
      data: <String, dynamic>{
        'providerName': ?providerName,
        'accountType': ?accountType,
        'currentBalance': ?currentBalance,
        'annualContribution': ?annualContribution,
        'interestRateOrReturn': ?interestRateOrReturn,
      },
    );
    return Pillar3aAccountDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /financial-profile/pillar3a/:id` (204).
  Future<void> deletePillar3aAccount(String id) async {
    await _api.delete('/financial-profile/pillar3a/$id');
  }

  // ─── Internal ──────────────────────────────────────────────────────

  Future<_UserMe> _fetchUser() async {
    final response = await _api.get('/users/me');
    return _UserMe.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /financial-profile` — null on 404 (profile never filled in,
  /// normal state on first access). Public since batch 7 (contextual
  /// 3a reminder: employment status picks the applicable cap).
  Future<FinancialProfileDto?> fetchProfileOrNull() async {
    try {
      final response = await _api.get('/financial-profile');
      return FinancialProfileDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}

/// Response from `GET /users/me` (contract §6) — internal to the
/// repository, exposed via [ProfileBaseData].
class _UserMe {
  const _UserMe({
    required this.id,
    required this.email,
    this.canton,
    this.municipality,
    this.birthYear,
    required this.replacementRateGoal,
    this.premium = PremiumStatus.none,
  });

  final String id;
  final String email;
  final String? canton;
  final String? municipality;
  final int? birthYear;
  final int replacementRateGoal;

  /// `premium` block (contract §11) — [PremiumStatus.none] if absent.
  final PremiumStatus premium;

  factory _UserMe.fromJson(Map<String, dynamic> json) => _UserMe(
    id: json['id'] as String,
    email: json['email'] as String,
    canton: json['canton'] as String?,
    municipality: json['municipality'] as String?,
    birthYear: (json['birthYear'] as num?)?.toInt(),
    replacementRateGoal: (json['replacementRateGoal'] as num?)?.toInt() ?? 70,
    premium: PremiumStatus.fromJson(json['premium']),
  );
}

final financialProfileRepositoryProvider = Provider<FinancialProfileRepository>(
  (ref) => FinancialProfileRepository(ref.watch(apiClientProvider)),
);
