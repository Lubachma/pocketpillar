import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../financial_profile/application/financial_profile_providers.dart';
import '../data/scenario_payloads.dart';

/// Scenario prefill data, derived from the API profile (same
/// cross-feature exception as the calculator — the
/// `FinancialProfileRepository` remains the only parsed source).
///
/// What's missing (profile 404, null fields) stays null/0: screens
/// then apply their own defaults ("incomplete profile" mode).
class ScenarioPrefill {
  const ScenarioPrefill({
    this.age,
    this.canton,
    this.municipality,
    this.maritalStatus,
    this.employmentStatus,
    this.grossAnnualIncome,
    this.pillar2Capital = 0,
    this.pillar2Contribution = 0,
    this.pillar3aBalance = 0,
    this.pillar3aAccountCount = 0,
  });

  /// Age computed from the birth year, clamped to the scenarios'
  /// bounds (25–64); null if the birth year is unknown.
  final int? age;

  /// 2-letter canton code, null if never provided.
  final String? canton;

  /// Municipality of residence, null if never provided (cantonal average).
  final String? municipality;

  /// Marital status from the profile (5 enums), null without a profile.
  final String? maritalStatus;

  /// `EMPLOYED | SELF_EMPLOYED | UNEMPLOYED | RETIRED`, null without a profile.
  final String? employmentStatus;

  /// Gross annual income, in centimes — null without a profile.
  final int? grossAnnualIncome;

  /// Sum of LPP capitals, in centimes.
  final int pillar2Capital;

  /// Sum of annual LPP contributions, in centimes.
  final int pillar2Contribution;

  /// Sum of 3a balances, in centimes.
  final int pillar3aBalance;

  /// Number of declared 3a accounts.
  final int pillar3aAccountCount;
}

/// Injectable clock (age computation) — tests.
final scenarioClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Loads the scenario prefill, derived from the shared profile
/// aggregate (I9: no refetch if the dashboard/profile has already
/// loaded it). autoDispose: the **view** is dropped when leaving the
/// screen; the aggregate stays cached. A 404 on the financial profile
/// is a normal state (null fields), any other error is carried by the
/// AsyncValue → error view with retry
/// (`ref.invalidate(profileAggregateProvider)`).
final scenarioPrefillProvider = FutureProvider.autoDispose<ScenarioPrefill>((
  ref,
) async {
  final aggregate = await ref.watch(profileAggregateProvider.future);
  final base = aggregate.base;
  final pillar2 = aggregate.pillar2Accounts;
  final pillar3a = aggregate.pillar3aAccounts;

  final birthYear = base.birthYear;
  final computedAge = birthYear != null
      ? (ref.read(scenarioClockProvider)().year - birthYear).clamp(
          scenarioMinAge,
          scenarioMaxAge,
        )
      : null;

  return ScenarioPrefill(
    age: computedAge,
    canton: base.canton,
    municipality: base.municipality,
    maritalStatus: base.profile?.maritalStatus,
    employmentStatus: base.profile?.employmentStatus,
    grossAnnualIncome: base.profile?.grossAnnualIncome,
    pillar2Capital: pillar2.fold<int>(0, (sum, a) => sum + a.currentCapital),
    pillar2Contribution: pillar2.fold<int>(
      0,
      (sum, a) => sum + (a.annualBvgContribution ?? 0),
    ),
    pillar3aBalance: pillar3a.fold<int>(0, (sum, a) => sum + a.currentBalance),
    pillar3aAccountCount: pillar3a.length,
  );
});
