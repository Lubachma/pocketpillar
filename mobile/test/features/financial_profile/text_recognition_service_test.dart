import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/financial_profile/data/text_recognition_service.dart';

void main() {
  group('createTextRecognitionService — platform selector', () {
    test(
      'iOS → native channel (Apple Vision on the native side, OcrPlugin.swift)',
      () {
        expect(
          createTextRecognitionService(platform: TargetPlatform.iOS),
          isA<NativeTextRecognitionService>(),
        );
      },
    );

    test(
      'android → native channel (ML Kit on the native side, OcrPlugin.kt)',
      () {
        expect(
          createTextRecognitionService(platform: TargetPlatform.android),
          isA<NativeTextRecognitionService>(),
        );
      },
    );

    test('platform without native handler → explicit UnsupportedError', () {
      expect(
        () => createTextRecognitionService(platform: TargetPlatform.macOS),
        throwsUnsupportedError,
      );
      expect(
        () => createTextRecognitionService(platform: TargetPlatform.linux),
        throwsUnsupportedError,
      );
    });
  });
}
