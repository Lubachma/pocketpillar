import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/components/app_card.dart';
import '../../premium/application/premium_providers.dart';

/// Life scenarios hub (tab 3) — port of iOS's `ScenariosView`: 5
/// cards leading to the simulators (couple first, as on iOS).
///
/// Paywall option B (contract §11): couple, staggered withdrawal,
/// property purchase, and divorce are Premium — lock icon for
/// non-subscribers, tap then opens the paywall. The 3a catch-up
/// stays accessible (free preview handled by its own screen).
class ScenariosScreen extends ConsumerWidget {
  const ScenariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final premium = ref.watch(premiumActiveProvider);

    void open(String route, {required bool isPremiumScenario}) {
      context.push(
        isPremiumScenario && !premium ? Routes.paywall : route,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scenarioTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.scenarioSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _ScenarioCard(
            icon: Icons.people_outline,
            color: colors.negative,
            title: l10n.coupleScenarioTitle,
            subtitle: l10n.coupleScenarioSubtitle,
            locked: !premium,
            onTap: () =>
                open(Routes.scenarioCouple, isPremiumScenario: true),
          ),
          const SizedBox(height: 8),
          _ScenarioCard(
            icon: Icons.history,
            color: colors.pillar2,
            title: l10n.scenario3aCatchupTitle,
            subtitle: l10n.scenario3aCatchupSubtitle,
            onTap: () =>
                open(Routes.scenarioCatchup3a, isPremiumScenario: false),
          ),
          const SizedBox(height: 8),
          _ScenarioCard(
            icon: Icons.home,
            color: colors.positive,
            title: l10n.scenarioPropertyTitle,
            subtitle: l10n.scenarioPropertySubtitle,
            locked: !premium,
            onTap: () => open(
              Routes.scenarioPropertyPurchase,
              isPremiumScenario: true,
            ),
          ),
          const SizedBox(height: 8),
          _ScenarioCard(
            icon: Icons.stacked_bar_chart,
            color: colors.pillar3a,
            title: l10n.scenarioWithdrawalTitle,
            subtitle: l10n.scenarioWithdrawalSubtitle,
            locked: !premium,
            onTap: () => open(
              Routes.scenarioStaggeredWithdrawal,
              isPremiumScenario: true,
            ),
          ),
          const SizedBox(height: 8),
          _ScenarioCard(
            icon: Icons.call_split,
            color: colors.warning,
            title: l10n.scenarioDivorceTitle,
            subtitle: l10n.scenarioDivorceSubtitle,
            locked: !premium,
            onTap: () =>
                open(Routes.scenarioDivorceImpact, isPremiumScenario: true),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.scenarioFooter,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Access card for a scenario: colored icon, title, subtitle,
/// chevron (parity with iOS's `NavigationLink`). [locked] replaces
/// the chevron with a lock icon (Premium scenario, non-subscriber) —
/// tap then opens the paywall (handled by the caller).
class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                Semantics(
                  label: context.l10n.premiumBadgeLabel,
                  child: Icon(
                    Icons.lock_outline,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
