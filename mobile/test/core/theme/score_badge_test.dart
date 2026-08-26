import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/theme/app_theme.dart';
import 'package:pocketpillar/core/theme/components/score_badge.dart';

void main() {
  Future<void> pumpBadge(WidgetTester tester, {required double dimension}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Center(child: ScoreBadge(score: 76, dimension: dimension)),
      ),
    );
  }

  testWidgets('large gauge (84): ring fills the frame, score never clipped', (
    tester,
  ) async {
    await pumpBadge(tester, dimension: 84);

    // The ring must fill the badge — without Positioned.fill, the
    // CircularProgressIndicator falls back to its intrinsic size (~36)
    // under the Stack's loose constraints (web visual bug from 26.08).
    expect(
      tester.getSize(find.byType(CircularProgressIndicator)),
      const Size(84, 84),
    );
    // The score is scaled to fit inside the ring, never clipped.
    expect(find.byType(FittedBox), findsOneWidget);
    expect(find.text('76'), findsOneWidget);
  });

  testWidgets('list size (44): ring fills the frame too', (tester) async {
    await pumpBadge(tester, dimension: 44);

    expect(
      tester.getSize(find.byType(CircularProgressIndicator)),
      const Size(44, 44),
    );
    expect(find.text('76'), findsOneWidget);
  });
}
