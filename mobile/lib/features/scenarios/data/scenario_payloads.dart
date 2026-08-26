/// Building the payloads for the 4 scenarios — pure functions (tested
/// without network access).
///
/// Bounds aligned with the Zod schemas
/// (`src/modules/calculator/calculator.schema.ts`); amounts in
/// **centimes** (contract §1).
library;

/// Reference retirement age (backend schemas' default).
const int scenarioRetirementAge = 65;

/// Minimum age for the scenarios (common lower bound of the
/// property-purchase / divorce-impact / staggered-withdrawal schemas).
const int scenarioMinAge = 25;

/// Maximum age for the scenarios: `retirementAge > age` required by
/// the schemas.
const int scenarioMaxAge = scenarioRetirementAge - 1;

/// Maximum number of catchable years (2025 reform — upper bound of
/// the `3a-catchup` schema).
const int catchupMaxYears = 10;

/// Maximum number of 3a accounts for staggering (upper bound of the
/// `staggered-withdrawal` schema).
const int staggeredMaxAccounts = 5;

/// Maximum number of years married (upper bound of the
/// `divorce-impact` schema).
const int divorceMaxYearsMarried = 50;

/// Payload for `POST /calculator/3a-catchup`.
///
/// `currentYear` and `pastContributions` are omitted: schema defaults
/// (current year, `{}` → gap = full cap per year). `canton`,
/// `maritalStatus`, and `municipality` (from the profile prefill)
/// enable the real tax-savings calculation on the backend side (FTA
/// [Federal Tax Administration] tax scales, year by year).
Map<String, dynamic> buildCatchup3aPayload({
  required int yearsMissed,
  required bool hasSecondPillar,
  required int taxableIncome,
  String? canton,
  String? maritalStatus,
  String? municipality,
}) => <String, dynamic>{
  'yearsSinceFirstEligible': yearsMissed,
  'hasSecondPillar': hasSecondPillar,
  'taxableIncome': taxableIncome,
  'canton': ?canton,
  'maritalStatus': ?maritalStatus,
  'municipality': ?municipality,
};

/// Payload for `POST /calculator/staggered-withdrawal`.
///
/// [maritalStatus] must already be normalized via
/// [mapMaritalStatusForWithdrawal] (the schema only accepts
/// `SINGLE | MARRIED`).
Map<String, dynamic> buildStaggeredWithdrawalPayload({
  required String canton,
  required int totalPillar3aBalance,
  required int numberOfAccounts,
  required int currentAge,
  required String maritalStatus,
  required int pillar2AsCapital,
}) => <String, dynamic>{
  'canton': canton,
  'totalPillar3aBalance': totalPillar3aBalance,
  'numberOfAccounts': numberOfAccounts,
  'retirementAge': scenarioRetirementAge,
  'currentAge': currentAge,
  'maritalStatus': maritalStatus,
  'pillar2AsCapital': pillar2AsCapital,
};

/// Normalizes the profile's marital status (5 enums) to the 2 values
/// of the `staggered-withdrawal` schema: a registered partnership is
/// taxed the same as marriage (backend's real joint tax scale).
String mapMaritalStatusForWithdrawal(String maritalStatus) =>
    maritalStatus == 'MARRIED' || maritalStatus == 'REGISTERED_PARTNERSHIP'
    ? 'MARRIED'
    : 'SINGLE';

/// Payload for `POST /calculator/property-purchase` (EPL).
///
/// `bvgCapitalAtAge50` is omitted: the backend falls back to half of
/// the current assets when age is ≥ 50.
Map<String, dynamic> buildPropertyPurchasePayload({
  required int age,
  required int currentBvgCapital,
  required int withdrawalAmount,
  required int annualContribution,
}) => <String, dynamic>{
  'age': age,
  'retirementAge': scenarioRetirementAge,
  'currentBvgCapital': currentBvgCapital,
  'withdrawalAmount': withdrawalAmount,
  'annualContribution': annualContribution,
};

/// Payload for `POST /calculator/divorce-impact`.
Map<String, dynamic> buildDivorceImpactPayload({
  required int age,
  required int bvgCapitalAtMarriage,
  required int bvgCapitalNow,
  required int spouseBvgCapitalAtMarriage,
  required int spouseBvgCapitalNow,
  required int yearsMarried,
  required int annualContribution,
}) => <String, dynamic>{
  'age': age,
  'retirementAge': scenarioRetirementAge,
  'bvgCapitalAtMarriage': bvgCapitalAtMarriage,
  'bvgCapitalNow': bvgCapitalNow,
  'spouseBvgCapitalAtMarriage': spouseBvgCapitalAtMarriage,
  'spouseBvgCapitalNow': spouseBvgCapitalNow,
  'yearsMarried': yearsMarried,
  'annualContribution': annualContribution,
};
