import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// App version (read from native metadata = pubspec) shown in
/// Settings. Falls back to "—" if the platform channel is
/// unavailable. Overridden in tests.
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  } on Object {
    return '—';
  }
});
