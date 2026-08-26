import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/swiss_pension.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/checklist_providers.dart';
import '../data/year_end_checklist.dart';

/// Year-end checklist (parity with iOS's `YearEndChecklistView`):
/// n/N progress ring, items filtered by relevance ("max 3a"
/// only if a 3a exists), year-persistent checking, navigation
/// to the target tab on tap.
///
/// Accessible year-round: iOS has no season guard on
/// the screen (only the dashboard card is seasonal).
class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final completed = ref.watch(checklistCompletedIdsProvider);
    // Single source already warm (screen pushed from the dashboard);
    // error/absence → conservative filter, like the dashboard card.
    final dashboard = ref.watch(dashboardProvider).valueOrNull;
    final hasPillar3a = dashboard?.hasPillar3a ?? false;
    final items = YearEndChecklist.applicableItems(hasPillar3a: hasPillar3a);
    final doneCount = items.where((item) => completed.contains(item.id)).length;
    // 3a cap displayed on the "max 3a" item (OPP3 art. 7, reviewed
    // batch 12): 7'258 with a 2nd pillar — EMPLOYED status **or an existing
    // LPP account** (a self-employed person's optional LPP included) — otherwise
    // min(36'288, 20% of income), declared net basis falling back to gross (same
    // rule as the annual reminder, `pillar3aMaxForProfile`). Profile
    // absent/unknown → 7'258 (historical conservative default).
    final data = dashboard;
    final profile = data?.profile;
    final pillar3aMax = (data == null || profile == null)
        ? pillar3aMaxWithPillar2
        : pillar3aMaxForProfile(
            employmentStatus: profile.employmentStatus,
            hasPillar2Account: data.pillar2Accounts.isNotEmpty,
            grossAnnualIncomeCentimes: profile.grossAnnualIncome,
            netAnnualIncomeCentimes: profile.netAnnualIncome,
          );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checklistTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressCard(doneCount: doneCount, totalCount: items.length),
          const SizedBox(height: 20),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _ChecklistRow(
              item: items[i],
              completed: completed.contains(items[i].id),
              pillar3aMax: pillar3aMax,
              onTap: () => _onItemTap(context, ref, items[i]),
            ),
          ],
        ],
      ),
    );
  }

  /// Check persisted, then navigation to the target tab if the item
  /// was just checked. iOS navigated on **uncheck** (inverted
  /// condition, contradicting its own chevron) — fixed here
  /// (journal 3.9).
  void _onItemTap(
    BuildContext context,
    WidgetRef ref,
    YearEndChecklistItem item,
  ) {
    final wasCompleted = ref
        .read(checklistCompletedIdsProvider)
        .contains(item.id);
    unawaited(ref.read(checklistCompletedIdsProvider.notifier).toggle(item.id));
    final target = item.targetTab;
    if (target != null && !wasCompleted) {
      context.go(switch (target) {
        ChecklistTarget.scenarios => Routes.scenarios,
        ChecklistTarget.documents => Routes.documents,
        ChecklistTarget.profile => Routes.settingsProfile,
      });
    }
  }
}

/// Header: n/N ring (accent) + "All done!" mention at 100%.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.doneCount, required this.totalCount});

  final int doneCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const accent = AppColors.accent;
    final progress = totalCount == 0 ? 0.0 : doneCount / totalCount;

    return AppCard(
      child: Column(
        children: [
          SizedBox.square(
            dimension: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  color: accent.withValues(alpha: 0.2),
                ),
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: accent,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$doneCount/$totalCount',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    Text(
                      l10n.checklistCompleted,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (progress >= 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: context.appColors.positive,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.checklistAllDone,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: context.appColors.positive,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Item row: colored icon, title (struck through if checked),
/// description, max 3a value, check state + navigation chevron.
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.item,
    required this.completed,
    required this.pillar3aMax,
    required this.onTap,
  });

  final YearEndChecklistItem item;
  final bool completed;

  /// 3a cap applicable to the profile (employment status + income), in
  /// centimes — displayed on the `max_3a` item.
  final int pillar3aMax;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final labels = checklistItemLabels(l10n, item.id);

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 22, color: item.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: completed
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labels.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.id == 'max_3a') ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.checklistMax3aValue(formatChf(pillar3aMax)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.appColors.pillar3a,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                completed ? Icons.check_circle : Icons.circle_outlined,
                color: completed
                    ? context.appColors.positive
                    : theme.colorScheme.onSurfaceVariant,
              ),
              if (item.targetTab != null && !completed) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
