import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/theme/components/primary_button.dart';
import '../../../../core/utils/currency.dart';
import '../../calculator/presentation/widgets/wizard_steps.dart';
import '../../financial_profile/application/financial_profile_providers.dart';
import '../../premium/presentation/widgets/premium_widgets.dart';
import '../application/scenario_prefill.dart';
import '../data/scenario_dtos.dart';
import '../data/scenario_payloads.dart';
import '../data/scenario_repository.dart';
import '../../calculator/presentation/widgets/help_sheet.dart';
import 'widgets/scenario_widgets.dart';

/// Staggered withdrawal fallback age when the birth year is unknown
/// ("incomplete profile" mode).
const int _defaultWithdrawalAge = 40;

/// Staggered withdrawal — port of iOS's `StaggeredWithdrawalView`,
/// calculated via `POST /calculator/staggered-withdrawal` (real
/// federal tax scales on the backend; iOS's simplified 6/8/10% scale
/// is not ported over).
///
/// Canton, age, and marital status aren't exposed: prefilled from the
/// profile, defaults otherwise (VD, 40, SINGLE — registered
/// partnership mapped to MARRIED, joint tax scale).
class StaggeredWithdrawalScreen extends ConsumerStatefulWidget {
  const StaggeredWithdrawalScreen({super.key});

  @override
  ConsumerState<StaggeredWithdrawalScreen> createState() =>
      _StaggeredWithdrawalScreenState();
}

