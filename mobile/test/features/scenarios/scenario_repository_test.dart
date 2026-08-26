import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_repository.dart';

import '../../helpers/fakes.dart';

/// Simulated API client: canned responses by path, records calls.
class _DispatchingApiClient extends FakeApiClient {
  final Map<String, Map<String, dynamic>> responses = {};

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    postCalls.add((path: path, data: data));
    final error = postError;
    if (error != null) throw error;
    return Response<T>(
      requestOptions: RequestOptions(),
      statusCode: 200,
      data: responses[path] as T,
    );
  }
}

const _catchupJson = <String, dynamic>{
  'maxPerYear': 725800,
  'eligibleYears': 1,
  'yearDetails': [
    {'year': 2025, 'maxContribution': 725800, 'actualContribution': 0, 'gap': 725800},
  ],
  'totalCatchupPotential': 725800,
  'currentYearGap': 725800,
  'mustMaxCurrentYearFirst': true,
  'estimatedTaxSavings': 217740,
  'estimatedMarginalRate': 30,
};

const _staggeredJson = <String, dynamic>{
  'strategies': [
    {
      'label': 'lump_sum',
      'years': [
        {'year': 2031, 'amount': 35000000},
      ],
      'totalTax': 2493820,
      'effectiveTaxRate': 7.13,
    },
  ],
  'bestStrategy': 'lump_sum',
  'taxSavingsVsLumpSum': 0,
};

const _propertyJson = <String, dynamic>{
  'maxWithdrawal': 20000000,
  'effectiveWithdrawal': 5000000,
  'capitalAtRetirementWithout': 41851576,
  'capitalAtRetirementWith': 35030613,
  'capitalLostAtRetirement': 6820963,
  'annualPensionWithout': 2511095,
  'annualPensionWith': 2101837,
  'annualPensionLoss': 409258,
  'monthlyPensionLoss': 34105,
};

const _divorceJson = <String, dynamic>{
  'myAccumulatedDuringMarriage': 15000000,
  'spouseAccumulatedDuringMarriage': 12000000,
  'totalMarriageCapital': 27000000,
  'transferAmount': -1500000,
  'capitalAfterDivorce': 18500000,
  'projectedCapitalWithMarriage': 41851576,
  'projectedCapitalAfterDivorce': 39805286,
  'annualPensionWithMarriage': 2511095,
  'annualPensionAfterDivorce': 2388317,
  'annualPensionDifference': 122778,
  'estimatedAvsImpact': 294000,
};

void main() {
  late _DispatchingApiClient api;
  late ScenarioRepository repository;

  setUp(() {
    api = _DispatchingApiClient();
    api.responses['/calculator/3a-catchup'] = _catchupJson;
    api.responses['/calculator/staggered-withdrawal'] = _staggeredJson;
    api.responses['/calculator/property-purchase'] = _propertyJson;
    api.responses['/calculator/divorce-impact'] = _divorceJson;
    repository = ScenarioRepository(api);
  });

  test('catchup3a: POST /calculator/3a-catchup, parsed response', () async {
    final payload = <String, dynamic>{
      'yearsSinceFirstEligible': 3,
      'hasSecondPillar': true,
      'taxableIncome': 9500000,
    };
    final result = await repository.catchup3a(payload);

    expect(api.postCalls.single.path, '/calculator/3a-catchup');
    expect(api.postCalls.single.data, payload);
    expect(result.totalCatchupPotential, 725800);
    expect(result.yearDetails.single.gap, 725800);
  });

  test('staggeredWithdrawal: POST + parsed response', () async {
    final result = await repository.staggeredWithdrawal(<String, dynamic>{});

    expect(api.postCalls.single.path, '/calculator/staggered-withdrawal');
    expect(result.strategies.single.label, 'lump_sum');
    expect(result.bestStrategy, 'lump_sum');
  });

  test('propertyPurchase: POST + parsed response', () async {
    final result = await repository.propertyPurchase(<String, dynamic>{});

    expect(api.postCalls.single.path, '/calculator/property-purchase');
    expect(result.maxWithdrawal, 20000000);
    expect(result.monthlyPensionLoss, 34105);
  });

  test('divorceImpact: POST + parsed response', () async {
    final result = await repository.divorceImpact(<String, dynamic>{});

    expect(api.postCalls.single.path, '/calculator/divorce-impact');
    expect(result.transferAmount, -1500000);
    expect(result.myShare, 13500000);
  });

  test('error propagated (400 EPL, network…): no partial result', () async {
    api.postError = const ApiException(
      'Le retrait minimum EPL est de CHF 20\'000',
      statusCode: 400,
    );

    await expectLater(
      repository.propertyPurchase(<String, dynamic>{}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having(
              (e) => e.message,
              'message',
              'Le retrait minimum EPL est de CHF 20\'000',
            ),
      ),
    );
  });
}
