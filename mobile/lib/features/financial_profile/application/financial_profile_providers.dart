import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/financial_profile_dtos.dart';
import '../data/financial_profile_repository.dart';

/// Shared profile aggregate (I9, full review 2026-08): `users/me` +
/// `financial-profile` + LPP/3a accounts, loaded **once** for the whole
/// app. Dashboard, profile screen, scenarios (prefill) and the calculator
/// derive their views from it instead of each fetching the same 4
/// endpoints.
///
/// Deliberately non-autoDispose (sharing is the point). Mutations:
/// saving the profile / logout → `ref.invalidate(profileAggregateProvider)`
/// (reloads everything; consumers watching it — dashboard… — rebuild in
/// cascade); CRUD on an account →
/// [ProfileAggregateNotifier.refreshPillar2Accounts] /
/// [ProfileAggregateNotifier.refreshPillar3aAccounts] (only reload the
/// relevant list, without rebuilding the profile form).
final profileAggregateProvider =
    AsyncNotifierProvider<ProfileAggregateNotifier, ProfileAggregate>(
      ProfileAggregateNotifier.new,
    );

class ProfileAggregateNotifier extends AsyncNotifier<ProfileAggregate> {
  @override
  Future<ProfileAggregate> build() =>
      ref.watch(financialProfileRepositoryProvider).loadAggregate();

  /// Reloads only the LPP accounts list after a CRUD op — the base
  /// (and thus the form's `loadedAt` key) stays unchanged.
  Future<void> refreshPillar2Accounts() async {
    final accounts = await ref
        .read(financialProfileRepositoryProvider)
        .fetchPillar2Accounts();
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      ProfileAggregate(
        base: current.base,
        pillar2Accounts: accounts,
        pillar3aAccounts: current.pillar3aAccounts,
      ),
    );
  }

  /// Same pattern as [refreshPillar2Accounts], for 3a accounts.
  Future<void> refreshPillar3aAccounts() async {
    final accounts = await ref
        .read(financialProfileRepositoryProvider)
        .fetchPillar3aAccounts();
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      ProfileAggregate(
        base: current.base,
        pillar2Accounts: current.pillar2Accounts,
        pillar3aAccounts: accounts,
      ),
    );
  }
}

/// User + financial profile (null on initial 404 → creation mode).
/// Derived from the shared aggregate; retry: `ref.invalidate(profileAggregateProvider)`.
final profileBaseProvider = FutureProvider.autoDispose<ProfileBaseData>(
  (ref) async => (await ref.watch(profileAggregateProvider.future)).base,
);

/// LPP accounts, derived from the shared aggregate. autoDispose: leaving
/// the screen drops the view, the underlying aggregate stays cached.
final pillar2AccountsProvider =
    FutureProvider.autoDispose<List<Pillar2AccountDto>>(
      (ref) async =>
          (await ref.watch(profileAggregateProvider.future)).pillar2Accounts,
    );

/// 3a accounts — same pattern as [pillar2AccountsProvider].
final pillar3aAccountsProvider =
    FutureProvider.autoDispose<List<Pillar3aAccountDto>>(
      (ref) async =>
          (await ref.watch(profileAggregateProvider.future)).pillar3aAccounts,
    );
