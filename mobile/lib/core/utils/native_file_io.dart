/// Native file access isolated behind a conditional import: the web
/// build doesn't compile `dart:io`. Selected at build time:
/// VM/native → `_io`, web (js_interop) → `_web`.
library;

export 'native_file_io_stub.dart'
    if (dart.library.io) 'native_file_io_io.dart'
    if (dart.library.js_interop) 'native_file_io_web.dart';
