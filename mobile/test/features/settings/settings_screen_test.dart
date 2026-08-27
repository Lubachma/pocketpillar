import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/app/app.dart';
import 'package:pocketpillar/core/api/api_client.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/notifications/notification_service.dart';
import 'package:pocketpillar/core/notifications/pillar3a_reminder.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/core/utils/app_version.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_dtos.dart'
    hide FinancialProfileDto, Pillar3aAccountDto;
import 'package:pocketpillar/features/dashboard/data/dashboard_repository.dart';
import 'package:pocketpillar/features/financial_profile/application/pillar3a_reminder_context.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:pocketpillar/features/financial_profile/presentation/financial_profile_screen.dart';
import 'package:pocketpillar/features/settings/data/account_repository.dart';
import 'package:pocketpillar/features/settings/presentation/privacy_policy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

/// Integration tests for the Settings screen: real app
/// (`PocketPillarApp`, real router), only repositories/services are
/// mocked. The fake session allows verifying real redirects
/// to /login.
void main() {
  late SharedPreferences prefs;
  late SignedInFakeAuthRepository auth;
  late FakeAccountRepository account;
  late FakeNotificationService notifications;
  late FakeDashboardRepository dashboard;
  late FakeFinancialProfileRepository profiles;

  setUp(() async {
    auth = SignedInFakeAuthRepository();
    account = FakeAccountRepository();
    notifications = FakeNotificationService();
    profiles = FakeFinancialProfileRepository();
    dashboard = FakeDashboardRepository();
    dashboard.data = const DashboardData(
      user: UserDto(
        id: 'u-1',
        email: 'user@example.ch',
        birthYear: 1991,
        replacementRateGoal: 70,
      ),
    );
  });

  /// Pumps the app and opens the Settings tab.
  Future<void> pumpSettings(
    WidgetTester tester, {
    Map<String, Object> initialPrefs = const {'hasSeenOnboarding': true},
  }) async {
    // Tall surface: all tiles visible without scrolling.
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(initialPrefs);
    prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          accountRepositoryProvider.overrideWithValue(account),
          notificationServiceProvider.overrideWithValue(notifications),
          appVersionProvider.overrideWith((ref) async => '0.1.0-test'),
          dashboardRepositoryProvider.overrideWithValue(dashboard),
          // Canned 3a profile for the contextual reminder (batch 7):
          // avoids any real request when toggling reminders.
          financialProfileRepositoryProvider.overrideWithValue(profiles),
          // 3a context factory — same wiring as main().
          pillar3aReminderContextLoaderProvider.overrideWith(
            (ref) =>
                () => loadPillar3aReminderContext(
                  auth: ref.read(authRepositoryProvider),
                  profiles: ref.read(financialProfileRepositoryProvider),
                ),
          ),
          // Avoids any real request (e.g. pushed financial profile).
          apiClientProvider.overrideWithValue(FakeApiClient()),
        ],
        child: const PocketPillarApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paramètres'));
    await tester.pumpAndSettle();
  }

  testWidgets('sections: profile, language, security, notifications, '
      'about, account', (tester) async {
    await pumpSettings(tester);

    // Section headers.
    expect(find.text('Profil'), findsOneWidget);
    // « Langue »: section header + tile title (dropdown).
    expect(find.text('Langue'), findsNWidgets(2));
    expect(find.text('Sécurité'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('À propos'), findsOneWidget);
    expect(find.text('Compte'), findsOneWidget);
    // Pedagogy section (practitioner review 08.2026).
    expect(find.text('Comprendre'), findsOneWidget);
    expect(find.text('Comprendre ma prévoyance'), findsOneWidget);

    // Key content.
    expect(find.text('Profil financier'), findsOneWidget);
    expect(find.text('user@example.ch'), findsOneWidget);
    expect(find.text('Verrouillage biométrique'), findsOneWidget);
    expect(find.text('Rappels annuels'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('0.1.0-test'), findsOneWidget);
    expect(find.text('Politique de confidentialité'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(find.text('Supprimer le compte'), findsOneWidget);
  });

  testWidgets('Understand tile opens the pedagogy screen', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Comprendre ma prévoyance'));
    await tester.pumpAndSettle();

    expect(find.text('Comment calculons-nous ?'), findsOneWidget);
    expect(find.text('Ce que nous ne modélisons pas'), findsOneWidget);
  });

  testWidgets('language: selection persisted', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();

    expect(prefs.getString('appLocale'), 'de');
  });

  testWidgets('biometric lock: toggle persisted', (tester) async {
    await pumpSettings(tester);

    // Default: enabled (phase 2 baseline parity).
    expect(prefs.getBool('biometricLockEnabled'), isNull);
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Verrouillage biométrique'),
    );
    await tester.pumpAndSettle();

    expect(prefs.getBool('biometricLockEnabled'), isFalse);
  });

  testWidgets('annual reminders ON: permission, scheduling, '
      'persistence', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Rappels annuels'));
    await tester.pumpAndSettle();

    expect(notifications.initializeCalls, 1);
    expect(notifications.requestPermissionCalls, 1);
    expect(notifications.scheduleCalls, 1);
    expect(
      notifications.lastYearEndChecklistBody,
      contains('checklist de fin d\'année'),
    );
    expect(notifications.lastPillar3aBody, contains("7'258"));
    expect(prefs.getBool('annualRemindersEnabled'), isTrue);
  });

  testWidgets('annual reminders ON with profile: contextual 3a body '
      '(real remaining amount, batch 7)', (tester) async {
    profiles.profile = const FinancialProfileDto(
      id: 'p-1',
      employmentStatus: 'EMPLOYED',
      maritalStatus: 'SINGLE',
      numberOfChildren: 0,
      grossAnnualIncome: 9500000,
    );
    profiles.pillar3aAccounts = [
      const Pillar3aAccountDto(
        id: 'a-1',
        providerName: 'VIAC',
        accountType: 'BANK',
        currentBalance: 1500000,
        annualContribution: 425800, // CHF 4'258 paid in
      ),
    ];
    await pumpSettings(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Rappels annuels'));
    await tester.pumpAndSettle();

    expect(notifications.scheduleCalls, 1);
    // 7'258 − 4'258 = CHF 3'000 remaining, instead of the generic cap.
    expect(notifications.lastPillar3aBody, contains("CHF 3'000"));
    expect(notifications.lastPillar3aBody, isNot(contains("jusqu'à")));
  });

  testWidgets('annual reminders ON + permission denied: toggle '
      'unchanged, snackbar, nothing scheduled', (tester) async {
    notifications.permissionGranted = false;
    await pumpSettings(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Rappels annuels'));
    await tester.pumpAndSettle();

    expect(notifications.requestPermissionCalls, 1);
    expect(notifications.scheduleCalls, 0);
    expect(prefs.getBool('annualRemindersEnabled'), isNull);
    expect(
      find.text(
        'Notifications refusées — activez-les dans les réglages système '
        'pour recevoir les rappels',
      ),
      findsOneWidget,
    );
  });

  testWidgets('annual reminders OFF: cancellation + persistence', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      initialPrefs: {'hasSeenOnboarding': true, 'annualRemindersEnabled': true},
    );

    await tester.tap(find.widgetWithText(SwitchListTile, 'Rappels annuels'));
    await tester.pumpAndSettle();

    expect(notifications.cancelCalls, 1);
    expect(notifications.scheduleCalls, 0);
    expect(prefs.getBool('annualRemindersEnabled'), isFalse);
  });

  testWidgets('privacy policy: navigates to the page', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Politique de confidentialité'));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    expect(find.text('Données collectées'), findsOneWidget);
  });

  testWidgets('financial profile: navigates to /settings/profile', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Profil financier'));
    await tester.pumpAndSettle();

    expect(find.byType(FinancialProfileScreen), findsOneWidget);
  });

  testWidgets('logout: signOut + redirect to /login', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    // Real router redirect (null session).
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Supprimer le compte'), findsNothing);
  });

  testWidgets('cancelled account deletion: no call made', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Supprimer le compte'));
    await tester.pumpAndSettle();

    // Explicit confirmation dialog shown.
    expect(find.text('Supprimer définitivement ?'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(account.deleteCalls, 0);
    expect(auth.signOutCalls, 0);
    expect(find.text('Supprimer le compte'), findsOneWidget);
  });

  testWidgets('confirmed account deletion: DELETE, reminders '
      'cancelled + pref reset, signOut, redirect to /login', (tester) async {
    await pumpSettings(
      tester,
      initialPrefs: {'hasSeenOnboarding': true, 'annualRemindersEnabled': true},
    );

    await tester.tap(find.text('Supprimer le compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer le compte'));
    await tester.pumpAndSettle();

    expect(account.deleteCalls, 1);
    // Review 3.10: reminders aren't rescheduled for a deleted
    // account (cancellation + pref persisted as false).
    expect(notifications.cancelCalls, 1);
    expect(prefs.getBool('annualRemindersEnabled'), isFalse);
    expect(auth.signOutCalls, 1);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('confirmed deletion but signOut fails: success is not '
      'hidden (no crash, no error snackbar)', (tester) async {
    // Network revoke fails: the local session doesn't emit null → no
    // redirect, but the user gets neither an error nor a block.
    auth.signOutError = const NetworkException();
    await pumpSettings(tester);

    await tester.tap(find.text('Supprimer le compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer le compte'));
    await tester.pumpAndSettle();

    expect(account.deleteCalls, 1);
    expect(auth.signOutCalls, 1);
    expect(notifications.cancelCalls, 1);
    expect(prefs.getBool('annualRemindersEnabled'), isFalse);
    // No error snackbar; the screen stays stable.
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Supprimer le compte'), findsOneWidget);
  });

  testWidgets('account deletion API error: snackbar, no '
      'logout', (tester) async {
    account.error = const ApiException(
      'Suppression impossible pour le moment',
      statusCode: 500,
    );
    await pumpSettings(tester);

    await tester.tap(find.text('Supprimer le compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer le compte'));
    await tester.pumpAndSettle();

    expect(account.deleteCalls, 1);
    expect(auth.signOutCalls, 0);
    // DELETE failed: the account still exists, reminders intact.
    expect(notifications.cancelCalls, 0);
    expect(find.text('Suppression impossible pour le moment'), findsOneWidget);
    // Still on Settings.
    expect(find.text('Supprimer le compte'), findsOneWidget);
  });

  testWidgets('offline account deletion: network error, no '
      'logout', (tester) async {
    account.error = const NetworkException();
    await pumpSettings(tester);

    await tester.tap(find.text('Supprimer le compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer le compte'));
    await tester.pumpAndSettle();

    expect(account.deleteCalls, 1);
    expect(auth.signOutCalls, 0);
    expect(notifications.cancelCalls, 0);
    expect(find.text('Erreur réseau'), findsOneWidget);
    expect(find.text('Supprimer le compte'), findsOneWidget);
  });
}
