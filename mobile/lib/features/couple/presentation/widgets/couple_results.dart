import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/utils/currency.dart';
import '../../../calculator/presentation/widgets/help_sheet.dart';
import '../../../calculator/presentation/widgets/results_view.dart';
import '../../../scenarios/presentation/widgets/scenario_widgets.dart';
import '../../data/couple_result.dart';

/// Result cards of the couple simulation, extracted from
/// `couple_screen.dart` (readability refactor 08.2026). Everything is
/// rendered from the server response — no business rule here.

/// Results: combined summary (+ AVS cap alert), side-by-side
/// comparison, couple taxation (married vs unmarried) and coordinated
/// withdrawal plan — everything comes from the server.
class CoupleResultsSection extends StatelessWidget {
  const CoupleResultsSection({required this.result, super.key});

  final CoupleResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CombinedSummaryCard(result: result),
        const SizedBox(height: 16),
        _ComparisonCard(result: result),
        const SizedBox(height: 16),
        _TaxEstimateCard(estimate: result.taxEstimate),
        const SizedBox(height: 16),
        _WithdrawalPlanCard(plan: result.withdrawalPlan),
      ],
    );
  }
}

/// Combined summary (parity with the iOS summary): combined monthly
/// income, combined replacement rate, couple AVS cap alert if reached.
class _CombinedSummaryCard extends StatelessWidget {
  const _CombinedSummaryCard({required this.result});

  final CoupleResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final rate = result.combinedReplacementRate;

    return AppCard(
      child: Column(
        children: [
          ScenarioSectionTitle(l10n.coupleCombinedTitle),
          const SizedBox(height: 8),
          Text(
            formatChf(result.combinedTotalAnnualIncome ~/ 12),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            l10n.coupleCombinedMonthly,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ScenarioMetricRow(
            label: l10n.coupleReplacementRate,
            value: '${rate.toStringAsFixed(0)} %',
            // Same scale as the guided calculator (`rateColor`).
            valueColor: rateColor(colors, rate),
            trailing: const HelpButton(termId: 'replacement_rate'),
          ),
          if (result.avsCapApplied) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 20, color: colors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.coupleAvsCapWarning,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Phasing nuance (practitioner review 08.2026): with
                        // an age gap the older spouse keeps a full pension
                        // until the younger retires — this simulation shows
                        // the situation once both pensions are paid.
                        Text(
                          l10n.coupleAvsCapPhasing,
                          style: theme.textTheme.bodySmall?.copyWith(
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
        ],
      ),
    );
  }
}

/// Side-by-side comparison — per-spouse values AFTER the couple AVS cap
/// (`personNIncome`, allocated pro rata server-side). The practitioner
/// review (08.2026) showed that uncapped per-person rows next to a capped
/// total read as inflated pensions. 3a capital stays the raw projection
/// (the cap only targets AVS).
class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.result});

  final CoupleResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final person1 = result.person1Income;
    final person2 = result.person2Income;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              Expanded(
                child: Text(
                  l10n.coupleYou,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.couplePartner,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _ComparisonRow(
            label: l10n.coupleAvs,
            value1: formatChf(person1.avsAnnual ~/ 12),
            value2: formatChf(person2.avsAnnual ~/ 12),
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: l10n.coupleBvg,
            value1: formatChf(person1.pillar2Annual ~/ 12),
            value2: formatChf(person2.pillar2Annual ~/ 12),
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: l10n.couplePillar3a,
            value1: formatChf(result.person1.projectedPillar3aBalance),
            value2: formatChf(result.person2.projectedPillar3aBalance),
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: l10n.coupleReplacementIndividual,
            value1: '${person1.replacementRate.toStringAsFixed(0)} %',
            value2: '${person2.replacementRate.toStringAsFixed(0)} %',
          ),
          const Divider(height: 24),
          _ComparisonRow(
            label: l10n.coupleTotalMonthly,
            value1: formatChf(person1.totalAnnual ~/ 12),
            value2: formatChf(person2.totalAnnual ~/ 12),
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.value1,
    required this.value2,
    this.isBold = false,
  });

  final String label;
  final String value1;
  final String value2;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = isBold
        ? theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          )
        : theme.textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(value1, textAlign: TextAlign.center, style: valueStyle),
        ),
        Expanded(
          child: Text(value2, textAlign: TextAlign.center, style: valueStyle),
        ),
      ],
    );
  }
}

