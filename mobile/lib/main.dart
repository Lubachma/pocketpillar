import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/api/api_config.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/supabase_config.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/notifications/annual_reminders.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/pillar3a_reminder.dart';
import 'core/storage/preferences.dart';
import 'core/utils/debug_log.dart';
import 'features/financial_profile/application/pillar3a_reminder_context.dart';
import 'features/financial_profile/data/financial_profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Wake the scale-to-zero demo API while the user reads the first
  // screen (fire-and-forget — outcome deliberately ignored; the
  // cold-start retry interceptor covers whatever this misses).
  unawaited(
    Dio()
        .get<void>('${ApiConfig.baseUrl}/health')
        .then((_) {}, onError: (Object _) {}),
  );
  // Without dart-defines, the app still starts (null client → /login).
  // Both initializations are independent → run in parallel (full
  // review 2026-08, startup minor).
  final (_, prefs) = await (
    SupabaseConfig.initialize(),
    SharedPreferences.getInstance(),
  ).wait;
  final preferences = PreferencesRepository(prefs);

  // Annual reminders (phase 3.10): rescheduled at startup when the
  // toggle is enabled — refreshes the notifications' language.
  // Batch 7: the generic body is scheduled here (no network before
  // runApp); the contextual rescheduling follows after the 1st frame,
  // in the tree (PocketPillarApp), via the factory injected below.
  final notificationService = LocalNotificationService();
  // Native local reminders only: nothing to schedule on web.
  if (!kIsWeb && preferences.annualRemindersEnabled) {
    try {
      final l10n = await AppLocalizations.delegate.load(
        preferences.locale ?? const Locale('fr'),
      );
      await syncAnnualRemindersAtStartup(
        service: notificationService,
        prefs: preferences,
        l10n: l10n,
      );
    } on Object catch (e) {
      // Platform channel unavailable: the app starts without rescheduling.
      debugLog('Annual reminders not rescheduled at startup: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notificationService),
        // 3a context for reminders (batch 7): injected here because the
        // data lives in the financial profile feature, unknown to core.
        pillar3aReminderContextLoaderProvider.overrideWith(
          (ref) => () => loadPillar3aReminderContext(
            auth: ref.read(authRepositoryProvider),
            profiles: ref.read(financialProfileRepositoryProvider),
          ),
        ),
      ],
      child: const PocketPillarApp(),
    ),
  );
}
