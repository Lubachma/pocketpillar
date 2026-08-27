/// The app's paths.
///
/// Public routes (without a session): `/onboarding`, `/login`, `/register`.
/// Everything else is protected by the router's redirect.
abstract final class Routes {
  /// Neutral screen shown while rereading the persisted session
  /// (neither public nor protected: transient, never a destination).
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';

  /// Dashboard sub-route (pushed from the checklist card).
  static const String checklist = '/dashboard/checklist';
  static const String calculator = '/calculator';
  static const String scenarios = '/scenarios';

  /// Scenario sub-routes (phases 3.5-3.6) — pushed from the hub.
  static const String scenarioCouple = '/scenarios/couple';
  static const String scenarioCatchup3a = '/scenarios/catchup-3a';
  static const String scenarioStaggeredWithdrawal =
      '/scenarios/staggered-withdrawal';
  static const String scenarioPropertyPurchase = '/scenarios/property-purchase';
  static const String scenarioDivorceImpact = '/scenarios/divorce-impact';

  static const String providers = '/providers';

  /// Provider sub-routes (phase 3.7) — the detail screen uses
  /// `/providers/<slug>` (path parameter).
  static const String providerBestMatch = '/providers/best-match';
  static const String providerCompare = '/providers/compare';
  static const String documents = '/documents';
  static const String settings = '/settings';

  /// Settings sub-route: financial profile (phase 3.3).
  static const String settingsProfile = '/settings/profile';

  /// Settings sub-route: privacy policy (3.10).
  static const String settingsPrivacy = '/settings/privacy';

  /// PocketPillar Premium paywall (launch sprint) — full-screen route
  /// outside the tab shell, pushed from the gates (locks, 402,
  /// settings).
  static const String paywall = '/paywall';

  /// "Understand your pension" — the 3 pillars and the calculation
  /// method in plain words (practitioner review 08.2026). Full-screen
  /// route outside the tab shell, pushed from settings and from the
  /// calculator results footer.
  static const String understand = '/understand';

  /// Routes reachable without a Supabase session.
  static const Set<String> public = {onboarding, login, register};
}
