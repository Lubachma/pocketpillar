import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/components/app_card.dart';

/// Educational sheet about the LPP buyback — ported from
/// `ios/.../Features/Calculator/BvgBuybackInfoSheet.swift`
/// (what / benefits / steps, `buyback*` keys).
class BuybackInfoSheet extends StatelessWidget {
  const BuybackInfoSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const BuybackInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pillar2 = context.appColors.pillar2;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: pillar2.withValues(alpha: 0.12),
                  child: Icon(Icons.add_circle, color: pillar2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.buybackTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoCard(
              icon: Icons.lightbulb,
              title: l10n.buybackWhatTitle,
              body: l10n.buybackWhatBody,
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.star,
              title: l10n.buybackBenefitsTitle,
              body: l10n.buybackBenefitsBody,
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.format_list_numbered,
              title: l10n.buybackStepsTitle,
              body: l10n.buybackStepsBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pillar2 = context.appColors.pillar2;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: pillar2),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
