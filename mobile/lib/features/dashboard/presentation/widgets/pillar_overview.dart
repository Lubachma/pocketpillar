import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/utils/currency.dart';
import '../../data/dashboard_dtos.dart';

/// Three mini pillar cards (AVS / LPP / 3a), cyan/blue/purple colors
/// reused from the iOS style guide.
class PillarOverview extends StatelessWidget {
  const PillarOverview({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appColors = context.appColors;

    final avsPension = data.projection?.estimatedAnnualAvsPension;
    // iOS parity: the LPP card shows the projected annual pension
    // (not the capital); "—" without a projection.
    final lppPension = data.projection?.annualPillar2Pension;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PillarCard(
            label: l10n.pillar1Short,
            value: avsPension != null ? formatChf(avsPension) : '—',
            color: appColors.pillar1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PillarCard(
            label: l10n.pillar2Short,
            value: lppPension != null ? formatChf(lppPension) : '—',
            color: appColors.pillar2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PillarCard(
            label: l10n.pillar3aShort,
            value: data.hasPillar3a
                ? formatChf(data.totalPillar3aBalance)
                : '—',
            color: appColors.pillar3a,
          ),
        ),
      ],
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
