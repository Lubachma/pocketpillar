import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/utils/currency.dart';
import '../../../scenarios/presentation/widgets/scenario_widgets.dart';
import '../../application/guided_calculator_controller.dart';
import '../../data/calculator_dtos.dart';
import '../../data/calculator_repository.dart';
import 'buyback_info_sheet.dart';
import 'help_sheet.dart';
import 'pdf_export_button.dart';
import 'projection_chart.dart';

/// Results screen for the guided flow — rework of
/// iOS's `ResultsSummaryView`, wired to backend responses.
///
/// Not carried over from iOS (logged in the journal): /100 score gauge and
/// comparison to the age average (no endpoint — P2-11), with/without 3a
/// comparison (delta always zero: 3a is excluded from retirement
/// income, contract §7), "approximate offline" badge (API-first).
class ResultsView extends StatelessWidget {
  const ResultsView({required this.state, required this.results, super.key});

  final GuidedCalculatorState state;
  final CalculatorResults results;

  @override
  Widget build(BuildContext context) {
    // The input frozen when the calculation started — not the current input,
    // which may have changed since (results ↔ PDF ↔ recommendations consistency).
    final input = state.lastInput;
    // Results only exist if the input was complete.
    if (input == null) return const SizedBox.shrink();

    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(retirement: results.retirement),
        const SizedBox(height: 16),
        _PillarsCard(retirement: results.retirement),
        const SizedBox(height: 16),
        _ProjectionCard(retirement: results.retirement),
        const SizedBox(height: 16),
        _TaxSavingsCard(tax: results.taxSavings),
        if (results.lppGap != null) ...[
          const SizedBox(height: 16),
          _LppGapCard(lppGap: results.lppGap!),
        ],
        const SizedBox(height: 16),
        _RecommendationsCard(state: state, results: results),
        const SizedBox(height: 16),
        PdfExportButton(input: input, results: results),
        const SizedBox(height: 16),
        ScenarioInfoCard(
          icon: Icons.balance,
          text: l10n.generalSimulationDisclaimer,
          color: context.appColors.warning,
        ),
        // Beginner path to the methodology (practitioner review 08.2026):
        // the numbers gain trust only if the "how" is one tap away.
        Center(
          child: TextButton.icon(
            onPressed: () => context.push(Routes.understand),
            icon: const Icon(Icons.school_outlined, size: 18),
            label: Text(l10n.resultsHowCalculated),
          ),
        ),
      ],
    );
  }
}

/// Semantic color for a replacement rate (≥ 70% positive,
/// ≥ 50% warning, otherwise negative) — scale shared with other
/// screens that display a rate (couple, etc.).
Color rateColor(AppSemanticColors colors, double rate) => rate >= 70
    ? colors.positive
    : rate >= 50
    ? colors.warning
    : colors.negative;

