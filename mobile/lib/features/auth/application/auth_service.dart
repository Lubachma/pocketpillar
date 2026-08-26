import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/utils/debug_log.dart';

/// The user must confirm their email before they can sign in
/// (Supabase did not return a session on `signUp`).
class EmailConfirmationRequiredException implements Exception {
  const EmailConfirmationRequiredException();
}

/// The backend refuses registration: this email is already linked to
/// another Supabase account (contract 409, no re-linking).
class EmailAlreadyTakenException implements Exception {
  const EmailAlreadyTakenException();
}

/// The user cancelled the Sign in with Apple sheet.
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

/// Authentication flow combining Supabase and the Fastify backend.
///
/// The `AuthRepository` (core) stays a pure Supabase facade; this
/// layer orchestrates the consecutive calls (`signUp` → `POST /auth/register`).
class AuthService {
  AuthService(this._auth, this._api);

  final AuthRepository _auth;
  final ApiClient _api;

  /// Email registration: Supabase `signUp` then backend registration.
  ///
  /// - [EmailConfirmationRequiredException] if Supabase requires email
  ///   confirmation (no session → no JWT to attach).
  /// - [EmailAlreadyTakenException] on backend 409; the fresh Supabase
  ///   session is then closed to avoid leaving a half-created account.
  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signUp(email: email, password: password);
    final identity = result.identity;
    if (identity == null) throw const EmailConfirmationRequiredException();
    await _registerOnBackend(identity, fallbackEmail: email);
  }

  /// Sign in with Apple (iOS) then best-effort backend upsert.
  ///
  /// Throws [AuthCancelledException] if the user closes the Apple sheet.
  Future<void> signInWithApple() async {
    final AuthIdentity identity;
    try {
      identity = await _auth.signInWithApple();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
    }
    // iOS parity: non-blocking, the user is already authenticated.
    try {
      await _registerOnBackend(identity);
    } on Exception catch (e) {
      debugLog('Register backend après Sign in with Apple ignoré : $e');
    }
  }

  /// `POST /auth/register` — upsert `{ email, supabaseId }` (contract §6).
  ///
  /// The JWT is attached by the dio client's interceptor. The email kept by
  /// the backend is the one from the verified token, never the one from the body.
  Future<void> _registerOnBackend(
    AuthIdentity identity, {
    String? fallbackEmail,
  }) async {
    try {
      await _api.post<void>(
        '/auth/register',
        data: <String, dynamic>{
          'email': identity.email ?? fallbackEmail ?? '',
          'supabaseId': identity.userId,
        },
      );
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        await _auth.signOut();
        throw const EmailAlreadyTakenException();
      }
      rethrow;
    }
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) =>
      AuthService(ref.watch(authRepositoryProvider), ref.watch(apiClientProvider)),
);

/// True during the whole registration flow (Supabase `signUp` +
/// `POST /auth/register`).
///
/// The router checks it to **hold back** its redirect: the session is
/// issued as soon as `signUp` resolves, so without this flag `/register`
/// would be redirected to `/dashboard` before the backend responds — a 409
/// (email already linked) or a network error would never be visible.
final registrationInProgressProvider = StateProvider<bool>((ref) => false);
