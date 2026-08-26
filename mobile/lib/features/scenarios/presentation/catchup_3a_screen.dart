import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'widgets/scenario_widgets.dart';

/// 3a catch-up (2025 reform) — port of iOS's `Catchup3aView`, calculated
/// via `POST /calculator/3a-catchup` (iOS's hardcoded caps are not
/// ported over).
///
/// Form: years without contribution (0–10), employed/self-employed
/// status (→ `hasSecondPillar`), taxable income. Past payment detail
/// (`pastContributions`) isn't entered — the gap is calculated at
/// full cap (backend schema default).
class Catchup3aScreen extends ConsumerStatefulWidget {
  const Catchup3aScreen({super.key});

  @override
  ConsumerState<Catchup3aScreen> createState() => _Catchup3aScreenState();
}

class _Catchup3aScreenState extends ConsumerState<Catchup3aScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();

  int _yearsMissed = 1;
  bool _hasSecondPillar = true;

  bool _prefilled = false;
  bool _submitting = false;
  Object? _error;
  Catchup3aResultDto? _result;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _applyPrefill(ScenarioPrefill prefill) {
    final income = prefill.grossAnnualIncome;
    final employmentStatus = prefill.employmentStatus;
    setState(() {
      if (income != null && income > 0) {
        _incomeController.text = centimesToChfInput(income);
      }
      // "With 2nd pillar" cap only for employees: SELF_EMPLOYED but
      // also UNEMPLOYED/RETIRED → cap without 2nd pillar (more
      // accurate when there's no pension fund). Unknown status (no
      // profile) → employed default kept.
      if (employmentStatus != null) {
        _hasSecondPillar = employmentStatus == 'EMPLOYED';
      }
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
      // Canton/marital status/municipality from the profile → tax
      // savings calculated on the real backend tax scales (absent →
      // flat-rate estimate).
      final prefill = ref.read(scenarioPrefillProvider).valueOrNull;
      final result = await ref
          .read(scenarioRepositoryProvider)
          .catchup3a(
            buildCatchup3aPayload(
              yearsMissed: _yearsMissed,
              hasSecondPillar: _hasSecondPillar,
              taxableIncome: chfFieldToCentimes(_incomeController.text),
              canton: prefill?.canton,
              maritalStatus: prefill?.maritalStatus,
              municipality: prefill?.municipality,
            ),
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _result = result;
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
      appBar: AppBar(title: Text(l10n.scenario3aCatchupTitle)),
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
                ScenarioSectionTitle(l10n.scenario3aCatchupInputSection),
                const SizedBox(height: 16),
                ScenarioSliderRow(
                  label: l10n.scenario3aCatchupYearsMissed,
                  value: '$_yearsMissed',
                  sliderValue: _yearsMissed.toDouble(),
                  min: 0,
                  max: catchupMaxYears.toDouble(),
                  onChanged: (value) =>
                      setState(() => _yearsMissed = value.round()),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.scenario3aCatchupStatusEmployed),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.scenario3aCatchupStatusSelfEmployed),
                      ),
                    ],
                    selected: {_hasSecondPillar},
                    onSelectionChanged: (selection) =>
                        setState(() => _hasSecondPillar = selection.first),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.calculatorTaxableIncome,
                  controller: _incomeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) => validateChfField(
                    l10n,
                    value,
                    required: true,
                    allowZero: false,
                  ),
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
          _CatchupResults(result: _result!),
          // Free preview (contract §11): totals are still served but
          // the year-by-year plan is reserved for Premium → upsell card.
          if (_result!.premiumRequired) ...[
            const SizedBox(height: 16),
            PremiumUpsellCard(
              title: l10n.catchupUpsellTitle,
              message: l10n.catchupUpsellBody,
            ),
          ],
          const SizedBox(height: 16),
          ScenarioInfoCard(
            icon: Icons.balance,
            text: l10n.generalSimulationDisclaimer,
            color: context.appColors.warning,
          ),
        ],
        const SizedBox(height: 16),
        ScenarioInfoCard(
          icon: Icons.info_outline,
          text: l10n.scenario3aCatchupInfo,
        ),
      ],
    );
  }
}

class _CatchupResults extends StatelessWidget {
  const _CatchupResults({required this.result});

  final Catchup3aResultDto result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScenarioSectionTitle(l10n.scenario3aCatchupResultSection),
          const SizedBox(height: 12),
          Text(
            formatChf(result.totalCatchupPotential),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.positive,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            l10n.scenario3aCatchupTotalCatchup,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ScenarioMetricRow(
            label: l10n.scenario3aCatchupMaxPerYear,
            value: formatChf(result.maxPerYear),
          ),
          const SizedBox(height: 8),
          ScenarioMetricRow(
            label: l10n.scenario3aCatchupEligibleYears,
            value: '${result.eligibleYears}',
          ),
          if (result.mustMaxCurrentYearFirst) ...[
            const SizedBox(height: 8),
            ScenarioMetricRow(
              label: l10n.scenario3aCatchupCurrentYearGap,
              value: formatChf(result.currentYearGap),
              valueColor: colors.warning,
            ),
          ],
          const SizedBox(height: 8),
          ScenarioMetricRow(
            label: l10n.scenario3aCatchupTaxSaving,
            value: '~ ${formatChf(result.estimatedTaxSavings)}',
            valueColor: colors.positive,
          ),
          const SizedBox(height: 8),
          ScenarioMetricRow(
            label: l10n.scenario3aCatchupMarginalRate,
            value: '${result.estimatedMarginalRate} %',
          ),
          if (result.yearDetails.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              l10n.scenario3aCatchupYearlySection,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final detail in result.yearDetails) ...[
              ScenarioMetricRow(
                label: '${detail.year}',
                value: formatChf(detail.gap),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }
}
