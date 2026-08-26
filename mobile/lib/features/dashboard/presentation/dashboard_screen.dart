import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/primary_button.dart';
import '../../../core/utils/clock.dart';
import '../../checklist/data/year_end_checklist.dart';
import '../../financial_profile/application/financial_profile_providers.dart';
import '../application/dashboard_providers.dart';
import '../application/educational_tips.dart';
import '../data/dashboard_dtos.dart';
import 'widgets/pillar_overview.dart';
import 'widgets/profile_cta_card.dart';
import 'widgets/recommendations_section.dart';
import 'widgets/score_card.dart';
import 'widgets/seasonal_checklist_card.dart';
import 'widgets/summary_card.dart';
import 'widgets/tip_card.dart';

/// Dashboard (phase 3.2 rework).
///
/// States: loading, error with retry (network / backend `{ error }`),
/// missing profile (initial 404 from `GET /financial-profile` → invitation to
/// complete the profile), loaded (pension score /100 — batch 3,
/// retirement summary, pillars, recommendations, seasonal checklist,
/// tip of the day).
/// Pull-to-refresh everywhere (the list stays scrollable in every state).
///
/// The score card (`GET /score`) is hidden when the backend responds with 422
/// (incomplete profile); its error retries locally, like the
/// recommendations. The score history (iOS monthly delta) is not
/// carried over: no endpoint (journal, batch 3).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dashboard = ref.watch(dashboardProvider);
    final data = dashboard.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: data != null
            ? _DashboardContent(data: data)
            : dashboard.hasError
            ? _ErrorView(error: dashboard.error!)
            : const _LoadingView(),
      ),
    );
  }

  /// Invalidates the shared profile aggregate (the dashboard follows via its
  /// watch) and the two providers specific to the screen; errors are
  /// carried by the [AsyncValue]s, never by the refresh future.
  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(profileAggregateProvider);
    ref.invalidate(recommendationsProvider);
    ref.invalidate(scoreProvider);
    try {
      await ref.read(dashboardProvider.future);
    } on Object {
      // Error state shown by the screen.
    }
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 420, child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 420,
          child: Center(
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 40,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage(l10n, error),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: l10n.commonRetry,
                    onPressed: () {
                      ref.invalidate(profileAggregateProvider);
                      ref.invalidate(recommendationsProvider);
                      ref.invalidate(scoreProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _GreetingHeader(now: now),
        const SizedBox(height: 16),
        if (!data.hasProfile)
          const ProfileCtaCard()
        else ...[
          const ScoreCard(),
          if (data.projection != null)
            SummaryCard(data: data)
          else
            // Profile created but projection not possible (missing birth
            // year or age outside 18–64): invite to complete it.
            const ProfileCtaCard(),
          const SizedBox(height: 16),
          PillarOverview(data: data),
          const SizedBox(height: 16),
          const RecommendationsSection(),
        ],
        if (YearEndChecklist.isSeason(now)) ...[
          const SizedBox(height: 16),
          SeasonalChecklistCard(hasPillar3a: data.hasPillar3a),
        ],
        const SizedBox(height: 16),
        TipOfDaySection(tip: EducationalTips.tipOfTheDay(now)),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final greeting = now.hour < 18
        ? l10n.dashboardGreeting
        : l10n.dashboardGreetingEvening;
    return Text(greeting, style: Theme.of(context).textTheme.headlineSmall);
  }
}

String _errorMessage(AppLocalizations l10n, Object error) => switch (error) {
  NetworkException() => l10n.errorNetwork,
  ApiException(:final message) => message,
  _ => l10n.errorUnknown,
};
