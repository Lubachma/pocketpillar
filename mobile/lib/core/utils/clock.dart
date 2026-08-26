import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared injectable clock: greeting, season, checklist persistence
/// year, and tip of the day depend on it (overridden in tests).
///
/// Lives in `core` — not in a feature — to avoid a checklist ↔
/// dashboard cycle at the provider level (review 3.9 #1).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
