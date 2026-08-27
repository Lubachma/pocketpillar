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

/// Property purchase fallback age when the birth year is unknown
/// ("incomplete profile" mode).
const int _defaultPropertyAge = 40;

/// Property purchase (EPL withdrawal) — port of iOS's
/// `PropertyPurchaseView`, calculated via
/// `POST /calculator/property-purchase` (iOS's buggy formula —
/// `max(x/2, x/2)` — is not ported over; the backend applies the real
/// rule: 100% before age 50, otherwise max(assets at 50, half of
/// current assets)).
///
/// A withdrawal below the legal minimum (CHF 20'000) returns a 400
/// whose localized backend message is shown in the inline error card
/// — the form stays editable.
class PropertyPurchaseScreen extends ConsumerStatefulWidget {
  const PropertyPurchaseScreen({super.key});

  @override
  ConsumerState<PropertyPurchaseScreen> createState() =>
      _PropertyPurchaseScreenState();
}

class _PropertyPurchaseScreenState
    extends ConsumerState<PropertyPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _capitalController = TextEditingController();
  final _withdrawalController = TextEditingController();

  int _age = _defaultPropertyAge;
  int _annualContribution = 0;

  bool _prefilled = false;
  bool _submitting = false;
  Object? _error;
  PropertyPurchaseResultDto? _result;

  @override
  void dispose() {
    _capitalController.dispose();
    _withdrawalController.dispose();
    super.dispose();
  }

  void _applyPrefill(ScenarioPrefill prefill) {
    setState(() {
      if (prefill.pillar2Capital > 0) {
        _capitalController.text = centimesToChfInput(prefill.pillar2Capital);
      }
      final age = prefill.age;
      if (age != null) _age = age;
      _annualContribution = prefill.pillar2Contribution;
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
          .propertyPurchase(
            buildPropertyPurchasePayload(
              age: _age,
              currentBvgCapital: chfFieldToCentimes(_capitalController.text),
              withdrawalAmount: chfFieldToCentimes(_withdrawalController.text),
              annualContribution: _annualContribution,
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
      appBar: AppBar(title: Text(l10n.scenarioPropertyTitle)),
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
                ScenarioSectionTitle(l10n.scenarioPropertyInputSection),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.scenarioPropertyBvgCapital,
                  controller: _capitalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      validateChfField(l10n, value, required: true),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),
                ScenarioSliderRow(
                  label: l10n.calculatorAge,
                  value: '$_age',
                  sliderValue: _age.toDouble(),
                  min: scenarioMinAge.toDouble(),
                  max: scenarioMaxAge.toDouble(),
                  onChanged: (value) => setState(() => _age = value.round()),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  label: l10n.scenarioPropertyWithdrawal,
                  controller: _withdrawalController,
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
          _PropertyResults(result: _result!),
          const SizedBox(height: 16),
          ScenarioInfoCard(
            icon: Icons.balance,
            text: l10n.generalSimulationDisclaimer,
            color: context.appColors.warning,
          ),
        ],
      ],
    );
  }
}

class _PropertyResults extends StatelessWidget {
  const _PropertyResults({required this.result});

  final PropertyPurchaseResultDto result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScenarioSectionTitle(l10n.scenarioPropertyImpactSection),
          const SizedBox(height: 12),
          ScenarioMetricRow(
            label: l10n.scenarioPropertyMaxWithdrawal,
            value: formatChf(result.maxWithdrawal),
          ),
          const SizedBox(height: 8),
          ScenarioMetricRow(
            label: l10n.scenarioPropertyEffectiveWithdrawal,
            value: formatChf(result.effectiveWithdrawal),
          ),
          const Divider(height: 24),
          ScenarioMetricRow(
            label: l10n.scenarioPropertyCapitalWithout,
            value: formatChf(result.capitalAtRetirementWithout),
          ),
          const SizedBox(height: 8),
          ScenarioMetricRow(
            label: l10n.scenarioPropertyCapitalWith,
            value: formatChf(result.capitalAtRetirementWith),
          ),
          const Divider(height: 24),
          ScenarioMetricRow(
            label: l10n.scenarioPropertyPensionLoss,
            value:
                '-${formatChf(result.monthlyPensionLoss)}/${l10n.scenarioMonth}',
            valueColor: colors.negative,
          ),
        ],
      ),
    );
  }
}
