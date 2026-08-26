import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import 'provider_dtos.dart';

/// 3a providers repository — public endpoints `GET /providers*` and
/// `POST /providers/best-match` (contract §1, routes verified against
/// `src/modules/provider/provider.routes.ts`).
///
/// iOS's offline catalogue (`OfflineProviderData`) is **not** ported
/// over: the API is the single source of truth (the seed covers the
/// same 12 providers, plus performance history). Every error is
/// propagated: screens show the error state with retry.
class ProviderRepository {
  ProviderRepository(this._api);

  final ApiClient _api;

  /// Full catalogue: active providers + products (with fees, without
  /// performance history).
  Future<List<ProviderDto>> listProviders() async {
    final response = await _api.get('/providers');
    return [
      for (final item in response.data as List<dynamic>)
        ProviderDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Ranking of scored products (`GET /providers/compare`). All
  /// filters are optional and combinable (Zod schema
  /// `compareQuerySchema`); with no filter, every active product is
  /// scored then sorted by descending score.
  Future<List<ScoredProductDto>> compareProducts({
    String? riskLevel,
    bool sustainableOnly = false,
    double? maxFeePercent,
  }) async {
    final response = await _api.get(
      '/providers/compare',
      queryParameters: <String, dynamic>{
        'riskLevel': ?riskLevel,
        // The backend checks the string 'true' (Zod transform).
        if (sustainableOnly) 'sustainableOnly': 'true',
        'maxFeePercent': ?maxFeePercent,
      },
    );
    return [
      for (final item in response.data as List<dynamic>)
        ScoredProductDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Provider detail sheet (`GET /providers/:slug`): products with
  /// detailed fees **and** annual performance history (included only
  /// here). 404 → `null` (unknown slug: the screen shows the "not
  /// found" state, not an error).
  Future<ProviderDto?> getProvider(String slug) async {
    try {
      final response = await _api.get('/providers/$slug');
      return ProviderDto.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Top 3 products based on the profile (`POST /providers/best-match`,
  /// rate limit 30/min). `maxFeePercent` null = no fee filter
  /// (optional schema field).
  Future<List<ScoredProductDto>> bestMatch({
    required String riskLevel,
    required bool preferEsg,
    double? maxFeePercent,
  }) async {
    final response = await _api.post(
      '/providers/best-match',
      data: <String, dynamic>{
        'riskLevel': riskLevel,
        'preferEsg': preferEsg,
        'maxFeePercent': ?maxFeePercent,
      },
    );
    return [
      for (final item in response.data as List<dynamic>)
        ScoredProductDto.fromJson(item as Map<String, dynamic>),
    ];
  }
}

final providerRepositoryProvider = Provider<ProviderRepository>(
  (ref) => ProviderRepository(ref.watch(apiClientProvider)),
);
