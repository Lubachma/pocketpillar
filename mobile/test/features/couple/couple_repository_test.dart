import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/features/couple/data/couple_payloads.dart';
import 'package:pocketpillar/features/couple/data/couple_repository.dart';

import '../../helpers/fakes.dart';
import 'couple_fixtures.dart';

const _person1 = CoupleSpouseInput(
  age: 40,
  grossAnnualIncome: 9500000,
  pillar2Capital: 2000000,
  pillar2Contribution: 500000,
  hasPillar3a: true,
  pillar3aBalance: 1000000,
);

const _person2 = CoupleSpouseInput(
  age: 35,
  grossAnnualIncome: 6000000,
  pillar2Capital: 0,
  pillar2Contribution: 0,
  hasPillar3a: false,
  pillar3aBalance: 0,
);

void main() {
  test(
    'a single POST /calculator/couple, nested payload, parsed response',
    () async {
      final api = _StubApiClient(coupleResponseJson());
      final repository = CoupleRepository(api);

      final result = await repository.simulate(
        person1: _person1,
        person2: _person2,
        canton: 'VD',
        maritalStatus: 'MARRIED',
      );

      expect(api.postCalls, hasLength(1));
      expect(api.postCalls.single.path, '/calculator/couple');

      final payload = api.postCalls.single.data! as Map<String, dynamic>;
      expect(payload['canton'], 'VD');
      expect(payload['maritalStatus'], 'MARRIED');
      final person1 = payload['person1'] as Map<String, dynamic>;
      expect(person1['currentAge'], 40);
      expect(person1['grossAnnualIncome'], 9500000);
      expect(person1['annualPillar3aContribution'], 725800);
      final person2 = payload['person2'] as Map<String, dynamic>;
      expect(person2['currentAge'], 35);
      expect(person2['annualPillar3aContribution'], 0);

      // Parsed response (the server computes everything, including the cap).
      expect(result.combinedTotalAnnualIncome, 9152000);
      expect(result.avsCapApplied, isFalse);
      expect(result.taxEstimate.cheaperStatus, 'CONCUBINAGE');
      expect(result.withdrawalPlan.steps, hasLength(4));
    },
  );

  test('error propagated (no partial result)', () async {
    final api = _StubApiClient(coupleResponseJson())
      ..postError = const NetworkException();
    final repository = CoupleRepository(api);

    await expectLater(
      repository.simulate(
        person1: _person1,
        person2: _person2,
        canton: 'VD',
        maritalStatus: 'MARRIED',
      ),
      throwsA(isA<NetworkException>()),
    );
  });
}

/// API client that returns a fixed response for any POST.
class _StubApiClient extends FakeApiClient {
  _StubApiClient(this._response);

  final Map<String, dynamic> _response;

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    postCalls.add((path: path, data: data));
    final error = postError;
    if (error != null) throw error;
    return Response<T>(
      requestOptions: RequestOptions(),
      statusCode: 200,
      data: _response as T,
    );
  }
}
