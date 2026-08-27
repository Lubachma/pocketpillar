import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/documents/data/document_dtos.dart';
import 'package:pocketpillar/features/documents/data/document_repository.dart';
import 'package:pocketpillar/features/documents/presentation/documents_screen.dart';

import '../../helpers/fakes.dart';

DocumentDto _doc(
  String id,
  String type,
  String filename, {
  int? year,
  int sizeBytes = 2048,
}) => DocumentDto(
  id: id,
  type: type,
  filename: filename,
  mimeType: 'application/pdf',
  sizeBytes: sizeBytes,
  year: year,
  uploadedAt: DateTime.utc(2026, 7, 1),
);

void main() {
  late FakeDocumentRepository repo;

  setUp(() {
    repo = FakeDocumentRepository()
      ..documents = [
        _doc('d1', 'SALARY_SLIP', 'fiche-salaire.pdf', year: 2025),
        _doc('d2', 'OTHER', 'note-diverse.pdf', sizeBytes: 4096),
        _doc(
          'd3',
          'BVG_STATEMENT',
          'certificat-lpp.pdf',
          year: 2024,
          sizeBytes: 3072,
        ),
      ];
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [documentRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DocumentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('list: grouped by type, size/year/date displayed', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Documents'), findsOneWidget);
    // Sections in the iOS enum order.
    expect(find.text('Certificat de salaire'), findsOneWidget);
    expect(find.text('Certificat LPP/BVG'), findsOneWidget);
    expect(find.text('Autre'), findsOneWidget);
    // Rows: name, formatted size, year.
    expect(find.text('fiche-salaire.pdf'), findsOneWidget);
    expect(find.textContaining('2 KB'), findsOneWidget);
    expect(find.textContaining('2025'), findsOneWidget);
    expect(find.text('note-diverse.pdf'), findsOneWidget);
    expect(find.text('certificat-lpp.pdf'), findsOneWidget);
  });

  testWidgets('dedicated empty state', (tester) async {
    repo.documents = [];
    await pumpScreen(tester);

    expect(find.text('Aucun document'), findsOneWidget);
    expect(
      find.text(
        'Ajoutez vos documents de prévoyance pour les garder en sécurité',
      ),
      findsOneWidget,
    );
  });

  testWidgets('network error: error state then retry', (tester) async {
    repo.failOnce = true;
    await pumpScreen(tester);

    expect(find.text('Erreur réseau'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('fiche-salaire.pdf'), findsOneWidget);
  });

  testWidgets('deletion: swipe → confirmation → removed from the list', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.fling(
      find.byType(Dismissible).first,
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();

    // Confirmation dialog (Flutter addition — iOS used to delete directly).
    expect(find.text('Supprimer ce document ?'), findsOneWidget);
    expect(find.text('Cette action est définitive.'), findsOneWidget);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(repo.deletedIds, ['d1']);
    expect(find.text('Document supprimé'), findsOneWidget); // snackbar
    expect(find.text('fiche-salaire.pdf'), findsNothing);
    expect(find.text('note-diverse.pdf'), findsOneWidget);
  });

  testWidgets('deletion cancelled: no call, document kept', (tester) async {
    await pumpScreen(tester);

    await tester.fling(
      find.byType(Dismissible).first,
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(repo.deletedIds, isEmpty);
    expect(find.text('fiche-salaire.pdf'), findsOneWidget);
  });

  testWidgets('opening: signed URL requested, failure → snackbar', (
    tester,
  ) async {
    // Mocked url_launcher channel: the open fails (launched == false)
    // → error snackbar, never silent (providers pattern).
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => false,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    await pumpScreen(tester);

    await tester.tap(find.text('fiche-salaire.pdf'));
    await tester.pumpAndSettle();

    // The signed URL is requested from the backend…
    expect(repo.downloadIds, ['d1']);
    // …then the system open failed → snackbar.
    expect(find.text('Impossible d\'ouvrir le document'), findsOneWidget);
  });

  testWidgets('404 deletion: snackbar + list resynced', (tester) async {
    await pumpScreen(tester);

    // Simulated desync: the document no longer exists server-side
    // (review 3.8 #2) — the DELETE fails with 404, the re-list succeeds
    // without the document.
    repo.documents = [
      for (final d in repo.documents)
        if (d.id != 'd1') d,
    ];
    repo.deleteError = const ApiException(
      'Document introuvable',
      statusCode: 404,
    );

    await tester.fling(
      find.byType(Dismissible).first,
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(repo.deletedIds, ['d1']);
    expect(find.text('Document introuvable'), findsOneWidget); // snackbar
    // The list was invalidated: the ghost document is gone.
    expect(find.text('fiche-salaire.pdf'), findsNothing);
    expect(find.text('note-diverse.pdf'), findsOneWidget);
  });

  testWidgets('+ button opens the upload sheet', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter un document'), findsOneWidget);
    expect(find.text('Choisir un fichier'), findsOneWidget);
  });
}
