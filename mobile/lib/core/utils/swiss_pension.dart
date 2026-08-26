/// Swiss pension constants shared across features — source of truth:
/// `src/lib/constants/swiss-pension.ts` (backend).
///
/// All amounts are in **centimes** (contract §1).
library;

/// Annual 3a ceiling with a 2nd pillar, in centimes (CHF 7,258 —
/// `SWISS_PENSION.PILLAR_3A_MAX_EMPLOYED`).
const int pillar3aMaxWithPillar2 = 725800;

/// Annual 3a ceiling without a 2nd pillar, in centimes (CHF 36,288 —
/// `SWISS_PENSION.PILLAR_3A_MAX_SELF_EMPLOYED`).
const int pillar3aMaxWithoutPillar2 = 3628800;

/// Share of income deductible in 3a without a 2nd pillar, in %
/// (`SWISS_PENSION.PILLAR_3A_SELF_EMPLOYED_RATE`).
const int pillar3aSelfEmployedRatePercent = 20;

/// Applicable annual 3a ceiling, in centimes (OPP3 art. 7, 2026 values) —
/// parity with the backend helper `pillar3aMaxContribution`
/// (`src/lib/pillar3a-max-contribution.ts`).
///
/// - **With a 2nd pillar** (affiliated with a fund, including voluntary
///   LPP): CHF 7,258 — income has no effect.
/// - **Without a 2nd pillar** (non-affiliated self-employed): **20% of
///   income**, capped at CHF 36,288 — never negative.
///
/// The legal basis is *net income from gainful employment*; callers use
/// the best available proxy (wizard gross, declared profile net falling
/// back to gross) — approximation documented in contract §7.
/// The 20% is **truncated** to the nearest lower centime (`~/`, parity
/// with the backend `Math.floor` — batch 12 review).
int pillar3aMaxContributionFor({
  required bool hasSecondPillar,
  required int incomeCentimes,
}) {
  if (hasSecondPillar) return pillar3aMaxWithPillar2;
  final byIncome = incomeCentimes * pillar3aSelfEmployedRatePercent ~/ 100;
  if (byIncome < 0) return 0;
  return byIncome < pillar3aMaxWithoutPillar2
      ? byIncome
      : pillar3aMaxWithoutPillar2;
}

/// Affiliation with a 2nd pillar per OPP3 art. 7 (batch 12 review):
/// **employed** status (`EMPLOYED`) **or** existing LPP account — a
/// self-employed person affiliated with a fund (**voluntary** LPP) is
/// thus entitled to the small 7,258 ceiling, not the 20% ceiling.
/// Parity with the backend (`recommendation.handler.ts`:
/// `EMPLOYED || LPP accounts`).
bool hasSecondPillarFor({
  required String? employmentStatus,
  required bool hasPillar2Account,
}) => employmentStatus == 'EMPLOYED' || hasPillar2Account;

/// Basis for the 20% rule (batch 12 review): **declared net income,
/// falling back to gross** — best available proxy for net income from
/// gainful employment (legal basis). Single rule shared by the annual
/// reminder and the checklist.
int pillar3aIncomeBaseFor({
  required int grossAnnualIncomeCentimes,
  int? netAnnualIncomeCentimes,
}) => netAnnualIncomeCentimes ?? grossAnnualIncomeCentimes;

/// Applicable 3a ceiling for a known profile (status + LPP account +
/// income), in centimes — composition of the three rules above.
int pillar3aMaxForProfile({
  required String? employmentStatus,
  required bool hasPillar2Account,
  required int grossAnnualIncomeCentimes,
  int? netAnnualIncomeCentimes,
}) => pillar3aMaxContributionFor(
  hasSecondPillar: hasSecondPillarFor(
    employmentStatus: employmentStatus,
    hasPillar2Account: hasPillar2Account,
  ),
  incomeCentimes: pillar3aIncomeBaseFor(
    grossAnnualIncomeCentimes: grossAnnualIncomeCentimes,
    netAnnualIncomeCentimes: netAnnualIncomeCentimes,
  ),
);
