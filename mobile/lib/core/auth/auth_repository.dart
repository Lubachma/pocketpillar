import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Minimal Supabase identity exposed to features (avoids leaking
/// Supabase types, which are heavy to construct in tests).
class AuthIdentity {
  const AuthIdentity({required this.userId, this.email});

  /// Supabase `user.id` — sent to the backend as `supabaseId`.
  final String userId;

  final String? email;
}

/// Result of a Supabase `signUp`.
class SignUpResult {
  const SignUpResult._(this.identity);

  /// Session opened immediately (email confirmation disabled).
  const SignUpResult.withSession(AuthIdentity identity) : this._(identity);

  /// No session: Supabase is waiting for an email confirmation.
  const SignUpResult.confirmationRequired() : this._(null);

  /// User identity, null if email confirmation is required.
  final AuthIdentity? identity;
}

/// Supabase authentication (email + password, Sign in with Apple).
///
/// The session is persisted by supabase_flutter itself; this repository
/// is only a testable facade on top of the client.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient? _client;

  /// Stream of session changes (emits the current session first).
  Stream<Session?> get sessionChanges async* {
    final client = _client;
    if (client == null) {
      yield null;
      return;
    }
    yield client.auth.currentSession;
    yield* client.auth.onAuthStateChange.map((event) => event.session);
  }

  Session? get currentSession => _client?.auth.currentSession;

  /// Email of the current account (Supabase session), null without a
  /// session (e.g. dev bypass).
  String? get currentEmail => _client?.auth.currentUser?.email;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _requireClient().auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _requireClient().auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (response.session == null || user == null) {
      // Email confirmation enabled on the Supabase side: no immediate session.
      return const SignUpResult.confirmationRequired();
    }
    return SignUpResult.withSession(
      AuthIdentity(userId: user.id, email: user.email ?? email),
    );
  }

  /// Exchanges an OAuth identity token (Apple) for a Supabase session.
  Future<AuthIdentity> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? nonce,
  }) async {
    final response = await _requireClient().auth.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      nonce: nonce,
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Supabase n\'a pas retourné d\'utilisateur.');
    }
    return AuthIdentity(userId: user.id, email: user.email);
  }

  /// Sign in with Apple (iOS only — see `LoginScreen`).
  ///
  /// Same flow as the iOS app: raw nonce sent to Supabase, **SHA-256
  /// hashed** nonce sent to Apple (replay mitigation).
  Future<AuthIdentity> signInWithApple() async {
    final rawNonce = generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw StateError("Apple n'a pas retourné de jeton d'identité.");
    }
    return signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  /// Without a configured client, sign-out is a no-op (dev bypass).
  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  /// Refreshed access token, or null **without a session** (never
  /// signed in, dev bypass): in that case there's nothing to refresh and
  /// calling `refreshSession()` would throw `AuthSessionMissingException`
  /// (just Supabase log noise). Used by the API client on 401.
  Future<String?> refreshAccessToken() async {
    final auth = _client?.auth;
    if (auth == null || auth.currentSession == null) return null;
    final response = await auth.refreshSession();
    return response.session?.accessToken;
  }

  /// Only signs out if a session exists: `signOut()` without a session
  /// still emits an auth event, which makes the router re-evaluate and
  /// re-invalidate the profile aggregate → refetch → 401 → new attempt
  /// (refresh/signOut storm observed in the journal on 2026-08-07).
  Future<void> signOutIfAuthenticated() async {
    final auth = _client?.auth;
    if (auth == null || auth.currentSession == null) return;
    await auth.signOut();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase non configuré : passer SUPABASE_URL et SUPABASE_ANON_KEY '
        'via --dart-define (voir mobile/README.md).',
      );
    }
    return client;
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(SupabaseConfig.clientOrNull),
);

/// Session state watched by the router (redirect to /login).
final authSessionProvider = StreamProvider<Session?>(
  (ref) => ref.watch(authRepositoryProvider).sessionChanges,
);

/// Sign-in bypass for dev (equivalent of the iOS `devSignIn()`):
/// authenticated **without a session** when Supabase isn't configured.
/// Consulted by the router only in `kDebugMode`.
final devAuthBypassProvider = StateProvider<bool>((ref) => false);
