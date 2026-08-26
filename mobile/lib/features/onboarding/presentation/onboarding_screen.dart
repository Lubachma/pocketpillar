import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/primary_button.dart';

/// Pre-login onboarding: 4-page carousel (parity with the iOS
/// `OnboardingView` — 3 pillars, per-pillar detail, features,
/// privacy), then `/login`.
///
/// The `hasSeenOnboarding` flag is persisted (shared_preferences): the
/// screen is only shown on first launch.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _pageCount = 4;

  final _pageController = PageController();
  int _page = 0;

  bool get _isLastPage => _page == _pageCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onPrimary() async {
    if (_isLastPage) {
      await _complete();
    } else {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _complete() async {
    await ref.read(hasSeenOnboardingProvider.notifier).complete();
    if (!mounted) return;
    // Any deep link remembered by the router: passed to login to
    // return to it after authentication (internal paths only).
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    context.go(
      Uri(
        path: Routes.login,
        queryParameters: {
          if (from != null && from.startsWith('/')) 'from': from,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed slot: avoids a layout jump on the last page.
            SizedBox(
              height: 48,
              child: _isLastPage
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _complete,
                        child: Text(l10n.onboardingSkip),
                      ),
                    ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: const [
                  _PillarsIntroPage(),
                  _PillarDetailsPage(),
                  _FeaturesPage(),
                  _ReadyPage(),
                ],
              ),
            ),
            _DotsIndicator(count: _pageCount, index: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: PrimaryButton(
                label: _isLastPage ? l10n.onboardingStart : l10n.onboardingNext,
                onPressed: _onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Common template: content, title, description.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.content,
    required this.title,
    required this.description,
  });

  final Widget content;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          content,
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Page 1: the 3 pillars as educational bars (fixed heights).
class _PillarsIntroPage extends StatelessWidget {
  const _PillarsIntroPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return _OnboardingPage(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PillarBar(color: colors.pillar1, height: 72, label: 'AVS'),
          const SizedBox(width: 24),
          _PillarBar(color: colors.pillar2, height: 120, label: 'LPP'),
          const SizedBox(width: 24),
          _PillarBar(color: colors.pillar3a, height: 96, label: '3a'),
        ],
      ),
      title: l10n.onboardingPillarsTitle,
      description: l10n.onboardingPillarsDesc,
    );
  }
}

class _PillarBar extends StatelessWidget {
  const _PillarBar({
    required this.color,
    required this.height,
    required this.label,
  });

  final Color color;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Page 2: one card per pillar (icon, title, description).
class _PillarDetailsPage extends StatelessWidget {
  const _PillarDetailsPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return _OnboardingPage(
      content: Column(
        children: [
          _PillarCard(
            icon: Icons.groups_outlined,
            color: colors.pillar1,
            title: l10n.onboardingP1Title,
            description: l10n.onboardingP1Desc,
          ),
          const SizedBox(height: 12),
          _PillarCard(
            icon: Icons.domain_outlined,
            color: colors.pillar2,
            title: l10n.onboardingP2Title,
            description: l10n.onboardingP2Desc,
          ),
          const SizedBox(height: 12),
          _PillarCard(
            icon: Icons.savings_outlined,
            color: colors.pillar3a,
            title: l10n.onboardingP3aTitle,
            description: l10n.onboardingP3aDesc,
          ),
        ],
      ),
      title: l10n.onboardingDetailsTitle,
      description: l10n.onboardingDetailsDesc,
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 3: key features in a single card.
class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    return _OnboardingPage(
      content: AppCard(
        child: Column(
          children: [
            _FeatureRow(
              icon: Icons.speed,
              color: theme.colorScheme.primary,
              text: l10n.onboardingFeatureScore,
            ),
            _FeatureRow(
              icon: Icons.show_chart,
              color: colors.positive,
              text: l10n.onboardingFeatureSimulate,
            ),
            _FeatureRow(
              icon: Icons.compare_arrows,
              color: colors.pillar3a,
              text: l10n.onboardingFeatureCompare,
            ),
            _FeatureRow(
              icon: Icons.lightbulb_outline,
              color: colors.warning,
              text: l10n.onboardingFeatureTips,
            ),
          ],
        ),
      ),
      title: l10n.onboardingFeaturesTitle,
      description: l10n.onboardingFeaturesDesc,
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Page 4: get started + privacy reminder.
class _ReadyPage extends StatelessWidget {
  const _ReadyPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    return _OnboardingPage(
      content: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 18, color: colors.positive),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.privacyLocalData,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      title: l10n.onboardingReadyTitle,
      description: l10n.onboardingReadyDesc,
    );
  }
}

/// Page indicator (widened active dot).
class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
