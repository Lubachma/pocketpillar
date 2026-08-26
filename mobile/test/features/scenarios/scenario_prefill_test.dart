import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';
import 'package:pocketpillar/features/scenarios/application/scenario_prefill.dart';

import '../../helpers/fakes.dart';

/// Simulated profile repository: canned data.
class _FakeProfileRepository extends FinancialProfileRepository {
  _FakeProfileRepository() : super(FakeApiClient());

  ProfileBaseData? baseData;
  List<Pillar2AccountDto> pillar2 = [];
  List<Pillar3aAccountDto> pillar3a = [];

  @override
  Future<ProfileBaseData> loadBase() async => baseData!;

  @override
  Future<List<Pillar2AccountDto>> fetchPillar2Accounts() async => pillar2;

  @override
  Future<List<Pillar3aAccountDto>> fetchPillar3aAccounts() async => pillar3a;
}

void main() {
  late _FakeProfileRepository profileRepo;

  /// Fixed clock: 2026 → birthYear 1991 = 35 years old.
  final fixedNow = DateTime(2026, 8, 5);

  setUp(() {
    profileRepo = _FakeProfileRepository()
      ..baseData = ProfileBaseData(
        userId: 'u-1',
        email: 'user@example.ch',
        canton: 'VD',
        birthYear: 1991,
        replacementRateGoal: 70,
        profile: const FinancialProfileDto(
          id: 'fp-1',
          employmentStatus: 'SELF_EMPLOYED',
          maritalStatus: 'REGISTERED_PARTNERSHIP',
          numberOfChildren: 0,
          grossAnnualIncome: 9500000,
        ),
        loadedAt: fixedNow,
      );
  });

  Future<ScenarioPrefill> load() {
    final container = ProviderContainer(
      overrides: [
        financialProfileRepositoryProvider.overrideWithValue(profileRepo),
        scenarioClockProvider.overrideWithValue(() => fixedNow),
      ],
    );
    addTearDown(container.dispose);
    return container.read(scenarioPrefillProvider.future);
  }

  test('age from birth year, profile and account totals',
      () async {
    profileRepo.pillar2 = const [
      Pillar2AccountDto(
        id: 'p2-1',
        currentCapital: 2000000,
        annualBvgContribution: 500000,
        isVestedBenefits: false,
      ),
      Pillar2AccountDto(
        id: 'p2-2',
        currentCapital: 300000,
        isVestedBenefits: true,
      ),
    ];
    profileRepo.pillar3a = const [
      Pillar3aAccountDto(
        id: 'p3-1',
        providerName: 'VIAC',
        accountType: 'BANK',
        currentBalance: 1000000,
      ),
      Pillar3aAccountDto(
        id: 'p3-2',
        providerName: 'Frankly',
        accountType: 'BANK',
        currentBalance: 500000,
      ),
    ];

    final prefill = await load();

    expect(prefill.age, 35);
    expect(prefill.canton, 'VD');
    expect(prefill.employmentStatus, 'SELF_EMPLOYED');
    expect(prefill.maritalStatus, 'REGISTERED_PARTNERSHIP');
    expect(prefill.grossAnnualIncome, 9500000);
    expect(prefill.pillar2Capital, 2300000);
    expect(prefill.pillar2Contribution, 500000); // null → 0 on the 2nd account
    expect(prefill.pillar3aBalance, 1500000);
    expect(prefill.pillar3aAccountCount, 2);
  });

  test('no profile (404) or birth year: null fields, totals 0',
      () async {
    profileRepo.baseData = ProfileBaseData(
      userId: 'u-1',
      email: 'user@example.ch',
      replacementRateGoal: 70,
      loadedAt: fixedNow,
    );

    final prefill = await load();

    expect(prefill.age, isNull);
    expect(prefill.canton, isNull);
    expect(prefill.employmentStatus, isNull);
    expect(prefill.maritalStatus, isNull);
    expect(prefill.grossAnnualIncome, isNull);
    expect(prefill.pillar2Capital, 0);
    expect(prefill.pillar3aAccountCount, 0);
  });

  test('age clamped to the scenario bounds (25–64)', () async {
    final base = profileRepo.baseData!;
    profileRepo.baseData = ProfileBaseData(
      userId: base.userId,
      email: base.email,
      birthYear: 2010, // 16 years old in 2026 → clamped to 25
      replacementRateGoal: 70,
      loadedAt: fixedNow,
    );

    final prefill = await load();
    expect(prefill.age, 25);
  });
}
