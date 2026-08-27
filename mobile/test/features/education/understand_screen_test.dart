import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/education/presentation/understand_screen.dart';

/// "Understand your pension" — the beginner hub (practitioner review
/// 08.2026): the 3 pillars reachable at last, and the calculation method
/// in plain words.
void main() {
  Future<void> pumpUnderstand(WidgetTester tester) async {
    // Tall surface: every block rendered without scrolling.
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UnderstandScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('title, 3 pillars and the 5 calculation blocks displayed', (
    tester,
  ) async {
    await pumpUnderstand(tester);

    expect(find.text('Comprendre ma prévoyance'), findsOneWidget);
    expect(find.text('Les 3 piliers'), findsOneWidget);

    // The three pillar tiles (previously orphan glossary sheets).
    expect(find.text('AVS (1er pilier)'), findsOneWidget);
    expect(find.text('LPP / 2e pilier'), findsOneWidget);
    expect(find.text('Pilier 3a'), findsOneWidget);

    // The five "how do we calculate?" blocks.
    expect(find.text('Comment calculons-nous ?'), findsOneWidget);
    expect(find.text('Rente AVS'), findsOneWidget);
    expect(find.text('Capital et rente LPP'), findsOneWidget);
    expect(find.text('Épargne 3a'), findsOneWidget);
    expect(find.text('Impôts'), findsOneWidget);
    expect(find.text('Ce que nous ne modélisons pas'), findsOneWidget);

    // Link to the published methodology (fiscal-accuracy.md).
    expect(
      find.text('Méthodologie complète et sources (publiées sur GitHub)'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a pillar opens its glossary sheet', (tester) async {
    await pumpUnderstand(tester);

    await tester.tap(find.text('LPP / 2e pilier'));
    await tester.pumpAndSettle();

    // Sheet sections: the title now appears twice (tile + sheet header).
    expect(find.text('LPP / 2e pilier'), findsNWidgets(2));
    expect(find.text("C'est quoi ?"), findsOneWidget);
    expect(find.text("Pourquoi c'est important ?"), findsOneWidget);
    expect(find.text('Où trouver cette info ?'), findsOneWidget);
  });
}
