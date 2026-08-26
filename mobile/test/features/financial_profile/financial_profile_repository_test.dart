import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_client.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';

/// Simulated API client: canned responses per method + path, calls
/// recorded to verify payloads (method, path, body).
class FakeProfileApiClient extends ApiClient {
  FakeProfileApiClient()
    : super(
        baseUrl: 'http://localhost:0',
        getAccessToken: () => null,
        refreshAccessToken: () async => null,
        onAuthExpired: () async {},
        getLanguage: () => 'fr',
      );

  /// Path → JSON (Map/List) or [Exception] to throw, per method.
  final Map<String, Object> getResponses = {};
  final Map<String, Object> putResponses = {};
  final Map<String, Object> postResponses = {};
  final Map<String, Object> patchResponses = {};
  final Set<String> deleteResponses = {};

  final List<String> getCalls = [];
  final List<Map<String, dynamic>?> getQueryParameters = [];
  final List<({String path, Object? data})> putCalls = [];
  final List<({String path, Object? data})> postCalls = [];
  final List<({String path, Object? data})> patchCalls = [];
  final List<String> deleteCalls = [];

  Response<T> _respond<T>(Object? stub, {int successCode = 200}) {
    if (stub is Exception) throw stub;
    if (stub == null) throw StateError('Aucun stub pour cet appel');
    return Response<T>(
      requestOptions: RequestOptions(),
      data: stub as T,
      statusCode: successCode,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    getCalls.add(path);
    getQueryParameters.add(queryParameters);
    return _respond(getResponses[path]);
  }

  @override
  Future<Response<T>> put<T>(String path, {Object? data}) async {
    putCalls.add((path: path, data: data));
    return _respond(putResponses[path], successCode: 201);
  }

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    postCalls.add((path: path, data: data));
    return _respond(postResponses[path], successCode: 201);
  }

  @override
  Future<Response<T>> patch<T>(String path, {Object? data}) async {
    patchCalls.add((path: path, data: data));
    return _respond(patchResponses[path]);
  }

  @override
  Future<Response<T>> delete<T>(String path) async {
    deleteCalls.add(path);
    if (!deleteResponses.contains(path)) {
      throw StateError('Aucun stub pour DELETE $path');
    }
    return Response<T>(requestOptions: RequestOptions(), statusCode: 204);
  }
}

Map<String, dynamic> _userJson() => {
  'id': 'u-1',
  'email': 'user@example.ch',
  'canton': 'VD',
  'municipality': 'Lausanne',
  'birthYear': 1991,
  'replacementRateGoal': 75,
  'createdAt': '2026-01-01T00:00:00.000Z',
};

Map<String, dynamic> _profileJson() => {
  'id': 'fp-1',
  'userId': 'u-1',
  'employmentStatus': 'EMPLOYED',
  'maritalStatus': 'REGISTERED_PARTNERSHIP',
  'numberOfChildren': 2,
  'grossAnnualIncome': 9500000,
  'netAnnualIncome': 7800000,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
};

