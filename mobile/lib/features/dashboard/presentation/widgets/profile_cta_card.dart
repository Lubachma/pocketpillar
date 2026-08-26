import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/primary_button.dart';

/// Card inviting the user to complete their profile (dashboard empty state:
/// financial profile never created, or projection not calculable).
///
/// **Non-blocking** CTA to `/settings/profile` (financial profile screen,
/// phase 3.3) — `go` switches the shell branch to Settings.
class ProfileCtaCard extends StatelessWidget {
  const ProfileCtaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        children: [
          Icon(Icons.person_outline, size: 40, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            l10n.dashboardEmptyTitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dashboardEmptyBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: l10n.dashboardEmptyCta,
            icon: Icons.arrow_forward,
            onPressed: () => context.go(Routes.settingsProfile),
          ),
        ],
      ),
    );
  }
}