/// Couple taxation: estimated annual tax under joint taxation
/// (marriage) vs separate (concubinage), conclusion and disclaimer. The
/// comparison is provided by the server regardless of the marital status
/// simulated — it answers "what if we got married?" (and vice versa).
class _TaxEstimateCard extends StatelessWidget {
  const _TaxEstimateCard({required this.estimate});

  final CoupleTaxEstimateDto estimate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;

    final conclusion = switch (estimate.cheaperStatus) {
      'MARRIED' => (
        l10n.coupleTaxCheaperMarried(
          formatChf(estimate.annualDifference.abs()),
        ),
        colors.positive,
      ),
      'CONCUBINAGE' => (
        l10n.coupleTaxCheaperConcubinage(
          formatChf(estimate.annualDifference.abs()),
        ),
        colors.positive,
      ),
      _ => (l10n.coupleTaxEqual, theme.colorScheme.onSurfaceVariant),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScenarioSectionTitle(l10n.coupleTaxTitle),
          const SizedBox(height: 12),
          ScenarioMetricRow(
            label: l10n.coupleTaxMarriedJoint,
            value:
                '${formatChf(estimate.married.totalTax)}/${l10n.scenarioYear}',
          ),
          const SizedBox(height: 8),
          ScenarioMetricRow(
            label: l10n.coupleTaxUnmarriedSeparate,
            value:
                '${formatChf(estimate.unmarried.totalTax)}/${l10n.scenarioYear}',
          ),
          const Divider(height: 24),
          Text(
            conclusion.$1,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: conclusion.$2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.coupleTaxDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Coordinated withdrawal plan (parity with iOS's `WithdrawalTimelineView`):
/// one withdrawal per row (year, spouse, pillar, amount, estimated tax),
/// then the total, the "all in the same year" tax and the savings achieved.
/// Tax-year anti-collision calculated server-side.
class _WithdrawalPlanCard extends StatelessWidget {
  const _WithdrawalPlanCard({required this.plan});

  final CoupleWithdrawalPlanDto plan;

  String _spouseLabel(AppLocalizations l10n, String spouse) => switch (spouse) {
    'person1' => l10n.coupleYou,
    'person2' => l10n.couplePartner,
    _ => l10n.coupleSectionTitle,
  };

  String _pillarLabel(AppLocalizations l10n, String pillar) => switch (pillar) {
    'pillar3a' => l10n.coupleWithdraw3a,
    _ => l10n.coupleWithdrawBvg,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: ScenarioSectionTitle(l10n.coupleWithdrawalTitle)),
              const HelpButton(termId: 'withdrawal_tax'),
            ],
          ),
          const SizedBox(height: 12),
          if (plan.steps.isEmpty)
            Text(
              l10n.coupleWithdrawalEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            for (var i = 0; i < plan.steps.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              Row(
                children: [
                  Text(
                    '${plan.steps[i].year}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _spouseLabel(l10n, plan.steps[i].spouse),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _pillarLabel(l10n, plan.steps[i].pillar),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    formatChf(plan.steps[i].amount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (plan.steps[i].estimatedTax > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      l10n.coupleTaxEstimate(
                        formatChf(plan.steps[i].estimatedTax),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const Divider(height: 24),
            ScenarioMetricRow(
              label: l10n.coupleWithdrawalTotalTax,
              value: formatChf(plan.totalEstimatedTax),
            ),
            const SizedBox(height: 8),
            ScenarioMetricRow(
              label: l10n.coupleWithdrawalSimultaneous,
              value: formatChf(plan.simultaneousEstimatedTax),
            ),
            const SizedBox(height: 8),
            ScenarioMetricRow(
              label: l10n.coupleWithdrawalSavings,
              value: formatChf(plan.taxSavingsVsSimultaneous),
              valueColor: plan.taxSavingsVsSimultaneous > 0
                  ? colors.positive
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
