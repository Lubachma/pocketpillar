import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/couple/data/couple_result.dart';

import 'couple_fixtures.dart';

/// Parsing of couple DTOs (`POST /calculator/couple` response, batch 6) —
/// no business rules on the client side: we verify faithful reading of the JSON.
void main() {
  test('parses the full response: spouses, combined, tax, plan', () {
    final result = CoupleResult.fromJson(coupleResponseJson());

    // Per-spouse projections (reused calculator DTO).
    expect(result.person1.estimatedAnnualAvsPension, 2352000);
    expect(result.person2.replacementRate, 58.0);

    // Combined (computed by the server, cap included).
    expect(result.combinedAvsAnnualRaw, 4152000);
    expect(result.combinedAvsAnnual, 4152000);
    expect(result.avsCapApplied, isFalse);
    expect(result.avsCapAnnual, 4410000);
    expect(result.combinedTotalAnnualIncome, 9152000);
    expect(result.combinedReplacementRate, 59.05);

    // Tax: married vs. unmarried.
    expect(result.taxEstimate.married.totalTax, 2581199);
    expect(result.taxEstimate.unmarried.totalTax, 2001465);
    expect(result.taxEstimate.annualDifference, 579734);
    expect(result.taxEstimate.cheaperStatus, 'CONCUBINAGE');

    // Coordinated withdrawal plan.
    expect(result.withdrawalPlan.steps, hasLength(4));
    final first = result.withdrawalPlan.steps.first;
    expect(first.year, 2048);
    expect(first.spouse, 'person2');
    expect(first.pillar, 'pillar2');
    expect(first.amount, 30000000);
    expect(first.estimatedTax, 1776868);
    expect(result.withdrawalPlan.totalEstimatedTax, 6712450);
    expect(result.withdrawalPlan.simultaneousEstimatedTax, 9305663);
    expect(result.withdrawalPlan.taxSavingsVsSimultaneous, 2593213);
  });

  test('parses the AVS couple cap variant', () {
    final result = CoupleResult.fromJson(coupleCappedResponseJson());

    expect(result.avsCapApplied, isTrue);
    expect(result.combinedAvsAnnualRaw, 5880000);
    expect(result.combinedAvsAnnual, 4410000);
    expect(result.combinedTotalAnnualIncome, 9410000);
  });

  test('parses an empty plan (no capital)', () {
    final result = CoupleResult.fromJson(coupleEmptyPlanResponseJson());

    expect(result.withdrawalPlan.steps, isEmpty);
    expect(result.withdrawalPlan.totalEstimatedTax, 0);
    expect(result.withdrawalPlan.taxSavingsVsSimultaneous, 0);
  });

  test('tolerates missing yearByYearProjection (empty list by default)', () {
    final json = coupleResponseJson();
    (json['person1'] as Map<String, dynamic>).remove('yearByYearProjection');

    final result = CoupleResult.fromJson(json);

    expect(result.person1.yearByYearProjection, isEmpty);
  });
}
