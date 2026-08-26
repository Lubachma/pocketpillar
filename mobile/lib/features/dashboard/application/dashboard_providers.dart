import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../financial_profile/application/financial_profile_providers.dart';
import '../data/dashboard_dtos.dart';
import '../data/dashboard_repository.dart';

/// Main dashboard aggregate (user, profile, accounts,
/// projection). The 4 profile endpoints come from the shared aggregate
/// [profileAggregateProvider] (I9, full review 2026-08) — only the
/// projection stays specific to the dashboard. Pull-to-refresh / retry:
/// `ref.invalidate(profileAggregateProvider)` (the dashboard rebuilds via
/// its watch).
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final aggregate = await ref.watch(profileAggregateProvider.future);
  return ref.watch(dashboardRepositoryProvider).loadFrom(aggregate);
});

/// Personalized recommendations — **separate** provider for a retry
/// localized to the section (the incomplete-profile 422 is mapped to `null`
/// by the repository: empty state, not an error).
final recommendationsProvider = FutureProvider<RecommendationResultDto?>(
  (ref) => ref.watch(dashboardRepositoryProvider).loadRecommendations(),
);

/// Pension score /100 + age benchmark — **separate** provider (like
/// the recommendations): incomplete-profile 422 → `null` (card hidden),
/// error → retry localized to the card.
final scoreProvider = FutureProvider<PensionScoreDto?>(
  (ref) => ref.watch(dashboardRepositoryProvider).loadScore(),
);
