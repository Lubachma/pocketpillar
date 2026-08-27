import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;
import 'package:local_auth/local_auth.dart';

import '../l10n/l10n.dart';
import '../storage/preferences.dart';
import '../utils/debug_log.dart';
import 'auth_repository.dart';

/// Enables the biometric lock.
///
/// Persisted in settings (shared_preferences), reread at startup.
final biometricLockEnabledProvider =
    NotifierProvider<BiometricLockEnabledNotifier, bool>(
      BiometricLockEnabledNotifier.new,
    );

class BiometricLockEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesRepositoryProvider).biometricLockEnabled;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref
        .read(preferencesRepositoryProvider)
        .setBiometricLockEnabled(enabled);
  }
}

/// Current lock state (true = lock screen shown).
final biometricLockedProvider = StateProvider<bool>((ref) => false);

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);

/// Biometric authentication (Face ID / Touch ID / Android biometrics).
class BiometricService {
  BiometricService([LocalAuthentication? localAuth])
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Returns true if the user is authenticated.
  ///
  /// **Fail-open** only when biometrics is structurally unavailable on
  /// the device (no hardware, nothing enrolled, no PIN code): the lock
  /// wouldn't make sense. **Fail-closed** in all other cases
  /// (cancellation, temporary lockout, auth in progress...).
  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(localizedReason: reason);
    } on LocalAuthException catch (e) {
      const unavailable = {
        LocalAuthExceptionCode.noBiometricHardware,
        LocalAuthExceptionCode.noBiometricsEnrolled,
        LocalAuthExceptionCode.noCredentialsSet,
      };
      final canUnlock = unavailable.contains(e.code);
      debugLog(
        canUnlock
            ? 'Biométrie indisponible (${e.code.name}) : déverrouillage dégradé'
            : 'Échec biométrique (${e.code.name}) : verrou maintenu',
      );
      return canUnlock;
    } on PlatformException catch (e) {
      // Safety net (e.g. missing plugin): we never unlock.
      debugLog('Biometric error (${e.code}): lock kept');
      return false;
    }
  }
}

/// Locks the app when it comes back from the background after more than
/// [lockAfter] seconds (parity with the iOS BiometricLockView).
///
/// Also covers the UI with an opaque veil when the app is inactive or
/// in the background: the app-switcher thumbnail shows no financial
/// data (in the spirit of the biometric lock).
class BiometricLock extends ConsumerStatefulWidget {
  const BiometricLock({required this.child, super.key});

  static const Duration lockAfter = Duration(seconds: 60);

  final Widget child;

  @override
  ConsumerState<BiometricLock> createState() => _BiometricLockState();
}

class _BiometricLockState extends ConsumerState<BiometricLock> {
  late final AppLifecycleListener _lifecycleListener;
  DateTime? _backgroundedAt;

  /// Cold-start arming done once per run (review 08.2026: the lock only
  /// armed on background return — a kill/relaunch with a persisted
  /// session landed straight on the financial data).
  bool _coldStartChecked = false;

  /// Veil for the multitasking thumbnail visibility (app inactive/backgrounded).
  bool _obscured = false;

  /// Arms the lock only when the run STARTS with a persisted session
  /// (`sessionChanges` yields the restored session first, so the first
  /// resolved emission decides — it may still be loading at the first
  /// frame, hence the build-time listener rather than a one-shot
  /// initState read). A session appearing later is a fresh login: the
  /// user just proved who they are, prompting biometrics on top would
  /// be wrong. Known miss: an expired persisted token resolves to null
  /// before its async refresh, so that relaunch skips the lock.
  void _maybeArmColdStart(AsyncValue<Session?> session) {
    if (_coldStartChecked) return;
    if (session.isLoading) return;
    _coldStartChecked = true;
    if (session.valueOrNull == null) return;
    if (!ref.read(biometricLockEnabledProvider)) return;
    // Never mutate providers during build: arm and prompt after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(biometricLockedProvider.notifier).state = true;
      unawaited(_unlock());
    });
  }

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      // iOS takes the app-switcher thumbnail during `inactive`;
      // Android covers the background (`pause`).
      onInactive: _obscure,
      onPause: () {
        _obscure();
        _backgroundedAt = DateTime.now();
      },
      onResume: _onResume,
    );
  }

  void _obscure() {
    if (!_obscured) setState(() => _obscured = true);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onResume() {
    if (_obscured) setState(() => _obscured = false);
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) return;
    if (!ref.read(biometricLockEnabledProvider)) return;
    final loggedIn = ref.read(authSessionProvider).valueOrNull != null;
    if (!loggedIn) return;
    if (DateTime.now().difference(backgroundedAt) <= BiometricLock.lockAfter) {
      return;
    }
    ref.read(biometricLockedProvider.notifier).state = true;
    unawaited(_unlock());
  }

  bool _unlocking = false;

  Future<void> _unlock() async {
    // Anti-reentrancy: only one biometric prompt at a time.
    if (_unlocking) return;
    _unlocking = true;
    try {
      final reason = context.l10n.biometricReason;
      final success = await ref
          .read(biometricServiceProvider)
          .authenticate(reason);
      if (success && mounted) {
        ref.read(biometricLockedProvider.notifier).state = false;
      }
    } finally {
      _unlocking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (_, next) => _maybeArmColdStart(next));
    _maybeArmColdStart(ref.read(authSessionProvider));
    final locked = ref.watch(biometricLockedProvider);
    return Stack(
      children: [
        widget.child,
        if (locked) Positioned.fill(child: _LockScreen(onUnlock: _unlock)),
        // Last: also covers the lock screen in the thumbnail.
        if (_obscured) const Positioned.fill(child: _AppSwitcherVeil()),
      ],
    );
  }
}

/// Opaque veil for the multitasking thumbnail: solid color + logo, no
/// data at all. Visible in `inactive` (iOS app-switcher) and in the
/// background (Android).
class _AppSwitcherVeil extends StatelessWidget {
  const _AppSwitcherVeil();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.primary,
      child: Center(
        child: Icon(
          Icons.shield_outlined,
          size: 72,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// Full-screen lock screen (financial data hidden).
class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final Future<void> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.biometricLockedMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onUnlock,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l10n.biometricUnlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
