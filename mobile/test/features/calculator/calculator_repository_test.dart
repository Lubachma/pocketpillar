import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/features/calculator/data/calculator_payloads.dart';
import 'package:pocketpillar/features/calculator/data/calculator_repository.dart';

import '../../helpers/fakes.dart';

/// Mock API client: canned responses by path, records the calls.
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

const _retirementJson = {
  'yearsToRetirement': 30,
  'projectedPillar2Capital': 50000000,
  'projectedPillar3aBalance': 8000000,
  'annualPillar2Pension': 3000000,
  'estimatedAnnualAvsPension': 2352000,
  'pillar3aAsLumpSum': 8000000,
  'totalAnnualRetirementIncome': 5352000,
  'replacementRate': 63.0,
  'yearByYearProjection': [
    {
      'year': 2027,
      'age': 36,
      'pillar2Capital': 2100000,
      'pillar3aBalance': 1758000,
      'totalCapital': 3858000,
    },
  ],
};

const _taxSavingsJson = {
  'federalTaxSaving': 85000,
  'cantonalTaxSaving': 90000,
  'communalTaxSaving': 45000,
  'totalTaxSaving': 220000,
  'effectiveReturnRate': 30.31,
  'maxContribution': 725800,
  'isAtMax': true,
};

const _lppGapJson = {
  'coordinatedSalary': 6800000,
  'bvgMinContribution': 612000,
  'contributionGap': 0,
  'projectedBvgMinCapital': 42000000,
  'projectedActualCapital': 45000000,
  'capitalGap': 0,
  'projectedMinAnnualPension': 2520000,
  'projectedActualAnnualPension': 2700000,
  'pensionGap': 0,
};

const _input = GuidedCalculatorInput(
  age: 35,
  canton: 'VD',
  maritalStatus: 'SINGLE',
  grossAnnualIncome: 9500000,
  pillar2Capital: 2000000,
  pillar2Contribution: 500000,
  hasPillar3a: true,
  pillar3aBalance: 1000000,
);

void main() {
  late _DispatchingApiClient api;
  late CalculatorRepository repository;

  setUp(() {
    api = _DispatchingApiClient();
    api.responses['/calculator/retirement'] = _retirementJson;
    api.responses['/calculator/tax-savings'] = _taxSavingsJson;
    api.responses['/calculator/lpp-gap'] = _lppGapJson;
    repository = CalculatorRepository(api);
  });

  test('age ≥ 25: all 3 endpoints are called, results parsed', () async {
    final results = await repository.calculateAll(_input);

    expect(api.postCalls.map((c) => c.path), [
      '/calculator/retirement',
      '/calculator/tax-savings',
      '/calculator/lpp-gap',
    ]);

    // Payloads in centimes (spot checks).
    final retirementPayload = api.postCalls[0].data! as Map<String, dynamic>;
    expect(retirementPayload['currentAge'], 35);
    expect(retirementPayload['grossAnnualIncome'], 9500000);
    final lppPayload = api.postCalls[2].data! as Map<String, dynamic>;
    expect(lppPayload['currentBvgCapital'], 2000000);

    expect(results.retirement.replacementRate, 63.0);
    expect(results.retirement.yearByYearProjection, hasLength(1));
    expect(results.taxSavings.totalTaxSaving, 220000);
    expect(results.lppGap, isNotNull);
    expect(results.lppGap!.coordinatedSalary, 6800000);
  });

  test('age < 25: lpp-gap omitted, null result', () async {
    final young = GuidedCalculatorInput(
      age: 20,
      canton: _input.canton,
      maritalStatus: _input.maritalStatus,
      grossAnnualIncome: _input.grossAnnualIncome,
      pillar2Capital: 0,
      pillar2Contribution: 0,
      hasPillar3a: false,
      pillar3aBalance: 0,
    );

    final results = await repository.calculateAll(young);

    expect(api.postCalls.map((c) => c.path), [
      '/calculator/retirement',
      '/calculator/tax-savings',
    ]);
    expect(results.lppGap, isNull);
  });

  test('error propagated (no partial result)', () async {
    api.postError = const NetworkException();

    await expectLater(
      repository.calculateAll(_input),
      throwsA(isA<NetworkException>()),
    );
  });
}
