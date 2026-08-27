import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_repository.dart';
import '../auth/supabase_config.dart';
import '../l10n/locale_provider.dart';
import 'api_config.dart';
import 'api_exceptions.dart';

/// HTTP client to the Fastify backend.
///
/// - Attaches the Supabase JWT (`Authorization: Bearer ...`) to every request.
/// - Sends `Accept-Language` (the backend localizes its error messages).
/// - On 401: refreshes the token **once** and replays the request;
///   on failure, signs out and throws [AuthExpiredException].
/// - Normalizes every HTTP error into [ApiException] (the contract's
///   `{ error }` format) and every transport error into [NetworkException].
class ApiClient {
  ApiClient({
    required String baseUrl,
    required String? Function() getAccessToken,
    required Future<String?> Function() refreshAccessToken,
    required Future<void> Function() onAuthExpired,
    required String Function() getLanguage,
    List<Duration> retryDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
    Dio? dio,
    // ignore: prefer_initializing_formals (public parameter, private field)
  }) : _refreshAccessToken = refreshAccessToken,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 20),
               headers: {'Accept': 'application/json'},
             ),
           ) {
    // BEFORE the auth interceptor: dio's `handler.reject` stops the error
    // chain, so the retry must see transport errors first (its replay then
    // re-enters the full chain, auth headers included).
    _dio.interceptors.add(
      ColdStartRetryInterceptor(dio: _dio, delays: retryDelays),
    );
    _dio.interceptors.add(
      _AuthInterceptor(
        dio: _dio,
        getAccessToken: getAccessToken,
        refreshAccessToken: _refreshSingleFlight,
        onAuthExpired: onAuthExpired,
        getLanguage: getLanguage,
      ),
    );
  }

  final Dio _dio;
  final Future<String?> Function() _refreshAccessToken;

  /// Shared in-flight refresh: concurrent 401s wait for the same
  /// refresh instead of each triggering their own (single-flight).
  Future<String?>? _refreshing;

  Future<String?> _refreshSingleFlight() {
    final pending = _refreshing;
    if (pending != null) return pending;
    late final Future<String?> future;
    future = _refreshAccessToken().whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
    _refreshing = future;
    return future;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _guard(() => _dio.get<T>(path, queryParameters: queryParameters));

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _guard(() => _dio.post<T>(path, data: data));

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _guard(() => _dio.put<T>(path, data: data));

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _guard(() => _dio.patch<T>(path, data: data));

  Future<Response<T>> delete<T>(String path) =>
      _guard(() => _dio.delete<T>(path));

  /// Converts [DioException]s into the contract's typed exceptions.
  Future<Response<T>> _guard<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      if (error is NetworkException) throw error;
      throw NetworkException(e.message ?? 'Erreur réseau');
    }
  }

  /// Exposed for special cases (multipart, download) — phase 3.
  Dio get raw => _dio;
}

/// Replays idempotent GETs that failed at the TRANSPORT level (no HTTP
/// response received): the demo API scales to zero and needs a few seconds
/// to boot, which used to surface as "network error" on the very first
/// screen (cold-start follow-up of the practitioner review, 08.2026).
/// HTTP errors (4xx/5xx) and non-GET methods are never replayed.
class ColdStartRetryInterceptor extends Interceptor {
  ColdStartRetryInterceptor({required this.dio, required this.delays});

  final Dio dio;

  /// One entry per replay (e.g. `[2s, 4s]` = up to two replays).
  final List<Duration> delays;

  static const _attemptKey = 'coldStartAttempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    final retriable =
        err.response == null &&
        err.type != DioExceptionType.cancel &&
        options.method.toUpperCase() == 'GET' &&
        attempt < delays.length;
    if (!retriable) return handler.next(err);

    await Future<void>.delayed(delays[attempt]);
    try {
      // The replay re-enters the whole chain (fresh auth header); nested
      // failures come back HERE with the incremented attempt counter.
      final response = await dio.fetch<dynamic>(
        options..extra[_attemptKey] = attempt + 1,
      );
      return handler.resolve(response);
    } on DioException catch (retryError) {
      // Already normalized by the inner chain (auth interceptor).
      return handler.reject(retryError);
    }
  }
}

/// Authentication interceptor and error normalization.
///
/// Simple [Interceptor] (no queue): the `dio.fetch` replay goes through
/// `onRequest`, which sets the fresh token, and the `authRetried` flag
/// guarantees a single refresh attempt per request.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required this.dio,
    required this.getAccessToken,
    required this.refreshAccessToken,
    required this.onAuthExpired,
    required this.getLanguage,
  });

  final Dio dio;
  final String? Function() getAccessToken;
  final Future<String?> Function() refreshAccessToken;
  final Future<void> Function() onAuthExpired;
  final String Function() getLanguage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept-Language'] = getLanguage();
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;

    // No response: transport error.
    if (response == null) {
      return handler.reject(
        err.copyWith(error: NetworkException(err.message ?? 'Erreur réseau')),
      );
    }

    final message = _extractErrorMessage(response);

    // 401 on the original request: a refresh (single-flight) then replay.
    if (response.statusCode == 401 &&
        err.requestOptions.extra['authRetried'] != true) {
      String? newToken;
      try {
        newToken = await refreshAccessToken();
      } on Object {
        // The refresh failed: treated as a dead session.
        newToken = null;
      }
      if (newToken == null) {
        await onAuthExpired();
        return handler.reject(
          err.copyWith(error: AuthExpiredException(message)),
        );
      }
      try {
        // The replay goes back through onRequest, which sets the fresh token.
        final retryResponse = await dio.fetch<dynamic>(
          err.requestOptions..extra['authRetried'] = true,
        );
        return handler.resolve(retryResponse);
      } on DioException catch (retryError) {
        // The replay failed; the error is already normalized by the chain.
        if (retryError.error is AuthExpiredException) await onAuthExpired();
        return handler.reject(retryError);
      }
    }

    // 401 after replay (or without a possible refresh): sign-out is
    // handled by the caller of the replay above.
    if (response.statusCode == 401) {
      return handler.reject(err.copyWith(error: AuthExpiredException(message)));
    }

    // 402: premium endpoint without an active subscription (contract
    // §11) — screens open the paywall instead of showing an error.
    if (response.statusCode == 402) {
      return handler.reject(
        err.copyWith(error: PremiumRequiredException(message)),
      );
    }

    return handler.reject(
      err.copyWith(
        error: ApiException(message, statusCode: response.statusCode),
      ),
    );
  }

  /// Parses the contract's unified error format `{ "error": "..." }`.
  String _extractErrorMessage(Response<dynamic> response) {
    final data = response.data;
    if (data is Map) {
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    return 'Erreur ${response.statusCode ?? 'inconnue'}';
  }
}

/// API client provider, wired to the Supabase session.
final apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.read(authRepositoryProvider);
  return ApiClient(
    baseUrl: ApiConfig.baseUrl,
    getAccessToken: () =>
        SupabaseConfig.clientOrNull?.auth.currentSession?.accessToken,
    // Both "without a session" guards live in AuthRepository: without
    // them, a 401 in dev bypass (no session) triggered a loop
    // refresh → signOut → auth event → refetch → 401...
    refreshAccessToken: auth.refreshAccessToken,
    onAuthExpired: () async {
      // Triggers onAuthStateChange → redirect to /login (no-op without a
      // session: the user is already effectively signed out).
      await auth.signOutIfAuthenticated();
    },
    getLanguage: () => ref.read(localeProvider).languageCode,
  );
});
