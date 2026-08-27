import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../checklist/application/checklist_providers.dart';
import '../../../checklist/data/year_end_checklist.dart';

/// "Year-end checklist" card shown from October to January
/// (parity with iOS's `SeasonalChecklistCard`): progress ring,
/// number of remaining actions, navigation to the checklist.
///
/// The ring refreshes on return from the checking screen (3.9):
/// both watch the same `checklistCompletedIdsProvider`.
class SeasonalChecklistCard extends ConsumerWidget {
  const SeasonalChecklistCard({required this.hasPillar3a, super.key});

  final bool hasPillar3a;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = context.appColors.warning;

    final completed = ref.watch(checklistCompletedIdsProvider);
    final applicable = YearEndChecklist.applicableItems(
      hasPillar3a: hasPillar3a,
    );
    final doneCount = applicable
        .where((item) => completed.contains(item.id))
        .length;
    final remaining = applicable.length - doneCount;
    final progress = applicable.isEmpty ? 0.0 : doneCount / applicable.length;

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push(Routes.checklist),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 4,
                      color: color.withValues(alpha: 0.2),
                    ),
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      color: color,
                    ),
                    Icon(Icons.checklist, size: 20, color: color),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.checklistCardTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.checklistCardRemaining(remaining),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
