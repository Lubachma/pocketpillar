import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Native variant (Android/iOS/desktop): reads via the pick's path.
Future<Uint8List?> readPickedFileBytes(PlatformFile file) {
  final path = file.path;
  if (path == null) return Future<Uint8List?>.value();
  return File(path).readAsBytes();
}

/// Best-effort deletion: cleanup must never mask the result (OCR
/// scan, upload...).
void deleteFileSync(String path) {
  try {
    File(path).deleteSync();
  } on Object {
    // Best-effort.
  }
}
