import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'calculator_dtos.dart';
import 'calculator_payloads.dart';

/// Aggregated results of the guided flow. [lppGap] is null when age is
/// under [lppGapMinAge] (call skipped — lower bound of the Zod schema).
class CalculatorResults {
  const CalculatorResults({
    required this.retirement,
    required this.taxSavings,
    this.lppGap,
  });

  final RetirementResultDto retirement;
  final TaxSavingsResultDto taxSavings;
  final LppGapResultDto? lppGap;
}

/// Calculator repository — `POST /calculator/*` endpoints from the
/// contract (§7). Unlike iOS (100% local calculations via
/// `OfflineCalculator`), the backend is the single source of truth
/// (phase 0 architecture decision).
class CalculatorRepository {
  CalculatorRepository(this._api);

  final ApiClient _api;

  /// Runs the calculations applicable to the input, in parallel. Any
  /// error (network, 400…) is propagated: the screen shows the error state
  /// with retry (no partial result).
  Future<CalculatorResults> calculateAll(GuidedCalculatorInput input) async {
    final payloads = buildCalculatorPayloads(input);
    final lppGapPayload = payloads.lppGap;

    final responses = await Future.wait([
      _api.post('/calculator/retirement', data: payloads.retirement),
      _api.post('/calculator/tax-savings', data: payloads.taxSavings),
      if (lppGapPayload != null)
        _api.post('/calculator/lpp-gap', data: lppGapPayload),
    ]);

    return CalculatorResults(
      retirement: RetirementResultDto.fromJson(
        responses[0].data as Map<String, dynamic>,
      ),
      taxSavings: TaxSavingsResultDto.fromJson(
        responses[1].data as Map<String, dynamic>,
      ),
      lppGap: responses.length > 2
          ? LppGapResultDto.fromJson(responses[2].data as Map<String, dynamic>)
          : null,
    );
  }
}

final calculatorRepositoryProvider = Provider<CalculatorRepository>(
  (ref) => CalculatorRepository(ref.watch(apiClientProvider)),
);
