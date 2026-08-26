import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/config/demo_config.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/auth/presentation/login_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAuthRepository authRepository;

  Widget buildSubject() {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(),
      ),
    );
  }

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
  }

  setUp(() {
    authRepository = FakeAuthRepository();
  });

  testWidgets('validation: invalid email and empty password', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse e-mail'),
      'pas-un-email',
    );
    // Password left empty.
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Adresse e-mail invalide'), findsOneWidget);
    expect(find.text('Mot de passe requis'), findsOneWidget);
    expect(authRepository.lastEmail, isNull);
  });

  testWidgets('short password accepted at login (≥ 8 reserved for '
      'registration)', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse e-mail'),
      'user@example.ch',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      '123',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Mot de passe requis'), findsNothing);
    expect(
      find.text('Le mot de passe doit contenir au moins 8 caractères'),
      findsNothing,
    );
    expect(authRepository.lastPassword, '123');
  });

  testWidgets('successful login: credentials passed to the repository', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse e-mail'),
      '  user@example.ch  ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'motdepasse123',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(authRepository.lastEmail, 'user@example.ch');
    expect(authRepository.lastPassword, 'motdepasse123');
    expect(find.text('Échec de la connexion'), findsNothing);
  });

  testWidgets('Supabase failure: localized error message shown', (
    tester,
  ) async {
    authRepository.signInError = AuthException('Invalid login credentials');
    await pumpLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse e-mail'),
      'user@example.ch',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'motdepasse123',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Échec de la connexion'), findsOneWidget);
  });

  testWidgets('Sign in with Apple: absent outside iOS (test default)', (
    tester,
  ) async {
    await pumpLogin(tester);
    expect(find.byType(SignInWithAppleButton), findsNothing);
  });

  testWidgets('Sign in with Apple: present on iOS', (tester) async {
    // The framework requires resetting this before the test ends
    // (invariant checked before tearDown). Set before the pump: a second
    // pumpWidget with an identical const tree wouldn't rebuild.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpLogin(tester);
    expect(find.byType(SignInWithAppleButton), findsOneWidget);
    expect(find.text('Se connecter avec Apple'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'Dev Login (debug): bypass without a session when Supabase is absent',
    (tester) async {
      await pumpLogin(tester);

      // Visible only in kDebugMode (true in tests). The button is at the
      // bottom of the page: scroll it into the viewport before tapping.
      await tester.ensureVisible(find.text('Dev Login'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dev Login'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LoginScreen)),
      );
      expect(container.read(devAuthBypassProvider), isTrue);
    },
  );

  testWidgets('demo mode: banner visible, registration hidden, '
      'login pre-filled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          demoLoginConfigProvider.overrideWithValue(
            const DemoLoginConfig(
              email: 'demo@pocketpillar.ch',
              password: 'demo-pass',
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Démo publique'), findsOneWidget);
    expect(find.text('Pas encore de compte ? Créer un compte'), findsNothing);

    await tester.ensureVisible(find.text('Se connecter avec le compte démo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter avec le compte démo'));
    await tester.pumpAndSettle();
    expect(authRepository.lastEmail, 'demo@pocketpillar.ch');
    expect(authRepository.lastPassword, 'demo-pass');
  });

  testWidgets('outside demo mode: no banner, registration visible', (
    tester,
  ) async {
    await pumpLogin(tester); // default provider → null (no dart-define)

    expect(find.text('Démo publique'), findsNothing);
    expect(find.text('Pas encore de compte ? Créer un compte'), findsOneWidget);
  });
}
