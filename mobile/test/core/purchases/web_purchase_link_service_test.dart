import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/purchases/purchases_service.dart';
import 'package:pocketpillar/core/purchases/web_purchase_link_service.dart';

void main() {
  const link = 'https://pay.revenuecat.com/wpl_abcd1234/';

  group('isAvailable', () {
    test('false without a configured link', () {
      expect(WebPurchaseLinkService(linkUrl: '').isAvailable, isFalse);
    });

    test('true with a configured link', () {
      expect(WebPurchaseLinkService(linkUrl: link).isAvailable, isTrue);
    });
  });

  group('purchaseAnnual', () {
    test('unavailable without a prior logIn (unknown app_user_id)', () async {
      final service = WebPurchaseLinkService(linkUrl: link);

      expect(await service.purchaseAnnual(), PurchaseOutcome.unavailable);
    });

    test('opens the checkout with app_user_id then stays silent', () async {
      Uri? opened;
      final service = WebPurchaseLinkService(
        linkUrl: link,
        opener: (uri) async {
          opened = uri;
          return true;
        },
      );
      await service.logIn('user-uuid-1');

      final outcome = await service.purchaseAnnual();

      expect(outcome, PurchaseOutcome.cancelled);
      expect(opened?.toString(), startsWith(link));
      expect(opened?.queryParameters['app_user_id'], 'user-uuid-1');
    });

    test('failed if opening the checkout fails', () async {
      final service = WebPurchaseLinkService(
        linkUrl: link,
        opener: (_) async => throw StateError('popup bloquée'),
      );
      await service.logIn('user-uuid-1');

      expect(await service.purchaseAnnual(), PurchaseOutcome.failed);
    });

    test('failed if the opener returns false (unable to open)', () async {
      final service = WebPurchaseLinkService(
        linkUrl: link,
        opener: (_) async => false,
      );
      await service.logIn('user-uuid-1');

      expect(await service.purchaseAnnual(), PurchaseOutcome.failed);
    });

    test('failed if the link is malformed (FormatException)', () async {
      final service = WebPurchaseLinkService(
        linkUrl: 'https://exemple.ch:abc/',
        opener: (_) async => true,
      );
      await service.logIn('user-uuid-1');

      expect(await service.purchaseAnnual(), PurchaseOutcome.failed);
    });
  });

  test(
    'fetchAnnualOffering: null without a link, known label with a link',
    () async {
      expect(
        await WebPurchaseLinkService(linkUrl: '').fetchAnnualOffering(),
        isNull,
      );
      final offering = await WebPurchaseLinkService(
        linkUrl: link,
      ).fetchAnnualOffering();
      expect(offering?.priceLabel, 'CHF 39.00');
    },
  );

  test(
    'restore: unavailable on web (users/me is the source of truth)',
    () async {
      expect(
        await WebPurchaseLinkService(linkUrl: link).restore(),
        RestoreOutcome.unavailable,
      );
    },
  );

  test('logOut clears the user', () async {
    final service = WebPurchaseLinkService(linkUrl: link);
    await service.logIn('user-uuid-1');
    await service.logOut();

    expect(await service.purchaseAnnual(), PurchaseOutcome.unavailable);
  });
}
