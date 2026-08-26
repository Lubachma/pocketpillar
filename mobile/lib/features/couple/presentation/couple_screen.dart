import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/theme/components/primary_button.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/swiss_canton.dart';
import '../../calculator/data/calculator_payloads.dart';
import '../../calculator/presentation/widgets/results_view.dart';
import '../../calculator/presentation/widgets/wizard_steps.dart';
import '../../financial_profile/application/financial_profile_providers.dart';
import '../../financial_profile/presentation/widgets/municipality_picker_sheet.dart';
import '../../premium/presentation/widgets/premium_widgets.dart';
import '../../scenarios/application/scenario_prefill.dart';
import '../../scenarios/presentation/widgets/scenario_widgets.dart';
import '../data/couple_payloads.dart';
import '../data/couple_repository.dart';
import '../data/couple_result.dart';

/// Fallback age for a spouse when the birth year is unknown
/// (iOS partner default; "incomplete profile" mode).
const int _defaultSpouseAge = 35;

/// Fallback canton when the profile doesn't have one (scenario default).
const String _defaultCanton = 'VD';

/// Couple simulation — a single `POST /calculator/couple` call (batch 6):
/// the backend calculates per-spouse projections, the couple AVS cap
/// 150%, the tax estimate (joint vs separate taxation) and the
/// anti-collision coordinated withdrawal plan. No local engine (backend =
/// source of truth).
///
/// Sections: combined summary (+ AVS cap alert), per-spouse comparison,
/// couple taxation (married vs unmarried) and coordinated withdrawal plan
/// (estimated tax per withdrawal — parity with iOS's `WithdrawalTimelineView`,
/// which replaces the wealth calendar from previous batches).
class CoupleScreen extends ConsumerStatefulWidget {
  const CoupleScreen({super.key});

  @override
  ConsumerState<CoupleScreen> createState() => _CoupleScreenState();
}

class _CoupleScreenState extends ConsumerState<CoupleScreen> {
  /// Simulatable marital statuses — only those that change the couple's tax
  /// (contract §7: marriage/partnership = joint taxation, concubinage =
  /// separate taxation).
  static const _coupleStatuses = [
    'MARRIED',
    'REGISTERED_PARTNERSHIP',
    'CONCUBINAGE',
  ];

  final _formKey = GlobalKey<FormState>();

  // Couple situation — pre-filled from the profile (canton, marital status).
  String _canton = _defaultCanton;
  String? _municipality;
  String _coupleStatus = 'MARRIED';

  // Spouse 1 ("You") — pre-filled from the profile API.
  final _income1Controller = TextEditingController();
  final _pillar2Capital1Controller = TextEditingController();
  final _pillar2Contribution1Controller = TextEditingController();
  final _balance3a1Controller = TextEditingController();
  int _age1 = _defaultSpouseAge;
  bool _has3a1 = false;

  // Spouse 2 ("Partner") — free-form entry.
  final _income2Controller = TextEditingController();
  final _pillar2Capital2Controller = TextEditingController();
  final _pillar2Contribution2Controller = TextEditingController();
  final _balance3a2Controller = TextEditingController();
  int _age2 = _defaultSpouseAge;
  bool _has3a2 = false;

  bool _prefilled = false;
  bool _submitting = false;
  Object? _error;
  CoupleResult? _result;

  @override
  void dispose() {
    _income1Controller.dispose();
    _pillar2Capital1Controller.dispose();
    _pillar2Contribution1Controller.dispose();
    _balance3a1Controller.dispose();
    _income2Controller.dispose();
    _pillar2Capital2Controller.dispose();
    _pillar2Contribution2Controller.dispose();
    _balance3a2Controller.dispose();
    super.dispose();
  }

