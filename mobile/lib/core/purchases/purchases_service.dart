import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../utils/debug_log.dart';
import 'purchases_config.dart';

/// RevenueCat entitlement identifier for the "option B" paywall
/// (contract §11).
const String premiumEntitlementId = 'premium';

/// Annual offering displayable on the paywall — only the store-localized
/// price label is exposed (e.g. "CHF 39.00"); RevenueCat types never
/// leave this service.
class PremiumOffering {
  const PremiumOffering({required this.priceLabel});

  final String priceLabel;
}

/// Outcome of a purchase attempt.
enum PurchaseOutcome {
  /// Purchase succeeded **and** the `premium` entitlement is active in
  /// the returned `CustomerInfo` → optimistic unlock on the client side.
  success,

  /// The user dismissed the store's purchase sheet — silent.
  cancelled,

  /// Failure (store error, payment declined...) — generic snackbar.
  failed,

  /// SDK not configured or no annual offering published.
  unavailable,
}

/// Outcome of a purchase restoration.
enum RestoreOutcome {
  /// A subscription with the `premium` entitlement active was found.
  restored,

  /// Restoration succeeded but no active subscription on this account.
  nothingToRestore,

  /// Store/network error.
  failed,

  /// SDK not configured (missing keys).
  unavailable,
}

/// Facade for in-app purchases (RevenueCat) — substitutable in tests.
///
/// Usage contract (contract §11):
/// - `logIn(<users.id>)` once the **backend** user is known (the local
///   uuid is the RevenueCat `app_user_id` — never the Supabase id);
/// - `logOut()` on sign-out;
/// - the displayed status comes from `GET /users/me`, the SDK only
///   serves the purchase/restore flow and the optimistic unlock.
abstract class PurchasesService {
  /// An SDK key exists for this platform — otherwise the app runs in
  /// "purchases unavailable" mode (informational paywall, no crash).
  bool get isAvailable;

  Future<void> logIn(String backendUserId);

  Future<void> logOut();

  /// Current annual offering, or null if unavailable (SDK not
  /// configured, no offering published). Store network errors are
  /// propagated: the screen shows an error state with retry.
  Future<PremiumOffering?> fetchAnnualOffering();

  /// Purchases the annual package of the current offering.
  Future<PurchaseOutcome> purchaseAnnual();

  /// Restores purchases for the current store account.
  Future<RestoreOutcome> restore();
}

/// RevenueCat implementation (plugin `purchases_flutter`).
///
/// The SDK is configured **lazily** on first use (logIn, offering,
/// purchase): without a key, no native channel call is ever emitted —
/// the app starts and runs fully without RevenueCat.
class RevenueCatPurchasesService implements PurchasesService {
  bool _configured = false;
  String? _loggedInUserId;

  @override
  bool get isAvailable => PurchasesConfig.isConfigured;

  /// Configures the SDK once; false if unavailable or on failure
  /// (never an exception — decision: purchases are an enhancement,
  /// never a blocker for the app).
  Future<bool> _ensureConfigured() async {
    if (!isAvailable) return false;
    if (_configured) return true;
    try {
      await Purchases.configure(
        PurchasesConfiguration(PurchasesConfig.apiKeyOrNull!),
      );
      _configured = true;
    } on Object catch (e) {
      debugLog('RevenueCat configuration failed: $e');
    }
    return _configured;
  }

  @override
  Future<void> logIn(String backendUserId) async {
    // Idempotent: the profile aggregate is reloaded on every invalidation
    // (profile save, purchase...) — do not replay logIn.
    if (_loggedInUserId == backendUserId) return;
    if (!await _ensureConfigured()) return;
    try {
      await Purchases.logIn(backendUserId);
      _loggedInUserId = backendUserId;
    } on Object catch (e) {
      // Best-effort: the next pass (new aggregate) will retry.
      debugLog('Purchases.logIn failed: $e');
    }
  }

  @override
  Future<void> logOut() async {
    _loggedInUserId = null;
    // Never configured → nothing to sign out (no native call).
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } on Object catch (e) {
      // `logOut` throws if the user is already anonymous — harmless.
      debugLog('Purchases.logOut ignored: $e');
    }
  }

  @override
  Future<PremiumOffering?> fetchAnnualOffering() async {
    if (!await _ensureConfigured()) return null;
    final package = _annualPackage(await Purchases.getOfferings());
    if (package == null) return null;
    return PremiumOffering(priceLabel: package.storeProduct.priceString);
  }

  @override
  Future<PurchaseOutcome> purchaseAnnual() async {
    if (!await _ensureConfigured()) return PurchaseOutcome.unavailable;
    try {
      final package = _annualPackage(await Purchases.getOfferings());
      if (package == null) return PurchaseOutcome.unavailable;
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final active = result.customerInfo.entitlements.active.containsKey(
        premiumEntitlementId,
      );
      // Transaction succeeded without an active entitlement: incomplete
      // RevenueCat mapping — no optimistic unlock, the backend webhook
      // will settle it (users/me remains the source of truth).
      return active ? PurchaseOutcome.success : PurchaseOutcome.failed;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      debugLog('Premium purchase failed: $e');
      return PurchaseOutcome.failed;
    } on Object catch (e) {
      debugLog('Premium purchase failed: $e');
      return PurchaseOutcome.failed;
    }
  }

  @override
  Future<RestoreOutcome> restore() async {
    if (!await _ensureConfigured()) return RestoreOutcome.unavailable;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(premiumEntitlementId)
          ? RestoreOutcome.restored
          : RestoreOutcome.nothingToRestore;
    } on Object catch (e) {
      debugLog('Purchase restore failed: $e');
      return RestoreOutcome.failed;
    }
  }

  /// Annual package of the current offering (fallback: first available
  /// package, if the offering doesn't use the standard identifier).
  Package? _annualPackage(Offerings offerings) {
    final current = offerings.current;
    if (current == null) return null;
    final packages = current.availablePackages;
    return current.annual ?? (packages.isNotEmpty ? packages.first : null);
  }
}
