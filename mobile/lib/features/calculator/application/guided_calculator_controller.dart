import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../financial_profile/application/financial_profile_providers.dart';
import '../data/calculator_payloads.dart';
import '../data/calculator_repository.dart';

/// Number of steps in the flow (situation, income, 2nd pillar, 3a) —
/// results are a phase, not a step.
const int guidedStepCount = 4;

/// State of the guided flow. Amounts in **centimes** (contract §1) — the
/// conversion from CHF input happens in the wizard steps.
class GuidedCalculatorState {
  const GuidedCalculatorState({
    this.currentStep = 0,
    this.age = 35,
    this.canton = 'VD',
    this.municipality,
    this.maritalStatus = 'SINGLE',
    this.grossAnnualIncome,
    this.pillar2Capital = 0,
    this.pillar2Contribution = 0,
    this.hasPillar3a = false,
    this.pillar3aBalance = 0,
    this.prefillLoading = true,
    this.prefillError,
    this.calculating = false,
    this.calculationError,
    this.results,
    this.lastInput,
  });

  /// Current step (0..[guidedStepCount] − 1).
  final int currentStep;

  /// First-open defaults = the iOS ones (35 years old, VD, SINGLE).
  final int age;
  final String canton;

  /// Municipality of residence — null → cantonal average on the calculator
  /// side (silent backend fallback for uncovered municipalities).
  final String? municipality;
  final String maritalStatus;

  /// Gross annual income, in centimes — null until it's either pre-filled
  /// or entered ("incomplete profile" mode: free-form field).
  final int? grossAnnualIncome;

  /// Current LPP capital, in centimes.
  final int pillar2Capital;

  /// Annual LPP contribution, in centimes.
  final int pillar2Contribution;

  final bool hasPillar3a;

  /// Current 3a balance, in centimes.
  final int pillar3aBalance;

  final bool prefillLoading;

  /// Prefill error (profile API) — full-screen error view.
  final Object? prefillError;

  final bool calculating;

  /// Calculation error — error view with retry (inputs survive).
  final Object? calculationError;

  /// Non-null → results phase (like iOS's `hasResults`).
  final CalculatorResults? results;

  /// Input **frozen** when the calculation starts — the one that produced
  /// [results]. The results/PDF phase consumes it (not [inputOrNull])
  /// to stay consistent if the fields are modified afterward.
  final GuidedCalculatorInput? lastInput;

  bool get hasResults => results != null;

  GuidedCalculatorInput? get inputOrNull {
    final income = grossAnnualIncome;
    if (income == null) return null;
    return GuidedCalculatorInput(
      age: age,
      canton: canton,
      municipality: municipality,
      maritalStatus: maritalStatus,
      grossAnnualIncome: income,
      pillar2Capital: pillar2Capital,
      pillar2Contribution: pillar2Contribution,
      hasPillar3a: hasPillar3a,
      pillar3aBalance: hasPillar3a ? pillar3aBalance : 0,
    );
  }

  GuidedCalculatorState copyWith({
    int? currentStep,
    int? age,
    String? canton,
    String? Function()? municipality,
    String? maritalStatus,
    int? Function()? grossAnnualIncome,
    int? pillar2Capital,
    int? pillar2Contribution,
    bool? hasPillar3a,
    int? pillar3aBalance,
    bool? prefillLoading,
    Object? Function()? prefillError,
    bool? calculating,
    Object? Function()? calculationError,
    CalculatorResults? Function()? results,
    GuidedCalculatorInput? Function()? lastInput,
  }) {
    return GuidedCalculatorState(
      currentStep: currentStep ?? this.currentStep,
      age: age ?? this.age,
      canton: canton ?? this.canton,
      municipality: municipality != null ? municipality() : this.municipality,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      grossAnnualIncome: grossAnnualIncome != null
          ? grossAnnualIncome()
          : this.grossAnnualIncome,
      pillar2Capital: pillar2Capital ?? this.pillar2Capital,
      pillar2Contribution: pillar2Contribution ?? this.pillar2Contribution,
      hasPillar3a: hasPillar3a ?? this.hasPillar3a,
      pillar3aBalance: pillar3aBalance ?? this.pillar3aBalance,
      prefillLoading: prefillLoading ?? this.prefillLoading,
      prefillError: prefillError != null ? prefillError() : this.prefillError,
      calculating: calculating ?? this.calculating,
      calculationError: calculationError != null
          ? calculationError()
          : this.calculationError,
      results: results != null ? results() : this.results,
      lastInput: lastInput != null ? lastInput() : this.lastInput,
    );
  }
}

