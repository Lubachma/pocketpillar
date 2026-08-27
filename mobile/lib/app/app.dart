import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_repository.dart';
import '../core/auth/biometric_lock.dart';
import '../core/l10n/gen/app_localizations.dart';
import '../core/l10n/locale_provider.dart';
import '../core/notifications/annual_reminders.dart';
import '../core/notifications/notification_service.dart';
import '../core/notifications/pillar3a_reminder.dart';
import '../core/purchases/purchases_service_provider.dart';
import '../core/storage/preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/debug_log.dart';
import '../features/financial_profile/application/financial_profile_providers.dart';
import '../features/dashboard/application/dashboard_providers.dart';
import '../features/documents/application/documents_providers.dart';
import '../features/premium/application/premium_providers.dart';
import 'router.dart';

/// PocketPillar application.
class PocketPillarApp extends ConsumerStatefulWidget {
  const PocketPillarApp({super.key});

  @override
  ConsumerState<PocketPillarApp> createState() => _PocketPillarAppState();
}

class _PocketPillarAppState extends ConsumerState<PocketPillarApp> {
  @override
  void initState() {
    super.initState();
    // Contextual 3a reminder (batch 7, review): the remaining amount to
    // pay in comes from the network — never before runApp. main() has
    // already scheduled the generic body; we reschedule it contextually
    // after the 1st frame, in the background (zonedSchedule replaces the
    // same ids: idempotent).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_rescheduleContextualAnnualReminders());
    });
  }

  Future<void> _rescheduleContextualAnnualReminders() async {
    if (kIsWeb) return; // Native local reminders only.
    final prefs = ref.read(preferencesRepositoryProvider);
    if (!prefs.annualRemindersEnabled) return;
    try {
      final loadContext = ref.read(pillar3aReminderContextLoaderProvider);
      final context = await loadContext?.call();
      // No context (not signed in, no profile, error): the generic body
      // scheduled by main() is already the right one — nothing to do.
      if (context == null || !mounted) return;
      final l10n = await AppLocalizations.delegate.load(
        ref.read(localeProvider),
      );
      if (!mounted) return;
      await syncAnnualRemindersAtStartup(
        service: ref.read(notificationServiceProvider),
        prefs: prefs,
        l10n: l10n,
        pillar3aContext: context,
      );
    } on Object catch (e) {
      // The generic one stays scheduled; the next launch will retry.
      debugLog('Contextual 3a reminder not scheduled at startup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cross-account leak (full review 2026-08, "with fixes" #1): the
    // profile aggregate is non-autoDispose (I9) — without invalidation, a
    // 401 (signOut via `onAuthExpired`) or a sign-out would leave the
    // previous account's data visible to the next one in the same run.
    // We compare `user.id`: a plain token refresh (new `Session`
    // instance, same user) invalidates nothing.
    // The listener lives here (core doesn't know about features) rather
    // than in `api_client` — no core → feature cycle.
    ref.listen(authSessionProvider, (previous, next) {
      final previousUserId = previous?.valueOrNull?.user.id;
      final nextUserId = next.valueOrNull?.user.id;
      if (previousUserId != nextUserId) {
        ref.invalidate(profileAggregateProvider);
        // Same leak class for every non-autoDispose account-data provider
        // (review 08.2026): user A opens Documents/Dashboard → sign-out →
        // user B logs in in the SAME run → without these, B saw A's
        // documents, recommendations and score.
        ref.invalidate(dashboardProvider);
        ref.invalidate(recommendationsProvider);
        ref.invalidate(scoreProvider);
        ref.invalidate(documentsProvider);
      }
      // Sign-out: `Purchases.logOut()` (best-effort, no-op without an
      // SDK key) and end of the optimistic unlock — the next account
      // starts fresh from the `users/me` status.
      if (previousUserId != null && nextUserId == null) {
        ref.read(optimisticPremiumProvider.notifier).state = false;
        unawaited(ref.read(purchasesServiceProvider).logOut());
      }
    });
    // RevenueCat (contract §11): `Purchases.logIn(<users.id>)` as soon as
    // the **backend** user is known — the local uuid from `users/me` is
    // the `app_user_id`, never the Supabase id. The service deduplicates
    // (the aggregate is often invalidated/reloaded for the same account).
    // Listener **conditioned on the session**: `ref.listen` activates the
    // watched provider — without the guard, the aggregate would be
    // fetched as early as the login screen (unnecessary 401 before login).
    if (ref.watch(authSessionProvider).valueOrNull != null) {
      ref.listen(profileAggregateProvider, (previous, next) {
        final previousId = previous?.valueOrNull?.base.userId;
        final nextId = next.valueOrNull?.base.userId;
        if (nextId == null) return;
        if (previousId != null && previousId != nextId) {
          // Account change within the same run (without passing through
          // a null session): the optimistic unlock does not carry over.
          ref.read(optimisticPremiumProvider.notifier).state = false;
        }
        unawaited(ref.read(purchasesServiceProvider).logIn(nextId));
      });
    }
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'PocketPillar',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      // Native: the biometric lock covers the whole screen.
      // Never mounted on web: `local_auth` has no web implementation
      // (unrecoverable MissingPluginException) and the pref defaults to
      // true (preferences.dart).
      // Wide-screen web: centered mobile column (v1) — pointless under 600px.
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!kIsWeb) return BiometricLock(child: content);
        if (MediaQuery.sizeOf(context).width <= 600) return content;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
