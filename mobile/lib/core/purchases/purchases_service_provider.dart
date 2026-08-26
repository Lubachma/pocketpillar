import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'purchases_service.dart';
import 'web_purchase_link_service.dart';

/// The app's purchase service (scope singleton): RevenueCat Web
/// Purchase Link on web, native `purchases_flutter` SDK elsewhere.
/// Tests replace it with a fake — the native plugin is never touched
/// outside a device.
final purchasesServiceProvider = Provider<PurchasesService>(
  (ref) => kIsWeb ? WebPurchaseLinkService() : RevenueCatPurchasesService(),
);