void main() {
  late FakeProfileApiClient api;
  late FinancialProfileRepository repository;

  setUp(() {
    api = FakeProfileApiClient();
    repository = FinancialProfileRepository(
      api,
      now: () => DateTime(2026, 8, 5),
    );
  });

  group('loadBase', () {
    test('user + existing profile: everything is parsed', () async {
      api.getResponses.addAll({
        '/users/me': _userJson(),
        '/financial-profile': _profileJson(),
      });

      final data = await repository.loadBase();

      expect(data.userId, 'u-1');
      expect(data.email, 'user@example.ch');
      expect(data.canton, 'VD');
      expect(data.municipality, 'Lausanne');
      expect(data.birthYear, 1991);
      expect(data.replacementRateGoal, 75);
      expect(data.hasProfile, isTrue);
      final profile = data.profile!;
      expect(profile.employmentStatus, 'EMPLOYED');
      expect(profile.maritalStatus, 'REGISTERED_PARTNERSHIP');
      expect(profile.numberOfChildren, 2);
      expect(profile.grossAnnualIncome, 9500000);
      expect(profile.netAnnualIncome, 7800000);
      expect(data.loadedAt, DateTime(2026, 8, 5));
    });

    test(
      'initial 404 on /financial-profile → profile null (creation mode)',
      () async {
        api.getResponses.addAll({
          '/users/me': _userJson(),
          '/financial-profile': const ApiException(
            'Profil non trouvé',
            statusCode: 404,
          ),
        });

        final data = await repository.loadBase();

        expect(data.hasProfile, isFalse);
        expect(data.profile, isNull);
        // The user data remains available.
        expect(data.canton, 'VD');
      },
    );

    test('500 on /financial-profile → propagated (not a 404)', () async {
      api.getResponses.addAll({
        '/users/me': _userJson(),
        '/financial-profile': const ApiException(
          'Une erreur interne est survenue',
          statusCode: 500,
        ),
      });

      expect(
        repository.loadBase(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('loadAggregate (I9)', () {
    test(
      'base + accounts in a single composed call, 404 profile tolerated',
      () async {
        api.getResponses.addAll({
          '/users/me': _userJson(),
          '/financial-profile': const ApiException(
            'Profil non trouvé',
            statusCode: 404,
          ),
          '/financial-profile/pillar2': [
            {'id': 'p2-1', 'currentCapital': 1500000},
          ],
          '/financial-profile/pillar3a': [
            {
              'id': 'p3-1',
              'providerName': 'VIAC',
              'accountType': 'BANK',
              'currentBalance': 1000000,
            },
          ],
        });

        final aggregate = await repository.loadAggregate();

        // All 4 endpoints in the profile scope are covered.
        expect(
          api.getCalls,
          containsAll([
            '/users/me',
            '/financial-profile',
            '/financial-profile/pillar2',
            '/financial-profile/pillar3a',
          ]),
        );
        // Initial 404: profile null, normal state — the rest is loaded.
        expect(aggregate.base.profile, isNull);
        expect(aggregate.base.canton, 'VD');
        expect(aggregate.pillar2Accounts.single.currentCapital, 1500000);
        expect(aggregate.pillar3aAccounts.single.providerName, 'VIAC');
      },
    );
  });

  group('updateUser', () {
    test('PATCH /users/me: all provided fields are sent', () async {
      api.patchResponses['/users/me'] = _userJson();

      await repository.updateUser(
        canton: 'ZH',
        birthYear: 1988,
        replacementRateGoal: 80,
      );

      expect(api.patchCalls, hasLength(1));
      final call = api.patchCalls.single;
      expect(call.path, '/users/me');
      expect(call.data, {
        'canton': 'ZH',
        'birthYear': 1988,
        'replacementRateGoal': 80,
      });
    });

    test('null fields are omitted from the body (Zod rejects null)', () async {
      api.patchResponses['/users/me'] = _userJson();

      await repository.updateUser(replacementRateGoal: 65);

      final body = api.patchCalls.single.data! as Map<String, dynamic>;
      expect(body, {'replacementRateGoal': 65});
      expect(body.containsKey('canton'), isFalse);
      expect(body.containsKey('birthYear'), isFalse);
    });

    test('municipality provided → included in the body', () async {
      api.patchResponses['/users/me'] = _userJson();

      await repository.updateUser(municipality: 'Lausanne');

      final body = api.patchCalls.single.data! as Map<String, dynamic>;
      expect(body, {'municipality': 'Lausanne'});
    });

    test('clearMunicipality → explicit null sent (clearing accepted '
        'by the backend)', () async {
      api.patchResponses['/users/me'] = _userJson();

      await repository.updateUser(clearMunicipality: true);

      final body = api.patchCalls.single.data! as Map<String, dynamic>;
      expect(body.containsKey('municipality'), isTrue);
      expect(body['municipality'], isNull);
    });
  });

  group('fetchMunicipalities', () {
    test(
      'GET /calculator/municipalities: list parsed, canton in query',
      () async {
        api.getResponses['/calculator/municipalities'] = [
          {'name': 'Adliswil', 'multiplier': 104},
          {'name': 'Zurich', 'multiplier': 119},
        ];

        final municipalities = await repository.fetchMunicipalities('ZH');

        expect(api.getCalls, ['/calculator/municipalities']);
        expect(api.getQueryParameters.single, {'canton': 'ZH'});
        expect(municipalities, hasLength(2));
        expect(municipalities.first.name, 'Adliswil');
        expect(municipalities.first.multiplier, 104.0);
        expect(municipalities.last.name, 'Zurich');
        expect(municipalities.last.multiplier, 119.0);
      },
    );

    test('canton with no covered municipality → empty list', () async {
      api.getResponses['/calculator/municipalities'] = <dynamic>[];

      expect(await repository.fetchMunicipalities('JU'), isEmpty);
    });

    // I7 (full review 2026-08): in-memory cache per canton, 24h TTL.
    group('cache', () {
      /// Repository with a controllable clock: [now] advances time.
      (FinancialProfileRepository, void Function(Duration)) clockedRepo(
        DateTime start,
      ) {
        var now = start;
        return (
          FinancialProfileRepository(api, now: () => now),
          (Duration d) => now = now.add(d),
        );
      }

      test('2nd call same canton: served from cache, no 2nd GET', () async {
        final (repo, _) = clockedRepo(DateTime(2026, 8, 5));
        api.getResponses['/calculator/municipalities'] = [
          {'name': 'Lausanne', 'multiplier': 79.5},
        ];

        final first = await repo.fetchMunicipalities('VD');
        // The stub is cleared: a 2nd GET would throw (no stub).
        api.getResponses.clear();
        final second = await repo.fetchMunicipalities('VD');

        expect(api.getCalls, ['/calculator/municipalities']);
        expect(second.single.name, first.single.name);
      });

      test('different canton: dedicated request (cache per canton)', () async {
        final (repo, _) = clockedRepo(DateTime(2026, 8, 5));
        api.getResponses['/calculator/municipalities'] = <dynamic>[];

        await repo.fetchMunicipalities('VD');
        await repo.fetchMunicipalities('ZH');
        await repo.fetchMunicipalities('VD'); // still cached

        expect(api.getCalls, hasLength(2));
        expect(api.getQueryParameters, [
          {'canton': 'VD'},
          {'canton': 'ZH'},
        ]);
      });

      test('TTL 24h exceeded: network refetch', () async {
        final (repo, advance) = clockedRepo(DateTime(2026, 8, 5));
        api.getResponses['/calculator/municipalities'] = [
          {'name': 'Lausanne', 'multiplier': 79.5},
        ];

        await repo.fetchMunicipalities('VD');
        advance(const Duration(hours: 23));
        await repo.fetchMunicipalities('VD'); // still fresh
        advance(const Duration(hours: 2)); // 25h > TTL
        await repo.fetchMunicipalities('VD'); // expired → GET

        expect(api.getCalls, hasLength(2));
      });

      test('network error: nothing is cached, the retry refetches', () async {
        final (repo, _) = clockedRepo(DateTime(2026, 8, 5));
        api.getResponses['/calculator/municipalities'] = const NetworkException();

        await expectLater(repo.fetchMunicipalities('VD'), throwsA(anything));

        api.getResponses['/calculator/municipalities'] = [
          {'name': 'Lausanne', 'multiplier': 79.5},
        ];
        expect((await repo.fetchMunicipalities('VD')).single.name, 'Lausanne');
        expect(api.getCalls, hasLength(2));
      });
    });
  });

  group('upsertProfile', () {
    test('PUT /financial-profile: full body in centimes', () async {
      api.putResponses['/financial-profile'] = _profileJson();

      final profile = await repository.upsertProfile(
        employmentStatus: 'SELF_EMPLOYED',
        maritalStatus: 'REGISTERED_PARTNERSHIP',
        numberOfChildren: 2,
        grossAnnualIncome: 9500000,
        netAnnualIncome: 7800000,
      );

      final call = api.putCalls.single;
      expect(call.path, '/financial-profile');
      expect(call.data, {
        'employmentStatus': 'SELF_EMPLOYED',
        'maritalStatus': 'REGISTERED_PARTNERSHIP',
        'numberOfChildren': 2,
        'grossAnnualIncome': 9500000,
        'netAnnualIncome': 7800000,
      });
      expect(profile.maritalStatus, 'REGISTERED_PARTNERSHIP');
    });

    test('net income null → omitted from the body', () async {
      api.putResponses['/financial-profile'] = _profileJson();

      await repository.upsertProfile(
        employmentStatus: 'EMPLOYED',
        maritalStatus: 'SINGLE',
        numberOfChildren: 0,
        grossAnnualIncome: 8500000,
      );

      final body = api.putCalls.single.data! as Map<String, dynamic>;
      expect(body.containsKey('netAnnualIncome'), isFalse);
    });
  });

  group('pillar2', () {
    final accountJson = {
      'id': 'p2-1',
      'providerName': 'Caisse ACME',
      'currentCapital': 1500000,
      'projectedCapitalAtRetirement': 50000000,
      'conversionRate': 6.0,
      'insuredSalary': 8000000,
      'coordinationDeduction': 2646000,
      'annualBvgContribution': 400000,
      'annualSupraContribution': 100000,
      'isVestedBenefits': false,
    };

    test('GET: full list parsed (all schema fields)', () async {
      api.getResponses['/financial-profile/pillar2'] = [accountJson];

      final accounts = await repository.fetchPillar2Accounts();

      expect(accounts, hasLength(1));
      final account = accounts.single;
      expect(account.providerName, 'Caisse ACME');
      expect(account.currentCapital, 1500000);
      expect(account.projectedCapitalAtRetirement, 50000000);
      expect(account.conversionRate, 6.0);
      expect(account.insuredSalary, 8000000);
      expect(account.coordinationDeduction, 2646000);
      expect(account.annualBvgContribution, 400000);
      expect(account.annualSupraContribution, 100000);
      expect(account.isVestedBenefits, isFalse);
    });

    test('POST: creation with entered fields, optional ones omitted', () async {
      api.postResponses['/financial-profile/pillar2'] = accountJson;

      await repository.createPillar2Account(
        currentCapital: 1500000,
        isVestedBenefits: false,
      );

      final call = api.postCalls.single;
      expect(call.path, '/financial-profile/pillar2');
      expect(call.data, {
        'currentCapital': 1500000,
        'isVestedBenefits': false,
      });
    });

    test('POST: advanced fields included in the body when entered', () async {
      api.postResponses['/financial-profile/pillar2'] = accountJson;

      await repository.createPillar2Account(
        currentCapital: 1500000,
        insuredSalary: 8000000,
        coordinationDeduction: 2646000,
        annualSupraContribution: 100000,
        isVestedBenefits: false,
      );

      final call = api.postCalls.single;
      expect(call.data, {
        'currentCapital': 1500000,
        'insuredSalary': 8000000,
        'coordinationDeduction': 2646000,
        'annualSupraContribution': 100000,
        'isVestedBenefits': false,
      });
    });

    test('PATCH: advanced fields modifiable alone', () async {
      api.patchResponses['/financial-profile/pillar2/p2-1'] = accountJson;

      await repository.updatePillar2Account(
        'p2-1',
        insuredSalary: 8500000,
        annualSupraContribution: 120000,
      );

      final call = api.patchCalls.single;
      expect(call.path, '/financial-profile/pillar2/p2-1');
      expect(call.data, {
        'insuredSalary': 8500000,
        'annualSupraContribution': 120000,
      });
    });

    test('PATCH: partial update on /:id', () async {
      api.patchResponses['/financial-profile/pillar2/p2-1'] = accountJson;

      await repository.updatePillar2Account(
        'p2-1',
        currentCapital: 2000000,
        conversionRate: 5.2,
      );

      final call = api.patchCalls.single;
      expect(call.path, '/financial-profile/pillar2/p2-1');
      expect(call.data, {'currentCapital': 2000000, 'conversionRate': 5.2});
    });

    test('DELETE: /:id', () async {
      api.deleteResponses.add('/financial-profile/pillar2/p2-1');

      await repository.deletePillar2Account('p2-1');

      expect(api.deleteCalls, ['/financial-profile/pillar2/p2-1']);
    });
  });

  group('pillar3a', () {
    final accountJson = {
      'id': 'p3-1',
      'providerName': 'VIAC',
      'accountType': 'BANK',
      'currentBalance': 1000000,
      'annualContribution': 725800,
      'interestRateOrReturn': 2.5,
    };

    test('GET: list parsed (account type, contribution, rate)', () async {
      api.getResponses['/financial-profile/pillar3a'] = [accountJson];

      final accounts = await repository.fetchPillar3aAccounts();

      expect(accounts, hasLength(1));
      final account = accounts.single;
      expect(account.providerName, 'VIAC');
      expect(account.accountType, 'BANK');
      expect(account.currentBalance, 1000000);
      expect(account.annualContribution, 725800);
      expect(account.interestRateOrReturn, 2.5);
    });

    test('POST: creation with type INSURANCE', () async {
      api.postResponses['/financial-profile/pillar3a'] = {
        ...accountJson,
        'accountType': 'INSURANCE',
      };

      await repository.createPillar3aAccount(
        providerName: 'Swiss Life',
        accountType: 'INSURANCE',
        currentBalance: 500000,
        annualContribution: 300000,
        interestRateOrReturn: 1.0,
      );

      final call = api.postCalls.single;
      expect(call.path, '/financial-profile/pillar3a');
      expect(call.data, {
        'providerName': 'Swiss Life',
        'accountType': 'INSURANCE',
        'currentBalance': 500000,
        'annualContribution': 300000,
        'interestRateOrReturn': 1.0,
      });
    });

    test('PATCH: partial update on /:id', () async {
      api.patchResponses['/financial-profile/pillar3a/p3-1'] = accountJson;

      await repository.updatePillar3aAccount('p3-1', currentBalance: 1100000);

      final call = api.patchCalls.single;
      expect(call.path, '/financial-profile/pillar3a/p3-1');
      expect(call.data, {'currentBalance': 1100000});
    });

    test('DELETE: /:id', () async {
      api.deleteResponses.add('/financial-profile/pillar3a/p3-1');

      await repository.deletePillar3aAccount('p3-1');

      expect(api.deleteCalls, ['/financial-profile/pillar3a/p3-1']);
    });
  });
}
