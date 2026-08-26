import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/api/api_exceptions.dart';
import 'package:pocketpillar/features/financial_profile/application/pillar3a_reminder_context.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart';

import '../../helpers/fakes.dart';

void main() {
  late SignedInFakeAuthRepository signedIn;
  late FakeFinancialProfileRepository profiles;

  const employedProfile = FinancialProfileDto(
    id: 'p-1',
    employmentStatus: 'EMPLOYED',
    maritalStatus: 'SINGLE',
    numberOfChildren: 0,
    grossAnnualIncome: 9500000,
  );

  const account = Pillar3aAccountDto(
    id: 'a-1',
    providerName: 'VIAC',
    accountType: 'BANK',
    currentBalance: 1500000,
    annualContribution: 425800, // CHF 4'258 paid
  );

  setUp(() {
    signedIn = SignedInFakeAuthRepository();
    profiles = FakeFinancialProfileRepository()
      ..profile = employedProfile
      ..pillar3aAccounts = [account];
  });

  test('not signed in → null, no network call', () async {
    final context = await loadPillar3aReminderContext(
      auth: FakeAuthRepository(), // no session
      profiles: profiles,
    );
    expect(context, isNull);
    expect(profiles.fetchPillar3aCalls, 0);
    expect(profiles.fetchProfileCalls, 0);
  });

  test('signed in: real remaining amount + days before 31/12', () async {
    final context = await loadPillar3aReminderContext(
      auth: signedIn,
      profiles: profiles,
      now: () => DateTime(2026, 11, 1),
    );
    // 7'258 − 4'258 = CHF 3'000 (300'000 ct), 60 days before 31/12.
    expect(context, isNotNull);
    expect(context!.remainingCentimes, 300000);
    expect(context.daysUntilYearEnd, 60);
  });

  test('days counted from issuance (Nov 1), not '
      'planning: opened in September → 60 (batch 7 review)', () async {
    final context = await loadPillar3aReminderContext(
      auth: signedIn,
      profiles: profiles,
      now: () => DateTime(2026, 9, 10),
    );
    expect(context, isNotNull);
    expect(context!.daysUntilYearEnd, 60);
  });

  test('SELF_EMPLOYED: cap = 20% of gross income (net not declared)', () async {
    profiles.profile = const FinancialProfileDto(
      id: 'p-1',
      employmentStatus: 'SELF_EMPLOYED',
      maritalStatus: 'SINGLE',
      numberOfChildren: 0,
      grossAnnualIncome: 9500000,
    );
    final context = await loadPillar3aReminderContext(
      auth: signedIn,
      profiles: profiles,
      now: () => DateTime(2026, 11, 1),
    );
    // 20% of CHF 95'000 = CHF 19'000 → 1'900'000 − 425'800 ct = CHF 14'742.
    expect(context!.remainingCentimes, 1474200);
  });

  test('SELF_EMPLOYED with LPP account (voluntary): small cap 7\'258 '
      '(OPP3 art. 7, batch 12 review)', () async {
    profiles
      ..profile = const FinancialProfileDto(
        id: 'p-1',
        employmentStatus: 'SELF_EMPLOYED',
        maritalStatus: 'SINGLE',
        numberOfChildren: 0,
        grossAnnualIncome: 30000000,
      )
      ..pillar2Accounts = [
        const Pillar2AccountDto(
          id: 'l-1',
          currentCapital: 5000000,
          isVestedBenefits: false,
        ),
      ];
    final context = await loadPillar3aReminderContext(
      auth: signedIn,
      profiles: profiles,
      now: () => DateTime(2026, 11, 1),
    );
    // Affiliated with a pension fund → 7'258, the 20% rule does not apply:
    // 725'800 − 425'800 ct = CHF 3'000.
    expect(context!.remainingCentimes, 300000);
  });

  test('SELF_EMPLOYED: declared net income is the base for the 20%', () async {
    profiles.profile = const FinancialProfileDto(
      id: 'p-1',
      employmentStatus: 'SELF_EMPLOYED',
      maritalStatus: 'SINGLE',
      numberOfChildren: 0,
      grossAnnualIncome: 9500000,
      netAnnualIncome: 8000000,
    );
    final context = await loadPillar3aReminderContext(
      auth: signedIn,
      profiles: profiles,
      now: () => DateTime(2026, 11, 1),
    );
    // 20% of CHF 80'000 (net) = CHF 16'000 → 1'600'000 − 425'800 ct =
    // CHF 11'742.
    expect(context!.remainingCentimes, 1174200);
  });

  test('profile missing (404) → null (generic fallback)', () async {
    profiles.profile = null;
    final context = await loadPillar3aReminderContext(
      auth: signedIn,
      profiles: profiles,
    );
    expect(context, isNull);
  });

  test('no 3a account → null (generic fallback)', () async {
    profiles.pillar3aAccounts = [];
    final context = await loadPillar3aReminderContext(
      auth: signedIn,
      profiles: profiles,
    );
    expect(context, isNull);
  });

  test('network error → null (graceful fallback, never throws)', () async {
    profiles.error = const NetworkException();
    final context = await loadPillar3aReminderContext(
      auth: signedIn,
      profiles: profiles,
    );
    expect(context, isNull);
  });
}
