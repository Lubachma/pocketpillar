import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/purchases/premium_status.dart';
import 'package:pocketpillar/features/financial_profile/application/financial_profile_providers.dart';
import 'package:pocketpillar/features/premium/application/premium_providers.dart';

import '../../helpers/fakes.dart';

/// Merges the premium status (contract §11): `users/me` (source of
/// truth) + optimistic unlock post-purchase while waiting for the
/// RevenueCat webhook to update the backend.
void main() {
  ProviderContainer buildContainer({PremiumStatus? backend}) {
    final container = ProviderContainer(
      overrides: [
        profileAggregateProvider.overrideWith(
          () => FakeProfileAggregateNotifier(
            buildFakeProfileAggregate(premium: backend ?? PremiumStatus.none),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('active backend → active premium, backend expiry date kept', () async {
    final expiresAt = DateTime.utc(2027, 8, 10);
    final container = buildContainer(
      backend: PremiumStatus(active: true, expiresAt: expiresAt),
    );
    await container.read(profileAggregateProvider.future);

    expect(container.read(premiumActiveProvider), isTrue);
    expect(container.read(premiumStatusProvider).expiresAt, expiresAt);
  });

  test('inactive backend, no purchase → not premium', () async {
    final container = buildContainer();
    await container.read(profileAggregateProvider.future);

    expect(container.read(premiumActiveProvider), isFalse);
    expect(container.read(premiumStatusProvider).expiresAt, isNull);
  });

  test('optimistic unlock: successful purchase but backend not yet '
      'updated → premium active (no expiry date)', () async {
    final container = buildContainer(); // users/me: not subscribed
    await container.read(profileAggregateProvider.future);
    container.read(optimisticPremiumProvider.notifier).state = true;

    expect(container.read(premiumActiveProvider), isTrue);
    expect(container.read(premiumStatusProvider).expiresAt, isNull);
  });

  test(
    'active backend takes precedence over the optimistic flag (real expiry date)',
    () async {
      final expiresAt = DateTime.utc(2027, 1, 1);
      final container = buildContainer(
        backend: PremiumStatus(active: true, expiresAt: expiresAt),
      );
      await container.read(profileAggregateProvider.future);
      container.read(optimisticPremiumProvider.notifier).state = true;

      expect(container.read(premiumStatusProvider).expiresAt, expiresAt);
    },
  );

  test('aggregate not yet loaded → not premium (locks shown), '
      'except with optimistic unlock', () {
    final container = buildContainer();
    // No await: the aggregate is still loading.
    expect(container.read(premiumActiveProvider), isFalse);

    container.read(optimisticPremiumProvider.notifier).state = true;
    expect(container.read(premiumActiveProvider), isTrue);
  });

  test('optimistic flag reverting to false (logout) → not premium', () async {
    final container = buildContainer();
    await container.read(profileAggregateProvider.future);
    container.read(optimisticPremiumProvider.notifier).state = true;
    expect(container.read(premiumActiveProvider), isTrue);

    container.read(optimisticPremiumProvider.notifier).state = false;
    expect(container.read(premiumActiveProvider), isFalse);
  });
}