/// Injectable clock (age calculation at prefill) — tests.
final calculatorClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Controller for the guided flow: prefill from the profile API
/// (`users/me` + `financial-profile` + accounts), inputs, then calculations via
/// [CalculatorRepository]. autoDispose: leaving the tab resets the
/// flow (like iOS's `viewModel` @State).
class GuidedCalculatorController
    extends AutoDisposeNotifier<GuidedCalculatorState> {
  @override
  GuidedCalculatorState build() {
    var disposed = false;
    ref.onDispose(() => disposed = true);
    _disposed = () => disposed;
    Future(_prefill);
    return const GuidedCalculatorState();
  }

  late bool Function() _disposed;

  /// Prefills from the shared profile aggregate (I9): age (birth
  /// year), canton, marital status, gross income, LPP capital/
  /// contributions, 3a balance. Already loaded by the dashboard/profile?
  /// No refetch. Whatever's missing stays at defaults / empty → free-form entry
  /// ("incomplete profile" mode).
  Future<void> _prefill() async {
    try {
      final aggregate = await ref.read(profileAggregateProvider.future);
      if (_disposed()) return;
      final base = aggregate.base;
      final pillar2 = aggregate.pillar2Accounts;
      final pillar3a = aggregate.pillar3aAccounts;
      final profile = base.profile;

      final birthYear = base.birthYear;
      final computedAge = birthYear != null
          ? ref.read(calculatorClockProvider)().year - birthYear
          : null;

      state = state.copyWith(
        prefillLoading: false,
        prefillError: () => null,
        age: computedAge != null
            ? computedAge.clamp(calculatorMinAge, calculatorMaxAge)
            : state.age,
        canton: base.canton ?? state.canton,
        municipality: () => base.municipality,
        maritalStatus: profile?.maritalStatus ?? state.maritalStatus,
        grossAnnualIncome: () => profile?.grossAnnualIncome,
        pillar2Capital: pillar2.fold<int>(
          0,
          (sum, a) => sum + a.currentCapital,
        ),
        pillar2Contribution: pillar2.fold<int>(
          0,
          (sum, a) => sum + (a.annualBvgContribution ?? 0),
        ),
        hasPillar3a: pillar3a.isNotEmpty,
        pillar3aBalance: pillar3a.fold<int>(
          0,
          (sum, a) => sum + a.currentBalance,
        ),
      );
    } on Object catch (e) {
      if (_disposed()) return;
      state = state.copyWith(
        prefillLoading: false,
        prefillError: () => e,
      );
    }
  }

  /// Retry the prefill (full-screen error view). The shared aggregate
  /// is invalidated first: without that, the retry would re-read its cached
  /// error instead of reloading.
  void retryPrefill() {
    ref.invalidate(profileAggregateProvider);
    state = state.copyWith(prefillLoading: true, prefillError: () => null);
    Future(_prefill);
  }

  void updateSituation({
    int? age,
    String? canton,
    String? maritalStatus,
    String? municipality,
    bool clearMunicipality = false,
  }) {
    // The municipality depends on the canton: a canton change
    // resets it, same as choosing "cantonal average" in the picker
    // ([clearMunicipality]); otherwise the explicit input applies
    // ([municipality] null = unchanged).
    final cantonChanged = canton != null && canton != state.canton;
    state = state.copyWith(
      age: age,
      canton: canton,
      maritalStatus: maritalStatus,
      municipality: (cantonChanged || clearMunicipality)
          ? () => null
          : (municipality != null ? () => municipality : null),
    );
  }

  void updateIncome(int grossAnnualIncomeCentimes) {
    state = state.copyWith(
      grossAnnualIncome: () => grossAnnualIncomeCentimes,
    );
  }

  void updatePillar2({required int capital, required int contribution}) {
    state = state.copyWith(
      pillar2Capital: capital,
      pillar2Contribution: contribution,
    );
  }

  void updatePillar3a({required bool has, required int balance}) {
    state = state.copyWith(
      hasPillar3a: has,
      pillar3aBalance: has ? balance : 0,
    );
  }

  void nextStep() {
    if (state.currentStep < guidedStepCount - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Runs the applicable calculations (last step). The input is frozen
  /// into `lastInput` when launched: the results and the PDF stay
  /// consistent even if the fields are modified during/after the calculation.
  /// Any error is carried by the state → error view with retry; the
  /// inputs survive.
  Future<void> calculate() async {
    final input = state.inputOrNull;
    // Unreachable via the UI (income is validated at step 2).
    if (input == null || state.calculating) return;
    state = state.copyWith(
      calculating: true,
      calculationError: () => null,
      lastInput: () => input,
    );
    try {
      final results = await ref
          .read(calculatorRepositoryProvider)
          .calculateAll(input);
      if (_disposed()) return;
      state = state.copyWith(
        calculating: false,
        results: () => results,
      );
    } on Object catch (e) {
      if (_disposed()) return;
      state = state.copyWith(
        calculating: false,
        calculationError: () => e,
      );
    }
  }

  /// Replays the calculations after an error (same inputs).
  void retryCalculation() {
    state = state.copyWith(calculationError: () => null);
    Future(calculate);
  }

  /// Clears the calculation error → back to the form (inputs intact).
  void clearCalculationError() {
    state = state.copyWith(calculationError: () => null);
  }

  /// Back to the wizard (↺ button) — inputs are kept, like iOS's
  /// `restart()`.
  void restart() {
    state = state.copyWith(
      currentStep: 0,
      calculationError: () => null,
      results: () => null,
      lastInput: () => null,
    );
  }
}

final guidedCalculatorControllerProvider =
    NotifierProvider.autoDispose<
      GuidedCalculatorController,
      GuidedCalculatorState
    >(GuidedCalculatorController.new);
