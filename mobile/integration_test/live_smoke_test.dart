// LIVE smoke test — full flow against the real local backend and the real
// cloud Supabase project (launch sprint, Phase 0).
//
// Difference from `smoke_test.dart` (fully mocked): here no repository
// is mocked — the app talks to Supabase and the backend for real, as in
// production. Covers: onboarding → login → dashboard → guided Bilan →
// results → documents tab → account deletion (cleanup).
//
// The test account is created via the Supabase admin API (pre-confirmed
// email): NEVER via the register screen — a real signUp would send a
// confirmation email to a nonexistent test address (bounce → risk to the
// project's sending privileges + the shared SMTP quota, which is nearly
// zero). The register UI flow is covered by the mocked tests
// (test/features/auth/register_screen_test.dart, test/app/registration_flow_test.dart).
//
// Prerequisites:
// - local backend listening (`make test` in a terminal)
// - Android emulator started (`make android` does this, or flutter emulators)
//
// Run:
//   flutter test integration_test/live_smoke_test.dart -d emulator-5554 \
//     --dart-define=API_BASE_URL=http://10.0.2.2:7777 \
//     --dart-define-from-file=.env \
//     --dart-define=SMOKE_SERVICE_KEY=sb_secret_…
//
// The service key (SMOKE_SERVICE_KEY) is only used to confirm the test
// account's email and delete it afterwards; it never leaves the machine
// (the test only runs locally, never in CI or in a shipped build).
// ignore_for_file: avoid_print — prints are the progress log
// visible in the integration test runner output.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocketpillar/app/app.dart';
import 'package:pocketpillar/core/api/api_config.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/auth/supabase_config.dart';
import 'package:pocketpillar/core/notifications/notification_service.dart';
import 'package:pocketpillar/core/notifications/pillar3a_reminder.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/features/financial_profile/application/pillar3a_reminder_context.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _serviceKey = String.fromEnvironment('SMOKE_SERVICE_KEY');
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');

/// Minimal JSON HTTP call (Supabase admin API + local backend).
Future<({int status, String body})> _http(
  String method,
  Uri url, {
  String? bearer,
  Map<String, dynamic>? body,
}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, url);
    if (bearer != null) {
      req.headers.set('apikey', bearer);
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
    }
    if (body != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));
    }
    final res = await req.close();
    return (status: res.statusCode, body: await res.transform(utf8.decoder).join());
  } finally {
    client.close();
  }
}

Future<void> _settle(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(seconds: 30));

