import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/features/providers/data/provider_repository.dart';

import '../../helpers/fakes.dart';

/// Mock API client: canned responses per path (GET with query,
/// POST), records calls.
class _DispatchingApiClient extends FakeApiClient {
  final Map<String, Object> responses = {};
  final List<({String path, Map<String, dynamic>? query})> getCalls = [];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    getCalls.add((path: path, query: queryParameters));
    final error = getError;
    if (error != null) throw error;
    return Response<T>(
      requestOptions: RequestOptions(),
      statusCode: 200,
      data: responses[path] as T,
    );
  }

  Object? getError;

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

const _providerJson = <String, dynamic>{
  'id': 'p1',
  'slug': 'viac',
  'name': 'VIAC',
  'description': 'Pilier 3a digital',
  'website': 'https://viac.ch',
  'isDigital': true,
  'products': [
    {
      'id': 'pr1',
      'name': 'VIAC Global 100',
      'slug': 'viac-global-100',
      'investmentCategory': 'PASSIVE_INDEX',
      'riskLevel': 'AGGRESSIVE',
      'equityAllocation': 97,
      'sustainableEsg': false,
      'fees': {'terPercent': 0, 'allInFeePercent': 0.44},
    },
  ],
};

const _scoredJson = <String, dynamic>{
  'productId': 'pr1',
  'providerName': 'VIAC',
  'providerSlug': 'viac',
  'productName': 'VIAC Global 100',
  'productSlug': 'viac-global-100',
  'riskLevel': 'AGGRESSIVE',
  'equityAllocation': 97,
  'allInFeePercent': 0.44,
  'sustainableEsg': false,
  'avgReturn3y': 13.43,
  'avgReturn5y': 8.76,
  'score': 88,
};

void main() {
  late _DispatchingApiClient api;
  late ProviderRepository repository;

  setUp(() {
    api = _DispatchingApiClient();
    api.responses['/providers'] = [_providerJson];
    api.responses['/providers/compare'] = [_scoredJson];
    api.responses['/providers/viac'] = _providerJson;
    api.responses['/providers/best-match'] = [_scoredJson];
    repository = ProviderRepository(api);
  });

  test('listProviders: GET /providers, parsed list', () async {
    final providers = await repository.listProviders();

    expect(api.getCalls.single.path, '/providers');
    expect(api.getCalls.single.query, isNull);
    expect(providers.single.name, 'VIAC');
    expect(providers.single.products.single.fees!.allInFeePercent, 0.44);
  });

  test('compareProducts: riskLevel query + combined filters', () async {
    final scored = await repository.compareProducts(
      riskLevel: 'GROWTH',
      sustainableOnly: true,
      maxFeePercent: 1.0,
    );

    final call = api.getCalls.single;
    expect(call.path, '/providers/compare');
    expect(call.query, {
      'riskLevel': 'GROWTH',
      // The backend checks for the string 'true' (Zod transform).
      'sustainableOnly': 'true',
      'maxFeePercent': 1.0,
    });
    expect(scored.single.score, 88);
  });

  test('compareProducts without filters: no query parameters', () async {
    await repository.compareProducts();

    expect(api.getCalls.single.query, isEmpty);
  });

  test('getProvider: GET /providers/:slug, parsed detail', () async {
    final provider = await repository.getProvider('viac');

    expect(api.getCalls.single.path, '/providers/viac');
    expect(provider!.slug, 'viac');
  });

  test('getProvider: 404 → null (not-found state, not an error)', () async {
    api.getError = const ApiException(
      'Prestataire non trouvé',
      statusCode: 404,
    );

    expect(await repository.getProvider('inconnu'), isNull);
  });

  test('getProvider: other error propagated', () async {
    api.getError = const NetworkException();

    await expectLater(
      repository.getProvider('viac'),
      throwsA(isA<NetworkException>()),
    );
  });

  test('bestMatch: POST /providers/best-match, exact body', () async {
    final results = await repository.bestMatch(
      riskLevel: 'BALANCED',
      preferEsg: true,
      maxFeePercent: 0.8,
    );

    expect(api.postCalls.single.path, '/providers/best-match');
    expect(api.postCalls.single.data, {
      'riskLevel': 'BALANCED',
      'preferEsg': true,
      'maxFeePercent': 0.8,
    });
    expect(results.single.productName, 'VIAC Global 100');
  });

  test(
    'bestMatch without a fee cap: maxFeePercent omitted from body',
    () async {
      await repository.bestMatch(riskLevel: 'GROWTH', preferEsg: false);

      expect(api.postCalls.single.data, {
        'riskLevel': 'GROWTH',
        'preferEsg': false,
      });
    },
  );

  test('network error propagated (no offline fallback)', () async {
    api.getError = const NetworkException();

    await expectLater(
      repository.listProviders(),
      throwsA(isA<NetworkException>()),
    );
  });
}