  void _applyPrefill(ScenarioPrefill prefill) {
    setState(() {
      final canton = prefill.canton;
      if (canton != null) _canton = canton;
      _municipality = prefill.municipality;
      _coupleStatus = switch (prefill.maritalStatus) {
        'MARRIED' => 'MARRIED',
        'REGISTERED_PARTNERSHIP' => 'REGISTERED_PARTNERSHIP',
        // Unknown or unmarried profile (SINGLE/DIVORCED/WIDOWED): we don't
        // presume marriage — concubinage by default, except when the
        // profile is unknown (null), where MARRIED remains the screen's
        // main use case.
        null => 'MARRIED',
        _ => 'CONCUBINAGE',
      };
      final age = prefill.age;
      if (age != null) _age1 = age;
      final income = prefill.grossAnnualIncome;
      if (income != null && income > 0) {
        _income1Controller.text = centimesToChfInput(income);
      }
      if (prefill.pillar2Capital > 0) {
        _pillar2Capital1Controller.text = centimesToChfInput(
          prefill.pillar2Capital,
        );
      }
      if (prefill.pillar2Contribution > 0) {
        _pillar2Contribution1Controller.text = centimesToChfInput(
          prefill.pillar2Contribution,
        );
      }
      if (prefill.pillar3aBalance > 0 || prefill.pillar3aAccountCount > 0) {
        _has3a1 = true;
      }
      if (prefill.pillar3aBalance > 0) {
        _balance3a1Controller.text = centimesToChfInput(
          prefill.pillar3aBalance,
        );
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
      final result = await ref
          .read(coupleRepositoryProvider)
          .simulate(
            person1: CoupleSpouseInput(
              age: _age1,
              grossAnnualIncome: chfFieldToCentimes(_income1Controller.text),
              pillar2Capital: chfFieldToCentimes(
                _pillar2Capital1Controller.text,
              ),
              pillar2Contribution: chfFieldToCentimes(
                _pillar2Contribution1Controller.text,
              ),
              hasPillar3a: _has3a1,
              pillar3aBalance: chfFieldToCentimes(_balance3a1Controller.text),
            ),
            person2: CoupleSpouseInput(
              age: _age2,
              grossAnnualIncome: chfFieldToCentimes(_income2Controller.text),
              pillar2Capital: chfFieldToCentimes(
                _pillar2Capital2Controller.text,
              ),
              pillar2Contribution: chfFieldToCentimes(
                _pillar2Contribution2Controller.text,
              ),
              hasPillar3a: _has3a2,
              pillar3aBalance: chfFieldToCentimes(_balance3a2Controller.text),
            ),
            canton: _canton,
            municipality: _municipality,
            maritalStatus: _coupleStatus,
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _result = result;
      });
    } on Object catch (e) {
      if (!mounted) return;
      // 402: Premium scenario without a subscription (contract §11) → paywall,
      // no error card — input is kept for when they come back.
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
    // Spouse 1 prefill applied only once: the user's inputs
    // aren't overwritten as long as it succeeded. After a
    // failure, the banner's retry applies it and can then overwrite
    // inputs (deliberate behavior).
    ref.listen(scenarioPrefillProvider, (_, next) {
      final data = next.valueOrNull;
      if (data != null && !_prefilled) {
        _prefilled = true;
        _applyPrefill(data);
      }
    });
    final prefill = ref.watch(scenarioPrefillProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.coupleTitle)),
      body: prefill.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Prefill failed: non-blocking banner — the
        // form stays usable with default values.
        error: (_, _) => Column(
          children: [
            ScenarioPrefillBanner(
              // The shared aggregate is the source: it's what we reload
              // (the derived view rebuilds via its watch).
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
    // (you + partner) are validated together.
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScenarioInfoCard(
            icon: Icons.people_outline,
            text: l10n.coupleFormIntro,
          ),
          const SizedBox(height: 16),
          _SituationCard(
            canton: _canton,
            onCantonChanged: (value) => setState(() {
              _canton = value;
              // The municipality depends on the canton: the previous
              // selection no longer applies to the new canton.
              _municipality = null;
            }),
            municipality: _municipality,
            onMunicipalityChanged: (value) =>
                setState(() => _municipality = value),
            coupleStatus: _coupleStatus,
            onStatusChanged: (value) => setState(() => _coupleStatus = value),
            statuses: _coupleStatuses,
          ),
          const SizedBox(height: 16),
          _SpouseFormCard(
            title: l10n.coupleYou,
            age: _age1,
            onAgeChanged: (value) => setState(() => _age1 = value),
            incomeController: _income1Controller,
            pillar2CapitalController: _pillar2Capital1Controller,
            pillar2ContributionController: _pillar2Contribution1Controller,
            has3a: _has3a1,
            has3aLabel: l10n.profileHas3a,
            onHas3aChanged: (value) => setState(() => _has3a1 = value),
            balance3aController: _balance3a1Controller,
            onSubmitted: _submit,
          ),
          const SizedBox(height: 16),
          _SpouseFormCard(
            title: l10n.couplePartner,
            age: _age2,
            onAgeChanged: (value) => setState(() => _age2 = value),
            incomeController: _income2Controller,
            pillar2CapitalController: _pillar2Capital2Controller,
            pillar2ContributionController: _pillar2Contribution2Controller,
            has3a: _has3a2,
            has3aLabel: l10n.couplePartnerHas3a,
            onHas3aChanged: (value) => setState(() => _has3a2 = value),
            balance3aController: _balance3a2Controller,
            onSubmitted: _submit,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: l10n.coupleCalculate,
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
            _CoupleResults(result: _result!),
        ],
      ),
    );
  }
}

/// Input card for a spouse: age (slider), gross income, LPP capital
/// and contribution, 3a (switch + balance). CHF validators reused from
/// the calculator (`validateChfField`).
class _SpouseFormCard extends StatelessWidget {
  const _SpouseFormCard({
    required this.title,
    required this.age,
    required this.onAgeChanged,
    required this.incomeController,
    required this.pillar2CapitalController,
    required this.pillar2ContributionController,
    required this.has3a,
    required this.has3aLabel,
    required this.onHas3aChanged,
    required this.balance3aController,
    required this.onSubmitted,
  });

  final String title;
  final int age;
  final ValueChanged<int> onAgeChanged;
  final TextEditingController incomeController;
  final TextEditingController pillar2CapitalController;
  final TextEditingController pillar2ContributionController;
  final bool has3a;
  final String has3aLabel;
  final ValueChanged<bool> onHas3aChanged;
  final TextEditingController balance3aController;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScenarioSectionTitle(title),
          const SizedBox(height: 8),
          ScenarioSliderRow(
            label: l10n.calculatorAge,
            value: '$age',
            sliderValue: age.toDouble(),
            min: calculatorMinAge.toDouble(),
            max: calculatorMaxAge.toDouble(),
            onChanged: (value) => onAgeChanged(value.round()),
          ),
          const SizedBox(height: 8),
          AppTextField(
            label: l10n.calculatorGrossIncome,
            controller: incomeController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) =>
                validateChfField(l10n, value, required: true, allowZero: false),
            onFieldSubmitted: (_) => onSubmitted(),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: l10n.calculatorBvgCapital,
            controller: pillar2CapitalController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) =>
                validateChfField(l10n, value, required: false),
            onFieldSubmitted: (_) => onSubmitted(),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: l10n.calculatorAnnualContribution,
            controller: pillar2ContributionController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) =>
                validateChfField(l10n, value, required: false),
            onFieldSubmitted: (_) => onSubmitted(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(has3aLabel),
            value: has3a,
            onChanged: onHas3aChanged,
            contentPadding: EdgeInsets.zero,
          ),
          if (has3a) ...[
            const SizedBox(height: 16),
            AppTextField(
              label: l10n.calculatorPillar3aBalance,
              controller: balance3aController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) =>
                  validateChfField(l10n, value, required: false),
              onFieldSubmitted: (_) => onSubmitted(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Results: combined summary (+ AVS cap alert), side-by-side
/// comparison, couple taxation (married vs unmarried) and coordinated
/// withdrawal plan — everything comes from the server.
class _CoupleResults extends StatelessWidget {
  const _CoupleResults({required this.result});

  final CoupleResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CombinedSummaryCard(result: result),
        const SizedBox(height: 16),
        _ComparisonCard(result: result),
        const SizedBox(height: 16),
        _TaxEstimateCard(estimate: result.taxEstimate),
        const SizedBox(height: 16),
        _WithdrawalPlanCard(plan: result.withdrawalPlan),
      ],
    );
  }
}

