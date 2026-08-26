import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Default body — never selected in practice (io or js_interop
/// always match), required by the conditional import syntax.
Future<Uint8List?> readPickedFileBytes(PlatformFile file) =>
    throw UnsupportedError('native_file_io : plateforme inconnue');

void deleteFileSync(String path) {}
