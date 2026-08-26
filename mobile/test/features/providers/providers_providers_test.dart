import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/providers/application/providers_providers.dart';

void main() {
  group('riskLevelForAge (mapping iOS UserProfileStore.riskLevelForAge)', () {
    test('bornes du mapping', () {
      expect(riskLevelForAge(18), 'GROWTH');
      expect(riskLevelForAge(34), 'GROWTH');
      expect(riskLevelForAge(35), 'BALANCED');
      expect(riskLevelForAge(44), 'BALANCED');
      expect(riskLevelForAge(45), 'MODERATE');
      expect(riskLevelForAge(54), 'MODERATE');
      expect(riskLevelForAge(55), 'CONSERVATIVE');
      expect(riskLevelForAge(64), 'CONSERVATIVE');
    });
  });
}
