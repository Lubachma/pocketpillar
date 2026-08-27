/// Synthetic `POST /calculator/couple` responses shared by the
/// DTO / repository / screen tests (shapes verified in
/// `src/modules/calculator/couple-simulation.ts`). Amounts in centimes.
library;

import 'package:pocketpillar/features/couple/data/couple_result.dart';

Map<String, dynamic> _retirementJson({
  required int yearsToRetirement,
  required int avs,
  required int lppPension,
  int projectedPillar2 = 50000000,
  int projectedPillar3a = 8000000,
  double replacementRate = 63.0,
}) => {
  'yearsToRetirement': yearsToRetirement,
  'projectedPillar2Capital': projectedPillar2,
  'projectedPillar3aBalance': projectedPillar3a,
  'annualPillar2Pension': lppPension,
  'estimatedAnnualAvsPension': avs,
  'pillar3aAsLumpSum': projectedPillar3a,
  'totalAnnualRetirementIncome': avs + lppPension,
  'replacementRate': replacementRate,
  'yearByYearProjection': <dynamic>[],
};

Map<String, dynamic> _personIncomeJson({
  required int avsAnnual,
  required int pillar2Annual,
  required double replacementRate,
}) => {
  'avsAnnual': avsAnnual,
  'pillar2Annual': pillar2Annual,
  'totalAnnual': avsAnnual + pillar2Annual,
  'replacementRate': replacementRate,
};

/// Base response: no AVS cap, 4 staggered withdrawals 2048–2051
/// (fixed years — the plan comes from the server, not the client clock).
Map<String, dynamic> coupleResponseJson() => {
  'person1': _retirementJson(
    yearsToRetirement: 30,
    avs: 2352000,
    lppPension: 3000000,
  ),
  'person2': _retirementJson(
    yearsToRetirement: 25,
    avs: 1800000,
    lppPension: 2000000,
    projectedPillar2: 33333333,
    projectedPillar3a: 5000000,
    replacementRate: 58.0,
  ),
  // No cap → per-spouse income mirrors the raw projections.
  'person1Income': _personIncomeJson(
    avsAnnual: 2352000,
    pillar2Annual: 3000000,
    replacementRate: 63.0,
  ),
  'person2Income': _personIncomeJson(
    avsAnnual: 1800000,
    pillar2Annual: 2000000,
    replacementRate: 58.0,
  ),
  'combinedAvsAnnualRaw': 4152000,
  'combinedAvsAnnual': 4152000,
  'avsCapApplied': false,
  'avsCapAnnual': 4410000,
  'combinedTotalAnnualIncome': 9152000,
  'combinedReplacementRate': 59.05,
  'taxEstimate': {
    'married': {
      'federalTax': 481199,
      'cantonalTax': 1000000,
      'communalTax': 1100000,
      'totalTax': 2581199,
    },
    'unmarried': {
      'federalTax': 317265,
      'cantonalTax': 802000,
      'communalTax': 882200,
      'totalTax': 2001465,
    },
    // Marriage = +5'797.34/year → concubinage is cheaper.
    'annualDifference': 579734,
    'cheaperStatus': 'CONCUBINAGE',
  },
  'withdrawalPlan': {
    'steps': [
      {
        'year': 2048,
        'spouse': 'person2',
        'pillar': 'pillar2',
        'amount': 30000000,
        'estimatedTax': 1776868,
      },
      {
        'year': 2049,
        'spouse': 'person2',
        'pillar': 'pillar3a',
        'amount': 10000000,
        'estimatedTax': 350240,
      },
      {
        'year': 2050,
        'spouse': 'person1',
        'pillar': 'pillar3a',
        'amount': 20000000,
        'estimatedTax': 992912,
      },
      {
        'year': 2051,
        'spouse': 'person1',
        'pillar': 'pillar2',
        'amount': 50000000,
        'estimatedTax': 3592430,
      },
    ],
    'totalEstimatedTax': 6712450,
    'simultaneousEstimatedTax': 9305663,
    'taxSavingsVsSimultaneous': 2593213,
  },
};

/// Variant at the AVS couple cap (2 × 29'400 → 44'100).
Map<String, dynamic> coupleCappedResponseJson() => {
  ...coupleResponseJson(),
  'person1': _retirementJson(
    yearsToRetirement: 30,
    avs: 2940000,
    lppPension: 3000000,
  ),
  'person2': _retirementJson(
    yearsToRetirement: 30,
    avs: 2940000,
    lppPension: 2000000,
    projectedPillar2: 33333333,
    projectedPillar3a: 5000000,
    replacementRate: 58.0,
  ),
  // Cap allocated pro rata (equal pensions → CHF 22'050/year each);
  // per-spouse totals sum back to combinedTotalAnnualIncome.
  'person1Income': _personIncomeJson(
    avsAnnual: 2205000,
    pillar2Annual: 3000000,
    replacementRate: 54.8,
  ),
  'person2Income': _personIncomeJson(
    avsAnnual: 2205000,
    pillar2Annual: 2000000,
    replacementRate: 44.3,
  ),
  'combinedAvsAnnualRaw': 5880000,
  'combinedAvsAnnual': 4410000,
  'avsCapApplied': true,
  'combinedTotalAnnualIncome': 9410000,
  'combinedReplacementRate': 49.53,
};

/// Variant with no capital at all (empty plan).
Map<String, dynamic> coupleEmptyPlanResponseJson() => {
  ...coupleResponseJson(),
  'withdrawalPlan': {
    'steps': <dynamic>[],
    'totalEstimatedTax': 0,
    'simultaneousEstimatedTax': 0,
    'taxSavingsVsSimultaneous': 0,
  },
};

/// Parsed result of the base response.
CoupleResult syntheticCoupleResult() =>
    CoupleResult.fromJson(coupleResponseJson());
