import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/core/storage/preferences.dart';
import 'package:pocketpillar/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  Widget buildSubject() {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('ÉCRAN_LOGIN')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('4-page flow then « Commencer » → login + flag set', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Page 1: the 3 pillars.
    expect(find.text('Votre retraite repose sur 3 piliers'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);

    // Page 2: detail by pillar.
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Comment ça marche ?'), findsOneWidget);
    expect(find.text('1er pilier (AVS)'), findsOneWidget);

    // Page 3: features.
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Évaluer votre santé prévoyance'), findsOneWidget);

    // Page 4: « Commencer » replaces « Suivant », « Passer » disappears.
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text("C'est parti !"), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    expect(find.text('Passer'), findsNothing);
    expect(find.text('Suivant'), findsNothing);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('hasSeenOnboarding'), isTrue);
    expect(find.text('ÉCRAN_LOGIN'), findsOneWidget);
  });

  testWidgets('« Passer » completes onboarding immediately', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('hasSeenOnboarding'), isTrue);
    expect(find.text('ÉCRAN_LOGIN'), findsOneWidget);
  });
}
