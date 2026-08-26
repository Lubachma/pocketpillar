import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/settings/presentation/privacy_policy_screen.dart';

void main() {
  Future<void> pumpPrivacy(WidgetTester tester) async {
    // Tall surface: all 7 sections rendered without scrolling.
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PrivacyPolicyScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('title + 7 sections displayed (parity with PrivacyPolicyView)', (
    tester,
  ) async {
    await pumpPrivacy(tester);

    expect(find.text('Politique de confidentialité'), findsOneWidget);

    // Titles of the 7 sections (iOS order).
    expect(find.text('Données collectées'), findsOneWidget);
    expect(find.text('Finalité du traitement'), findsOneWidget);
    expect(find.text('Stockage et sécurité'), findsOneWidget);
    expect(find.text('Partage des données'), findsOneWidget);
    expect(find.text('Vos droits (nDSG)'), findsOneWidget);
    expect(find.text('Mesures de sécurité'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
  });

  testWidgets('section bodies displayed as-is (privacy* keys)', (tester) async {
    await pumpPrivacy(tester);

    expect(
      find.textContaining('PocketPillar collecte votre adresse e-mail'),
      findsOneWidget,
    );
    expect(find.textContaining('nDSG'), findsWidgets);
    expect(find.textContaining('privacy@pocketpillar.ch'), findsOneWidget);
  });
}
