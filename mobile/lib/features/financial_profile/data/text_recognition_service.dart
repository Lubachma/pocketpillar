import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Abstraction over the text recognition engine — **on-device** (no
/// image ever leaves the phone, a key privacy argument for a Swiss
/// financial app). Substituted in tests via
/// `textRecognitionServiceProvider`: tests never touch the native
/// channel.
abstract class TextRecognitionService {
  /// Raw text recognized on the image at [imagePath] — empty string if
  /// the image contains no usable text.
  Future<String> recognizeText(String imagePath);
}

/// Native implementation via the `ch.pocketpillar.app/ocr` MethodChannel.
///
/// The engine depends on the platform, on the native code side (same
/// channel):
/// - **iOS**: Apple Vision (`VNRecognizeTextRequest`, `OcrPlugin.swift`) —
///   system framework, native arm64 simulator, no pod;
/// - **Android**: ML Kit (`com.google.mlkit:text-recognition`,
///   `OcrPlugin.kt`) — Gradle dependency, so never linked on iOS.
///
/// Replaces the `google_mlkit_text_recognition` pub package: its iOS
/// binaries have no arm64 simulator slice, and iOS 26 no longer runs
/// x86_64 — the simulator refused installation ("must be updated by the
/// developer").
class NativeTextRecognitionService implements TextRecognitionService {
  static const _channel = MethodChannel('ch.pocketpillar.app/ocr');

  @override
  Future<String> recognizeText(String imagePath) async {
    final text = await _channel.invokeMethod<String>(
      'recognizeText',
      {'imagePath': imagePath},
    );
    return text ?? '';
  }
}

/// Selects the implementation based on the platform — [platform] is
/// injectable to test the selector. iOS and Android go through the same
/// native channel (the engine choice, Vision / ML Kit, is made on the
/// native side); other platforms have no handler → an explicit error
/// rather than a late `MissingPluginException`.
TextRecognitionService createTextRecognitionService({
  TargetPlatform? platform,
}) {
  final effectivePlatform = platform ?? defaultTargetPlatform;
  if (effectivePlatform == TargetPlatform.iOS ||
      effectivePlatform == TargetPlatform.android) {
    return NativeTextRecognitionService();
  }
  throw UnsupportedError('OCR non supporté sur $effectivePlatform.');
}
