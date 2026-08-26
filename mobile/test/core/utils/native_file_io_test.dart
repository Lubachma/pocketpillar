import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/utils/native_file_io.dart';

void main() {
  group('readPickedFileBytes (VM variant)', () {
    test('reads the bytes via the native path', () async {
      final dir = Directory.systemTemp.createTempSync('pp_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/releve.pdf')..writeAsBytesSync([1, 2, 3]);
      final picked = PlatformFile(name: 'releve.pdf', size: 3, path: file.path);

      expect(await readPickedFileBytes(picked), [1, 2, 3]);
    });

    test(
      'returns null without a path (on web, bytes would come from the pick)',
      () async {
        final picked = PlatformFile(name: 'releve.pdf', size: 3);

        expect(await readPickedFileBytes(picked), isNull);
      },
    );
  });

  group('deleteFileSync', () {
    test('deletes the file', () {
      final dir = Directory.systemTemp.createTempSync('pp_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/tmp.jpg')..writeAsBytesSync([0]);

      deleteFileSync(file.path);

      expect(file.existsSync(), isFalse);
    });

    test('tolerates a missing file (best-effort cleanup)', () {
      expect(() => deleteFileSync('/chemin/inexistant'), returnsNormally);
    });
  });
}
