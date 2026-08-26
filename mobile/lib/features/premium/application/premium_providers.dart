import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/purchases/premium_status.dart';
import '../../financial_profile/application/financial_profile_providers.dart';

/// Optimistic unlock after a successful purchase/restore (`premium`
/// entitlement active in RevenueCat's `CustomerInfo`): the RevenueCat →
/// backend webhook can take a few moments to populate `subscriptions`
/// — without this flag, a user who just paid would still see the
/// locks during that propagation delay.
///
/// Reset to false on logout and account switch (`PocketPillarApp`
/// listeners). Session-scoped only: on next startup, `users/me` (the
/// source of truth) takes over.
final optimisticPremiumProvider = StateProvider<bool>((ref) => false);

/// Displayed premium status, merging two sources (contract §11):
///
/// 1. the `premium` block from `GET /users/me` (shared profile
///    aggregate) — **source of truth**; it wins as soon as it's
///    active (and then carries the real expiry date);
/// 2. the optimistic post-purchase unlock, while the webhook
///    propagates (with no known expiry date).
///
/// Aggregate not loaded yet or errored → non-premium (locks are
/// shown; any 402 opens the paywall regardless).
final premiumStatusProvider = Provider<PremiumStatus>((ref) {
  final backend =
      ref
          .watch(profileAggregateProvider)
          .valueOrNull
          ?.base
          .premium ??
      PremiumStatus.none;
  if (backend.active) return backend;
  if (ref.watch(optimisticPremiumProvider)) {
    return const PremiumStatus(active: true);
  }
  return backend;
});

/// Shortcut for UI gates: `ref.watch(premiumActiveProvider)`.
final premiumActiveProvider = Provider<bool>(
  (ref) => ref.watch(premiumStatusProvider).active,
);
