import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/purchases/purchases_service.dart';
import '../../../core/purchases/purchases_service_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/primary_button.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../financial_profile/application/financial_profile_providers.dart';
import '../application/premium_providers.dart';

/// PocketPillar Premium paywall (option B, CHF 39/year — contract §11).
///
/// - Price: localized store label from the RevenueCat offering,
///   falling back to "CHF 39/year" while the offering isn't loaded.
/// - States: offering loading, error (retry), "purchases unavailable"
///   (missing SDK keys or no published offering — the app stays
///   fully usable in free mode), subscription already active.
/// - After a successful purchase/restore: optimistic unlock (the
///   RevenueCat → backend webhook can take a few moments) then a
///   `users/me` refresh (source of truth).
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _loadingOffering = false;
  Object? _offeringError;
  PremiumOffering? _offering;

  bool _purchasing = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  Future<void> _loadOffering() async {
    final service = ref.read(purchasesServiceProvider);
    if (!service.isAvailable) return;
    setState(() {
      _loadingOffering = true;
      _offeringError = null;
    });
    try {
      final offering = await service.fetchAnnualOffering();
      if (!mounted) return;
      setState(() {
        _loadingOffering = false;
        _offering = offering;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingOffering = false;
        _offeringError = e;
      });
    }
  }

  /// Optimistic unlock + refresh of `users/me` (and of the
  /// recommendations, now accessible) after an entitlement is obtained.
  void _activatePremium() {
    ref.read(optimisticPremiumProvider.notifier).state = true;
    ref
      ..invalidate(profileAggregateProvider)
      ..invalidate(recommendationsProvider);
  }

  Future<void> _purchase() async {
    if (_purchasing || _restoring) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    // `Navigator` (not go_router's `context.pop`): the paywall closes
    // whether pushed by the router or hosted directly (tests).
    final navigator = Navigator.of(context);
    setState(() => _purchasing = true);
    final outcome = await ref.read(purchasesServiceProvider).purchaseAnnual();
    if (!mounted) return;
    setState(() => _purchasing = false);
    switch (outcome) {
      case PurchaseOutcome.success:
        _activatePremium();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.paywallPurchaseSuccess)),
        );
        if (navigator.canPop()) navigator.pop();
      case PurchaseOutcome.cancelled:
        break; // Store sheet dismissed: silent.
      case PurchaseOutcome.failed:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.paywallPurchaseFailed)),
        );
      case PurchaseOutcome.unavailable:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.paywallUnavailableBody)),
        );
    }
  }

  Future<void> _restore() async {
    if (_purchasing || _restoring) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _restoring = true);
    final outcome = await ref.read(purchasesServiceProvider).restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    switch (outcome) {
      case RestoreOutcome.restored:
        _activatePremium();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.paywallRestoreSuccess)),
        );
        if (navigator.canPop()) navigator.pop();
      case RestoreOutcome.nothingToRestore:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.paywallRestoreNothing)),
        );
      case RestoreOutcome.failed:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.paywallRestoreFailed)),
        );
      case RestoreOutcome.unavailable:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.paywallUnavailableBody)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final service = ref.watch(purchasesServiceProvider);
    final premiumActive = ref.watch(premiumActiveProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paywallTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Icon(
            Icons.workspace_premium,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.paywallHeadline,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _offering != null
                ? l10n.paywallPricePerYear(_offering!.priceLabel)
                : l10n.paywallPriceFallback,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paywallFeaturesTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _FeatureRow(text: l10n.paywallFeatureCatchup),
                _FeatureRow(text: l10n.paywallFeatureScenarios),
                _FeatureRow(text: l10n.paywallFeatureOcr),
                _FeatureRow(text: l10n.paywallFeatureRecommendations),
                _FeatureRow(text: l10n.paywallFeaturePdf),
                _FeatureRow(text: l10n.paywallFeatureDocuments),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._buildActions(service, premiumActive),
          const SizedBox(height: 16),
          Text(
            l10n.paywallLegal,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Action area based on state: active subscription, purchases
  /// unavailable, offering loading/error, or purchase/restore
  /// buttons.
  List<Widget> _buildActions(PurchasesService service, bool premiumActive) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (premiumActive) {
      return [
        AppCard(
          child: Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.paywallAlreadyActive,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // Missing SDK keys (RevenueCat project not created yet) or no
    // published offering: informational state, never blocking or
    // crashing.
    if (!service.isAvailable ||
        (!_loadingOffering && _offeringError == null && _offering == null)) {
      return [
        AppCard(
          child: Column(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.paywallUnavailableTitle,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.paywallUnavailableBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Native restore only: on web, `users/me` is the source of truth.
        if (!kIsWeb && service.isAvailable)
          TextButton(
            onPressed: _restoring ? null : _restore,
            child: Text(l10n.paywallRestore),
          ),
      ];
    }

    if (_loadingOffering) {
      return [const Center(child: CircularProgressIndicator())];
    }

    if (_offeringError != null) {
      return [
        AppCard(
          child: Column(
            children: [
              Icon(Icons.cloud_off, size: 40, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                l10n.paywallOfferingError,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: l10n.commonRetry, onPressed: _loadOffering),
            ],
          ),
        ),
      ];
    }

    return [
      PrimaryButton(
        label: l10n.paywallSubscribe,
        icon: Icons.workspace_premium_outlined,
        isLoading: _purchasing,
        onPressed: _purchase,
      ),
      const SizedBox(height: 4),
      if (!kIsWeb)
        TextButton(
          onPressed: _purchasing || _restoring ? null : _restore,
          child: _restoring
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.paywallRestore),
        ),
    ];
  }
}

/// Row in the benefits list: checkmark + text.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: context.appColors.positive,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
