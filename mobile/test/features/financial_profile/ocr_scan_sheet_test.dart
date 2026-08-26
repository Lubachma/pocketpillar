import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/financial_profile/application/ocr_scan_providers.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:pocketpillar/features/financial_profile/data/scan_image_picker.dart';
import 'package:pocketpillar/features/financial_profile/data/text_recognition_service.dart';
import 'package:pocketpillar/features/financial_profile/presentation/financial_profile_screen.dart';
import 'package:pocketpillar/features/financial_profile/presentation/widgets/account_sheets.dart';
import 'package:pocketpillar/features/financial_profile/presentation/widgets/ocr_scan_sheet.dart';
import 'package:pocketpillar/features/premium/application/premium_providers.dart';

import '../../helpers/fakes.dart';

/// Fake image picker: canned path (null = cancellation),
/// configurable error (permission denied, `already_active`), last
/// recorded source. Never a real platform channel in tests.
class FakeScanImagePicker implements ScanImagePicker {
  String? path = '/fake/scan.jpg';
  Object? error;
  ScanImageSource? lastSource;

  @override
  Future<String?> pickImagePath(ScanImageSource source) async {
    lastSource = source;
    final failure = error;
    if (failure != null) throw failure;
    return path;
  }
}

/// Fake OCR engine: canned text or configurable error.
class FakeTextRecognitionService implements TextRecognitionService {
  String text = '';
  Object? error;
  final List<String> recognizedPaths = [];

  @override
  Future<String> recognizeText(String imagePath) async {
    recognizedPaths.add(imagePath);
    final failure = error;
    if (failure != null) throw failure;
    return text;
  }
}

/// Minimal profile repository for integration tests: both account
/// sections load empty (the form doesn't need anything else).
class _ProfileRepoFake extends FakeFinancialProfileRepository {
  @override
  Future<List<Pillar2AccountDto>> fetchPillar2Accounts() async => [];
}

const _salaryText = "CERTIFICAT DE SALAIRE\n1. Salaire brut 95'000.00";
const _lppText = '''
RELEVÉ DE PRÉVOYANCE 2025
Avoir de vieillesse au 31.12.2025 : 128'540.75
Salaire assuré : 68'250.00
Cotisation annuelle : 9'550.00
''';

