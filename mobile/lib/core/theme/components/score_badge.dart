import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Score badge /100 — equivalent of the iOS `ScoreBadge`: colored
/// progress ring (≥ 70 green, ≥ 40 orange, otherwise red) with the
/// score in the center.
///
/// Shared between 3a providers (product score, [dimension] 44 by
/// default) and the dashboard's "Pension health" card (large ring,
/// e.g. 110 — parity with the iOS gauge).
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({required this.score, this.dimension = 44, super.key});

  final int score;

  /// Badge side in logical pixels (44 = list size, ≥ 80 = large gauge
  /// with bolder typography and stroke).
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = score >= 70
        ? colors.positive
        : score >= 40
        ? colors.warning
        : colors.negative;
    final large = dimension >= 80;
    final strokeWidth = large ? 10.0 : 3.0;
    return SizedBox.square(
      dimension: dimension,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Positioned.fill: under the Stack's loose constraints, the
          // indicator would otherwise fall back to its intrinsic size
          // (36) instead of filling the badge.
          Positioned.fill(
            child: CircularProgressIndicator(
              value: score.clamp(0, 100) / 100,
              strokeWidth: strokeWidth,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          // FittedBox: the score stays INSIDE the ring regardless of
          // font metrics (web, accessibility scale) — shrinks as
          // needed, never clipped.
          Padding(
            padding: EdgeInsets.all(strokeWidth + 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$score',
                style:
                    (large
                            ? Theme.of(context).textTheme.headlineMedium
                            : Theme.of(context).textTheme.labelLarge)
                        ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
