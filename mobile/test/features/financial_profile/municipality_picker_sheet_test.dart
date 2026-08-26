import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:pocketpillar/features/financial_profile/data/municipality.dart';
import 'package:pocketpillar/features/financial_profile/presentation/widgets/municipality_picker_sheet.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeFinancialProfileRepository repository;

  setUp(() {
    repository = FakeFinancialProfileRepository()
      ..municipalities = const [
        MunicipalityInfo(name: 'Échallens', multiplier: 78),
        MunicipalityInfo(name: 'Lausanne', multiplier: 79.5),
        MunicipalityInfo(name: 'Renens', multiplier: 77),
      ];
  });

  /// Pumps an 'Ouvrir' button that shows the sheet; [onResult] receives
  /// the returned value (name, 'cantonal average' sentinel, or null
  /// if the sheet is closed without a choice).
  Future<void> pumpApp(
    WidgetTester tester, {
    required void Function(String?) onResult,
    String canton = 'VD',
    String? selectedName,
  }) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financialProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  onResult(
                    await MunicipalityPickerSheet.show(
                      context,
                      cantonCode: canton,
                      selectedName: selectedName,
                    ),
                  );
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('loading: indicator then list, canton passed to the repository', (
    tester,
  ) async {
    await pumpApp(tester, onResult: (_) {});

    await tester.tap(find.text('Ouvrir'));
    await tester.pump(); // sheet open, fetch still in flight
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(repository.fetchMunicipalitiesCalls, 1);
    expect(repository.lastMunicipalitiesCanton, 'VD');
    expect(find.text('Choisir une commune'), findsOneWidget);
    // 'Cantonal average' option first, then the municipalities.
    expect(find.text('Moyenne cantonale (commune non listée)'), findsOneWidget);
    expect(find.text('Échallens'), findsOneWidget);
    expect(find.text('Lausanne'), findsOneWidget);
    expect(find.text('Renens'), findsOneWidget);
  });

  testWidgets('accent-insensitive filtering search', (tester) async {
    await pumpApp(tester, onResult: (_) {});
    await openSheet(tester);

    // 'echallens' (no capital, no accent) finds 'Échallens'.
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher une commune'),
      'echallens',
    );
    await tester.pumpAndSettle();

    expect(find.text('Échallens'), findsOneWidget);
    expect(find.text('Lausanne'), findsNothing);
    expect(find.text('Renens'), findsNothing);
  });

  testWidgets('selection: the municipality name is returned', (tester) async {
    String? result = 'inchangé';
    var completed = false;
    await pumpApp(
      tester,
      onResult: (value) {
        result = value;
        completed = true;
      },
    );
    await openSheet(tester);

    await tester.tap(find.text('Lausanne'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, 'Lausanne');
  });

  testWidgets('"cantonal average" option: sentinel returned '
      '(explicit deselection, distinct from closing without a choice)', (
    tester,
  ) async {
    String? result = 'inchangé';
    var completed = false;
    await pumpApp(
      tester,
      selectedName: 'Lausanne',
      onResult: (value) {
        result = value;
        completed = true;
      },
    );
    await openSheet(tester);

    await tester.tap(find.text('Moyenne cantonale (commune non listée)'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, municipalityCantonalAverageSentinel);
  });

  testWidgets('canton with no covered municipality: info text shown, even '
      'with a search in progress', (tester) async {
    repository.municipalities = [];
    await pumpApp(tester, onResult: (_) {});
    await openSheet(tester);

    expect(
      find.text(
        'Aucune commune couverte pour ce canton — la moyenne cantonale '
        'est utilisée.',
      ),
      findsOneWidget,
    );

    // A search in an empty list keeps the 'coverage' message
    // (the canton has no municipalities, this isn't a search failure).
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher une commune'),
      'zzz',
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Aucune commune couverte pour ce canton — la moyenne cantonale '
        'est utilisée.',
      ),
      findsOneWidget,
    );
    expect(find.text('Aucun résultat'), findsNothing);
  });

  testWidgets('search with no results: dedicated message, "cantonal '
      'average" option still visible', (tester) async {
    await pumpApp(tester, onResult: (_) {});
    await openSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher une commune'),
      'zzz',
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun résultat'), findsOneWidget);
    // The 'canton with no coverage' message would be misleading here.
    expect(
      find.text(
        'Aucune commune couverte pour ce canton — la moyenne cantonale '
        'est utilisée.',
      ),
      findsNothing,
    );
    expect(find.text('Échallens'), findsNothing);
    expect(find.text('Moyenne cantonale (commune non listée)'), findsOneWidget);
  });

  testWidgets('loading error: message + retry reloads the list', (
    tester,
  ) async {
    repository.error = const NetworkException();
    await pumpApp(tester, onResult: (_) {});
    await openSheet(tester);

    expect(find.text('Impossible de charger les communes'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Échallens'), findsOneWidget);
    expect(repository.fetchMunicipalitiesCalls, 2);
  });
}