/// Active wait for a label — `pumpAndSettle` isn't enough for
/// navigations triggered by a network response (no frame is
/// scheduled during the call: settle returns before the redirect).
Future<bool> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 90),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Scrolls the first list until the label if it hasn't
/// been built yet (ListViews are lazy on a real screen).
Future<void> _ensureVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Taps a wizard label after first scrolling it into the viewport:
/// the steps are ListViews whose action button is the LAST child
/// — below the fold on a real screen, it isn't built (lazy list).
Future<void> _tapWizard(WidgetTester tester, String label) async {
  final target = find.text(label);
  await _ensureVisible(tester, target);
  await tester.tap(target);
  await _settle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live flow: onboarding → login → Bilan → results → '
      'documents → deletion', (tester) async {
    if (_serviceKey.isEmpty || _supabaseUrl.isEmpty) {
      fail(
        'SMOKE_SERVICE_KEY et/ou SUPABASE_URL manquants — voir l\'en-tête du '
        'fichier pour la commande de lancement complète.',
      );
    }

    // Disposable test account (gmail: pocketpillar.ch has no MX record, Supabase
    // rejects domains without an MX record).
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'pocketpillar.smoke+$stamp@gmail.com';
    const password = 'Smoke-Test-2026-Ab!';
    print('→ compte de test : $email');

    // Bootstrap identical to main(): Supabase + prefs + same overrides.
    // Blank state + FR locale (the emulator defaults to en-US).
    await SupabaseConfig.initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('appLocale', 'fr');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(
            LocalNotificationService(),
          ),
          pillar3aReminderContextLoaderProvider.overrideWith(
            (ref) => () => loadPillar3aReminderContext(
              auth: ref.read(authRepositoryProvider),
              profiles: ref.read(financialProfileRepositoryProvider),
            ),
          ),
        ],
        child: const PocketPillarApp(),
      ),
    );
    await _settle(tester);

    // ── Onboarding (4 pages) ──────────────────────────────────────────
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Suivant'));
      await _settle(tester);
    }
    await tester.tap(find.text('Commencer'));
    await _settle(tester);
    expect(find.text('Se connecter'), findsOneWidget);
    print('✅ onboarding');

    // ── Test account via the admin API — NEVER via the register screen ──
    // A real-conditions signUp would send a confirmation email to
    // a nonexistent address → bounce ("sending privileges" alert
    // received on 12.08) + the free shared SMTP quota, which is nearly zero. The
    // register UI flow is covered by the mocked tests (register_screen_test,
    // registration_flow_test); here we validate login → features → deletion.
    final create = await _http(
      'POST',
      Uri.parse('$_supabaseUrl/auth/v1/admin/users'),
      bearer: _serviceKey,
      body: {'email': email, 'password': password, 'email_confirm': true},
    );
    expect(create.status, 200, reason: create.body);
    print('✅ compte créé via l\'API admin (aucun email envoyé)');

    // Backend registration (what the register screen does in production:
    // signUp → POST /auth/register). Without a `users` row, `resolveAuth`
    // responds 401 user_not_found to every authenticated request.
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    final grant = await _http(
      'POST',
      Uri.parse('$_supabaseUrl/auth/v1/token?grant_type=password'),
      bearer: anonKey,
      body: {'email': email, 'password': password},
    );
    expect(grant.status, 200, reason: grant.body);
    final accessToken =
        (jsonDecode(grant.body) as Map<String, dynamic>)['access_token']!
            as String;
    final authUserId =
        (jsonDecode(create.body) as Map<String, dynamic>)['id']! as String;
    final reg = await _http(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      bearer: accessToken,
      body: {'supabaseId': authUserId, 'email': email},
    );
    expect(reg.status, 200, reason: reg.body);
    print('✅ utilisateur enregistré côté backend (POST /auth/register)');

    // ── Login ─────────────────────────────────────────────────────────
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse e-mail'),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      password,
    );
    await tester.tap(find.text('Se connecter'));
    // Navigation triggered after Supabase's network response → active wait.
    final onDashboard = await _waitFor(tester, find.text('Bilan'));
    if (!onDashboard) {
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .join(' | ');
      print('⚠️  écran après login : $texts');
    }
    // The tab bar proves we've landed on the authenticated shell.
    expect(find.text('Bilan'), findsOneWidget);
    print('✅ login → dashboard');

    // ── Guided Bilan (real backend calculation) ─────────────────────────
    await tester.tap(find.text('Bilan'));
    // Pre-filled from the backend → active wait on the wizard.
    expect(await _waitFor(tester, find.text('Votre situation')), isTrue);
    await _tapWizard(tester, 'Suivant'); // situation → income
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut (CHF)'),
      '95000',
    );
    await _tapWizard(tester, 'Suivant'); // income → 2nd pillar
    await _tapWizard(tester, 'Suivant'); // 2nd pillar → 3a
    await _tapWizard(tester, 'Voir mes résultats');
    // Real backend calculation → active wait on the results screen.
    expect(await _waitFor(tester, find.text('Vos résultats')), isTrue);
    // The card is further down the results list → scroll.
    final taxCard = find.text('Économies fiscales');
    await _ensureVisible(tester, taxCard);
    expect(taxCard, findsOneWidget);
    print('✅ bilan guidé → résultats (calcul backend réel)');

    // ── Documents (empty for a brand-new account) ──────────────────────
    await tester.tap(find.text('Documents'));
    expect(
      await _waitFor(tester, find.textContaining('Aucun document')),
      isTrue,
    );
    print('✅ onglet documents');

    // ── Cleanup: account deletion (backend + auth) ─────────────────────
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    expect(token, isNotNull);
    final deleted = await _http(
      'DELETE',
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      bearer: token,
    );
    expect(
      deleted.status,
      anyOf(200, 204),
      reason: deleted.body,
    );
    print('✅ compte supprimé (backend + auth) — aucune trace laissée');
  });
}
