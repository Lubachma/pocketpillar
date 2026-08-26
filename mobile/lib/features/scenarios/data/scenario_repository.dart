import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'scenario_dtos.dart';

/// Scenarios repository — `POST /calculator/*` endpoints from the
/// contract (§7). The backend is the single source of truth (phase 0
/// architecture decision): iOS's inline calculations (hardcoded caps,
/// simplified 6/8/10% withdrawal scale, buggy EPL formula
/// `max(x/2, x/2)`) are not ported over.
class ScenarioRepository {
  ScenarioRepository(this._api);

  final ApiClient _api;

  /// 3a catch-up (2025 reform). Every error is propagated: the screen
  /// shows the error card with retry.
  Future<Catchup3aResultDto> catchup3a(Map<String, dynamic> payload) async {
    final response = await _api.post('/calculator/3a-catchup', data: payload);
    return Catchup3aResultDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Optimization of staggered withdrawals (real federal tax scales).
  Future<StaggeredWithdrawalResultDto> staggeredWithdrawal(
    Map<String, dynamic> payload,
  ) async {
    final response = await _api.post(
      '/calculator/staggered-withdrawal',
      data: payload,
    );
    return StaggeredWithdrawalResultDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Impact of an EPL withdrawal. A withdrawal below the legal
  /// minimum (CHF 20'000) throws a 400 [ApiException] whose localized
  /// backend message is displayed as-is by the screen.
  Future<PropertyPurchaseResultDto> propertyPurchase(
    Map<String, dynamic> payload,
  ) async {
    final response = await _api.post(
      '/calculator/property-purchase',
      data: payload,
    );
    return PropertyPurchaseResultDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// LPP split in case of divorce.
  Future<DivorceImpactResultDto> divorceImpact(
    Map<String, dynamic> payload,
  ) async {
    final response = await _api.post(
      '/calculator/divorce-impact',
      data: payload,
    );
    return DivorceImpactResultDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

final scenarioRepositoryProvider = Provider<ScenarioRepository>(
  (ref) => ScenarioRepository(ref.watch(apiClientProvider)),
);
