import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/primary_button.dart';
import '../../../core/theme/components/score_badge.dart';
import '../../premium/presentation/widgets/premium_widgets.dart';
import '../../scenarios/application/scenario_prefill.dart';
import '../../scenarios/presentation/widgets/scenario_widgets.dart';
import '../application/providers_providers.dart';
import '../data/provider_dtos.dart';
import '../data/provider_repository.dart';
import 'widgets/provider_widgets.dart';

/// "Find my ideal 3a" wizard — port of iOS's `BestMatchView`:
/// 3 steps (risk profile → preferences → top 3) backed by
/// `POST /providers/best-match`.
///
/// The risk level is prefilled based on the profile's age (iOS
/// `riskLevelForAge` mapping, via [scenarioPrefillProvider] — same
/// cross-feature exception as the scenarios); with no profile or on a
/// prefill error, the BALANCED default applies (backend schema
/// default) — the suggestion never blocks the wizard.
///
/// iOS's local fallback (`OfflineProviderData.bestMatch`) is not
/// ported over: error → inline card with retry, input preserved.
class BestMatchScreen extends ConsumerStatefulWidget {
  const BestMatchScreen({super.key});

  @override
  ConsumerState<BestMatchScreen> createState() => _BestMatchScreenState();
}

class _BestMatchScreenState extends ConsumerState<BestMatchScreen> {
  static const _riskOptions = <(String, IconData)>[
    ('CONSERVATIVE', Icons.shield_outlined),
    ('MODERATE', Icons.eco_outlined),
    ('BALANCED', Icons.balance),
    ('GROWTH', Icons.trending_up),
    ('AGGRESSIVE', Icons.local_fire_department_outlined),
  ];

  String _riskLevel = 'BALANCED';
  bool _didPrefill = false;
  bool _preferEsg = false;
  double _maxFee = 1.0;

  int _step = 0;
  bool _submitting = false;
  Object? _error;
  List<ScoredProductDto>? _results;

  Future<void> _findBestMatch() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(providerRepositoryProvider)
          .bestMatch(
            riskLevel: _riskLevel,
            preferEsg: _preferEsg,
            maxFeePercent: _maxFee,
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _results = results;
        _step = 2;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Prefilled only once: the user's choice is never overwritten. A
    // prefill failure is ignored (BALANCED default) — it's only a
    // suggestion.
    ref.listen(scenarioPrefillProvider, (_, next) {
      final age = next.valueOrNull?.age;
      if (age != null && !_didPrefill) {
        _didPrefill = true;
        setState(() => _riskLevel = riskLevelForAge(age));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bestmatchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(value: _step / 2),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                switch (_step) {
                  0 => _buildRiskStep(),
                  1 => _buildPreferencesStep(),
                  _ => _buildResultsStep(),
                },
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1 — risk profile (5 illustrated options).
  Widget _buildRiskStep() {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    String description(String level) => switch (level) {
      'CONSERVATIVE' => l10n.bestmatchRiskConservativeDesc,
      'MODERATE' => l10n.bestmatchRiskModerateDesc,
      'BALANCED' => l10n.bestmatchRiskBalancedDesc,
      'GROWTH' => l10n.bestmatchRiskGrowthDesc,
      _ => l10n.bestmatchRiskAggressiveDesc,
    };

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.bestmatchRiskQuestion,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.bestmatchRiskExplanation,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        for (final (level, icon) in _riskOptions) ...[
          _RiskOptionTile(
            icon: icon,
            title: riskLevelLabel(l10n, level),
            description: description(level),
            selected: _riskLevel == level,
            onTap: () => setState(() {
              _riskLevel = level;
              _step = 1;
            }),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// Step 2 — preferences (max fee, ESG).
  Widget _buildPreferencesStep() {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(l10n.bestmatchPreferences, style: theme.textTheme.titleLarge),
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.bestmatchMaxFee,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    formatPercent(_maxFee, decimals: 1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxFee,
                min: 0.1,
                max: 2.0,
                divisions: 19,
                label: formatPercent(_maxFee, decimals: 1),
                onChanged: (value) => setState(() => _maxFee = value),
              ),
              Text(
                l10n.bestmatchFeeHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            secondary: Icon(
              Icons.eco,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.bestmatchEsg),
            subtitle: Text(l10n.bestmatchEsgHint),
            value: _preferEsg,
            onChanged: (value) => setState(() => _preferEsg = value),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : () => setState(() => _step = 0),
                child: Text(l10n.guidedBack),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: l10n.bestmatchFind,
                onPressed: _findBestMatch,
                isLoading: _submitting,
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          // 402: best-match reserved for Premium (contract §11) →
          // "paywall-style" state instead of an error card.
          if (_error is PremiumRequiredException)
            PremiumUpsellCard(message: l10n.premiumUpsellBestMatch)
          else
            ScenarioErrorCard(
              message: providerErrorMessage(l10n, _error!),
              onRetry: _findBestMatch,
            ),
        ],
      ],
    );
  }

  /// Step 3 — top 3 with podium + explanation of the criteria.
  Widget _buildResultsStep() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final results = _results ?? const [];

    if (results.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.search_off,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(l10n.bestmatchNoResults, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.bestmatchTryDifferent,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => setState(() => _step = 0),
            child: Text(l10n.bestmatchRestart),
          ),
        ],
      );
    }

    const podiumColors = [
      Color(0xFFFFC107), // gold
      Color(0xFF9E9E9E), // silver
      Color(0xFF8D6E63), // bronze
    ];

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(l10n.bestmatchResultsTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        for (var i = 0; i < results.length; i++) ...[
          _BestMatchResultCard(
            rank: i + 1,
            rankColor: podiumColors[i.clamp(0, 2)],
            product: results[i],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        ScenarioInfoCard(
          icon: Icons.info_outline,
          text: l10n.bestmatchScoreExplanation,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => setState(() {
            _step = 0;
            _results = null;
          }),
          child: Text(l10n.bestmatchRestart),
        ),
      ],
    );
  }
}

/// Illustrated risk option (icon + title + description) — tap =
/// selection and advance to the next step (iOS behavior).
class _RiskOptionTile extends StatelessWidget {
  const _RiskOptionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Material(
      color: selected ? accent.withValues(alpha: 0.08) : null,
      borderRadius: BorderRadius.circular(14),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            icon,
            size: 28,
            color: selected ? accent : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(title, style: theme.textTheme.titleSmall),
          subtitle: Text(description),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Podium result card (colored rank, provider, product,
/// equity/fee chips, score badge).
class _BestMatchResultCard extends StatelessWidget {
  const _BestMatchResultCard({
    required this.rank,
    required this.rankColor,
    required this.product,
  });

  final int rank;
  final Color rankColor;
  final ScoredProductDto product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: rankColor,
            child: Text(
              '$rank',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.providerName, style: theme.textTheme.titleSmall),
                Text(
                  product.productName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    _ChipMetric(
                      icon: Icons.pie_chart_outline,
                      label: '${product.equityAllocation} %',
                    ),
                    _ChipMetric(
                      icon: Icons.sell_outlined,
                      label: formatPercent(product.allInFeePercent),
                    ),
                    if (product.sustainableEsg)
                      _ChipMetric(
                        icon: Icons.eco,
                        label: context.l10n.providersEsgBadge,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ScoreBadge(score: product.score),
        ],
      ),
    );
  }
}

/// Icon-based mini metric for the podium cards.
class _ChipMetric extends StatelessWidget {
  const _ChipMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
