import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Web variant: no path — `file_picker` provides the bytes
/// directly (pickFiles called with `withData: true` on web).
Future<Uint8List?> readPickedFileBytes(PlatformFile file) async => file.bytes;

/// No file system on web — nothing to clean up.
void deleteFileSync(String path) {}
