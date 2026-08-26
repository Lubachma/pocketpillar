import 'package:image_picker/image_picker.dart';

/// Source of the image to scan.
enum ScanImageSource { camera, gallery }

/// Abstraction over the image picker (platform channel `image_picker`) —
/// substitutable in tests via `scanImagePickerProvider` (same pattern as
/// `DocumentFilePicker` in the documents feature).
abstract class ScanImagePicker {
  /// Local path of the chosen image, or null if the user cancelled.
  Future<String?> pickImagePath(ScanImageSource source);
}

class ImagePickerScanImagePicker implements ScanImagePicker {
  @override
  Future<String?> pickImagePath(ScanImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source == ScanImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // A smartphone photo is several thousand px: 2500 px is plenty
      // for OCR and bounds memory use.
      maxWidth: 2500,
      maxHeight: 2500,
    );
    return file?.path;
  }
}