void main() {
  late FakeScanImagePicker picker;
  late FakeTextRecognitionService ocr;

  setUp(() {
    picker = FakeScanImagePicker();
    ocr = FakeTextRecognitionService();
  });

  /// Pumps a minimal host and opens the scan sheet; the result future
  /// is exposed via [resultHolder].
  Future<void> pumpAndOpenSheet(
    WidgetTester tester,
    OcrScanKind kind,
    List<OcrScanResult?> resultHolder,
  ) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanImagePickerProvider.overrideWithValue(picker),
          textRecognitionServiceProvider.overrideWithValue(ocr),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultHolder.add(
                    await OcrScanSheet.show(context, kind: kind),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// From the source choice: photo → analysis (simulated).
  Future<void> takePhoto(WidgetTester tester) async {
    await tester.tap(find.text('Prendre une photo'));
    await tester.pumpAndSettle();
  }

  testWidgets('salary: detected value pre-filled, Appliquer returns '
      'the centimes', (tester) async {
    ocr.text = _salaryText;
    final results = <OcrScanResult?>[];
    await pumpAndOpenSheet(tester, OcrScanKind.salaryCertificate, results);

    // Source choice shown (local-privacy note along the way).
    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Choisir une image'), findsOneWidget);
    expect(
      find.text("Analyse locale : l'image ne quitte jamais votre appareil."),
      findsOneWidget,
    );

    await takePhoto(tester);
    expect(picker.lastSource, ScanImageSource.camera);
    expect(ocr.recognizedPaths, ['/fake/scan.jpg']);

    // Proposal card: the field is pre-filled with the CHF value.
    final field = find.widgetWithText(
      TextFormField,
      'Revenu brut annuel (CHF)',
    );
    expect(field, findsOneWidget);
    expect(tester.widget<TextFormField>(field).controller!.text, '95000');

    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    expect(results.single?.grossAnnualIncome, 9500000);
    expect(results.single?.currentCapital, isNull);
  });

  testWidgets('salary: the proposed value stays editable before '
      'applying', (tester) async {
    ocr.text = _salaryText;
    final results = <OcrScanResult?>[];
    await pumpAndOpenSheet(tester, OcrScanKind.salaryCertificate, results);
    await takePhoto(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenu brut annuel (CHF)'),
      '96000',
    );
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    expect(results.single?.grossAnnualIncome, 9600000);
  });

  testWidgets('LPP: balance, insured salary and contribution proposed '
      'then applied', (tester) async {
    ocr.text = _lppText;
    final results = <OcrScanResult?>[];
    await pumpAndOpenSheet(tester, OcrScanKind.lppStatement, results);
    await takePhoto(tester);

    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Capital actuel (CHF)'),
          )
          .controller!
          .text,
      '128540.75',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Salaire assuré (CHF)'),
          )
          .controller!
          .text,
      '68250',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Cotisation annuelle (CHF)'),
          )
          .controller!
          .text,
      '9550',
    );

    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    expect(results.single?.currentCapital, 12854075);
    expect(results.single?.insuredSalary, 6825000);
    expect(results.single?.annualContribution, 955000);
    expect(results.single?.grossAnnualIncome, isNull);
  });

  testWidgets('LPP partial: only detected fields are proposed', (tester) async {
    ocr.text = "Altersguthaben: 45'600.–";
    final results = <OcrScanResult?>[];
    await pumpAndOpenSheet(tester, OcrScanKind.lppStatement, results);
    await takePhoto(tester);

    expect(
      find.widgetWithText(TextFormField, 'Capital actuel (CHF)'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'Salaire assuré (CHF)'),
      findsNothing,
    );

    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    expect(results.single?.currentCapital, 4560000);
    expect(results.single?.insuredSalary, isNull);
    expect(results.single?.annualContribution, isNull);
  });

  testWidgets('no text found: dedicated message, Réessayer goes back to '
      'the source choice', (tester) async {
    ocr.text = '   ';
    await pumpAndOpenSheet(tester, OcrScanKind.salaryCertificate, []);
    await takePhoto(tester);

    expect(find.textContaining('Aucun texte détecté sur l'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Prendre une photo'), findsOneWidget);
  });

  testWidgets('text with no recognized values: dedicated message', (
    tester,
  ) async {
    ocr.text = 'Bonjour, ceci est une photo de paysage.';
    await pumpAndOpenSheet(tester, OcrScanKind.salaryCertificate, []);
    await takePhoto(tester);

    expect(find.textContaining('Aucune valeur reconnue'), findsOneWidget);
  });

  testWidgets('picker cancellation: silent return to the source choice', (
    tester,
  ) async {
    picker.path = null;
    await pumpAndOpenSheet(tester, OcrScanKind.salaryCertificate, []);
    await takePhoto(tester);

    // Still on the source choice, no error message.
    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.textContaining('Aucun'), findsNothing);
    expect(ocr.recognizedPaths, isEmpty);
  });

  testWidgets('analysis failure: error message + Réessayer', (tester) async {
    ocr.error = StateError('mlkit unavailable');
    await pumpAndOpenSheet(tester, OcrScanKind.salaryCertificate, []);
    await takePhoto(tester);

    expect(find.textContaining("L'analyse a échoué"), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Prendre une photo'), findsOneWidget);
  });

  // Batch 9 review regression (minor 6): an exception from the PICKER (permission
  // denied, `already_active` double-tap) ends up in the same error state
  // as an analysis failure — never an uncaught exception.
  testWidgets('picker failure (already_active): error state', (tester) async {
    picker.error = StateError('already_active');
    await pumpAndOpenSheet(tester, OcrScanKind.salaryCertificate, []);
    await takePhoto(tester);

    expect(find.textContaining("L'analyse a échoué"), findsOneWidget);
    expect(ocr.recognizedPaths, isEmpty);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Prendre une photo'), findsOneWidget);
  });

  // Batch 9 review regression (minor 7): the temp file written by the
  // picker is deleted after OCR (success or failure alike). Synchronous I/O:
  // real I/O futures don't resolve inside the fake-async zone
  // used by widget tests.
  testWidgets('the temporary image file is deleted after the scan', (
    tester,
  ) async {
    final temp = File(
      '${Directory.systemTemp.path}/ocr_scan_sheet_test_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    temp.writeAsBytesSync(const [0xFF, 0xD8, 0xFF]);
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync();
    });
    picker.path = temp.path;
    ocr.text = _salaryText;

    final results = <OcrScanResult?>[];
    await pumpAndOpenSheet(tester, OcrScanKind.salaryCertificate, results);
    await takePhoto(tester);

    // The proposal is shown AND the temp file is deleted.
    expect(
      find.widgetWithText(TextFormField, 'Revenu brut annuel (CHF)'),
      findsOneWidget,
    );
    expect(temp.existsSync(), isFalse);
  });

  testWidgets('profile integration: Appliquer fills the gross income '
      'field in the form (without saving)', (tester) async {
    ocr.text = _salaryText;
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financialProfileRepositoryProvider.overrideWithValue(
            _ProfileRepoFake(),
          ),
          scanImagePickerProvider.overrideWithValue(picker),
          textRecognitionServiceProvider.overrideWithValue(ocr),
          // OCR scanning is a Premium feature (contract §11): this
          // integration test runs as a subscriber.
          premiumActiveProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileForm(
              data: ProfileBaseData(
                userId: 'u-1',
                email: 'user@example.ch',
                canton: 'VD',
                municipality: null,
                birthYear: 1991,
                replacementRateGoal: 70,
                profile: null,
                loadedAt: DateTime(2026, 8, 6),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final grossField = find.widgetWithText(
      TextFormField,
      'Revenu brut annuel (CHF)',
    );
    expect(tester.widget<TextFormField>(grossField).controller!.text, '');

    await tester.tap(find.text('Scanner un certificat de salaire'));
    await tester.pumpAndSettle();
    await takePhoto(tester);
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    // The field is filled, the form hasn't been saved (the 'Enregistrer'
    // button is left to the user).
    expect(tester.widget<TextFormField>(grossField).controller!.text, '95000');
    expect(
      find.text('Champs préremplis — vérifiez puis enregistrez'),
      findsOneWidget,
    );
  });

  testWidgets('LPP sheet integration: Appliquer fills capital and insured '
      'salary (advanced section expanded)', (tester) async {
    ocr.text = _lppText;
    Pillar2AccountFormResult? formResult;
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanImagePickerProvider.overrideWithValue(picker),
          textRecognitionServiceProvider.overrideWithValue(ocr),
          // OCR scanning is a Premium feature (contract §11): this
          // integration test runs as a subscriber.
          premiumActiveProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  formResult = await Pillar2AccountSheet.show(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scanner un relevé LPP'));
    await tester.pumpAndSettle();
    await takePhoto(tester);
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    // The LPP sheet is still open, fields filled.
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Capital actuel (CHF)'),
          )
          .controller!
          .text,
      '128540.75',
    );
    // Advanced section expanded by applying the insured salary.
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Salaire assuré (CHF)'),
          )
          .controller!
          .text,
      '68250',
    );

    // The sheet's validation stays manual: Enregistrer sends the
    // applied values (in centimes) — proof the flow hasn't regressed.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prestataire'),
      'Caisse Exemple',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(formResult?.currentCapital, 12854075);
    expect(formResult?.insuredSalary, 6825000);
    expect(formResult?.annualBvgContribution, 955000);
  });
}
