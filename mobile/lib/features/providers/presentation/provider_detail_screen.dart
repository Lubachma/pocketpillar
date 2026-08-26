import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/primary_button.dart';
import '../application/providers_providers.dart';
import '../data/provider_dtos.dart';
import 'widgets/provider_widgets.dart';

/// Detailed sheet for a 3a provider — `GET /providers/:slug`
/// (iOS used the data already in memory; the detail endpoint is
/// consumed here for the first time: it brings the **year-by-year
/// performance history**, absent from iOS).
///
/// States: loading, error with retry, 404 → "not found" state.
class ProviderDetailScreen extends ConsumerWidget {
  const ProviderDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(providerDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(title: Text(detail.valueOrNull?.name ?? '')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 40,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    providerErrorMessage(l10n, error),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: l10n.commonRetry,
                    onPressed: () =>
                        ref.invalidate(providerDetailProvider(slug)),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (provider) => provider == null
            ? Center(child: Text(l10n.providersEmpty))
            : _ProviderDetailBody(provider: provider),
      ),
    );
  }
}

class _ProviderDetailBody extends StatelessWidget {
  const _ProviderDetailBody({required this.provider});

  final ProviderDto provider;

  /// Opens the provider's website in the browser; on failure (no
  /// browser, invalid URL, platform with no handler), a localized
  /// snackbar is shown instead of a silent crash.
  Future<void> _openWebsite(BuildContext context, String url) async {
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('launchUrl a renvoyé false');
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.providersWebsiteError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final productsWithFees = [
      for (final p in provider.products)
        if (p.fees != null) p,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.description != null) ...[
          Text(
            provider.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (provider.website != null)
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(
                Icons.language,
                color: theme.colorScheme.primary,
              ),
              title: Text(l10n.providersVisitWebsite),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openWebsite(context, provider.website!),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          l10n.providersProducts,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final product in provider.products) ...[
          _ProductCard(product: product),
          const SizedBox(height: 8),
        ],
        if (productsWithFees.length > 1) ...[
          const SizedBox(height: 16),
          Text(
            l10n.providersFeeComparison,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          AppCard(
            child: _FeeComparisonBars(products: productsWithFees),
          ),
        ],
      ],
    );
  }
}

/// Product card: name, risk/ESG badges, category, equity share,
/// detailed fees (hidden if absent) and per-year return (hidden if
/// the history is empty — e.g. a list response with no history).
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProviderProductDto product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fees = product.fees;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.providersRiskLevel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              RiskBadge(riskLevel: product.riskLevel),
              if (product.sustainableEsg) const EsgBadge(),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: l10n.providersCategory,
            value: investmentCategoryLabel(
              l10n,
              product.investmentCategory,
            ),
          ),
          _DetailRow(
            label: l10n.providersEquityShort,
            value: '${product.equityAllocation} %',
          ),
          if (fees != null) ...[
            const Divider(height: 24),
            Text(
              l10n.providersFeesDetail,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            _DetailRow(
              label: l10n.providersAllInFee,
              value: formatPercent(fees.allInFeePercent),
            ),
            _DetailRow(
              label: l10n.providersTer,
              value: formatPercent(fees.terPercent),
            ),
            if (fees.custodyFeePercent != null)
              _DetailRow(
                label: l10n.providersCustodyFee,
                value: formatPercent(fees.custodyFeePercent!),
              ),
            if (fees.entryFeePercent > 0)
              _DetailRow(
                label: l10n.providersEntryFee,
                value: formatPercent(fees.entryFeePercent),
              ),
            if (fees.exitFeePercent > 0)
              _DetailRow(
                label: l10n.providersExitFee,
                value: formatPercent(fees.exitFeePercent),
              ),
          ],
          if (product.performanceHistory.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              l10n.providersPerformance,
              style: theme.textTheme.labelLarge,
            ),
            // The backend caps history at 5 years (take: 5) — the
            // seeded 6th year never arrives: we label the window
            // rather than imply a complete history (2026-08 review).
            if (product.performanceHistory.length >= 5)
              Text(
                l10n.providersPerformanceWindow,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 4),
            for (final year in product.performanceHistory)
              _DetailRow(
                label: '${year.year}',
                value: formatPercent(year.returnPercent, decimals: 1),
                valueColor: year.returnPercent >= 0
                    ? context.appColors.positive
                    : theme.colorScheme.error,
              ),
          ],
        ],
      ),
    );
  }
}

/// Label → value row of the product sheet.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// All-in fee comparison bars across the provider's products —
/// replaces iOS's SwiftUI `Chart` (bars colored by risk level, %
/// annotation on the right).
class _FeeComparisonBars extends StatelessWidget {
  const _FeeComparisonBars({required this.products});

  final List<ProviderProductDto> products;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxFee = products.fold<double>(
      0.01,
      (max, p) =>
          p.fees!.allInFeePercent > max ? p.fees!.allInFeePercent : max,
    );
    return Column(
      children: [
        for (final product in products)
          ComparisonBarRow(
            label: product.name,
            value: formatPercent(product.fees!.allInFeePercent),
            fraction: product.fees!.allInFeePercent / maxFee,
            color: riskLevelColor(product.riskLevel, colors),
          ),
      ],
    );
  }
}
