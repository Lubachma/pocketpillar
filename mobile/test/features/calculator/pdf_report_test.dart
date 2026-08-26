import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/features/calculator/data/calculator_dtos.dart';
import 'package:pocketpillar/features/calculator/data/calculator_payloads.dart';
import 'package:pocketpillar/features/calculator/data/calculator_repository.dart';
import 'package:pocketpillar/features/calculator/data/pdf_report.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));

  const input = GuidedCalculatorInput(
    age: 35,
    canton: 'VD',
    maritalStatus: 'SINGLE',
    grossAnnualIncome: 9500000,
    pillar2Capital: 2000000,
    pillar2Contribution: 500000,
    hasPillar3a: true,
    pillar3aBalance: 1000000,
  );

  const results = CalculatorResults(
    retirement: RetirementResultDto(
      yearsToRetirement: 30,
      projectedPillar2Capital: 50000000,
      projectedPillar3aBalance: 8000000,
      annualPillar2Pension: 3000000,
      estimatedAnnualAvsPension: 2352000,
      pillar3aAsLumpSum: 8000000,
      totalAnnualRetirementIncome: 5352000,
      replacementRate: 63.0,
      yearByYearProjection: [
        YearProjectionDto(
          year: 2027,
          age: 36,
          pillar2Capital: 2100000,
          pillar3aBalance: 1758000,
          totalCapital: 3858000,
        ),
      ],
    ),
    taxSavings: TaxSavingsResultDto(
      federalTaxSaving: 85000,
      cantonalTaxSaving: 90000,
      communalTaxSaving: 45000,
      totalTaxSaving: 220000,
      effectiveReturnRate: 30.31,
      maxContribution: 725800,
      isAtMax: true,
    ),
    lppGap: LppGapResultDto(
      coordinatedSalary: 6800000,
      bvgMinContribution: 612000,
      contributionGap: 0,
      projectedBvgMinCapital: 42000000,
      projectedActualCapital: 45000000,
      capitalGap: 0,
      projectedMinAnnualPension: 2520000,
      projectedActualAnnualPension: 2700000,
      pensionGap: 0,
    ),
  );

  test('generates a non-empty PDF document (%PDF- header)', () async {
    final bytes = await buildPensionReportPdf(
      l10n: l10n,
      dateLabel: '5 août 2026',
      input: input,
      results: results,
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('also generates without tax savings (section omitted)', () async {
    final noTax = CalculatorResults(
      retirement: results.retirement,
      taxSavings: TaxSavingsResultDto(
        federalTaxSaving: 0,
        cantonalTaxSaving: 0,
        communalTaxSaving: 0,
        totalTaxSaving: 0,
        effectiveReturnRate: 0,
        maxContribution: 725800,
        isAtMax: false,
      ),
    );

    final bytes = await buildPensionReportPdf(
      l10n: l10n,
      dateLabel: '5 août 2026',
      input: input,
      results: noTax,
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('the other locales (de/en) also generate a document', () async {
    for (final locale in const [Locale('de'), Locale('en')]) {
      final bytes = await buildPensionReportPdf(
        l10n: lookupAppLocalizations(locale),
        dateLabel: '5 August 2026',
        input: input,
        results: results,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    }
  });
}
