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

  test('parses the per-spouse income view (capped values, practitioner '
      'review 08.2026)', () {
    final base = CoupleResult.fromJson(coupleResponseJson());
    // No cap: the per-spouse view mirrors the raw projections.
    expect(base.person1Income.avsAnnual, 2352000);
    expect(base.person1Income.pillar2Annual, 3000000);
    expect(base.person1Income.totalAnnual, 5352000);
    expect(base.person1Income.replacementRate, 63.0);
    expect(base.person2Income.totalAnnual, 3800000);

    final capped = CoupleResult.fromJson(coupleCappedResponseJson());
    // Cap allocated pro rata server-side; shares sum back to the cap.
    expect(capped.person1Income.avsAnnual, 2205000);
    expect(capped.person2Income.avsAnnual, 2205000);
    expect(
      capped.person1Income.totalAnnual + capped.person2Income.totalAnnual,
      capped.combinedTotalAnnualIncome,
    );
  });

  test('parses the retirement timeline (phases, ages, cap)', () {
    final base = CoupleResult.fromJson(coupleResponseJson());
    expect(base.timeline, hasLength(2));
    final first = base.timeline.first;
    expect(first.startYear, 2052);
    expect(first.endYear, 2057);
    expect(first.person1Retired, isFalse);
    expect(first.person2Retired, isTrue);
    expect(first.person2TotalAnnual, 3800000);
    expect(first.combinedAnnual, 3800000);
    expect(base.timeline.last.endYear, isNull);

    final capped = CoupleResult.fromJson(coupleCappedResponseJson());
    expect(capped.timeline, hasLength(1));
    expect(capped.timeline.single.avsCapApplied, isTrue);
    expect(capped.timeline.single.person1AvsAnnual, 2205000);
  });

  test('tolerates a missing timeline (older backend → empty list)', () {
    final json = coupleResponseJson()..remove('timeline');
    final result = CoupleResult.fromJson(json);
    expect(result.timeline, isEmpty);
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
