import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/utils/clock.dart';

/// Ids of the checklist items checked for the current year, persisted
/// under `checklist.<year>.completed` (same key as iOS, StringList
/// format established in 3.2).
///
/// New year → new key → **automatic reset** (iOS parity;
/// the previous year is kept, never purged). Note: the reset
/// isn't hot-reactive — an app open when January 1st hits
/// keeps the year in memory until the provider rebuilds (iOS parity
/// assumed, see journal 3.9).
///
/// The checking screen and the dashboard card (`SeasonalChecklistCard`)
/// watch the same provider: the dashboard's progress ring
/// refreshes itself on return (TODO 3.2 resolved — no more single
/// synchronous read).
final checklistCompletedIdsProvider =
    NotifierProvider<ChecklistCompletedIdsNotifier, Set<String>>(
      ChecklistCompletedIdsNotifier.new,
    );

class ChecklistCompletedIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final year = ref.watch(clockProvider)().year;
    return ref
        .watch(preferencesRepositoryProvider)
        .getCompletedChecklistItems(year)
        .toSet();
  }

  /// (Un)checks an item: state updated immediately, then persisted.
  Future<void> toggle(String itemId) async {
    final next = {...state};
    if (!next.remove(itemId)) next.add(itemId);
    state = next;
    final year = ref.read(clockProvider)().year;
    try {
      await ref
          .read(preferencesRepositoryProvider)
          .setCompletedChecklistItems(year, next.toList());
    } on Exception {
      // Persistence failure deliberately swallowed: parity with iOS's
      // `try?` (`JSONEncoder` + UserDefaults). The check remains
      // effective in memory for the session; it will simply be lost
      // at the provider's next rebuild.
    }
  }
}

/// Localized labels for an item (ARB `checklist*` keys migrated in 3.2).
({String title, String description}) checklistItemLabels(
  AppLocalizations l10n,
  String itemId,
) => switch (itemId) {
  'max_3a' => (
    title: l10n.checklistMax3aTitle,
    description: l10n.checklistMax3aDescription,
  ),
  'bvg_buyback' => (
    title: l10n.checklistBvgBuybackTitle,
    description: l10n.checklistBvgBuybackDescription,
  ),
  'request_certificate' => (
    title: l10n.checklistCertificateTitle,
    description: l10n.checklistCertificateDescription,
  ),
  'tax_documents' => (
    title: l10n.checklistTaxDocsTitle,
    description: l10n.checklistTaxDocsDescription,
  ),
  'update_profile' => (
    title: l10n.checklistUpdateProfileTitle,
    description: l10n.checklistUpdateProfileDescription,
  ),
  'plan_next_year' => (
    title: l10n.checklistPlanNextTitle,
    description: l10n.checklistPlanNextDescription,
  ),
  _ => throw ArgumentError.value(itemId, 'itemId', 'Item checklist inconnu'),
};