/// Combined summary (parity with the iOS summary): combined monthly
/// income, combined replacement rate, couple AVS cap alert if reached.
class _CombinedSummaryCard extends StatelessWidget {
  const _CombinedSummaryCard({required this.result});

  final CoupleResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final rate = result.combinedReplacementRate;

    return AppCard(
      child: Column(
        children: [
          ScenarioSectionTitle(l10n.coupleCombinedTitle),
          const SizedBox(height: 8),
          Text(
            formatChf(result.combinedTotalAnnualIncome ~/ 12),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            l10n.coupleCombinedMonthly,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ScenarioMetricRow(
            label: l10n.coupleReplacementRate,
            value: '${rate.toStringAsFixed(0)} %',
            // Same scale as the guided calculator (`rateColor`).
            valueColor: rateColor(colors, rate),
          ),
          if (result.avsCapApplied) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 20, color: colors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.coupleAvsCapWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Side-by-side comparison (parity with iOS's `CoupleComparisonCard`:
/// individual values **not** capped) + individual replacement rates.
class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.result});

  final CoupleResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final person1 = result.person1;
    final person2 = result.person2;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              Expanded(
                child: Text(
                  l10n.coupleYou,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.couplePartner,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _ComparisonRow(
            label: l10n.coupleAvs,
            value1: formatChf(person1.estimatedAnnualAvsPension ~/ 12),
            value2: formatChf(person2.estimatedAnnualAvsPension ~/ 12),
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: l10n.coupleBvg,
            value1: formatChf(person1.annualPillar2Pension ~/ 12),
            value2: formatChf(person2.annualPillar2Pension ~/ 12),
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: l10n.couplePillar3a,
            value1: formatChf(person1.projectedPillar3aBalance),
            value2: formatChf(person2.projectedPillar3aBalance),
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: l10n.coupleReplacementIndividual,
            value1: '${person1.replacementRate.toStringAsFixed(0)} %',
            value2: '${person2.replacementRate.toStringAsFixed(0)} %',
          ),
          const Divider(height: 24),
          _ComparisonRow(
            label: l10n.coupleTotalMonthly,
            value1: formatChf(person1.totalAnnualRetirementIncome ~/ 12),
            value2: formatChf(person2.totalAnnualRetirementIncome ~/ 12),
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.value1,
    required this.value2,
    this.isBold = false,
  });

  final String label;
  final String value1;
  final String value2;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = isBold
        ? theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          )
        : theme.textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(value1, textAlign: TextAlign.center, style: valueStyle),
        ),
        Expanded(
          child: Text(value2, textAlign: TextAlign.center, style: valueStyle),
        ),
      ],
    );
  }
}