/// Label + value row, with an optional help button (equivalent to iOS's
/// `ContextualMetric`).
class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.helpTermId,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? helpTermId;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(child: Text(label, style: theme.textTheme.bodyMedium)),
              if (helpTermId != null) HelpButton(termId: helpTermId!),
            ],
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.retirement});

  final RetirementResultDto retirement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rate = retirement.replacementRate;
    final color = rateColor(context.appColors, rate);

    return AppCard(
      child: Column(
        children: [
          Text(
            '${rate.round()} %',
            style: theme.textTheme.displayMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.resultsSummaryPhrase(rate.round()),
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.resultsPensionMonthly(
              formatChf(retirement.totalAnnualRetirementIncome ~/ 12),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Proportional horizontal bar for a pillar (label, bar, value).
class _PillarBar extends StatelessWidget {
  const _PillarBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    this.helpTermId,
  });

  final String label;
  final int value;
  final double fraction;
  final Color color;

  /// Glossary term opened on tap (bar rows double as pedagogy).
  final String? helpTermId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction.clamp(0.02, 1.0),
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatChf(value),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (helpTermId != null) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.info_outline,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
    if (helpTermId == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => HelpSheet.show(context, helpTermId!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}

class _PillarsCard extends StatelessWidget {
  const _PillarsCard({required this.retirement});

  final RetirementResultDto retirement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;

    // Each bar opens its pillar's glossary sheet — the base pedagogy
    // (pillar_1_avs/pillar_2_bvg/pillar_3a) was written but unreachable
    // before the practitioner review (08.2026).
    final pillars = [
      (
        l10n.pdfPillar1,
        retirement.estimatedAnnualAvsPension,
        colors.pillar1,
        'pillar_1_avs',
      ),
      (
        l10n.pdfPillar2,
        retirement.annualPillar2Pension,
        colors.pillar2,
        'pillar_2_bvg',
      ),
      (
        l10n.pdfPillar3a,
        retirement.projectedPillar3aBalance,
        colors.pillar3a,
        'pillar_3a',
      ),
    ];
    final maxValue = pillars.fold<int>(
      1,
      (max, p) => p.$2 > max ? p.$2 : max,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.resultsYourPillars,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const HelpButton(termId: 'pillar_system'),
            ],
          ),
          const SizedBox(height: 12),
          for (final (label, value, color, termId) in pillars) ...[
            _PillarBar(
              label: label,
              value: value,
              fraction: value / maxValue,
              color: color,
              helpTermId: termId,
            ),
            const SizedBox(height: 8),
          ],
          const Divider(),
          _MetricRow(
            label: l10n.resultsReplacementRate,
            value: '${retirement.replacementRate.round()} %',
            helpTermId: 'replacement_rate',
            valueColor: rateColor(colors, retirement.replacementRate),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: l10n.resultsYearsToRetirement,
            value: '${retirement.yearsToRetirement}',
          ),
        ],
      ),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.retirement});

  final RetirementResultDto retirement;

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
              Expanded(
                child: Text(
                  l10n.pdfProjectionTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const HelpButton(termId: 'retirement_age'),
            ],
          ),
          const SizedBox(height: 12),
          ProjectionBarChart(projection: retirement.yearByYearProjection),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: colors.pillar2, label: l10n.pdfPillar2),
              const SizedBox(width: 16),
              _LegendDot(color: colors.pillar3a, label: l10n.pdfPillar3a),
            ],
          ),
          const Divider(height: 24),
          _MetricRow(
            label: l10n.calculatorProjectedPillar2,
            value: formatChf(retirement.projectedPillar2Capital),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: l10n.calculatorProjectedPillar3a,
            value: formatChf(retirement.projectedPillar3aBalance),
          ),
          // Withdrawal tax on the 3a lump sum (official FTA 2026 tables) —
          // present when the backend knew the canton (practitioner review
          // 08.2026: gross capitals without the exit tax read as overstated).
          if (retirement.pillar3aWithdrawalTax != null) ...[
            const SizedBox(height: 8),
            _MetricRow(
              label: l10n.calculatorWithdrawalTax3a,
              value: '−${formatChf(retirement.pillar3aWithdrawalTax!)}',
              helpTermId: 'withdrawal_tax',
            ),
          ],
          if (retirement.pillar3aNetLumpSum != null) ...[
            const SizedBox(height: 8),
            _MetricRow(
              label: l10n.calculatorNet3aAfterTax,
              value: formatChf(retirement.pillar3aNetLumpSum!),
            ),
          ],
          const SizedBox(height: 8),
          _MetricRow(
            label: l10n.calculatorAnnualRetirementIncome,
            value: formatChf(retirement.totalAnnualRetirementIncome),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _TaxSavingsCard extends StatelessWidget {
  const _TaxSavingsCard({required this.tax});

  final TaxSavingsResultDto tax;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final total = tax.totalTaxSaving > 0 ? tax.totalTaxSaving : 1;

    final parts = [
      (l10n.calculatorFederalSaving, tax.federalTaxSaving, colors.pillar1),
      (l10n.calculatorCantonalSaving, tax.cantonalTaxSaving, colors.pillar2),
      (l10n.calculatorCommunalSaving, tax.communalTaxSaving, colors.pillar3a),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.resultsTaxSavings,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const HelpButton(termId: 'tax_savings_3a'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatChf(tax.totalTaxSaving),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.positive,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            l10n.resultsAnnualSavings,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Stacked bar federal / cantonal / communal (iOS donut).
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final (_, amount, color) in parts)
                    if (amount > 0)
                      Expanded(
                        // flex > 0 required: at least 1 part out of 1000.
                        flex: (amount * 1000 ~/ total).clamp(1, 1000),
                        child: ColoredBox(color: color),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final (label, amount, _) in parts) ...[
            _MetricRow(label: label, value: formatChf(amount)),
            const SizedBox(height: 4),
          ],
          const Divider(),
          _MetricRow(
            label: l10n.calculatorEffectiveReturn,
            value: l10n.resultsEffectiveReturn(
              tax.effectiveReturnRate.toStringAsFixed(1),
            ),
            helpTermId: 'effective_return',
            valueColor: colors.positive,
          ),
        ],
      ),
    );
  }
}

