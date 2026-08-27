import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';

/// Help content for a glossary term — ported from
/// `ios/PocketPillar/Models/HelpContent.swift` (15 terms, 4 sections per
/// term: title / explanation / why / where to find).
class HelpContent {
  const HelpContent({
    required this.icon,
    required this.title,
    required this.explanation,
    required this.why,
    required this.whereToFind,
  });

  final IconData icon;
  final String title;
  final String explanation;
  final String why;
  final String whereToFind;
}

/// Resolves the localized content for a term (`pillar_3a`, `gross_income`…).
/// Returns null for an unknown id (the caller then hides the button).
HelpContent? helpContentFor(AppLocalizations l10n, String termId) {
  return switch (termId) {
    'pillar_system' => HelpContent(
      icon: Icons.account_balance,
      title: l10n.helpPillarSystemTitle,
      explanation: l10n.helpPillarSystemExplanation,
      why: l10n.helpPillarSystemWhy,
      whereToFind: l10n.helpPillarSystemWhere,
    ),
    'pillar_1_avs' => HelpContent(
      icon: Icons.people,
      title: l10n.helpPillar1AvsTitle,
      explanation: l10n.helpPillar1AvsExplanation,
      why: l10n.helpPillar1AvsWhy,
      whereToFind: l10n.helpPillar1AvsWhere,
    ),
    'pillar_2_bvg' => HelpContent(
      icon: Icons.business,
      title: l10n.helpPillar2BvgTitle,
      explanation: l10n.helpPillar2BvgExplanation,
      why: l10n.helpPillar2BvgWhy,
      whereToFind: l10n.helpPillar2BvgWhere,
    ),
    'pillar_3a' => HelpContent(
      icon: Icons.payments,
      title: l10n.helpPillar3aTitle,
      explanation: l10n.helpPillar3aExplanation,
      why: l10n.helpPillar3aWhy,
      whereToFind: l10n.helpPillar3aWhere,
    ),
    'coordinated_salary' => HelpContent(
      icon: Icons.swap_horiz,
      title: l10n.helpCoordinatedSalaryTitle,
      explanation: l10n.helpCoordinatedSalaryExplanation,
      why: l10n.helpCoordinatedSalaryWhy,
      whereToFind: l10n.helpCoordinatedSalaryWhere,
    ),
    'conversion_rate' => HelpContent(
      icon: Icons.percent,
      title: l10n.helpConversionRateTitle,
      explanation: l10n.helpConversionRateExplanation,
      why: l10n.helpConversionRateWhy,
      whereToFind: l10n.helpConversionRateWhere,
    ),
    'bvg_capital' => HelpContent(
      icon: Icons.bar_chart,
      title: l10n.helpBvgCapitalTitle,
      explanation: l10n.helpBvgCapitalExplanation,
      why: l10n.helpBvgCapitalWhy,
      whereToFind: l10n.helpBvgCapitalWhere,
    ),
    // Practitioner review 08.2026: an expert had to ask what "annual
    // contribution" meant (employee+employer? projected?) — a beginner
    // has no chance without this sheet.
    'annual_contribution' => HelpContent(
      icon: Icons.savings,
      title: l10n.helpAnnualContributionTitle,
      explanation: l10n.helpAnnualContributionExplanation,
      why: l10n.helpAnnualContributionWhy,
      whereToFind: l10n.helpAnnualContributionWhere,
    ),
    'withdrawal_tax' => HelpContent(
      icon: Icons.receipt_long,
      title: l10n.helpWithdrawalTaxTitle,
      explanation: l10n.helpWithdrawalTaxExplanation,
      why: l10n.helpWithdrawalTaxWhy,
      whereToFind: l10n.helpWithdrawalTaxWhere,
    ),
    'pension_score' => HelpContent(
      icon: Icons.favorite_outline,
      title: l10n.helpPensionScoreTitle,
      explanation: l10n.helpPensionScoreExplanation,
      why: l10n.helpPensionScoreWhy,
      whereToFind: l10n.helpPensionScoreWhere,
    ),
    'replacement_rate' => HelpContent(
      icon: Icons.speed,
      title: l10n.helpReplacementRateTitle,
      explanation: l10n.helpReplacementRateExplanation,
      why: l10n.helpReplacementRateWhy,
      whereToFind: l10n.helpReplacementRateWhere,
    ),
    'pension_gap' => HelpContent(
      icon: Icons.warning_amber,
      title: l10n.helpPensionGapTitle,
      explanation: l10n.helpPensionGapExplanation,
      why: l10n.helpPensionGapWhy,
      whereToFind: l10n.helpPensionGapWhere,
    ),
    'tax_savings_3a' => HelpContent(
      icon: Icons.eco,
      title: l10n.helpTaxSavings3aTitle,
      explanation: l10n.helpTaxSavings3aExplanation,
      why: l10n.helpTaxSavings3aWhy,
      whereToFind: l10n.helpTaxSavings3aWhere,
    ),
    'bvg_buyback' => HelpContent(
      icon: Icons.add_circle,
      title: l10n.helpBvgBuybackTitle,
      explanation: l10n.helpBvgBuybackExplanation,
      why: l10n.helpBvgBuybackWhy,
      whereToFind: l10n.helpBvgBuybackWhere,
    ),
    'retirement_age' => HelpContent(
      icon: Icons.calendar_month,
      title: l10n.helpRetirementAgeTitle,
      explanation: l10n.helpRetirementAgeExplanation,
      why: l10n.helpRetirementAgeWhy,
      whereToFind: l10n.helpRetirementAgeWhere,
    ),
    'contribution_3a_max' => HelpContent(
      icon: Icons.vertical_align_top,
      title: l10n.helpContribution3aMaxTitle,
      explanation: l10n.helpContribution3aMaxExplanation,
      why: l10n.helpContribution3aMaxWhy,
      whereToFind: l10n.helpContribution3aMaxWhere,
    ),
    'gross_income' => HelpContent(
      icon: Icons.paid,
      title: l10n.helpGrossIncomeTitle,
      explanation: l10n.helpGrossIncomeExplanation,
      why: l10n.helpGrossIncomeWhy,
      whereToFind: l10n.helpGrossIncomeWhere,
    ),
    'effective_return' => HelpContent(
      icon: Icons.trending_up,
      title: l10n.helpEffectiveReturnTitle,
      explanation: l10n.helpEffectiveReturnExplanation,
      why: l10n.helpEffectiveReturnWhy,
      whereToFind: l10n.helpEffectiveReturnWhere,
    ),
    _ => null,
  };
}

/// "i" button opening the glossary sheet — equivalent to iOS's
/// `InfoButton`. Compact size to fit into metric rows.
class HelpButton extends StatelessWidget {
  const HelpButton({required this.termId, super.key});

  final String termId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline, size: 18),
      color: Theme.of(context).colorScheme.primary,
      visualDensity: VisualDensity.compact,
      tooltip: helpContentFor(context.l10n, termId)?.title,
      onPressed: () => HelpSheet.show(context, termId),
    );
  }
}

/// Help sheet: title + sections "What is it? / Why is it
/// important? / Where to find this info?" (`helpSection*` keys).
class HelpSheet extends StatelessWidget {
  const HelpSheet({required this.termId, super.key});

  final String termId;

  static Future<void> show(BuildContext context, String termId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => HelpSheet(termId: termId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = helpContentFor(l10n, termId);
    if (content == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

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
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  child: Icon(content.icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(content.title, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _HelpSection(
              title: l10n.helpSectionWhat,
              body: content.explanation,
            ),
            _HelpSection(title: l10n.helpSectionWhy, body: content.why),
            _HelpSection(
              title: l10n.helpSectionWhere,
              body: content.whereToFind,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