/// "Your situation" card: canton (shared by the couple — taxation at
/// the shared residence), municipality (search picker, actual communal
/// multiplier server-side) and simulated marital status, which drive the
/// tax and the AVS cap server-side.
class _SituationCard extends StatelessWidget {
  const _SituationCard({
    required this.canton,
    required this.onCantonChanged,
    required this.municipality,
    required this.onMunicipalityChanged,
    required this.coupleStatus,
    required this.onStatusChanged,
    required this.statuses,
  });

  final String canton;
  final ValueChanged<String> onCantonChanged;
  final String? municipality;

  /// Null = back to the cantonal average (explicit deselection).
  final ValueChanged<String?> onMunicipalityChanged;
  final String coupleStatus;
  final ValueChanged<String> onStatusChanged;
  final List<String> statuses;

  String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
    'MARRIED' => l10n.coupleStatusMarried,
    'REGISTERED_PARTNERSHIP' => l10n.coupleStatusPartnership,
    _ => l10n.coupleStatusConcubinage,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScenarioSectionTitle(l10n.coupleSituationTitle),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: canton,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.profileCanton),
            items: [
              for (final c in swissCantons)
                DropdownMenuItem(
                  value: c.code,
                  child: Text(c.displayName(languageCode)),
                ),
            ],
            onChanged: (value) {
              if (value != null) onCantonChanged(value);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.profileMunicipality),
            subtitle: Text(
              municipality ?? l10n.municipalityCantonalAverageOption,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final name = await MunicipalityPickerSheet.show(
                context,
                cantonCode: canton,
                selectedName: municipality,
              );
              if (name != null) {
                // "Cantonal average" sentinel → deselection (null).
                onMunicipalityChanged(
                  name == municipalityCantonalAverageSentinel ? null : name,
                );
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: coupleStatus,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.coupleFiscalStatus),
            items: [
              for (final status in statuses)
                DropdownMenuItem(
                  value: status,
                  child: Text(_statusLabel(l10n, status)),
                ),
            ],
            onChanged: (value) {
              if (value != null) onStatusChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

/// Couple taxation: estimated annual tax under joint taxation
/// (marriage) vs separate (concubinage), conclusion and disclaimer. The
/// comparison is provided by the server regardless of the marital status
/// simulated — it answers "what if we got married?" (and vice versa).
class _TaxEstimateCard extends StatelessWidget {
  const _TaxEstimateCard({required this.estimate});

  final CoupleTaxEstimateDto estimate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;

    final conclusion = switch (estimate.cheaperStatus) {
      'MARRIED' => (
        l10n.coupleTaxCheaperMarried(formatChf(estimate.annualDifference.abs())),
        colors.positive,
      ),
      'CONCUBINAGE' => (
        l10n.coupleTaxCheaperConcubinage(
          formatChf(estimate.annualDifference.abs()),
        ),
        colors.positive,
      ),
      _ => (l10n.coupleTaxEqual, theme.colorScheme.onSurfaceVariant),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScenarioSectionTitle(l10n.coupleTaxTitle),
          const SizedBox(height: 12),
          ScenarioMetricRow(
            label: l10n.coupleTaxMarriedJoint,
            value: '${formatChf(estimate.married.totalTax)}/${l10n.scenarioYear}',
          ),
          const SizedBox(height: 8),
          ScenarioMetricRow(
            label: l10n.coupleTaxUnmarriedSeparate,
            value:
                '${formatChf(estimate.unmarried.totalTax)}/${l10n.scenarioYear}',
          ),
          const Divider(height: 24),
          Text(
            conclusion.$1,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: conclusion.$2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.coupleTaxDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Coordinated withdrawal plan (parity with iOS's `WithdrawalTimelineView`):
/// one withdrawal per row (year, spouse, pillar, amount, estimated tax),
/// then the total, the "all in the same year" tax and the savings achieved.
/// Tax-year anti-collision calculated server-side.
class _WithdrawalPlanCard extends StatelessWidget {
  const _WithdrawalPlanCard({required this.plan});

  final CoupleWithdrawalPlanDto plan;

  String _spouseLabel(AppLocalizations l10n, String spouse) => switch (spouse) {
    'person1' => l10n.coupleYou,
    'person2' => l10n.couplePartner,
    _ => l10n.coupleSectionTitle,
  };

  String _pillarLabel(AppLocalizations l10n, String pillar) => switch (pillar) {
    'pillar3a' => l10n.coupleWithdraw3a,
    _ => l10n.coupleWithdrawBvg,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScenarioSectionTitle(l10n.coupleWithdrawalTitle),
          const SizedBox(height: 12),
          if (plan.steps.isEmpty)
            Text(
              l10n.coupleWithdrawalEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            for (var i = 0; i < plan.steps.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              Row(
                children: [
                  Text(
                    '${plan.steps[i].year}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _spouseLabel(l10n, plan.steps[i].spouse),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _pillarLabel(l10n, plan.steps[i].pillar),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    formatChf(plan.steps[i].amount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (plan.steps[i].estimatedTax > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      l10n.coupleTaxEstimate(
                        formatChf(plan.steps[i].estimatedTax),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const Divider(height: 24),
            ScenarioMetricRow(
              label: l10n.coupleWithdrawalTotalTax,
              value: formatChf(plan.totalEstimatedTax),
            ),
            const SizedBox(height: 8),
            ScenarioMetricRow(
              label: l10n.coupleWithdrawalSimultaneous,
              value: formatChf(plan.simultaneousEstimatedTax),
            ),
            const SizedBox(height: 8),
            ScenarioMetricRow(
              label: l10n.coupleWithdrawalSavings,
              value: formatChf(plan.taxSavingsVsSimultaneous),
              valueColor: plan.taxSavingsVsSimultaneous > 0
                  ? colors.positive
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
