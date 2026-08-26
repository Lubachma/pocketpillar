import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';

/// Educational tip — ported from `ios/.../Models/EducationalTips.swift`.
/// The texts come from the ARB `tip*` keys (already migrated).
class EducationalTip {
  const EducationalTip({required this.id, required this.icon});

  /// Stable identifier (e.g. `max_3a_2026`) — used for l10n resolution.
  final String id;

  /// Material icon (equivalent to iOS's SF Symbol).
  final IconData icon;
}

/// Resolution of a tip's localized texts.
extension EducationalTipL10n on EducationalTip {
  String title(AppLocalizations l10n) => switch (id) {
    'max_3a_2026' => l10n.tipMax3a2026Title,
    'bvg_buyback' => l10n.tipBvgBuybackTitle,
    '3a_tax_deduction' => l10n.tip3aTaxDeductionTitle,
    'start_early' => l10n.tipStartEarlyTitle,
    'compound_interest' => l10n.tipCompoundInterestTitle,
    'multiple_3a' => l10n.tipMultiple3aTitle,
    'retirement_gap' => l10n.tipRetirementGapTitle,
    '3_pillars' => l10n.tip3PillarsTitle,
    'avs_max' => l10n.tipAvsMaxTitle,
    'pillar_2_interest' => l10n.tipPillar2InterestTitle,
    '3a_withdrawal' => l10n.tip3aWithdrawalTitle,
    _ => l10n.tipCantonTaxesTitle,
  };

  String body(AppLocalizations l10n) => switch (id) {
    'max_3a_2026' => l10n.tipMax3a2026Body,
    'bvg_buyback' => l10n.tipBvgBuybackBody,
    '3a_tax_deduction' => l10n.tip3aTaxDeductionBody,
    'start_early' => l10n.tipStartEarlyBody,
    'compound_interest' => l10n.tipCompoundInterestBody,
    'multiple_3a' => l10n.tipMultiple3aBody,
    'retirement_gap' => l10n.tipRetirementGapBody,
    '3_pillars' => l10n.tip3PillarsBody,
    'avs_max' => l10n.tipAvsMaxBody,
    'pillar_2_interest' => l10n.tipPillar2InterestBody,
    '3a_withdrawal' => l10n.tip3aWithdrawalBody,
    _ => l10n.tipCantonTaxesBody,
  };
}

/// The 12 tips, in the same order as the iOS app.
abstract final class EducationalTips {
  static const List<EducationalTip> all = [
    EducationalTip(id: 'max_3a_2026', icon: Icons.payments),
    EducationalTip(id: 'bvg_buyback', icon: Icons.add_circle),
    EducationalTip(id: '3a_tax_deduction', icon: Icons.eco),
    EducationalTip(id: 'start_early', icon: Icons.schedule),
    EducationalTip(id: 'compound_interest', icon: Icons.trending_up),
    EducationalTip(id: 'multiple_3a', icon: Icons.stacked_bar_chart),
    EducationalTip(id: 'retirement_gap', icon: Icons.warning_amber),
    EducationalTip(id: '3_pillars', icon: Icons.account_balance),
    EducationalTip(id: 'avs_max', icon: Icons.groups),
    EducationalTip(id: 'pillar_2_interest', icon: Icons.percent),
    EducationalTip(id: '3a_withdrawal', icon: Icons.event_available),
    EducationalTip(id: 'canton_taxes', icon: Icons.map),
  ];

  /// Rotation by day of the year (iOS `tipOfTheDay()` parity, whose
  /// ordinality is **1-based**: January 1st → `all[1]`).
  static EducationalTip tipOfTheDay(DateTime now) {
    final dayOfYear = now.difference(DateTime(now.year)).inDays + 1;
    return all[dayOfYear % all.length];
  }
}
