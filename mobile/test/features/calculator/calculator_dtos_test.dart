import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/calculator/data/calculator_dtos.dart';

/// Parsing of calculator DTOs on responses conforming to
/// `src/modules/calculator/calculator.types.ts` (amounts in centimes).
void main() {
  group('LppGapResultDto', () {
    test('parses a complete response', () {
      final dto = LppGapResultDto.fromJson(const {
        'coordinatedSalary': 6800000,
        'bvgMinContribution': 612000,
        'contributionGap': 112000,
        'projectedBvgMinCapital': 42000000,
        'projectedActualCapital': 38000000,
        'capitalGap': 4000000,
        'projectedMinAnnualPension': 2520000,
        'projectedActualAnnualPension': 2280000,
        'pensionGap': 240000,
      });

      expect(dto.coordinatedSalary, 6800000);
      expect(dto.bvgMinContribution, 612000);
      expect(dto.contributionGap, 112000);
      expect(dto.projectedBvgMinCapital, 42000000);
      expect(dto.projectedActualCapital, 38000000);
      expect(dto.capitalGap, 4000000);
      expect(dto.projectedMinAnnualPension, 2520000);
      expect(dto.projectedActualAnnualPension, 2280000);
      expect(dto.pensionGap, 240000);
    });
  });

  group('TaxSavingsResultDto', () {
    test('parses a complete response (rate as double, isAtMax bool)', () {
      final dto = TaxSavingsResultDto.fromJson(const {
        'federalTaxSaving': 85000,
        'cantonalTaxSaving': 90000,
        'communalTaxSaving': 45000,
        'totalTaxSaving': 220000,
        'effectiveReturnRate': 30.31,
        'maxContribution': 725800,
        'isAtMax': true,
      });

      expect(dto.federalTaxSaving, 85000);
      expect(dto.cantonalTaxSaving, 90000);
      expect(dto.communalTaxSaving, 45000);
      expect(dto.totalTaxSaving, 220000);
      expect(dto.effectiveReturnRate, 30.31);
      expect(dto.maxContribution, 725800);
      expect(dto.isAtMax, isTrue);
    });

    test('effectiveReturnRate integer → double', () {
      final dto = TaxSavingsResultDto.fromJson(const {
        'federalTaxSaving': 0,
        'cantonalTaxSaving': 0,
        'communalTaxSaving': 0,
        'totalTaxSaving': 0,
        'effectiveReturnRate': 0,
        'maxContribution': 3628800,
        'isAtMax': false,
      });

      expect(dto.effectiveReturnRate, isA<double>());
      expect(dto.effectiveReturnRate, 0.0);
      expect(dto.isAtMax, isFalse);
    });
  });

  group('RetirementResultDto', () {
    test('parses a complete response with year-by-year projection', () {
      final dto = RetirementResultDto.fromJson(const {
        'yearsToRetirement': 30,
        'projectedPillar2Capital': 50000000,
        'projectedPillar3aBalance': 8000000,
        'annualPillar2Pension': 3000000,
        'estimatedAnnualAvsPension': 2352000,
        'pillar3aAsLumpSum': 8000000,
        'totalAnnualRetirementIncome': 5352000,
        'replacementRate': 63.0,
        'yearByYearProjection': [
          {
            'year': 2027,
            'age': 36,
            'pillar2Capital': 2100000,
            'pillar3aBalance': 1758000,
            'totalCapital': 3858000,
          },
          {
            'year': 2028,
            'age': 37,
            'pillar2Capital': 2206250,
            'pillar3aBalance': 2536074,
            'totalCapital': 4742324,
          },
        ],
      });

      expect(dto.yearsToRetirement, 30);
      expect(dto.projectedPillar2Capital, 50000000);
      expect(dto.projectedPillar3aBalance, 8000000);
      expect(dto.annualPillar2Pension, 3000000);
      expect(dto.estimatedAnnualAvsPension, 2352000);
      expect(dto.pillar3aAsLumpSum, 8000000);
      expect(dto.totalAnnualRetirementIncome, 5352000);
      expect(dto.replacementRate, 63.0);

      expect(dto.yearByYearProjection, hasLength(2));
      final first = dto.yearByYearProjection.first;
      expect(first.year, 2027);
      expect(first.age, 36);
      expect(first.pillar2Capital, 2100000);
      expect(first.pillar3aBalance, 1758000);
      expect(first.totalCapital, 3858000);
    });

    test('yearByYearProjection absent → empty list', () {
      final dto = RetirementResultDto.fromJson(const {
        'yearsToRetirement': 1,
        'projectedPillar2Capital': 0,
        'projectedPillar3aBalance': 0,
        'annualPillar2Pension': 0,
        'estimatedAnnualAvsPension': 1470000,
        'pillar3aAsLumpSum': 0,
        'totalAnnualRetirementIncome': 1470000,
        'replacementRate': 17,
      });

      expect(dto.yearByYearProjection, isEmpty);
      // Integer rate → double.
      expect(dto.replacementRate, 17.0);
      // No canton in the request → no withdrawal tax fields.
      expect(dto.pillar3aWithdrawalTax, isNull);
      expect(dto.pillar3aNetLumpSum, isNull);
    });

    test('parses the 3a withdrawal tax estimate when present (canton sent — '
        'practitioner review 08.2026)', () {
      final dto = RetirementResultDto.fromJson(const {
        'yearsToRetirement': 5,
        'projectedPillar2Capital': 0,
        'projectedPillar3aBalance': 50000000,
        'annualPillar2Pension': 0,
        'estimatedAnnualAvsPension': 2352000,
        'pillar3aAsLumpSum': 50000000,
        'totalAnnualRetirementIncome': 2352000,
        'replacementRate': 30.0,
        // ZH single anchor: CHF 500'000 → 35'068 (official FTA 2026 table).
        'pillar3aWithdrawalTax': 3506800,
        'pillar3aNetLumpSum': 46493200,
      });

      expect(dto.pillar3aWithdrawalTax, 3506800);
      expect(dto.pillar3aNetLumpSum, 46493200);
    });
  });
}
