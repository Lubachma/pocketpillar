import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/calculator_dtos.dart';

/// Lightweight bar chart of the year-by-year projection — stacked bars,
/// LPP (bottom) + 3a (top), no external dependency (equivalent to
/// iOS's stacked `AreaMark`).
class ProjectionBarChart extends StatelessWidget {
  const ProjectionBarChart({required this.projection, super.key});

  final List<YearProjectionDto> projection;

  static const double _chartHeight = 160;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    if (projection.isEmpty) return const SizedBox.shrink();

    final maxCapital = projection.fold<int>(
      1,
      (max, p) => p.totalCapital > max ? p.totalCapital : max,
    );

    return Column(
      children: [
        SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in projection)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height:
                              _chartHeight * point.pillar3aBalance / maxCapital,
                          decoration: BoxDecoration(
                            color: colors.pillar3a,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                        Container(
                          height:
                              _chartHeight * point.pillar2Capital / maxCapital,
                          color: colors.pillar2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${projection.first.year}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${projection.last.year}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
