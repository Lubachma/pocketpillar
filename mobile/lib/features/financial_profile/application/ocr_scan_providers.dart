import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scan_image_picker.dart';
import '../data/text_recognition_service.dart';

/// On-device OCR engine (Apple Vision on iOS, ML Kit on Android — see
/// `data/text_recognition_service.dart`) — substituted with a fake in
/// tests.
final textRecognitionServiceProvider = Provider<TextRecognitionService>(
  (ref) => createTextRecognitionService(),
);

/// Image picker (camera / gallery) — substituted with a fake in tests.
final scanImagePickerProvider = Provider<ScanImagePicker>(
  (ref) => ImagePickerScanImagePicker(),
);
