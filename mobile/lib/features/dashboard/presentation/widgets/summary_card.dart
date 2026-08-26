import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/utils/currency.dart';
import '../../data/dashboard_dtos.dart';

/// Summary card: estimated replacement rate (retirement projection from
/// the calculator API) and progress toward the user's target.
class SummaryCard extends StatelessWidget {
  const SummaryCard({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = context.appColors;
    final projection = data.projection!;

    final rate = projection.replacementRate.round();
    final goal = data.user.replacementRateGoal;
    final progress = goal > 0 ? (rate / goal).clamp(0.0, 1.0) : 0.0;
    final goalReached = rate >= goal;
    final monthlyIncome = (projection.totalAnnualRetirementIncome / 12).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashboardSynthesisTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text(
                  '$rate %',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.dashboardSummary(rate),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.resultsPensionMonthly(formatChf(monthlyIncome)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboardGoalProgress,
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '$rate % / $goal %',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            color: goalReached ? appColors.positive : colorScheme.primary,
          ),
          if (goalReached) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: appColors.positive),
                const SizedBox(width: 4),
                Text(
                  l10n.dashboardGoalReached,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: appColors.positive,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
