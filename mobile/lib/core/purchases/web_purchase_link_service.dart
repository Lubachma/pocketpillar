import 'package:url_launcher/url_launcher.dart';

import '../utils/debug_log.dart';
import 'purchases_config.dart';
import 'purchases_service.dart';

/// **Web** purchases via a RevenueCat Web Purchase Link (hosted
/// checkout).
///
/// `purchaseAnnual` opens the checkout in the same tab with
/// `app_user_id` (= backend `users.id`, passed via `logIn`, same
/// convention as the native SDK). The purchase completes outside the
/// app: RevenueCat redirects back to the app, the page reloads and
/// `GET /users/me` — fed by the existing backend webhook — reflects
/// premium. No optimistic unlock or restore on web.
class WebPurchaseLinkService implements PurchasesService {
  WebPurchaseLinkService({
    String? linkUrl,
    Future<bool> Function(Uri uri)? opener,
  }) : _linkUrl = linkUrl ?? PurchasesConfig.webPurchaseLinkUrl,
       _opener = opener ?? _defaultOpener;

  final String _linkUrl;
  final Future<bool> Function(Uri uri) _opener;
  String? _userId;

  static Future<bool> _defaultOpener(Uri uri) =>
      launchUrl(uri, webOnlyWindowName: '_self');

  @override
  bool get isAvailable => _linkUrl.isNotEmpty;

  @override
  Future<void> logIn(String backendUserId) async {
    _userId = backendUserId;
  }

  @override
  Future<void> logOut() async {
    _userId = null;
  }

  @override
  Future<PremiumOffering?> fetchAnnualOffering() async {
    if (!isAvailable) return null;
    // The exact price is shown by the hosted checkout; here it's the
    // known label for the single product (contract §11).
    return const PremiumOffering(priceLabel: 'CHF 39.00');
  }

  @override
  Future<PurchaseOutcome> purchaseAnnual() async {
    final userId = _userId;
    if (!isAvailable || userId == null) return PurchaseOutcome.unavailable;
    try {
      final base = Uri.parse(_linkUrl);
      final uri = base.replace(
        queryParameters: {...base.queryParameters, 'app_user_id': userId},
      );
      // A `launchUrl` resolving to false = opening silently
      // impossible (webview unavailable...) → visible failure, not a
      // misleading "cancelled".
      final opened = await _opener(uri);
      if (!opened) return PurchaseOutcome.failed;
    } on Object catch (e) {
      debugLog('Opening the web checkout failed: $e');
      return PurchaseOutcome.failed;
    }
    // Silent: the purchase outcome arrives via the webhook then the
    // page reload — nothing to report in the current tab.
    return PurchaseOutcome.cancelled;
  }

  /// No restore on web: the status comes from `users/me` right after
  /// sign-in — the "Restore" button is hidden on web (paywall).
  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.unavailable;
}