class _LppGapCard extends StatelessWidget {
  const _LppGapCard({required this.lppGap});

  final LppGapResultDto lppGap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final hasGap = lppGap.pensionGap > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.calculatorLppGap, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _MetricRow(
            label: l10n.calculatorCoordinatedSalary,
            value: formatChf(lppGap.coordinatedSalary),
            helpTermId: 'coordinated_salary',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: l10n.calculatorBvgMinContribution,
            value: formatChf(lppGap.bvgMinContribution),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            helpTermId: 'conversion_rate',
            label: l10n.calculatorProjectedPension,
            value: formatChf(lppGap.projectedActualAnnualPension),
          ),
          const Divider(height: 24),
          _MetricRow(
            label: l10n.calculatorPensionGap,
            value: formatChf(lppGap.pensionGap),
            helpTermId: 'pension_gap',
            valueColor: hasGap ? colors.negative : colors.positive,
          ),
        ],
      ),
    );
  }
}

class _Recommendation {
  const _Recommendation({
    required this.text,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.state, required this.results});

  final GuidedCalculatorState state;
  final CalculatorResults results;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final input = state.lastInput;

    // Same conditional logic as iOS's `ResultsSummaryView`, based on
    // the input frozen at calculation time (not the current input).
    final recommendations = <_Recommendation>[
      if (input != null && !input.hasPillar3a)
        _Recommendation(
          text: l10n.resultsRecOpen3a,
          icon: Icons.add_circle,
          color: colors.pillar3a,
          onTap: () => context.go(Routes.providers),
        )
      else ...[
        if (input != null)
          _Recommendation(
            text: l10n.resultsRecMax3a(
              formatChf(input.pillar3aMaxContribution),
            ),
            icon: Icons.arrow_upward,
            color: colors.pillar3a,
            onTap: () => context.go(Routes.providers),
          ),
        if (results.taxSavings.totalTaxSaving > 0)
          _Recommendation(
            text: l10n.resultsRecTaxSaving(
              formatChf(results.taxSavings.totalTaxSaving),
            ),
            icon: Icons.eco,
            color: colors.positive,
          ),
      ],
      if (results.retirement.replacementRate < 60)
        _Recommendation(
          text: l10n.resultsRecIncreaseCoverage,
          icon: Icons.warning_amber,
          color: colors.warning,
        ),
      if ((results.lppGap?.pensionGap ?? 0) > 0)
        _Recommendation(
          text: l10n.resultsRecBvgBuyback,
          icon: Icons.add_circle,
          color: colors.pillar2,
          onTap: () => BuybackInfoSheet.show(context),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.resultsWhatToDo, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final rec in recommendations) ...[
          AppCard(
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: rec.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(rec.icon, color: rec.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(rec.text, style: theme.textTheme.bodyMedium),
                    ),
                    if (rec.onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
