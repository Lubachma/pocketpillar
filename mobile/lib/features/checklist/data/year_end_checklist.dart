import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Target tab for a checklist item (iOS `targetTab` parity, which
/// stored a tab index: 2 = Scenarios, 4 = Documents,
/// 5 = Profile). The mapping to routes happens in the screen.
enum ChecklistTarget { scenarios, documents, profile }

/// Year-end checklist item — ported from
/// `ios/.../Models/YearEndChecklistItem.swift`.
///
/// `color` and `targetTab` (deferred in 3.2) are ported in 3.9. Note:
/// iOS never rendered `icon`/`color` in its view (dead fields) —
/// the Flutter screen displays them (deliberate addition, see journal 3.9).
class YearEndChecklistItem {
  const YearEndChecklistItem({
    required this.id,
    required this.icon,
    required this.color,
    this.targetTab,
    this.requiresPillar3a = false,
  });

  /// Stable identifier, persisted in `checklist.<year>.completed`.
  final String id;
  final IconData icon;

  /// Item color (iOS `Theme.*` palette).
  final Color color;

  /// Tab to navigate to on tap, null if none (iOS parity).
  final ChecklistTarget? targetTab;

  /// iOS parity: "max 3a" is only relevant if a 3a exists.
  final bool requiresPillar3a;
}

/// The 6 items, in the same order as the iOS app.
abstract final class YearEndChecklist {
  static const List<YearEndChecklistItem> allItems = [
    YearEndChecklistItem(
      id: 'max_3a',
      icon: Icons.payments,
      color: AppColors.pillar3a,
      requiresPillar3a: true,
    ),
    YearEndChecklistItem(
      id: 'bvg_buyback',
      icon: Icons.add_circle,
      color: AppColors.pillar2,
    ),
    YearEndChecklistItem(
      id: 'request_certificate',
      icon: Icons.description,
      color: AppColors.accent,
      targetTab: ChecklistTarget.documents,
    ),
    YearEndChecklistItem(
      id: 'tax_documents',
      icon: Icons.folder,
      color: AppColors.warning,
      targetTab: ChecklistTarget.documents,
    ),
    YearEndChecklistItem(
      id: 'update_profile',
      icon: Icons.person,
      color: AppColors.accent,
      targetTab: ChecklistTarget.profile,
    ),
    YearEndChecklistItem(
      id: 'plan_next_year',
      icon: Icons.event,
      color: AppColors.positive,
      targetTab: ChecklistTarget.scenarios,
    ),
  ];

  /// Items relevant to the user (filter from iOS's
  /// `applicableItems(for:)`).
  static List<YearEndChecklistItem> applicableItems({
    required bool hasPillar3a,
  }) => [
    for (final item in allItems)
      if (!item.requiresPillar3a || hasPillar3a) item,
  ];

  /// Display season for the dashboard card: October to January
  /// (iOS parity `month >= 10 || month == 1`). The checking screen itself
  /// is accessible year-round (no season guard in iOS).
  static bool isSeason(DateTime now) => now.month >= 10 || now.month == 1;
}
