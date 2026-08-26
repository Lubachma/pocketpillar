import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/dashboard/data/dashboard_dtos.dart';

/// DTOs for `GET /score` (contract §8 bis).
void main() {
  Map<String, dynamic> scoreJson() => {
    'score': 87,
    'breakdown': [
      {
        'criterion': 'REPLACEMENT_RATE',
        'label': 'Taux de remplacement',
        'points': 32,
        'maxPoints': 40,
      },
      {
        'criterion': 'PILLAR_3A',
        'label': 'Épargne 3a',
        'points': 30,
        'maxPoints': 30,
      },
      {
        'criterion': 'AGE_AWARENESS',
        'label': 'Horizon retraite',
        'points': 25,
        'maxPoints': 30,
      },
    ],
    'benchmark': {
      'bracket': {'minAge': 35, 'maxAge': 39},
      'averagePillar3aBalance': 4800000,
      'averageReplacementRate': 58,
      'averageBvgCapital': 12000000,
      'userPillar3aBalance': 4800000,
      'userReplacementRate': 65.0,
      'userBvgCapital': 12000000,
    },
    'generatedAt': '2026-08-06T10:00:00.000Z',
  };

  test('full payload: score, breakdown and benchmark parsed', () {
    final dto = PensionScoreDto.fromJson(scoreJson());

    expect(dto.score, 87);
    expect(dto.breakdown, hasLength(3));
    expect(dto.breakdown[0].criterion, 'REPLACEMENT_RATE');
    expect(dto.breakdown[0].label, 'Taux de remplacement');
    expect(dto.breakdown[0].points, 32);
    expect(dto.breakdown[0].maxPoints, 40);

    final benchmark = dto.benchmark;
    expect(benchmark.hasBracket, isTrue);
    expect(benchmark.bracketMinAge, 35);
    expect(benchmark.bracketMaxAge, 39);
    expect(benchmark.averagePillar3aBalance, 4800000);
    expect(benchmark.averageReplacementRate, 58.0);
    expect(benchmark.averageBvgCapital, 12000000);
    expect(benchmark.userPillar3aBalance, 4800000);
    expect(benchmark.userReplacementRate, 65.0);
    expect(benchmark.userBvgCapital, 12000000);
  });

  test('null bracket (age outside 25–65) → null bounds', () {
    final json = scoreJson();
    json['benchmark'] = <String, dynamic>{
      ...json['benchmark'] as Map<String, dynamic>,
      'bracket': null,
    };

    final dto = PensionScoreDto.fromJson(json);

    expect(dto.benchmark.hasBracket, isFalse);
    expect(dto.benchmark.bracketMinAge, isNull);
    expect(dto.benchmark.bracketMaxAge, isNull);
  });

  test('integer JSON rates → Dart doubles', () {
    final dto = PensionScoreDto.fromJson(scoreJson());

    expect(dto.benchmark.averageReplacementRate, isA<double>());
    expect(dto.benchmark.userReplacementRate, isA<double>());
  });
}
