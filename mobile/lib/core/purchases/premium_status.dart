/// Account premium status — `premium` block from `GET /users/me`
/// (contract §6/§11): `{ active: boolean, expiresAt: string|null }`.
///
/// The **source of truth** is the backend (`subscriptions` table, fed
/// by the RevenueCat webhook); this model only carries the response.
/// The optimistic unlock after a purchase is handled separately
/// (`optimisticPremiumProvider`).
class PremiumStatus {
  const PremiumStatus({required this.active, this.expiresAt});

  /// No subscription (default: existing accounts, block absent).
  static const PremiumStatus none = PremiumStatus(active: false);

  /// Active entitlement (`expiresAt > now` on the backend side).
  final bool active;

  /// Subscription expiry (ISO 8601 UTC), null if never subscribed.
  final DateTime? expiresAt;

  /// `premium` block from `users/me` — tolerant: missing or malformed
  /// block → [none] (never an exception, a backend predating the
  /// launch sprint doesn't return this field).
  factory PremiumStatus.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return none;
    final expiresAtRaw = json['expiresAt'];
    return PremiumStatus(
      // `== true` rather than a cast: an unexpected type counts as "inactive".
      active: json['active'] == true,
      expiresAt: expiresAtRaw is String
          ? DateTime.tryParse(expiresAtRaw)
          : null,
    );
  }
}
