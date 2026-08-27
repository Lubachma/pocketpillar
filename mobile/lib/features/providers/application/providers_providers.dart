import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/provider_dtos.dart';
import '../data/provider_repository.dart';

/// Risk levels, ascending order (backend `RiskLevel` enum, same list
/// as iOS's `ProvidersViewModel.riskLevels`).
const List<String> providerRiskLevels = [
  'CONSERVATIVE',
  'MODERATE',
  'BALANCED',
  'GROWTH',
  'AGGRESSIVE',
];

/// Maximum number of products selectable for comparison (mission
/// spec: 2–3; iOS allowed 4).
const int compareMaxSelection = 3;

/// Suggested risk level based on age — mapping carried over as-is
/// from iOS's `UserProfileStore.riskLevelForAge` (best-match prefill).
String riskLevelForAge(int age) {
  if (age < 35) return 'GROWTH';
  if (age < 45) return 'BALANCED';
  if (age < 55) return 'MODERATE';
  return 'CONSERVATIVE';
}

/// Ranking risk filter — defaults to GROWTH (iOS default
/// `ProvidersViewModel.selectedRisk`).
final providersRiskFilterProvider = StateProvider<String>((ref) => 'GROWTH');

/// Providers catalogue (`GET /providers`). Pull-to-refresh /
/// retry: `ref.invalidate(providersCatalogueProvider)`.
final providersCatalogueProvider = FutureProvider<List<ProviderDto>>(
  (ref) => ref.watch(providerRepositoryProvider).listProviders(),
);

/// Scored ranking for the given risk level
/// (`GET /providers/compare?riskLevel=`).
final scoredProductsProvider =
    FutureProvider.family<List<ScoredProductDto>, String>(
      (ref, riskLevel) => ref
          .watch(providerRepositoryProvider)
          .compareProducts(riskLevel: riskLevel),
    );

/// Ids of products selected for comparison (max
/// [compareMaxSelection] — the cap is enforced by the screen).
/// Reset when the risk filter changes (iOS behavior).
final compareSelectionProvider = StateProvider<Set<String>>((ref) => {});

/// Provider detail sheet (`GET /providers/:slug`) — null if the slug
/// is unknown (repository 404 → "not found" state).
final providerDetailProvider = FutureProvider.autoDispose
    .family<ProviderDto?, String>(
      (ref, slug) => ref.watch(providerRepositoryProvider).getProvider(slug),
    );
