import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/documents/application/documents_providers.dart';
import 'package:pocketpillar/features/documents/data/document_repository.dart';
import 'package:pocketpillar/features/documents/presentation/document_upload_sheet.dart';
import 'package:pocketpillar/features/documents/presentation/documents_screen.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeDocumentRepository repo;
  late FakeDocumentFilePicker picker;

  setUp(() {
    repo = FakeDocumentRepository();
    picker = FakeDocumentFilePicker();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentRepositoryProvider.overrideWithValue(repo),
          documentFilePickerProvider.overrideWithValue(picker),
        ],
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

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter un document'), findsOneWidget);
  }

  testWidgets('full flow: type + year → upload, snackbar, list updated', (
    tester,
  ) async {
    await pumpScreen(tester);
    await openSheet(tester);

    // Type: OTHER (iOS default) → Certificat de salaire.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Certificat de salaire').last);
    await tester.pumpAndSettle();

    // Year: iOS toggle, default = current year.
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);

    picker.result = DocumentPickedFile(
      name: 'salaire-2026.pdf',
      bytes: Uint8List(2048),
    );
    await tester.tap(find.text('Choisir un fichier'));
    await tester.pumpAndSettle();

    expect(repo.uploadCalls, 1);
    expect(repo.lastUploadType, 'SALARY_SLIP');
    expect(repo.lastUploadYear, DateTime.now().year);
    expect(repo.lastUploadFilename, 'salaire-2026.pdf');
    // Sheet closed on success (iOS behavior) + snackbar + list
    // reloaded with the new document.
    expect(find.text('Ajouter un document'), findsNothing);
    expect(find.text('Document ajouté'), findsOneWidget);
    expect(find.text('salaire-2026.pdf'), findsOneWidget);
  });

  testWidgets('without year checked: year null sent', (tester) async {
    await pumpScreen(tester);
    await openSheet(tester);

    picker.result = DocumentPickedFile(name: 'note.pdf', bytes: Uint8List(10));
    await tester.tap(find.text('Choisir un fichier'));
    await tester.pumpAndSettle();

    expect(repo.uploadCalls, 1);
    expect(repo.lastUploadType, 'OTHER');
    expect(repo.lastUploadYear, isNull);
  });

  testWidgets('file > 10 MB: snackbar, no upload, sheet kept', (tester) async {
    await pumpScreen(tester);
    await openSheet(tester);

    // Detected in the picker BEFORE reading the file (review 3.8 #1).
    picker.result = const DocumentPickTooLarge();
    await tester.tap(find.text('Choisir un fichier'));
    await tester.pumpAndSettle();

    expect(
      find.text('Le fichier dépasse la taille maximale de 10 Mo'),
      findsOneWidget,
    );
    expect(repo.uploadCalls, 0);
    expect(find.text('Ajouter un document'), findsOneWidget);
  });

  testWidgets('invalid extension: snackbar, no upload', (tester) async {
    await pumpScreen(tester);
    await openSheet(tester);

    picker.result = const DocumentPickInvalidType();
    await tester.tap(find.text('Choisir un fichier'));
    await tester.pumpAndSettle();

    expect(
      find.text('Format non pris en charge (PDF, JPEG ou PNG)'),
      findsOneWidget,
    );
    expect(repo.uploadCalls, 0);
  });

  testWidgets('unreadable data: snackbar, no upload (≠ cancelled)', (
    tester,
  ) async {
    await pumpScreen(tester);
    await openSheet(tester);

    // Pick succeeded but the bytes are unreadable (review 3.8 #4).
    picker.result = const DocumentPickUnreadable();
    await tester.tap(find.text('Choisir un fichier'));
    await tester.pumpAndSettle();

    expect(find.text('Impossible de lire le fichier'), findsOneWidget);
    expect(repo.uploadCalls, 0);
    expect(find.text('Ajouter un document'), findsOneWidget);
  });

  testWidgets('API error on upload: snackbar, sheet kept', (tester) async {
    await pumpScreen(tester);
    await openSheet(tester);

    repo.error = const ApiException(
      'Type de fichier non pris en charge',
      statusCode: 400,
    );
    picker.result = DocumentPickedFile(name: 'note.pdf', bytes: Uint8List(10));
    await tester.tap(find.text('Choisir un fichier'));
    await tester.pumpAndSettle();

    expect(repo.uploadCalls, 1);
    expect(find.text('Type de fichier non pris en charge'), findsOneWidget);
    expect(find.text('Ajouter un document'), findsOneWidget);
  });

  testWidgets('picker cancelled: nothing happens (silent)', (tester) async {
    await pumpScreen(tester);
    await openSheet(tester);

    picker.result = const DocumentPickCancelled();
    await tester.tap(find.text('Choisir un fichier'));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(repo.uploadCalls, 0);
    expect(find.text('Ajouter un document'), findsOneWidget);
    // No snackbar.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('sheet closed during upload: invalidation + snackbar '
      'survive', (tester) async {
    await pumpScreen(tester);
    await openSheet(tester);

    // Upload blocked on the gate: the sheet is closed during the send
    // (review 3.8 #3).
    repo.uploadGate = Completer<void>();
    picker.result = DocumentPickedFile(name: 'note.pdf', bytes: Uint8List(10));
    await tester.tap(find.text('Choisir un fichier'));
    await tester.pump();

    // Close the sheet during the upload.
    Navigator.of(tester.element(find.byType(DocumentUploadSheet))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Ajouter un document'), findsNothing);

    // The upload finishes after the close.
    repo.uploadGate!.complete();
    await tester.pumpAndSettle();

    // The list is still reloaded and the success snackbar is
    // displayed (container + messenger captured before the async gap).
    expect(find.text('Document ajouté'), findsOneWidget);
    expect(find.text('note.pdf'), findsOneWidget);
  });
}
