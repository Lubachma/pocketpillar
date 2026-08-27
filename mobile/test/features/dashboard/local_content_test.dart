import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/checklist/data/year_end_checklist.dart';
import 'package:pocketpillar/features/dashboard/application/educational_tips.dart';

void main() {
  group('EducationalTips (iOS parity)', () {
    test('12 tips, unique ids', () {
      expect(EducationalTips.all, hasLength(12));
      expect(EducationalTips.all.map((t) => t.id).toSet(), hasLength(12));
    });

    test('rotation by day of the year (1-based, iOS parity)', () {
      // 1-based ordinality: January 1st → all[1], January 2nd → all[2].
      expect(
        EducationalTips.tipOfTheDay(DateTime(2026)).id,
        EducationalTips.all[1].id,
      );
      expect(
        EducationalTips.tipOfTheDay(DateTime(2026, 1, 2)).id,
        EducationalTips.all[2].id,
      );
      // Wraps around the list: January 12th → all[0].
      expect(
        EducationalTips.tipOfTheDay(DateTime(2026, 1, 12)).id,
        EducationalTips.all.first.id,
      );
    });
  });

  group('YearEndChecklist (iOS parity)', () {
    test('season: October through January inclusive', () {
      expect(YearEndChecklist.isSeason(DateTime(2026, 10)), isTrue);
      expect(YearEndChecklist.isSeason(DateTime(2026, 12, 31)), isTrue);
      expect(YearEndChecklist.isSeason(DateTime(2026, 1, 15)), isTrue);
      expect(YearEndChecklist.isSeason(DateTime(2026, 9, 30)), isFalse);
      expect(YearEndChecklist.isSeason(DateTime(2026, 2)), isFalse);
      expect(YearEndChecklist.isSeason(DateTime(2026, 8, 5)), isFalse);
    });

    test("'max 3a' relevant only with a 3a account", () {
      expect(YearEndChecklist.applicableItems(hasPillar3a: true), hasLength(6));
      final sans3a = YearEndChecklist.applicableItems(hasPillar3a: false);
      expect(sans3a, hasLength(5));
      expect(sans3a.any((item) => item.id == 'max_3a'), isFalse);
    });
  });
}
