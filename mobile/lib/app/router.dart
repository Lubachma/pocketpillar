import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_repository.dart';
import '../core/l10n/l10n.dart';
import '../core/storage/preferences.dart';
import '../features/auth/application/auth_service.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/calculator/presentation/calculator_screen.dart';
import '../features/checklist/presentation/checklist_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/documents/presentation/documents_screen.dart';
import '../features/financial_profile/presentation/financial_profile_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/premium/presentation/paywall_screen.dart';
import '../features/providers/data/provider_dtos.dart';
import '../features/providers/presentation/best_match_screen.dart';
import '../features/providers/presentation/compare_screen.dart';
import '../features/providers/presentation/provider_detail_screen.dart';
import '../features/providers/presentation/providers_screen.dart';
import '../features/couple/presentation/couple_screen.dart';
import '../features/scenarios/presentation/catchup_3a_screen.dart';
import '../features/scenarios/presentation/divorce_impact_screen.dart';
import '../features/scenarios/presentation/property_purchase_screen.dart';
import '../features/scenarios/presentation/scenarios_screen.dart';
import '../features/scenarios/presentation/staggered_withdrawal_screen.dart';
import '../features/education/presentation/understand_screen.dart';
import '../features/settings/presentation/privacy_policy_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'routes.dart';
import 'splash_screen.dart';

/// The app's router.
///
/// - Without a session: `/onboarding` on first launch, then `/login`
///   (public routes: onboarding, login, register).
/// - With a session: any public route redirects to the dashboard.
/// - The tab shell mirrors the iOS app's 6 tabs.
final routerProvider = Provider<GoRouter>((ref) {
  // Recomputes redirects on every change of session, dev bypass,
  // onboarding flag, or in-progress registration.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authSessionProvider, (_, _) => refresh.value++);
  ref.listen(devAuthBypassProvider, (_, _) => refresh.value++);
  ref.listen(hasSeenOnboardingProvider, (_, _) => refresh.value++);
  ref.listen(registrationInProgressProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final location = state.matchedLocation;

      // Internal target remembered in `from` during the splash,
      // onboarding, or login (only accepts an internal path — an
      // external or protocol-relative `//host` `from` falls back to the
      // default on return).
      String? pendingFrom() {
        final from = state.uri.queryParameters['from'];
        return from != null && from.startsWith('/') && !from.startsWith('//')
            ? from
            : null;
      }

      // Persisted session not yet reread: neutral splash (avoids the
      // dashboard flashing for a signed-out user). The original target —
      // a possible deep link — is kept in `from` for the rest of the
      // redirect once the session is known.
      if (session.isLoading) {
        if (location == Routes.splash) return null;
        final from = state.uri.toString();
        return Uri(
          path: Routes.splash,
          queryParameters: {if (from != '/') 'from': from},
        ).toString();
      }
      // Registration in progress: the Supabase session is already
      // issued but POST /auth/register hasn't responded yet. Hold back
      // navigation, otherwise a 409 (email already linked) would never
      // be visible.
      if (ref.read(registrationInProgressProvider)) return null;
      final loggedIn =
          session.valueOrNull != null ||
          (kDebugMode && ref.read(devAuthBypassProvider));
      if (!loggedIn) {
        // First launch: pre-login onboarding before the login screen.
        // The original target is kept in `from` (retrieved on return
        // from the splash if applicable) to go back to it after signing in.
        if (!ref.read(hasSeenOnboardingProvider)) {
          if (location == Routes.onboarding) return null;
          final from = location == Routes.splash
              ? pendingFrom()
              : state.uri.toString();
          return Uri(
            path: Routes.onboarding,
            queryParameters: {if (from != null && from != '/') 'from': from},
          ).toString();
        }
        if (!Routes.public.contains(location)) {
          // Remembers the target to return to it after signing in.
          final from = location == Routes.splash
              ? pendingFrom()
              : state.uri.toString();
          return Uri(
            path: Routes.login,
            queryParameters: {if (from != null && from != '/') 'from': from},
          ).toString();
        }
        return null;
      }
      if (Routes.public.contains(location) || location == Routes.splash) {
        return pendingFrom() ?? Routes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      // Premium paywall: full screen, over the tab shell (protected by
      // the default redirect — not public).
      GoRoute(
        path: Routes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      // Pension pedagogy: full screen, over the tab shell (reachable
      // from settings and the calculator results — protected by the
      // default redirect).
      GoRoute(
        path: Routes.understand,
        builder: (context, state) => const UnderstandScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.dashboard,
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'checklist',
                    builder: (context, state) => const ChecklistScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.calculator,
                builder: (context, state) => const CalculatorScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.scenarios,
                builder: (context, state) => const ScenariosScreen(),
                routes: [
                  GoRoute(
                    path: 'couple',
                    builder: (context, state) => const CoupleScreen(),
                  ),
                  GoRoute(
                    path: 'catchup-3a',
                    builder: (context, state) => const Catchup3aScreen(),
                  ),
                  GoRoute(
                    path: 'staggered-withdrawal',
                    builder: (context, state) =>
                        const StaggeredWithdrawalScreen(),
                  ),
                  GoRoute(
                    path: 'property-purchase',
                    builder: (context, state) => const PropertyPurchaseScreen(),
                  ),
                  GoRoute(
                    path: 'divorce-impact',
                    builder: (context, state) => const DivorceImpactScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.providers,
                builder: (context, state) => const ProvidersScreen(),
                routes: [
                  // Static routes before ':slug' (match order).
                  GoRoute(
                    path: 'best-match',
                    builder: (context, state) => const BestMatchScreen(),
                  ),
                  GoRoute(
                    path: 'compare',
                    // The comparison is fed by the list selection (no
                    // endpoint by ids): without extra, back to the list.
                    redirect: (context, state) {
                      final products = state.extra;
                      return products is List<ScoredProductDto> &&
                              products.length >= 2
                          ? null
                          : Routes.providers;
                    },
                    builder: (context, state) => CompareScreen(
                      products: state.extra! as List<ScoredProductDto>,
                    ),
                  ),
                  GoRoute(
                    path: ':slug',
                    builder: (context, state) => ProviderDetailScreen(
                      slug: state.pathParameters['slug']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.documents,
                builder: (context, state) => const DocumentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const FinancialProfileScreen(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacyPolicyScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Tab shell (parity with the 6 iOS tabs).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calculate_outlined),
            selectedIcon: const Icon(Icons.calculate),
            label: l10n.tabCalculator,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.tabScenarios,
          ),
          NavigationDestination(
            icon: const Icon(Icons.business_outlined),
            selectedIcon: const Icon(Icons.business),
            label: l10n.tabProviders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: l10n.tabDocuments,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsTitle,
          ),
        ],
      ),
    );
  }
}
