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
import 'widgets/scenario_widgets.dart';

/// Divorce fallback age when the birth year is unknown ("incomplete
/// profile" mode).
const int _defaultDivorceAge = 40;

/// Divorce impact — port of iOS's `DivorceImpactView`, calculated via
/// `POST /calculator/divorce-impact` (50/50 split of LPP assets
/// accumulated during the marriage + AVS splitting estimate).
///
/// Deliberately neutral presentation: raw figures and a disclaimer
/// (indicative simulation, not legal advice).
class DivorceImpactScreen extends ConsumerStatefulWidget {
  const DivorceImpactScreen({super.key});

  @override
  ConsumerState<DivorceImpactScreen> createState() =>
      _DivorceImpactScreenState();
}

class _DivorceImpactScreenState extends ConsumerState<DivorceImpactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _myMarriageController = TextEditingController();
  final _myNowController = TextEditingController();
  final _spouseMarriageController = TextEditingController();
  final _spouseNowController = TextEditingController();

  int _yearsMarried = 10;
  int _age = _defaultDivorceAge;
  int _annualContribution = 0;

  bool _prefilled = false;
  bool _submitting = false;
  Object? _error;
  DivorceImpactResultDto? _result;

  @override
  void dispose() {
    _myMarriageController.dispose();
    _myNowController.dispose();
    _spouseMarriageController.dispose();
    _spouseNowController.dispose();
    super.dispose();
  }

  void _applyPrefill(ScenarioPrefill prefill) {
    setState(() {
      if (prefill.pillar2Capital > 0) {
        _myNowController.text = centimesToChfInput(prefill.pillar2Capital);
      }
      final age = prefill.age;
      if (age != null) _age = age;
      _annualContribution = prefill.pillar2Contribution;
    });
  }

  /// Cross-field validator for the marriage capital: it can't exceed
  /// the current capital **of the same spouse** (the backend accepts
  /// the inversion and would return nonsensical results — the
  /// suggestion of a Zod refine on the API side is logged in the
  /// journal). The comparison is skipped while the current capital
  /// isn't parsable: its own validator already flags that.
  String? _validateMarriageCapital(
    AppLocalizations l10n,
    String? value,
    TextEditingController nowController,
  ) {
    final error = validateChfField(l10n, value, required: false);
    if (error != null) return error;
    final now = parseChfToCentimes(nowController.text);
    if (now != null && chfFieldToCentimes(value) > now) {
      return l10n.scenarioDivorceCapitalExceedsNow;
    }
    return null;
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
          .divorceImpact(
            buildDivorceImpactPayload(
              age: _age,
              bvgCapitalAtMarriage: chfFieldToCentimes(
                _myMarriageController.text,
              ),
              bvgCapitalNow: chfFieldToCentimes(_myNowController.text),
              spouseBvgCapitalAtMarriage: chfFieldToCentimes(
                _spouseMarriageController.text,
              ),
              spouseBvgCapitalNow: chfFieldToCentimes(
                _spouseNowController.text,
              ),
              yearsMarried: _yearsMarried,
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
      appBar: AppBar(title: Text(l10n.scenarioDivorceTitle)),
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
    // The Form wraps the whole ListView: the fields of both cards
    // (your LPP + spouse's LPP) are validated together.
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScenarioSectionTitle(l10n.scenarioDivorceMySection),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.scenarioDivorceMyCapitalMarriage,
                  controller: _myMarriageController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      _validateMarriageCapital(l10n, value, _myNowController),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.scenarioDivorceMyCapitalNow,
                  controller: _myNowController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      validateChfField(l10n, value, required: true),
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScenarioSectionTitle(l10n.scenarioDivorceSpouseSection),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.scenarioDivorceSpouseCapitalMarriage,
                  controller: _spouseMarriageController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) => _validateMarriageCapital(
                    l10n,
                    value,
                    _spouseNowController,
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.scenarioDivorceSpouseCapitalNow,
                  controller: _spouseNowController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      validateChfField(l10n, value, required: true),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),
                ScenarioSliderRow(
                  label: l10n.scenarioDivorceYearsMarried,
                  value: '$_yearsMarried',
                  sliderValue: _yearsMarried.toDouble(),
                  min: 0,
                  max: divorceMaxYearsMarried.toDouble(),
                  onChanged: (value) =>
                      setState(() => _yearsMarried = value.round()),
                ),
              ],
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
          else if (_result != null)
            _DivorceResults(result: _result!),
          const SizedBox(height: 16),
          ScenarioInfoCard(
            icon: Icons.balance,
            text: l10n.scenarioDivorceDisclaimer,
            color: context.appColors.warning,
          ),
        ],
      ),
    );
  }
}

class _DivorceResults extends StatelessWidget {
  const _DivorceResults({required this.result});

  final DivorceImpactResultDto result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final transfer = result.transferAmount;
    final pensionDiff = result.annualPensionDifference;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScenarioSectionTitle(l10n.scenarioDivorceResultSection),
          const SizedBox(height: 12),
          ScenarioMetricRow(
            label: l10n.scenarioDivorceTotalMarriageCapital,
            value: formatChf(result.totalMarriageCapital),
          ),
          const SizedBox(height: 8),
          ScenarioMetricRow(
            label: l10n.scenarioDivorceMyShare,
            value: formatChf(result.myShare),
          ),
          const Divider(height: 24),
          ScenarioMetricRow(
            label: l10n.scenarioDivorceTransfer,
            value: transfer >= 0
                ? '+${formatChf(transfer)}'
                : formatChf(transfer),
            valueColor: transfer >= 0 ? colors.positive : colors.negative,
            suffix: transfer >= 0
                ? l10n.scenarioDivorceYouReceive
                : l10n.scenarioDivorceYouPay,
          ),
          const SizedBox(height: 8),
          ScenarioMetricRow(
            label: l10n.scenarioDivorceCapitalAfter,
            value: formatChf(result.capitalAfterDivorce),
          ),
          // Like iOS (`if pensionDifference != 0`): a zero row is
          // hidden rather than showing "-CHF 0.00/year" in green.
          if (pensionDiff != 0) ...[
            const Divider(height: 24),
            ScenarioMetricRow(
              label: l10n.scenarioDivorcePensionImpact,
              value: pensionDiff > 0
                  ? '-${formatChf(pensionDiff)}/${l10n.scenarioYear}'
                  : '+${formatChf(-pensionDiff)}/${l10n.scenarioYear}',
              valueColor: pensionDiff > 0 ? colors.negative : colors.positive,
            ),
          ],
          if (result.estimatedAvsImpact != 0) ...[
            if (pensionDiff != 0)
              const SizedBox(height: 8)
            else
              const Divider(height: 24),
            ScenarioMetricRow(
              label: l10n.scenarioDivorceAvsImpact,
              value:
                  '-${formatChf(result.estimatedAvsImpact)}/${l10n.scenarioYear}',
              valueColor: colors.warning,
            ),
          ],
        ],
      ),
    );
  }
}
