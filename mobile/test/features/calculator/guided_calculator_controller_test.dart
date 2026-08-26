import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/calculator/application/guided_calculator_controller.dart';
import 'package:pocketpillar/features/calculator/data/calculator_dtos.dart';
import 'package:pocketpillar/features/calculator/data/calculator_payloads.dart';
import 'package:pocketpillar/features/calculator/data/calculator_repository.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';

import '../../helpers/fakes.dart';

class _FakeProfileRepository extends FinancialProfileRepository {
  _FakeProfileRepository() : super(FakeApiClient());

  /// Municipality returned by `loadBase` (null by default).
  String? municipality;

  @override
  Future<ProfileBaseData> loadBase() async => ProfileBaseData(
    userId: 'u-1',
    email: 'user@example.ch',
    canton: 'VD',
    municipality: municipality,
    birthYear: 1991,
    replacementRateGoal: 70,
    loadedAt: DateTime(2026, 8, 5),
  );

  @override
  Future<List<Pillar2AccountDto>> fetchPillar2Accounts() async => [];

  @override
  Future<List<Pillar3aAccountDto>> fetchPillar3aAccounts() async => [];
}

class _FakeCalculatorRepository extends CalculatorRepository {
  _FakeCalculatorRepository() : super(FakeApiClient());

  @override
  Future<CalculatorResults> calculateAll(GuidedCalculatorInput input) async =>
      const CalculatorResults(
        retirement: RetirementResultDto(
          yearsToRetirement: 30,
          projectedPillar2Capital: 0,
          projectedPillar3aBalance: 0,
          annualPillar2Pension: 0,
          estimatedAnnualAvsPension: 2352000,
          pillar3aAsLumpSum: 0,
          totalAnnualRetirementIncome: 2352000,
          replacementRate: 63.0,
          yearByYearProjection: [],
        ),
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
}

void main() {
  /// Container wired to the fakes, pre-fill completed. Keeps the
  /// autoDispose provider alive for the duration of the test.
  Future<GuidedCalculatorController> pumpController(
    _FakeProfileRepository profileRepo,
  ) async {
    final container = ProviderContainer(
      overrides: [
        financialProfileRepositoryProvider.overrideWithValue(profileRepo),
        calculatorRepositoryProvider.overrideWithValue(
          _FakeCalculatorRepository(),
        ),
        calculatorClockProvider.overrideWithValue(() => DateTime(2026, 8, 5)),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(guidedCalculatorControllerProvider, (_, _) {});
    addTearDown(sub.close);

    while (container.read(guidedCalculatorControllerProvider).prefillLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    return container.read(guidedCalculatorControllerProvider.notifier);
  }

  test(
    'pre-fill: the profile municipality is carried over into the input',
    () async {
      final notifier = await pumpController(
        _FakeProfileRepository()..municipality = 'Lausanne',
      );

      expect(notifier.state.municipality, 'Lausanne');

      notifier.updateIncome(9500000);
      expect(notifier.state.inputOrNull!.municipality, 'Lausanne');
    },
  );

  test('updateSituation: municipality stored, reset when the canton '
      'changes, unchanged otherwise', () async {
    final notifier = await pumpController(_FakeProfileRepository());

    // Without a pre-filled municipality: cantonal average (null).
    expect(notifier.state.municipality, isNull);

    notifier.updateSituation(municipality: 'Lausanne');
    expect(notifier.state.municipality, 'Lausanne');

    // An update without a municipality doesn't touch it.
    notifier.updateSituation(age: 40);
    expect(notifier.state.municipality, 'Lausanne');

    // Changing the canton invalidates the chosen municipality.
    notifier.updateSituation(canton: 'ZH');
    expect(notifier.state.municipality, isNull);

    // Explicit deselection (« moyenne cantonale » option in the picker).
    notifier.updateSituation(municipality: 'Zurich');
    expect(notifier.state.municipality, 'Zurich');
    notifier.updateSituation(clearMunicipality: true);
    expect(notifier.state.municipality, isNull);
  });

  test('calculate() freezes lastInput: later edits don\'t alter it', () async {
    final container = ProviderContainer(
      overrides: [
        financialProfileRepositoryProvider.overrideWithValue(
          _FakeProfileRepository(),
        ),
        calculatorRepositoryProvider.overrideWithValue(
          _FakeCalculatorRepository(),
        ),
        calculatorClockProvider.overrideWithValue(() => DateTime(2026, 8, 5)),
      ],
    );
    addTearDown(container.dispose);
    // Keeps the autoDispose provider alive during the test.
    final sub = container.listen(guidedCalculatorControllerProvider, (_, _) {});
    addTearDown(sub.close);

    // End of pre-fill (the fakes respond immediately).
    while (container.read(guidedCalculatorControllerProvider).prefillLoading) {
      await Future<void>.delayed(Duration.zero);
    }

    final notifier = container.read(
      guidedCalculatorControllerProvider.notifier,
    );
    notifier.updateIncome(9500000); // CHF 95'000
    await notifier.calculate();

    // The fields remain editable during/after the calculation.
    notifier.updateIncome(5000000); // CHF 50'000

    final state = container.read(guidedCalculatorControllerProvider);
    expect(state.results, isNotNull);
    // The frozen input matches the one that produced the results…
    expect(state.lastInput!.grossAnnualIncome, 9500000);
    // …even though the current input has changed.
    expect(state.inputOrNull!.grossAnnualIncome, 5000000);
  });

  test('restart() clears results and lastInput, keeps the inputs', () async {
    final container = ProviderContainer(
      overrides: [
        financialProfileRepositoryProvider.overrideWithValue(
          _FakeProfileRepository(),
        ),
        calculatorRepositoryProvider.overrideWithValue(
          _FakeCalculatorRepository(),
        ),
        calculatorClockProvider.overrideWithValue(() => DateTime(2026, 8, 5)),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(guidedCalculatorControllerProvider, (_, _) {});
    addTearDown(sub.close);

    while (container.read(guidedCalculatorControllerProvider).prefillLoading) {
      await Future<void>.delayed(Duration.zero);
    }

    final notifier = container.read(
      guidedCalculatorControllerProvider.notifier,
    );
    notifier.updateIncome(9500000);
    await notifier.calculate();
    notifier.restart();

    final state = container.read(guidedCalculatorControllerProvider);
    expect(state.results, isNull);
    expect(state.lastInput, isNull);
    expect(state.currentStep, 0);
    expect(state.grossAnnualIncome, 9500000); // input kept
  });
}
