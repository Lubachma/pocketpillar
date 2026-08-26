import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/score_badge.dart';
import '../../../../core/utils/currency.dart';
import '../../application/dashboard_providers.dart';
import '../../data/dashboard_dtos.dart';

/// "Pension health" card: score /100 from `GET /score` with
/// breakdown by criterion and comparison to the age bracket
/// averages (port of the iOS gauge, batch 3).
///
/// States: loading (loader card), error (message + retry localized to
/// the card), incomplete-profile 422 → `null` provider → card **hidden**.
/// The card carries its own bottom spacing when visible (the parent
/// doesn't insert a separator).
class ScoreCard extends ConsumerWidget {
  const ScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final score = ref.watch(scoreProvider);

    return switch (score) {
      AsyncData(value: final dto) =>
        dto == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ScoreCardContent(dto: dto),
              ),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AppCard(
          child: Column(
            children: [
              Text(
                _errorMessage(l10n, error),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(scoreProvider),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: AppCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    };
  }
}

String _errorMessage(AppLocalizations l10n, Object error) => switch (error) {
  NetworkException() => l10n.errorNetwork,
  ApiException(:final message) => message,
  _ => l10n.errorUnknown,
};

class _ScoreCardContent extends StatelessWidget {
  const _ScoreCardContent({required this.dto});

  final PensionScoreDto dto;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final benchmark = dto.benchmark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashboardScoreLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  ScoreBadge(score: dto.score, dimension: 84),
                  const SizedBox(height: 4),
                  Text(
                    '/100',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (final item in dto.breakdown)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                item.label,
                                style: theme.textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${item.points}/${item.maxPoints}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
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
          if (benchmark.hasBracket) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              l10n.dashboardScoreBenchmarkTitle(
                benchmark.bracketMinAge!,
                benchmark.bracketMaxAge!,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            _BenchmarkRow(
              text: l10n.dashboardScoreBenchmarkRate(
                '${benchmark.userReplacementRate.round()} %',
                '${benchmark.averageReplacementRate.round()} %',
              ),
              aboveOrAtAverage:
                  benchmark.userReplacementRate >=
                  benchmark.averageReplacementRate,
            ),
            _BenchmarkRow(
              text: l10n.dashboardScoreBenchmark3a(
                formatChf(benchmark.userPillar3aBalance),
                formatChf(benchmark.averagePillar3aBalance),
              ),
              aboveOrAtAverage:
                  benchmark.userPillar3aBalance >=
                  benchmark.averagePillar3aBalance,
            ),
            _BenchmarkRow(
              text: l10n.dashboardScoreBenchmarkBvg(
                formatChf(benchmark.userBvgCapital),
                formatChf(benchmark.averageBvgCapital),
              ),
              aboveOrAtAverage:
                  benchmark.userBvgCapital >= benchmark.averageBvgCapital,
            ),
          ],
        ],
      ),
    );
  }
}

/// Comparison row to the age average: colored trend icon
/// (green if ≥ average, orange otherwise) + values.
class _BenchmarkRow extends StatelessWidget {
  const _BenchmarkRow({required this.text, required this.aboveOrAtAverage});

  final String text;
  final bool aboveOrAtAverage;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            aboveOrAtAverage ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: aboveOrAtAverage ? colors.positive : colors.warning,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
