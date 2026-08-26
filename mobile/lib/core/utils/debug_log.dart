import 'package:flutter/foundation.dart';

/// `debugPrint` confined to debug mode: diagnostic messages (reminder
/// rescheduling failures, biometrics unavailable...) must write nothing
/// to logs in release (full review 2026-08, security minor).
void debugLog(String message) {
  if (kDebugMode) debugPrint(message);
}
