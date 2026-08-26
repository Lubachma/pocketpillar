import 'package:flutter/material.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';

/// Formats a percentage per the project's convention ("0.44 %").
String formatPercent(num value, {int decimals = 2}) =>
    '${value.toStringAsFixed(decimals)} %';

/// Localized error message: network → generic message, otherwise the
/// backend's `{ error }` message (already localized via Accept-Language).
String providerErrorMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      NetworkException() => l10n.errorNetwork,
      ApiException(:final message) => message,
      _ => l10n.errorUnknown,
    };

/// Color for a risk level — palette carried over from iOS's
/// `ProviderDetailView.riskColor` (blue → red).
Color riskLevelColor(String riskLevel, AppSemanticColors colors) =>
    switch (riskLevel) {
      'CONSERVATIVE' => AppColors.accent,
      'MODERATE' => colors.pillar1,
      'BALANCED' => colors.positive,
      'GROWTH' => colors.warning,
      'AGGRESSIVE' => colors.negative,
      _ => colors.warning,
    };

/// Localized label for a risk level (same keys as iOS:
/// `bestmatch.risk.<level>.title`).
String riskLevelLabel(AppLocalizations l10n, String riskLevel) =>
    switch (riskLevel) {
      'CONSERVATIVE' => l10n.bestmatchRiskConservativeTitle,
      'MODERATE' => l10n.bestmatchRiskModerateTitle,
      'BALANCED' => l10n.bestmatchRiskBalancedTitle,
      'GROWTH' => l10n.bestmatchRiskGrowthTitle,
      'AGGRESSIVE' => l10n.bestmatchRiskAggressiveTitle,
      _ => riskLevel,
    };

/// Localized label for an investment category (backend enum
/// `InvestmentCategory`).
String investmentCategoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'PASSIVE_INDEX' => l10n.providersCategoryPassiveIndex,
      'ACTIVE_MANAGED' => l10n.providersCategoryActiveManaged,
      'INSURANCE' => l10n.providersCategoryInsurance,
      'SAVINGS_ACCOUNT' => l10n.providersCategorySavings,
      _ => category,
    };

/// Score /100 badge: moved to `core/theme/components/score_badge.dart`
/// (shared with the dashboard since batch 3).

/// Risk-level badge (label + level color).
class RiskBadge extends StatelessWidget {
  const RiskBadge({required this.riskLevel, super.key});

  final String riskLevel;

  @override
  Widget build(BuildContext context) {
    final color = riskLevelColor(riskLevel, context.appColors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        riskLevelLabel(context.l10n, riskLevel),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// "Sustainable" ESG badge (green leaf, capsule).
class EsgBadge extends StatelessWidget {
  const EsgBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.positive.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, size: 14, color: colors.positive),
          const SizedBox(width: 4),
          Text(
            context.l10n.providersEsgBadge,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.positive,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Comparative horizontal bar (fees, returns, allocation) — replaces
/// iOS's SwiftUI `Chart`s, with no external dependency (same pattern
/// as the calculator's `ProjectionBarChart`).
class ComparisonBarRow extends StatelessWidget {
  const ComparisonBarRow({
    required this.label,
    required this.value,

    /// Bar fraction (0–1) — ratio against the series' max.
    required this.fraction,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.02, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
