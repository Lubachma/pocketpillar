import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_client.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';

/// Fake HTTP adapter: responds according to [handler] and records requests.
///
/// The 401 replay reuses the same [RequestOptions], so we snapshot a copy
/// of the headers at the time of each call.
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;
  final List<Map<String, dynamic>> requestHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requestHeaders.add(Map.of(options.headers));
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, int statusCode) => ResponseBody.fromString(
  jsonEncode(body),
  statusCode,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// API client wired to instrumented fake callbacks.
class _Harness {
  _Harness({required Future<ResponseBody> Function(RequestOptions) handler}) {
    adapter = _MockAdapter(handler);
    client = ApiClient(
      baseUrl: 'http://localhost:3000',
      dio: Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
        ..httpClientAdapter = adapter,
      getAccessToken: () => accessToken,
      refreshAccessToken: () async {
        refreshCalls++;
        // Let concurrent requests pile up on the single-flight.
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (refreshFails) throw Exception('refresh impossible');
        accessToken = 'new-token';
        return accessToken;
      },
      onAuthExpired: () async => authExpiredCalls++,
      getLanguage: () => 'fr',
    );
  }

  late final _MockAdapter adapter;
  late final ApiClient client;
  String? accessToken = 'old-token';
  bool refreshFails = false;
  int refreshCalls = 0;
  int authExpiredCalls = 0;
}

void main() {
  group('ApiClient', () {
    test('(a) parses the { error } format into ApiException', () async {
      final harness = _Harness(
        handler: (options) async =>
            _json({'error': 'Erreur de validation'}, 400),
      );

      await expectLater(
        () => harness.client.get('/financial-profile'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Erreur de validation')
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
      expect(harness.refreshCalls, 0);
      expect(harness.authExpiredCalls, 0);
    });

    test('(b) 401 → refresh OK → replay OK with the new token', () async {
      final harness = _Harness(
        handler: (options) async =>
            options.headers['Authorization'] == 'Bearer new-token'
            ? _json({'status': 'ok'}, 200)
            : _json({'error': 'Jeton expiré'}, 401),
      );

      final response = await harness.client.get('/users/me');

      expect((response.data as Map<String, dynamic>)['status'], 'ok');
      expect(harness.refreshCalls, 1);
      expect(harness.authExpiredCalls, 0);
      expect(harness.adapter.requestHeaders, hasLength(2));
      expect(
        harness.adapter.requestHeaders.first['Authorization'],
        'Bearer old-token',
      );
      expect(
        harness.adapter.requestHeaders.last['Authorization'],
        'Bearer new-token',
      );
    });

    test('(c) 401 → refresh OK → replay 401 → AuthExpiredException', () async {
      final harness = _Harness(
        handler: (options) async => _json({'error': 'Jeton expiré'}, 401),
      );

      await expectLater(
        () => harness.client.get('/users/me'),
        throwsA(isA<AuthExpiredException>()),
      );
      // Only one refresh attempt and one replay: no loop.
      expect(harness.refreshCalls, 1);
      expect(harness.authExpiredCalls, 1);
      expect(harness.adapter.requestHeaders, hasLength(2));
    });

    test('(d) failed refresh → AuthExpiredException without replay', () async {
      final harness = _Harness(
        handler: (options) async => _json({'error': 'Jeton expiré'}, 401),
      )..refreshFails = true;

      await expectLater(
        () => harness.client.get('/users/me'),
        throwsA(isA<AuthExpiredException>()),
      );
      expect(harness.refreshCalls, 1);
      expect(harness.authExpiredCalls, 1);
      expect(harness.adapter.requestHeaders, hasLength(1));
    });

    test('(e) concurrent 401s share a single refresh', () async {
      final harness = _Harness(
        handler: (options) async =>
            options.headers['Authorization'] == 'Bearer new-token'
            ? _json({'ok': true}, 200)
            : _json({'error': 'Jeton expiré'}, 401),
      );

      final responses = await Future.wait([
        harness.client.get('/a'),
        harness.client.get('/b'),
        harness.client.get('/c'),
      ]);

      expect(responses, hasLength(3));
      expect(harness.refreshCalls, 1);
      expect(harness.authExpiredCalls, 0);
      expect(harness.adapter.requestHeaders, hasLength(6));
    });

    test('402 → PremiumRequiredException with the localized message from '
        'the backend (contract §11)', () async {
      final harness = _Harness(
        handler: (options) async =>
            _json({'error': 'Cette fonctionnalité requiert Premium'}, 402),
      );

      await expectLater(
        () => harness.client.get('/recommendations'),
        throwsA(
          isA<PremiumRequiredException>()
              .having(
                (e) => e.message,
                'message',
                'Cette fonctionnalité requiert Premium',
              )
              .having((e) => e.statusCode, 'statusCode', 402),
        ),
      );
      // Not a token problem: no refresh, no sign-out.
      expect(harness.refreshCalls, 0);
      expect(harness.authExpiredCalls, 0);
    });

    test('transport error → NetworkException', () async {
      final harness = _Harness(
        handler: (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'SocketException',
        ),
      );

      await expectLater(
        () => harness.client.get('/health'),
        throwsA(isA<NetworkException>()),
      );
      expect(harness.refreshCalls, 0);
    });
  });
}
