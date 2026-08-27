import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/primary_button.dart';
import '../../../core/theme/components/score_badge.dart';
import '../application/providers_providers.dart';
import '../data/provider_dtos.dart';
import 'widgets/provider_widgets.dart';

/// 3a providers — port of iOS's `ProvidersView` (phase 3.7).
///
/// - Best Match CTA (`/providers/best-match`);
/// - ranking of scored products (`GET /providers/compare?riskLevel=`),
///   filterable by risk level (appbar menu, 5 levels),
///   selecting 2–3 products → comparison (`/providers/compare`);
/// - providers catalogue (`GET /providers`) → detail sheet
///   (`/providers/:slug`).
///
/// States: loading, error with retry (catalogue **or** ranking
/// failed), empty. Pull-to-refresh everywhere (the list stays
/// scrollable in every state). iOS's offline fallback
/// (`OfflineProviderData`) is not ported over: API = source of truth.
class ProvidersScreen extends ConsumerWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final riskLevel = ref.watch(providersRiskFilterProvider);
    final catalogue = ref.watch(providersCatalogueProvider);
    final scored = ref.watch(scoredProductsProvider(riskLevel));

    final error = catalogue.error ?? scored.error;
    final data = catalogue.hasValue && scored.hasValue
        ? (providers: catalogue.value!, scored: scored.value!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.providersTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n.providersFilter,
            initialValue: riskLevel,
            onSelected: (level) {
              ref.read(providersRiskFilterProvider.notifier).state = level;
              // iOS behavior: the selection is reset when the filter
              // changes (the ranking changes).
              ref.read(compareSelectionProvider.notifier).state = {};
            },
            itemBuilder: (context) => [
              for (final level in providerRiskLevels)
                PopupMenuItem(
                  value: level,
                  child: Row(
                    children: [
                      Expanded(child: Text(riskLevelLabel(l10n, level))),
                      if (level == riskLevel)
                        Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref, riskLevel),
        child: data != null
            ? _ProvidersContent(providers: data.providers, scored: data.scored)
            : error != null
            ? _ProvidersError(error: error, riskLevel: riskLevel)
            : const _ProvidersLoading(),
      ),
    );
  }

  /// Invalidates both providers and awaits both reloads; the error
  /// is carried by the [AsyncValue]s, never by the refresh future.
  Future<void> _onRefresh(WidgetRef ref, String riskLevel) async {
    ref.invalidate(providersCatalogueProvider);
    ref.invalidate(scoredProductsProvider(riskLevel));
    try {
      await Future.wait([
        ref.read(providersCatalogueProvider.future),
        ref.read(scoredProductsProvider(riskLevel).future),
      ]);
    } on Object {
      // Error state shown by the screen.
    }
  }
}

class _ProvidersLoading extends StatelessWidget {
  const _ProvidersLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(
          height: 420,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _ProvidersError extends ConsumerWidget {
  const _ProvidersError({required this.error, required this.riskLevel});

  final Object error;
  final String riskLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 420,
          child: Center(
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 40,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    providerErrorMessage(l10n, error),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: l10n.commonRetry,
                    onPressed: () {
                      ref.invalidate(providersCatalogueProvider);
                      ref.invalidate(scoredProductsProvider(riskLevel));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProvidersContent extends ConsumerWidget {
  const _ProvidersContent({required this.providers, required this.scored});

  final List<ProviderDto> providers;
  final List<ScoredProductDto> scored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // I8 (full review 2026-08): the selection is **not** watched here
    // — each tile only listens to its own boolean (`select`) and only
    // the "Compare" button derives the selection. A (de)selection
    // therefore rebuilds neither this column nor the catalogue.

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Best Match CTA.
        AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            title: Text(l10n.bestmatchTitle, style: theme.textTheme.titleSmall),
            subtitle: Text(l10n.bestmatchSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.providerBestMatch),
          ),
        ),
        const SizedBox(height: 24),

        // Scored ranking with selection for comparison.
        if (scored.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.providersRanking,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                l10n.providersTapToCompare,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                for (final product in scored)
                  _ScoredProductTile(product: product),
              ],
            ),
          ),
          // "Compare" button: the only widget in the column that
          // watches the selection (I8) — it alone rebuilds when it
          // changes.
          _CompareButton(scored: scored),
          const SizedBox(height: 24),
        ],

        // Providers catalogue.
        Text(l10n.providersAll, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (providers.isEmpty)
          AppCard(
            child: Text(
              l10n.providersEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final provider in providers)
                  ListTile(
                    title: Text(provider.name),
                    subtitle: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${provider.products.length} '
                          '${l10n.providersProducts}',
                        ),
                        if (provider.isDigital)
                          _DigitalBadge(label: l10n.providersDigital),
                      ],
                    ),
                    leading: provider.isDigital
                        ? Icon(
                            Icons.smartphone,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/providers/${provider.slug}'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Digital" badge for purely online providers (catalogue).
class _DigitalBadge extends StatelessWidget {
  const _DigitalBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "Compare N products" button — visible from 2 selected products.
/// Extracted from [_ProvidersContent] (I8): it's the only consumer
/// of the full selection; the rest of the screen doesn't rebuild on
/// every tap.
class _CompareButton extends ConsumerWidget {
  const _CompareButton({required this.scored});

  final List<ScoredProductDto> scored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selection = ref.watch(compareSelectionProvider);
    final selectedProducts = [
      for (final product in scored)
        if (selection.contains(product.productId)) product,
    ];
    if (selectedProducts.length < 2) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 12),
        PrimaryButton(
          label: l10n.providersCompareSelected(selectedProducts.length),
          icon: Icons.compare_arrows,
          onPressed: () =>
              context.push(Routes.providerCompare, extra: selectedProducts),
        ),
      ],
    );
  }
}

/// Scored product row with a selection circle (max
/// [compareMaxSelection]) — equivalent of iOS's `scoredRow`.
class _ScoredProductTile extends ConsumerWidget {
  const _ScoredProductTile({required this.product});

  final ScoredProductDto product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    // I8: the tile only rebuilds when **its own** selection toggles,
    // not on every change to the set.
    final selected = ref.watch(
      compareSelectionProvider.select((s) => s.contains(product.productId)),
    );

    return InkWell(
      onTap: () {
        final notifier = ref.read(compareSelectionProvider.notifier);
        final selection = ref.read(compareSelectionProvider);
        if (selected) {
          notifier.state = {...selection}..remove(product.productId);
        } else if (selection.length < compareMaxSelection) {
          notifier.state = {...selection, product.productId};
        }
      },
      child: Container(
        color: selected
            ? colors.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? colors.primary : colors.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.providerName, style: theme.textTheme.titleSmall),
                  Text(
                    product.productName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MiniMetric(
                        label: l10n.providersFeeShort,
                        value: formatPercent(product.allInFeePercent),
                      ),
                      _MiniMetric(
                        label: l10n.providersEquityShort,
                        value: '${product.equityAllocation} %',
                      ),
                      if (product.avgReturn3y != null)
                        _MiniMetric(
                          label: l10n.providersReturnShort,
                          value: formatPercent(
                            product.avgReturn3y!,
                            decimals: 1,
                          ),
                          valueColor: product.avgReturn3y! >= 0
                              ? context.appColors.positive
                              : theme.colorScheme.error,
                        ),
                      if (product.sustainableEsg)
                        Icon(Icons.eco, size: 16, color: Colors.green.shade600),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ScoreBadge(score: product.score),
          ],
        ),
      ),
    );
  }
}

/// Compact metric (label above, value below) — equivalent of the
/// fee/equity/return `VStack`s in the iOS row.
class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}
