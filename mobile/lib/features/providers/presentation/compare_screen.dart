import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/score_badge.dart';
import '../data/provider_dtos.dart';
import 'widgets/provider_widgets.dart';

/// Comparison of 2–3 3a products — port of iOS's `CompareView`.
///
/// Products are passed in by the list screen (selection from the
/// scored ranking): there is **no** comparison-by-ids endpoint
/// (verified in `provider.routes.ts` — `GET /providers/compare`
/// only takes filters); as on iOS, the comparison is purely
/// client-side, built from the already-loaded DTOs.
class CompareScreen extends StatelessWidget {
  const CompareScreen({required this.products, super.key});

  final List<ScoredProductDto> products;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final lowestFee = products.fold<double>(
      double.infinity,
      (min, p) => p.allInFeePercent < min ? p.allInFeePercent : min,
    );
    final best = products.reduce(
      (a, b) => a.score >= b.score ? a : b,
    );
    final hasReturns = products.any((p) => p.avgReturn3y != null);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.compareTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header cards: score + provider + product.
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final product in products)
                  Expanded(
                    child: Column(
                      children: [
                        ScoreBadge(score: product.score),
                        const SizedBox(height: 8),
                        Text(
                          product.providerName,
                          style: Theme.of(context).textTheme.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.productName,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Annual fees (the cheapest shown in green).
          _CompareSection(
            title: l10n.compareFees,
            icon: Icons.sell_outlined,
            child: Column(
              children: [
                for (final product in products)
                  ComparisonBarRow(
                    label: product.providerName,
                    value: formatPercent(product.allInFeePercent),
                    fraction:
                        product.allInFeePercent /
                        products.fold<double>(
                          0.01,
                          (max, p) =>
                              p.allInFeePercent > max
                                  ? p.allInFeePercent
                                  : max,
                        ),
                    color: product.allInFeePercent == lowestFee
                        ? colors.positive
                        : colors.warning,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Average 3-year return (hidden if no product has one).
          if (hasReturns) ...[
            _CompareSection(
              title: l10n.compareReturns,
              icon: Icons.trending_up,
              child: Column(
                children: [
                  for (final product in products)
                    if (product.avgReturn3y != null)
                      ComparisonBarRow(
                        label: product.providerName,
                        value: formatPercent(
                          product.avgReturn3y!,
                          decimals: 1,
                        ),
                        fraction:
                            product.avgReturn3y!.abs() /
                            products.fold<double>(
                              0.01,
                              (max, p) =>
                                  (p.avgReturn3y?.abs() ?? 0) > max
                                      ? p.avgReturn3y!.abs()
                                      : max,
                            ),
                        color: product.avgReturn3y! >= 0
                            ? colors.positive
                            : colors.negative,
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Equity share (0–100 scale).
          _CompareSection(
            title: l10n.compareAllocation,
            icon: Icons.pie_chart_outline,
            child: Column(
              children: [
                for (final product in products)
                  ComparisonBarRow(
                    label: product.providerName,
                    value: '${product.equityAllocation} %',
                    fraction: product.equityAllocation / 100,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.7),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detail table.
          AppCard(
            child: Column(
              children: [
                _CompareTableRow(
                  label: l10n.compareScore,
                  cells: [
                    for (final product in products)
                      Text(
                        '${product.score}/100',
                        style: _cellStyle(
                          context,
                          product.score >= 70
                              ? colors.positive
                              : product.score >= 40
                              ? colors.warning
                              : colors.negative,
                        ),
                      ),
                  ],
                ),
                const Divider(),
                _CompareTableRow(
                  label: l10n.compareFeesLabel,
                  cells: [
                    for (final product in products)
                      Column(
                        children: [
                          Text(
                            formatPercent(product.allInFeePercent),
                            style: _cellStyle(context),
                          ),
                          if (product.allInFeePercent == lowestFee)
                            Text(
                              l10n.compareLowest,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.positive),
                            ),
                        ],
                      ),
                  ],
                ),
                const Divider(),
                _CompareTableRow(
                  label: l10n.compareReturn3y,
                  cells: [
                    for (final product in products)
                      product.avgReturn3y != null
                          ? Text(
                              formatPercent(
                                product.avgReturn3y!,
                                decimals: 1,
                              ),
                              style: _cellStyle(
                                context,
                                product.avgReturn3y! >= 0
                                    ? colors.positive
                                    : colors.negative,
                              ),
                            )
                          : Text(
                              '—',
                              style: _cellStyle(
                                context,
                                Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                  ],
                ),
                const Divider(),
                _CompareTableRow(
                  label: l10n.compareEsgLabel,
                  cells: [
                    for (final product in products)
                      Icon(
                        product.sustainableEsg ? Icons.eco : Icons.close,
                        size: 18,
                        color: product.sustainableEsg
                            ? colors.positive
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
                const Divider(),
                _CompareTableRow(
                  label: l10n.compareEquity,
                  cells: [
                    for (final product in products)
                      Text(
                        '${product.equityAllocation} %',
                        style: _cellStyle(context),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Verdict: best overall score.
          AppCard(
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 28,
                  color: Color(0xFFFFC107),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.compareBestChoice,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${best.providerName} — ${best.productName}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle? _cellStyle(BuildContext context, [Color? color]) =>
      Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: color);
}

/// Titled section with icon (fees, returns, allocation).
class _CompareSection extends StatelessWidget {
  const _CompareSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Row in the comparison table: label on the left, one centered
/// cell per product.
class _CompareTableRow extends StatelessWidget {
  const _CompareTableRow({required this.label, required this.cells});

  final String label;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final cell in cells)
            Expanded(
              child: Center(child: cell),
            ),
        ],
      ),
    );
  }
}
