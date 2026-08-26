import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/scenarios/data/scenario_dtos.dart';

/// Parsing of the 4 scenario DTOs against **real backend responses**
/// (generated via `calculatePillar3aCatchup` / `calculatePropertyPurchaseImpact`
/// / `calculateDivorceImpact` / `calculateStaggeredWithdrawal` from
/// `src/modules/calculator/` on 2026-08-05).
///
/// ⚠️ The fixture years (2025 for catch-up, 2029–2031 for staggered
/// withdrawal) depend on `SWISS_PENSION.CURRENT_YEAR` — dynamic
/// (`new Date().getFullYear()`). Regenerate every year (or whenever the
/// reference year changes) to stay faithful to the backend.
void main() {
  group('Catchup3aResultDto', () {
    // Real response: currentYear 2026, 3 years requested, no past
    // contributions, employed (2nd pillar), income CHF 95'000.
    const json = <String, dynamic>{
      'maxPerYear': 725800,
      'eligibleYears': 1,
      'yearDetails': [
        {
          'year': 2025,
          'maxContribution': 725800,
          'actualContribution': 0,
          'gap': 725800,
        },
      ],
      'totalCatchupPotential': 725800,
      'currentYearGap': 725800,
      'mustMaxCurrentYearFirst': true,
      'estimatedTaxSavings': 217740,
      'estimatedMarginalRate': 30,
    };

    test('parses a real response', () {
      final dto = Catchup3aResultDto.fromJson(json);

      expect(dto.maxPerYear, 725800);
      expect(dto.eligibleYears, 1);
      expect(dto.yearDetails, hasLength(1));
      expect(dto.yearDetails.single.year, 2025);
      expect(dto.yearDetails.single.gap, 725800);
      expect(dto.totalCatchupPotential, 725800);
      expect(dto.currentYearGap, 725800);
      expect(dto.mustMaxCurrentYearFirst, isTrue);
      expect(dto.estimatedTaxSavings, 217740);
      expect(dto.estimatedMarginalRate, 30);
    });

    test('yearDetails missing → empty list', () {
      final dto = Catchup3aResultDto.fromJson({...json}..remove('yearDetails'));
      expect(dto.yearDetails, isEmpty);
    });
  });

  group('StaggeredWithdrawalResultDto', () {
    // Real response: VD, 3a CHF 150'000, 3 accounts, 60 years old, SINGLE,
    // LPP as capital CHF 200'000.
    const json = <String, dynamic>{
      'strategies': [
        {
          'label': 'lump_sum',
          'years': [
            {'year': 2031, 'amount': 35000000},
          ],
          'totalTax': 2493820,
          'effectiveTaxRate': 7.13,
        },
        {
          'label': 'stagger_2_years',
          'years': [
            {'year': 2030, 'amount': 17500000},
            {'year': 2031, 'amount': 17500000},
          ],
          'totalTax': 1729112,
          'effectiveTaxRate': 4.94,
        },
        {
          'label': 'stagger_3_years',
          'years': [
            {'year': 2029, 'amount': 11666667},
            {'year': 2030, 'amount': 11666667},
            {'year': 2031, 'amount': 11666666},
          ],
          'totalTax': 1310595,
          'effectiveTaxRate': 3.74,
        },
      ],
      'bestStrategy': 'stagger_3_years',
      'taxSavingsVsLumpSum': 1183225,
    };

    test('parses a real response (3 strategies)', () {
      final dto = StaggeredWithdrawalResultDto.fromJson(json);

      expect(dto.strategies, hasLength(3));
      expect(dto.strategies.first.label, 'lump_sum');
      expect(dto.strategies.first.totalTax, 2493820);
      expect(dto.strategies.first.effectiveTaxRate, 7.13);
      expect(dto.strategies[2].years, hasLength(3));
      expect(dto.strategies[2].years.first.year, 2029);
      expect(dto.bestStrategy, 'stagger_3_years');
      expect(dto.taxSavingsVsLumpSum, 1183225);
    });

    test('integer effective rate (0) → double', () {
      // Zero capital: the backend returns `0` (JSON int), not `0.0`.
      final dto = StaggeredWithdrawalResultDto.fromJson({
        'strategies': [
          {
            'label': 'lump_sum',
            'years': [
              {'year': 2031, 'amount': 0},
            ],
            'totalTax': 0,
            'effectiveTaxRate': 0,
          },
        ],
        'bestStrategy': 'lump_sum',
        'taxSavingsVsLumpSum': 0,
      });

      expect(dto.strategies.single.effectiveTaxRate, 0.0);
      expect(dto.strategies.single.effectiveTaxRate, isA<double>());
    });
  });

  group('PropertyPurchaseResultDto', () {
    // Real response: 40 years old, capital CHF 200'000, withdrawal CHF 50'000,
    // contribution CHF 5'000/year.
    const json = <String, dynamic>{
      'maxWithdrawal': 20000000,
      'effectiveWithdrawal': 5000000,
      'capitalAtRetirementWithout': 41851576,
      'capitalAtRetirementWith': 35030613,
      'capitalLostAtRetirement': 6820963,
      'annualPensionWithout': 2511095,
      'annualPensionWith': 2101837,
      'annualPensionLoss': 409258,
      'monthlyPensionLoss': 34105,
    };

    test('parses a real response', () {
      final dto = PropertyPurchaseResultDto.fromJson(json);

      expect(dto.maxWithdrawal, 20000000);
      expect(dto.effectiveWithdrawal, 5000000);
      expect(dto.capitalAtRetirementWithout, 41851576);
      expect(dto.capitalAtRetirementWith, 35030613);
      expect(dto.capitalLostAtRetirement, 6820963);
      expect(dto.annualPensionLoss, 409258);
      expect(dto.monthlyPensionLoss, 34105);
    });
  });

  group('DivorceImpactResultDto', () {
    // Real response: 40 years old, 10-year marriage, assets CHF 50k→200k (self)
    // and CHF 30k→150k (spouse), contribution CHF 5'000/year.
    const json = <String, dynamic>{
      'myAccumulatedDuringMarriage': 15000000,
      'spouseAccumulatedDuringMarriage': 12000000,
      'totalMarriageCapital': 27000000,
      'transferAmount': -1500000,
      'capitalAfterDivorce': 18500000,
      'projectedCapitalWithMarriage': 41851576,
      'projectedCapitalAfterDivorce': 39805286,
      'annualPensionWithMarriage': 2511095,
      'annualPensionAfterDivorce': 2388317,
      'annualPensionDifference': 122778,
      'estimatedAvsImpact': 294000,
    };

    test('parses a real response (negative transfer = to pay)', () {
      final dto = DivorceImpactResultDto.fromJson(json);

      expect(dto.myAccumulatedDuringMarriage, 15000000);
      expect(dto.spouseAccumulatedDuringMarriage, 12000000);
      expect(dto.totalMarriageCapital, 27000000);
      expect(dto.transferAmount, -1500000);
      expect(dto.capitalAfterDivorce, 18500000);
      expect(dto.annualPensionDifference, 122778);
      expect(dto.estimatedAvsImpact, 294000);
    });

    test('myShare derived = 50% share (myAccumulated + transfer)', () {
      final dto = DivorceImpactResultDto.fromJson(json);
      // 15000000 + (-1500000) = 13500000 = 27000000 / 2.
      expect(dto.myShare, 13500000);
    });
  });
}
