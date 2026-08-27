import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/documents/application/documents_providers.dart';
import 'package:pocketpillar/features/documents/data/document_dtos.dart';

/// Fake `file_picker` platform — `extends FilePicker` inherits the
/// `PlatformInterface` token, so the `FilePicker.platform` setter accepts
/// the instance. Records the received arguments (notably `withData`,
/// central to review 3.8 #1).
class _FakeFilePickerPlatform extends FilePicker {
  FilePickerResult? result;
  bool? lastWithData;
  List<String>? lastAllowedExtensions;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    lastWithData = withData;
    lastAllowedExtensions = allowedExtensions;
    return result;
  }
}

PlatformFile _platformFile({
  required String name,
  required int size,
  String? path,
}) => PlatformFile(name: name, size: size, path: path);

void main() {
  late _FakeFilePickerPlatform platform;
  late FilePickerDocumentFilePicker picker;

  setUp(() {
    // In tests, `_instance` is never initialized (no plugin registrant),
    // so we set the fake platform directly.
    platform = _FakeFilePickerPlatform();
    FilePicker.platform = platform;
    picker = FilePickerDocumentFilePicker();
  });

  test('cancelled → DocumentPickCancelled', () async {
    platform.result = null;

    expect(await picker.pick(), isA<DocumentPickCancelled>());
  });

  test('withData: false required (no RAM loading before the guard)', () async {
    platform.result = null;

    await picker.pick();

    expect(platform.lastWithData, isFalse);
    expect(platform.lastAllowedExtensions, documentAllowedExtensions);
  });

  test('invalid extension → DocumentPickInvalidType', () async {
    platform.result = FilePickerResult([
      _platformFile(name: 'script.exe', size: 10, path: '/tmp/x'),
    ]);

    expect(await picker.pick(), isA<DocumentPickInvalidType>());
  });

  test(
    '> 10 MB → TooLarge WITHOUT reading the file (nonexistent path)',
    () async {
      // The path doesn't exist: if the picker tried to read it, the
      // result would be Unreadable — TooLarge proves the size guard
      // runs before the read (review 3.8 #1).
      platform.result = FilePickerResult([
        _platformFile(
          name: 'gros.pdf',
          size: documentMaxSizeBytes + 1,
          path: '/chemin/inexistant.pdf',
        ),
      ]);

      expect(await picker.pick(), isA<DocumentPickTooLarge>());
    },
  );

  test('size OK but unreadable file → DocumentPickUnreadable', () async {
    platform.result = FilePickerResult([
      _platformFile(name: 'note.pdf', size: 10, path: '/chemin/inexistant.pdf'),
    ]);

    expect(await picker.pick(), isA<DocumentPickUnreadable>());
  });

  test('missing path (web/desktop) → DocumentPickUnreadable', () async {
    platform.result = FilePickerResult([
      _platformFile(name: 'note.pdf', size: 10),
    ]);

    expect(await picker.pick(), isA<DocumentPickUnreadable>());
  });

  test('valid file → read from the path (DocumentPickedFile)', () async {
    final temp = await File(
      '${Directory.systemTemp.path}/picker_test_${DateTime.now().microsecondsSinceEpoch}.pdf',
    ).writeAsBytes(Uint8List.fromList('%PDF-fake'.codeUnits));
    addTearDown(() => temp.delete());

    platform.result = FilePickerResult([
      _platformFile(name: 'releve.pdf', size: 9, path: temp.path),
    ]);

    final picked = await picker.pick();

    expect(picked, isA<DocumentPickedFile>());
    final file = picked as DocumentPickedFile;
    expect(file.name, 'releve.pdf');
    expect(String.fromCharCodes(file.bytes), '%PDF-fake');
  });

  test('misreported size: re-checked after reading', () async {
    // declared size under the limit, actual content above it → TooLarge
    // (belt and suspenders).
    final big = Uint8List(documentMaxSizeBytes + 1);
    final temp = await File(
      '${Directory.systemTemp.path}/picker_big_${DateTime.now().microsecondsSinceEpoch}.png',
    ).writeAsBytes(big);
    addTearDown(() => temp.delete());

    platform.result = FilePickerResult([
      _platformFile(name: 'big.png', size: 10, path: temp.path),
    ]);

    expect(await picker.pick(), isA<DocumentPickTooLarge>());
  });
}
