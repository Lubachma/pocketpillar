import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/calculator/application/guided_calculator_controller.dart';
import 'package:pocketpillar/features/financial_profile/application/financial_profile_providers.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_dtos.dart';
import 'package:pocketpillar/features/financial_profile/data/financial_profile_repository.dart';

import '../../helpers/fakes.dart';

void main() {
  late CountingFakeFinancialProfileRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = CountingFakeFinancialProfileRepository();
    container = ProviderContainer(
      overrides: [
        financialProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('multiple reads → a single load of the 4 endpoints', () async {
    final first = await container.read(profileAggregateProvider.future);
    final second = await container.read(profileAggregateProvider.future);

    expect(identical(first, second), isTrue);
    expect(repository.loadBaseCalls, 1);
    expect(repository.fetchPillar2Calls, 1);
    expect(repository.fetchPillar3aCalls, 1);
  });

  test('derived views (base, accounts) share the same load', () async {
    final base = await container.read(profileBaseProvider.future);
    final pillar2 = await container.read(pillar2AccountsProvider.future);
    final pillar3a = await container.read(pillar3aAccountsProvider.future);

    expect(base.canton, 'VD');
    expect(pillar2.single.id, 'p2-1');
    expect(pillar3a, isEmpty);
    expect(repository.loadBaseCalls, 1);
    expect(repository.fetchPillar2Calls, 1);
    expect(repository.fetchPillar3aCalls, 1);
  });

  test(
    'calculator opened after the dashboard: prefilled without refetch',
    () async {
      // The dashboard (or any other consumer) has already loaded the aggregate.
      await container.read(profileAggregateProvider.future);
      expect(repository.loadBaseCalls, 1);

      // Opening the guided flow: prefill consumes the aggregate.
      final sub = container.listen(
        guidedCalculatorControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      while (container
          .read(guidedCalculatorControllerProvider)
          .prefillLoading) {
        await Future<void>.delayed(Duration.zero);
      }

      final state = container.read(guidedCalculatorControllerProvider);
      expect(state.prefillError, isNull);
      expect(state.canton, 'VD'); // prefilled from the aggregate
      // No new network call.
      expect(repository.loadBaseCalls, 1);
      expect(repository.fetchPillar2Calls, 1);
      expect(repository.fetchPillar3aCalls, 1);
    },
  );

  test('invalidation (profile save, logout) → reload', () async {
    await container.read(profileAggregateProvider.future);

    container.invalidate(profileAggregateProvider);
    await container.read(profileAggregateProvider.future);

    expect(repository.loadBaseCalls, 2);
    expect(repository.fetchPillar2Calls, 2);
    expect(repository.fetchPillar3aCalls, 2);
  });

  test('refreshPillar2Accounts: only the LPP list is reloaded, '
      'the base stays identical', () async {
    final before = await container.read(profileAggregateProvider.future);

    repository.pillar2Accounts = const [
      Pillar2AccountDto(
        id: 'p2-2',
        currentCapital: 200000,
        isVestedBenefits: true,
      ),
    ];
    await container
        .read(profileAggregateProvider.notifier)
        .refreshPillar2Accounts();

    final after = container.read(profileAggregateProvider).valueOrNull!;
    expect(repository.loadBaseCalls, 1); // base not refetched…
    expect(identical(after.base, before.base), isTrue); // …and unchanged
    expect(repository.fetchPillar2Calls, 2); // only the list is refetched
    expect(repository.fetchPillar3aCalls, 1);
    expect(after.pillar2Accounts.single.id, 'p2-2');
  });
}
