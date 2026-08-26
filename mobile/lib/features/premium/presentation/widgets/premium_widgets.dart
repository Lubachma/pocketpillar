import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/components/app_card.dart';

/// Opens the paywall if [error] is the contract's 402 (§11); true if
/// the error was handled — the calling screen then **doesn't** show
/// an error card (the input is preserved for the return trip).
bool redirectToPaywallIf402(BuildContext context, Object error) {
  if (error is! PremiumRequiredException) return false;
  GoRouter.of(context).push(Routes.paywall);
  return true;
}

/// "Paywall-style" upsell card: lock, message, CTA to the paywall.
/// Used as the premium empty state (recommendations, best-match) and
/// as an invitation below the free preview of the 3a catch-up.
class PremiumUpsellCard extends StatelessWidget {
  const PremiumUpsellCard({required this.message, this.title, super.key});

  /// Optional title (e.g. "Unlock the year-by-year plan").
  final String? title;

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(Routes.paywall),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(l10n.premiumDiscoverCta),
            ),
          ),
        ],
      ),
    );
  }
}
