/// The API client's typed exceptions.
///
/// The backend returns every error in the `{ "error": "message" }`
/// format (see `docs/api-contract.md` §2): [ApiException.message]
/// contains that message, already localized by the backend via
/// `Accept-Language`.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  /// Human-readable message (contract's `error` field), or a fallback message.
  final String message;

  /// HTTP status code (400, 403, 404, 409, 422, 429, 500...), null if unknown.
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Expired session or invalid token after a refresh attempt: the user
/// is sent back to sign-in.
class AuthExpiredException extends ApiException {
  const AuthExpiredException([super.message = 'Session expirée'])
    : super(statusCode: 401);
}

/// Premium endpoint called without an active subscription — contract's
/// **402** (§11). [message] is the backend's localized message; the
/// screens that catch it open the paywall instead of showing an error.
class PremiumRequiredException extends ApiException {
  const PremiumRequiredException([super.message = 'Abonnement premium requis'])
    : super(statusCode: 402);
}

/// Transport error (offline, timeout, DNS...): no HTTP response.
class NetworkException implements Exception {
  const NetworkException([this.message = 'Erreur réseau']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}
