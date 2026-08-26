import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/core/l10n/gen/app_localizations.dart';
import 'package:pocketpillar/core/purchases/premium_status.dart';
import 'package:pocketpillar/core/purchases/purchases_service.dart';
import 'package:pocketpillar/core/purchases/purchases_service_provider.dart';
import 'package:pocketpillar/features/financial_profile/application/financial_profile_providers.dart';
import 'package:pocketpillar/features/premium/application/premium_providers.dart';
import 'package:pocketpillar/features/premium/presentation/paywall_screen.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakePurchasesService purchases;

  setUp(() {
    purchases = FakePurchasesService();
  });

  Future<ProviderContainer> pumpPaywall(
    WidgetTester tester, {
    PremiumStatus backend = PremiumStatus.none,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          purchasesServiceProvider.overrideWithValue(purchases),
          profileAggregateProvider.overrideWith(
            () => FakeProfileAggregateNotifier(
              buildFakeProfileAggregate(premium: backend),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PaywallScreen(),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PaywallScreen)),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('offer available: store price, 6 benefits, purchase '
      'and restore buttons, legal notice', (tester) async {
    await pumpPaywall(tester);

    expect(find.text('PocketPillar Premium'), findsOneWidget);
    // Localized store price (RevenueCat offering), not the fallback.
    expect(find.text('CHF 39.00 par an'), findsOneWidget);
    expect(find.text('CHF 39/an'), findsNothing);
    // Copy option B.
    expect(find.text('Inclus dans Premium'), findsOneWidget);
    expect(
      find.text('Rattrapage 3a : détail année par année et plan d\'action'),
      findsOneWidget,
    );
    expect(
      find.text(
        '4 scénarios avancés : couple, retrait échelonné, '
        'achat immobilier, divorce',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Scan de documents (OCR) pour préremplir votre profil'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Recommandations complètes et meilleur prestataire pour votre profil',
      ),
      findsOneWidget,
    );
    expect(find.text('Export PDF de votre bilan'), findsOneWidget);
    expect(find.text('Documents illimités'), findsOneWidget);
    // Actions and legal notice (auto-renewing subscription, store management).
    expect(find.text('Débloquer Premium'), findsOneWidget);
    expect(find.text('Restaurer mes achats'), findsOneWidget);
    expect(
      find.textContaining('Abonnement annuel renouvelé automatiquement'),
      findsOneWidget,
    );
  });

  testWidgets('missing SDK keys: « achat indisponible » state, fallback '
      'price, no purchase button — never crashes', (tester) async {
    purchases.available = false;
    await pumpPaywall(tester);

    expect(find.text('Achat indisponible'), findsOneWidget);
    expect(find.text('CHF 39/an'), findsOneWidget); // fallback
    expect(find.text('Débloquer Premium'), findsNothing);
    expect(find.text('Restaurer mes achats'), findsNothing);
    expect(purchases.offeringCalls, 0); // SDK never called
  });

  testWidgets('no offering published (store products not yet created): '
      'unavailable state but restore still possible', (tester) async {
    purchases.offering = null;
    await pumpPaywall(tester);

    expect(find.text('Achat indisponible'), findsOneWidget);
    expect(find.text('Débloquer Premium'), findsNothing);
    expect(find.text('Restaurer mes achats'), findsOneWidget);
  });

  testWidgets('purchase: in-progress state then success → optimistic '
      'unlock, users/me aggregate invalidated, snackbar', (tester) async {
    purchases.purchaseGate = Completer<void>();
    final container = await pumpPaywall(tester);

    await tester.tap(find.text('Débloquer Premium'));
    await tester.pump();

    // Purchase in progress: spinner in the button, label hidden.
    expect(find.text('Débloquer Premium'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(container.read(optimisticPremiumProvider), isFalse);

    purchases.purchaseGate!.complete();
    await tester.pumpAndSettle();

    expect(container.read(optimisticPremiumProvider), isTrue);
    expect(container.read(premiumActiveProvider), isTrue);
    expect(find.text('Premium activé — merci !'), findsOneWidget);
    expect(purchases.purchaseCalls, 1);
  });

  testWidgets('cancelled purchase (store sheet dismissed): silent, '
      'no unlock', (tester) async {
    purchases.purchaseOutcome = PurchaseOutcome.cancelled;
    final container = await pumpPaywall(tester);

    await tester.tap(find.text('Débloquer Premium'));
    await tester.pumpAndSettle();

    expect(container.read(optimisticPremiumProvider), isFalse);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Débloquer Premium'), findsOneWidget);
  });

  testWidgets('failed purchase: localized snackbar, no unlock', (tester) async {
    purchases.purchaseOutcome = PurchaseOutcome.failed;
    final container = await pumpPaywall(tester);

    await tester.tap(find.text('Débloquer Premium'));
    await tester.pumpAndSettle();

    expect(
      find.text('L\'achat n\'a pas abouti. Réessayez plus tard.'),
      findsOneWidget,
    );
    expect(container.read(optimisticPremiumProvider), isFalse);
  });

  testWidgets('restore without subscription: dedicated snackbar, no '
      'unlock', (tester) async {
    purchases.restoreOutcome = RestoreOutcome.nothingToRestore;
    final container = await pumpPaywall(tester);

    await tester.tap(find.text('Restaurer mes achats'));
    await tester.pumpAndSettle();

    expect(
      find.text('Aucun abonnement à restaurer pour ce compte.'),
      findsOneWidget,
    );
    expect(container.read(optimisticPremiumProvider), isFalse);
  });

  testWidgets('successful restore: optimistic unlock + snackbar', (
    tester,
  ) async {
    final container = await pumpPaywall(tester);

    await tester.tap(find.text('Restaurer mes achats'));
    await tester.pumpAndSettle();

    expect(find.text('Abonnement restauré !'), findsOneWidget);
    expect(container.read(premiumActiveProvider), isTrue);
  });

  testWidgets('offering error (store network): error card, retry '
      'reloads the offering', (tester) async {
    purchases.offeringError = Exception('store injoignable');
    await pumpPaywall(tester);

    expect(
      find.text(
        'Impossible de charger l\'offre. Vérifiez votre connexion puis '
        'réessayez.',
      ),
      findsOneWidget,
    );
    expect(find.text('Débloquer Premium'), findsNothing);

    purchases.offeringError = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('CHF 39.00 par an'), findsOneWidget);
    expect(find.text('Débloquer Premium'), findsOneWidget);
    expect(purchases.offeringCalls, 2);
  });

  testWidgets('subscription already active (users/me): "active" state, '
      'no purchase button', (tester) async {
    await pumpPaywall(
      tester,
      backend: PremiumStatus(
        active: true,
        expiresAt: DateTime.utc(2027, 8, 10),
      ),
    );

    expect(find.text('Votre abonnement Premium est actif.'), findsOneWidget);
    expect(find.text('Débloquer Premium'), findsNothing);
  });
}
