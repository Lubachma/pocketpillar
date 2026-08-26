import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/utils/currency.dart';
import '../../../premium/presentation/widgets/premium_widgets.dart';
import '../../../scenarios/presentation/widgets/scenario_widgets.dart';
import '../../application/dashboard_providers.dart';
import '../../data/dashboard_dtos.dart';

/// "Recommendations" section: top 3 from `GET /recommendations`.
///
/// States: loading (loader in a card), error (message + retry
/// **localized to the section**), 422 → empty state inviting to complete the
/// profile, empty list → encouragement (iOS "good track" parity),
/// 402 → Premium upsell card (contract §11 — `/score` stays
/// free, only this section is locked).
class RecommendationsSection extends ConsumerWidget {
  const RecommendationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final recommendations = ref.watch(recommendationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardRecommendationsTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        switch (recommendations) {
          AsyncData(value: final result) =>
            result == null || result.recommendations.isEmpty
                ? AppCard(
                    child: Text(
                      result == null
                          ? l10n.dashboardRecommendationsEmpty
                          : l10n.dashboardRecGoodTrack,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : Column(
                    children: [
                      for (final recommendation
                          in result.recommendations.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RecommendationCard(
                            recommendation: recommendation,
                          ),
                        ),
                      ScenarioInfoCard(
                        icon: Icons.balance,
                        text: l10n.generalSimulationDisclaimer,
                        color: context.appColors.warning,
                      ),
                    ],
                  ),
          // 402: recommendations reserved for Premium → empty state
          // "paywall-style" (not an error).
          AsyncError(error: PremiumRequiredException()) => PremiumUpsellCard(
            message: l10n.premiumUpsellRecommendations,
          ),
          AsyncError(:final error) => AppCard(
            child: Column(
              children: [
                Text(
                  _errorMessage(l10n, error),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(recommendationsProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
          _ => const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        },
      ],
    );
  }
}

String _errorMessage(AppLocalizations l10n, Object error) => switch (error) {
  NetworkException() => l10n.errorNetwork,
  ApiException(:final message) => message,
  _ => l10n.errorUnknown,
};

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final RecommendationDto recommendation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = _priorityColor(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_typeIcon(), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (recommendation.estimatedAnnualImpact > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.dashboardEstimatedAnnualImpact(
                      formatChf(recommendation.estimatedAnnualImpact),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.appColors.positive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// iOS color parity: HIGH red, MEDIUM orange, LOW accent.
  Color _priorityColor(BuildContext context) => switch (recommendation
      .priority) {
    'HIGH' => context.appColors.negative,
    'MEDIUM' => context.appColors.warning,
    _ => Theme.of(context).colorScheme.primary,
  };

  /// iOS icon parity (SF Symbols → Material).
  IconData _typeIcon() => switch (recommendation.type) {
    'OPEN_FIRST_3A' => Icons.add_circle,
    'MAX_3A_CONTRIBUTION' => Icons.savings,
    'PROVIDER_SWITCH' => Icons.swap_horiz,
    'BVG_VOLUNTARY_PURCHASE' => Icons.arrow_upward,
    'OPEN_ADDITIONAL_3A' => Icons.call_split,
    _ => Icons.lightbulb,
  };
}
