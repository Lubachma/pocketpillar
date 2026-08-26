import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/biometric_lock.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/notifications/annual_reminders.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/pillar3a_reminder.dart';
import '../../../core/utils/app_version.dart';
import '../../../core/utils/debug_log.dart';
import '../../financial_profile/application/financial_profile_providers.dart';
import '../../premium/application/premium_providers.dart';
import '../data/account_repository.dart';

/// Settings — parity with iOS's `ProfileView` (phase 3.10).
///
/// Sections: profile (link to financial profile 3.3 + account email),
/// language, security (biometric lock), notifications (annual
/// reminders), about (version, privacy policy), account (sign out,
/// deletion). Not carried over from iOS (like 3.3): appearance,
/// "replay onboarding", couple access, PDF export.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  /// Offered locales (fr/de/en); names stay in their own language
  /// (endonyms, not translated).
  static const List<Locale> _locales = [
    Locale('fr'),
    Locale('de'),
    Locale('en'),
  ];

  static String _languageName(Locale locale) => switch (locale.languageCode) {
    'de' => 'Deutsch',
    'en' => 'English',
    _ => 'Français',
  };

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Account deletion in progress (tile disabled + spinner).
  bool _deletingAccount = false;

  Future<void> _signOut() async {
    // Also resets any dev bypass (debug only).
    if (kDebugMode) {
      ref.read(devAuthBypassProvider.notifier).state = false;
    }
    // The shared profile aggregate is non-autoDispose (I9): without
    // invalidation, it would leak the departing account's data into
    // the next logged-in account.
    ref.invalidate(profileAggregateProvider);
    await ref.read(authRepositoryProvider).signOut();
  }

  /// Annual reminders toggle: permission is requested on activation
  /// (denied → toggle unchanged + snackbar), then both reminders are
  /// scheduled/cancelled and the state is persisted.
  Future<void> _setAnnualReminders(bool enabled) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(notificationServiceProvider);
    if (!enabled) {
      await ref
          .read(annualRemindersEnabledProvider.notifier)
          .setEnabled(false);
      await service.cancelAnnualReminders();
      return;
    }
    await service.initialize();
    final granted = await service.requestPermission();
    if (!mounted) return;
    if (!granted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsNotificationsDenied)),
      );
      return;
    }
    await ref.read(annualRemindersEnabledProvider.notifier).setEnabled(true);
    // Contextual 3a body (batch 7): real remaining amount if the
    // profile can be read, generic otherwise — via the factory
    // injected in main() (null by default → generic; the resolution
    // never throws).
    final loadPillar3aContext = ref.read(pillar3aReminderContextLoaderProvider);
    final pillar3aContext = await loadPillar3aContext?.call();
    await service.scheduleAnnualReminders(
      yearEndChecklistBody: l10n.notificationYearEndChecklist,
      pillar3aBody: pillar3aReminderBody(l10n, pillar3aContext),
    );
  }

  /// Explicit confirmation → `DELETE /users/me` → cancel annual
  /// reminders (pref + scheduling) → sign out (the router redirects
  /// to /login once the session becomes null).
  /// On a DELETE error the account still exists: no sign out,
  /// snackbar with the message (localized backend / network).
  /// After a successful DELETE, no local error (cancellation,
  /// revoke) hides the success.
  Future<void> _deleteAccount() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsDeleteConfirmTitle),
        content: Text(l10n.settingsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.authCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.settingsDeleteAccount,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingAccount = true);
    try {
      await ref.read(accountRepositoryProvider).deleteAccount();
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    } on NetworkException {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorNetwork)));
      }
      return;
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
    // Account deleted on the backend side: local cleanup, no step
    // depends on the widget or should hide the success.
    if (kDebugMode) {
      ref.read(devAuthBypassProvider.notifier).state = false;
    }
    // Shared profile aggregate (I9): purges the deleted account's data.
    ref.invalidate(profileAggregateProvider);
    // Without this reset, reminders would be rescheduled on next
    // startup for a deleted account.
    try {
      await ref
          .read(annualRemindersEnabledProvider.notifier)
          .setEnabled(false);
      await ref.read(notificationServiceProvider).cancelAnnualReminders();
    } on Object catch (e) {
      debugLog('Annual reminders not cancelled on account deletion: $e');
    }
    // Any network revoke doesn't hide the success.
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on Object catch (e) {
      debugLog('signOut after account deletion failed: $e');
    }
  }

  /// Subtitle of the Premium tile: "Subscribed — until `date`",
  /// "Subscribed" (unknown expiry), or "Not subscribed — CHF 39/year".
  String _premiumSubtitle() {
    final l10n = context.l10n;
    final premium = ref.watch(premiumStatusProvider);
    if (!premium.active) return l10n.settingsPremiumInactive;
    final expiresAt = premium.expiresAt;
    if (expiresAt == null) return l10n.settingsPremiumActive;
    return l10n.settingsPremiumActiveUntil(
      DateFormat.yMMMd(l10n.localeName).format(expiresAt.toLocal()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final biometricEnabled = ref.watch(biometricLockEnabledProvider);
    final remindersEnabled = ref.watch(annualRemindersEnabledProvider);
    final locale = ref.watch(localeProvider);
    final email = ref.watch(authRepositoryProvider).currentEmail;
    final version = ref.watch(appVersionProvider).valueOrNull ?? '—';
    final errorColor = Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(l10n.settingsSectionProfile),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.financialProfileTitle),
            subtitle: Text(l10n.profileSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.settingsProfile),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(l10n.authEmail),
            subtitle: Text(email ?? '—'),
          ),
          // Premium subscription (contract §11): status from
          // `users/me` (+ optimistic post-purchase unlock); the
          // paywall handles purchase and restore.
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l10n.settingsPremiumTitle),
            subtitle: Text(_premiumSubtitle()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.paywall),
          ),
          _SectionHeader(l10n.settingsSectionLanguage),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.profileLanguage),
            trailing: DropdownButton<Locale>(
              value: locale,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(value);
                }
              },
              items: [
                for (final item in SettingsScreen._locales)
                  DropdownMenuItem(
                    value: item,
                    child: Text(SettingsScreen._languageName(item)),
                  ),
              ],
            ),
          ),
          // Biometrics and local reminders: native only — hidden on web.
          if (!kIsWeb) ...[
            _SectionHeader(l10n.profileSectionSecurity),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(l10n.settingsBiometricLock),
              value: biometricEnabled,
              onChanged: (value) => ref
                  .read(biometricLockEnabledProvider.notifier)
                  .setEnabled(value),
            ),
            _SectionHeader(l10n.settingsSectionNotifications),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: Text(l10n.settingsAnnualReminders),
              subtitle: Text(l10n.settingsAnnualRemindersSubtitle),
              value: remindersEnabled,
              onChanged: _setAnnualReminders,
            ),
          ],
          _SectionHeader(l10n.profileAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.profileVersion),
            trailing: Text(version),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.settingsPrivacy),
          ),
          _SectionHeader(l10n.profileSectionAccount),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.authSignOut),
            onTap: _signOut,
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: errorColor),
            title: Text(
              l10n.settingsDeleteAccount,
              style: TextStyle(color: errorColor),
            ),
            trailing: _deletingAccount
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _deletingAccount ? null : _deleteAccount,
          ),
        ],
      ),
    );
  }
}

/// Settings section header (Material equivalent of iOS's grouped
/// sections).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
