import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../application/educational_tips.dart';

/// "Tip of the day" section (parity with iOS's `TipCard`): educational
/// tip chosen by daily rotation.
class TipOfDaySection extends StatelessWidget {
  const TipOfDaySection({required this.tip, super.key});

  final EducationalTip tip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashboardTipOfDay, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(tip.icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.title(l10n), style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      tip.body(l10n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