class _StaggeredWithdrawalScreenState
    extends ConsumerState<StaggeredWithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _balanceController = TextEditingController();
  final _pillar2Controller = TextEditingController();

  int _numberOfAccounts = 2;
  int _age = _defaultWithdrawalAge;
  String _canton = 'VD';
  String _maritalStatus = 'SINGLE';

  bool _prefilled = false;
  bool _submitting = false;
  Object? _error;
  StaggeredWithdrawalResultDto? _result;

  @override
  void dispose() {
    _balanceController.dispose();
    _pillar2Controller.dispose();
    super.dispose();
  }

  void _applyPrefill(ScenarioPrefill prefill) {
    setState(() {
      if (prefill.pillar3aBalance > 0) {
        _balanceController.text = centimesToChfInput(prefill.pillar3aBalance);
      }
      if (prefill.pillar3aAccountCount > 0) {
        _numberOfAccounts = prefill.pillar3aAccountCount.clamp(
          1,
          staggeredMaxAccounts,
        );
      }
      if (prefill.pillar2Capital > 0) {
        _pillar2Controller.text = centimesToChfInput(prefill.pillar2Capital);
      }
      final age = prefill.age;
      if (age != null) _age = age;
      final canton = prefill.canton;
      if (canton != null) _canton = canton;
      final maritalStatus = prefill.maritalStatus;
      if (maritalStatus != null) _maritalStatus = maritalStatus;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(scenarioRepositoryProvider)
          .staggeredWithdrawal(
            buildStaggeredWithdrawalPayload(
              canton: _canton,
              totalPillar3aBalance: chfFieldToCentimes(_balanceController.text),
              numberOfAccounts: _numberOfAccounts,
              currentAge: _age,
              maritalStatus: mapMaritalStatusForWithdrawal(_maritalStatus),
              pillar2AsCapital: chfFieldToCentimes(_pillar2Controller.text),
            ),
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _result = result;
      });
    } on Object catch (e) {
      if (!mounted) return;
      // 402: Premium scenario without a subscription (contract §11) →
      // paywall, no error card — the input is preserved for the return.
      if (redirectToPaywallIf402(context, e)) {
        setState(() => _submitting = false);
        return;
      }
      setState(() {
        _submitting = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Prefill applied only once: the user's input isn't overwritten
    // once it has succeeded. After a failure, the banner's retry
    // applies it and may then overwrite input (accepted behavior).
    ref.listen(scenarioPrefillProvider, (_, next) {
      final data = next.valueOrNull;
      if (data != null && !_prefilled) {
        _prefilled = true;
        _applyPrefill(data);
      }
    });
    final prefill = ref.watch(scenarioPrefillProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scenarioWithdrawalTitle)),
      body: prefill.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Prefill failed: non-blocking banner — the form stays
        // usable with the default values.
        error: (_, _) => Column(
          children: [
            ScenarioPrefillBanner(
              onRetry: () => ref.invalidate(profileAggregateProvider),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
        data: (_) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScenarioSectionTitle(l10n.scenarioWithdrawalInputSection),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.scenarioWithdrawal3aBalance,
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      validateChfField(l10n, value, required: true),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),
                ScenarioSliderRow(
                  label: l10n.scenarioWithdrawalAccounts,
                  value: '$_numberOfAccounts',
                  sliderValue: _numberOfAccounts.toDouble(),
                  min: 1,
                  max: staggeredMaxAccounts.toDouble(),
                  onChanged: (value) =>
                      setState(() => _numberOfAccounts = value.round()),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  label: l10n.scenarioWithdrawalPillar2Capital,
                  controller: _pillar2Controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      validateChfField(l10n, value, required: false),
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: l10n.calculatorCalculate,
          onPressed: _submit,
          isLoading: _submitting,
        ),
        const SizedBox(height: 16),
        if (_error != null)
          ScenarioErrorCard(
            message: scenarioErrorMessage(l10n, _error!),
            onRetry: _submit,
          )
        else if (_result != null) ...[
          _WithdrawalResults(result: _result!),
          const SizedBox(height: 16),
          ScenarioInfoCard(
            icon: Icons.balance,
            text: l10n.generalSimulationDisclaimer,
            color: context.appColors.warning,
          ),
        ],
        const SizedBox(height: 16),
        ScenarioInfoCard(
          icon: Icons.lightbulb_outline,
          text: l10n.scenarioWithdrawalTip,
          color: context.appColors.warning,
        ),
      ],
    );
  }
}

/// Localized label for a strategy: `lump_sum` or `stagger_<N>_years`
/// (format guaranteed by the backend).
String _strategyLabel(AppLocalizations l10n, String label) {
  if (label == 'lump_sum') return l10n.scenarioWithdrawalStrategyLumpSum;
  final years = int.tryParse(
    label.replaceFirst('stagger_', '').replaceFirst('_years', ''),
  );
  return years != null
      ? l10n.scenarioWithdrawalStrategyStaggered(years)
      : label;
}

class _WithdrawalResults extends StatelessWidget {
  const _WithdrawalResults({required this.result});

  final StaggeredWithdrawalResultDto result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final maxTax = result.strategies.fold<int>(
      1,
      (max, s) => s.totalTax > max ? s.totalTax : max,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ScenarioSectionTitle(l10n.scenarioWithdrawalComparison),
              ),
              const HelpButton(termId: 'withdrawal_tax'),
            ],
          ),
          const SizedBox(height: 12),
          for (final strategy in result.strategies) ...[
            _StrategyBar(
              strategy: strategy,
              isBest: strategy.label == result.bestStrategy,
              fraction: strategy.totalTax / maxTax,
            ),
            const SizedBox(height: 12),
          ],
          const Divider(height: 24),
          ScenarioMetricRow(
            label: l10n.scenarioWithdrawalSaving,
            value: formatChf(result.taxSavingsVsLumpSum),
            valueColor: colors.positive,
          ),
        ],
      ),
    );
  }
}

/// Comparative bar for a strategy: label (+ best-strategy badge), bar
/// proportional to the tax, amount, and effective rate.
class _StrategyBar extends StatelessWidget {
  const _StrategyBar({
    required this.strategy,
    required this.isBest,
    required this.fraction,
  });

  final WithdrawalStrategyDto strategy;
  final bool isBest;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final color = isBest ? colors.positive : colors.negative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _strategyLabel(l10n, strategy.label),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isBest ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (isBest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.positive.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.scenarioWithdrawalBestStrategy,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.positive,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.02, 1.0),
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                formatChf(strategy.totalTax),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${l10n.scenarioWithdrawalEffectiveRate} : '
              '${strategy.effectiveTaxRate.toStringAsFixed(1)} %',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
