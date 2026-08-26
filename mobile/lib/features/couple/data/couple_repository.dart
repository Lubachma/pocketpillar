import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'couple_payloads.dart';
import 'couple_result.dart';

/// Couple repository — **a single** `POST /calculator/couple` call (batch 6,
/// dedicated endpoint; before: composed from 2 × `/calculator/retirement`).
/// The backend calculates everything: per-spouse projections, couple AVS
/// cap 150%, married vs unmarried tax estimate and anti-collision
/// coordinated withdrawal plan — no local calculation (backend = source of
/// truth).
class CoupleRepository {
  CoupleRepository(this._api);

  final ApiClient _api;

  /// Runs the couple simulation. Any error (network, 400…) is propagated:
  /// the screen shows the inline error card with retry (no partial
  /// result).
  Future<CoupleResult> simulate({
    required CoupleSpouseInput person1,
    required CoupleSpouseInput person2,
    required String canton,
    String? municipality,
    required String maritalStatus,
  }) async {
    final response = await _api.post(
      '/calculator/couple',
      data: buildCoupleSimulationPayload(
        person1: person1,
        person2: person2,
        canton: canton,
        municipality: municipality,
        maritalStatus: maritalStatus,
      ),
    );

    return CoupleResult.fromJson(response.data as Map<String, dynamic>);
  }
}

final coupleRepositoryProvider = Provider<CoupleRepository>(
  (ref) => CoupleRepository(ref.watch(apiClientProvider)),
);
