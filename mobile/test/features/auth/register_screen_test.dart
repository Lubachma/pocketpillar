import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketpillar/app/routes.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/auth/auth_repository.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/auth/application/auth_service.dart';
import 'package:pocketpillar/features/auth/presentation/register_screen.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAuthRepository authRepository;
  late FakeApiClient apiClient;

  Widget buildSubject() {
    // Minimal router: success navigates explicitly to /dashboard and
    // the confirmation-email case offers a CTA to /login.
    final router = GoRouter(
      initialLocation: Routes.register,
      routes: [
        GoRoute(
          path: Routes.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: Routes.dashboard,
          builder: (context, state) => const Scaffold(body: Text('DASHBOARD')),
        ),
        GoRoute(
          path: Routes.login,
          builder: (context, state) => const Scaffold(body: Text('LOGIN')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(
          AuthService(authRepository, apiClient),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Future<void> pumpRegister(WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String email = 'user@example.ch',
    String password = 'motdepasse123',
    String confirm = 'motdepasse123',
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse e-mail'),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      password,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
      confirm,
    );
  }

  setUp(() {
    authRepository = FakeAuthRepository();
    apiClient = FakeApiClient();
  });

  testWidgets('validation: password < 8 characters rejected', (tester) async {
    await pumpRegister(tester);
    await fillForm(tester, password: 'court', confirm: 'court');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(
      find.text('Le mot de passe doit contenir au moins 8 caractères'),
      findsOneWidget,
    );
    expect(apiClient.postCalls, isEmpty);
  });

  testWidgets('validation: different confirmation rejected', (tester) async {
    await pumpRegister(tester);
    await fillForm(tester, confirm: 'autrechose123');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);
    expect(apiClient.postCalls, isEmpty);
  });

  testWidgets(
    'success: Supabase signUp, POST /auth/register, dashboard navigation',
    (tester) async {
      await pumpRegister(tester);
      await fillForm(tester);
      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();

      expect(authRepository.lastEmail, 'user@example.ch');
      expect(apiClient.postCalls, hasLength(1));
      final call = apiClient.postCalls.single;
      expect(call.path, '/auth/register');
      expect(call.data, {'email': 'user@example.ch', 'supabaseId': 'supa-123'});
      expect(find.text('DASHBOARD'), findsOneWidget);
    },
  );

  testWidgets('409 backend: localized message + Supabase session closed', (
    tester,
  ) async {
    apiClient.postError = const ApiException('Conflit', statusCode: 409);
    await pumpRegister(tester);
    await fillForm(tester);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cette adresse e-mail est déjà liée à un autre compte'),
      findsOneWidget,
    );
    expect(authRepository.signOutCalls, 1);
    // Still on /register: the message stays visible.
    expect(find.text('DASHBOARD'), findsNothing);
  });

  testWidgets('network error: localized message shown', (tester) async {
    apiClient.postError = const NetworkException();
    await pumpRegister(tester);
    await fillForm(tester);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Erreur réseau'), findsOneWidget);
    expect(authRepository.signOutCalls, 0);
  });

  testWidgets('email confirmation: info message, no backend call, login CTA', (
    tester,
  ) async {
    authRepository.signUpResult = const SignUpResult.confirmationRequired();
    await pumpRegister(tester);
    await fillForm(tester);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Vérifiez votre boîte de réception pour confirmer votre adresse '
        'e-mail, puis connectez-vous',
      ),
      findsOneWidget,
    );
    expect(apiClient.postCalls, isEmpty);

    await tester.tap(find.text('Aller à la connexion'));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
