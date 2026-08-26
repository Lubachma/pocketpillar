import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/theme/components/canton_picker_sheet.dart';
import '../../../../core/theme/components/primary_button.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/swiss_canton.dart';
import '../../../financial_profile/presentation/widgets/municipality_picker_sheet.dart';
import '../../application/guided_calculator_controller.dart';
import '../../data/calculator_payloads.dart';
import 'help_sheet.dart';

/// Backend upper bound: 10¹¹ centimes = CHF 1 billion (same bound as
/// the financial profile validators).
const int _maxMoneyCentimes = 100000000000;

/// Shared CHF validation for the steps: [required] enforces an input,
/// [allowZero] false enforces a strictly positive amount (Zod bounds
/// `positive()` / `nonnegative()` of the calculator schemas).
String? validateChfField(
  AppLocalizations l10n,
  String? value, {
  required bool required,
  bool allowZero = true,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return required ? l10n.profileFieldRequired : null;
  final centimes = parseChfToCentimes(text);
  if (centimes == null ||
      centimes < 0 ||
      (!allowZero && centimes == 0) ||
      centimes > _maxMoneyCentimes) {
    return l10n.profileAmountInvalid;
  }
  return null;
}

/// CHF entered → centimes; empty field → 0 (optional fields).
int chfFieldToCentimes(String? value) =>
    parseChfToCentimes(value?.trim() ?? '') ?? 0;

/// Step header (icon + title + subtitle) — equivalent to iOS's
/// `stepHeader`.
class StepHeader extends StatelessWidget {
  const StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Column(
      children: [
        Icon(icon, size: 44, color: accent),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Wizard navigation buttons (optional Back + primary action).
class StepNavigation extends StatelessWidget {
  const StepNavigation({
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.primaryLoading = false,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;
  final bool primaryLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = PrimaryButton(
      label: primaryLabel,
      onPressed: onPrimary,
      isLoading: primaryLoading,
    );
    if (onBack == null) return primary;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: primaryLoading ? null : onBack,
            child: Text(l10n.guidedBack),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: primary),
      ],
    );
  }
}

/// Step 1 — situation: age (slider 18–64), canton (picker), marital
/// status (5 options — the profile prefill can produce
/// DIVORCED/WIDOWED, unlike iOS's 3 options).
class SituationStep extends ConsumerWidget {
  const SituationStep({super.key});

  static const _maritalStatuses = [
    'SINGLE',
    'MARRIED',
    'REGISTERED_PARTNERSHIP',
    'DIVORCED',
    'WIDOWED',
  ];

  String _maritalLabel(AppLocalizations l10n, String status) =>
      switch (status) {
        'SINGLE' => l10n.guidedMaritalSingle,
        'MARRIED' => l10n.guidedMaritalMarried,
        'REGISTERED_PARTNERSHIP' => l10n.guidedMaritalPartnership,
        'DIVORCED' => l10n.profileMaritalDivorced,
        _ => l10n.profileMaritalWidowed,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(guidedCalculatorControllerProvider);
    final controller = ref.read(guidedCalculatorControllerProvider.notifier);
    final languageCode = Localizations.localeOf(context).languageCode;

    final canton = swissCantons
        .where((c) => c.code == state.canton)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StepHeader(
          icon: Icons.person,
          title: l10n.guidedSituationTitle,
          subtitle: l10n.guidedSituationSubtitle,
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            children: [
              Text(
                '${state.age}',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.guidedAgeYears,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Slider(
                value: state.age.toDouble(),
                min: calculatorMinAge.toDouble(),
                max: calculatorMaxAge.toDouble(),
                divisions: calculatorMaxAge - calculatorMinAge,
                label: '${state.age}',
                onChanged: (value) =>
                    controller.updateSituation(age: value.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            title: Text(l10n.calculatorCanton),
            subtitle: canton != null
                ? Text(canton.displayName(languageCode))
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final code = await CantonPickerSheet.show(
                context,
                selectedCode: state.canton,
              );
              if (code != null) controller.updateSituation(canton: code);
            },
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            title: Text(l10n.profileMunicipality),
            subtitle: Text(
              state.municipality ?? l10n.municipalityCantonalAverageOption,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final name = await MunicipalityPickerSheet.show(
                context,
                cantonCode: state.canton,
                selectedName: state.municipality,
              );
              if (name != null) {
                // "Cantonal average" sentinel → deselection (null).
                if (name == municipalityCantonalAverageSentinel) {
                  controller.updateSituation(clearMunicipality: true);
                } else {
                  controller.updateSituation(municipality: name);
                }
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  l10n.guidedMaritalTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              for (final status in _maritalStatuses)
                _OptionRow(
                  label: _maritalLabel(l10n, status),
                  selected: state.maritalStatus == status,
                  onTap: () =>
                      controller.updateSituation(maritalStatus: status),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        StepNavigation(
          primaryLabel: l10n.guidedNext,
          onPrimary: controller.nextStep,
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected
                  ? accent
                  : Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 2 — income: gross annual salary in CHF (required, > 0 — schema
/// `positive()` bound). Never expose centimes.
class IncomeStep extends ConsumerStatefulWidget {
  const IncomeStep({super.key});

  @override
  ConsumerState<IncomeStep> createState() => _IncomeStepState();
}

class _IncomeStepState extends ConsumerState<IncomeStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _incomeController;

  @override
  void initState() {
    super.initState();
    final income = ref
        .read(guidedCalculatorControllerProvider)
        .grossAnnualIncome;
    _incomeController = TextEditingController(
      text: income != null ? centimesToChfInput(income) : '',
    );
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(guidedCalculatorControllerProvider.notifier);
    controller.updateIncome(chfFieldToCentimes(_incomeController.text));
    controller.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = ref.read(guidedCalculatorControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StepHeader(
          icon: Icons.paid,
          title: l10n.guidedSalaryTitle,
          subtitle: l10n.guidedSalarySubtitle,
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: l10n.calculatorGrossIncome,
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
                    onFieldSubmitted: (_) => _next(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: HelpButton(termId: 'gross_income'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        StepNavigation(
          primaryLabel: l10n.guidedNext,
          onPrimary: _next,
          onBack: controller.previousStep,
        ),
      ],
    );
  }
}

/// Step 3 — 2nd pillar: LPP capital and annual contribution in CHF
/// (optional, ≥ 0, empty = 0).
class Pillar2Step extends ConsumerStatefulWidget {
  const Pillar2Step({super.key});

  @override
  ConsumerState<Pillar2Step> createState() => _Pillar2StepState();
}

class _Pillar2StepState extends ConsumerState<Pillar2Step> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _capitalController;
  late final TextEditingController _contributionController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(guidedCalculatorControllerProvider);
    _capitalController = TextEditingController(
      text: state.pillar2Capital > 0
          ? centimesToChfInput(state.pillar2Capital)
          : '',
    );
    _contributionController = TextEditingController(
      text: state.pillar2Contribution > 0
          ? centimesToChfInput(state.pillar2Contribution)
          : '',
    );
  }

  @override
  void dispose() {
    _capitalController.dispose();
    _contributionController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(guidedCalculatorControllerProvider.notifier);
    controller.updatePillar2(
      capital: chfFieldToCentimes(_capitalController.text),
      contribution: chfFieldToCentimes(_contributionController.text),
    );
    controller.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = ref.read(guidedCalculatorControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StepHeader(
          icon: Icons.business,
          title: l10n.guidedPillar2Title,
          subtitle: l10n.guidedPillar2Subtitle,
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: l10n.calculatorBvgCapital,
                        controller: _capitalController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            validateChfField(l10n, value, required: false),
                        onFieldSubmitted: (_) => _next(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: HelpButton(termId: 'bvg_capital'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.calculatorAnnualContribution,
                  controller: _contributionController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      validateChfField(l10n, value, required: false),
                  onFieldSubmitted: (_) => _next(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        StepNavigation(
          primaryLabel: l10n.guidedNext,
          onPrimary: _next,
          onBack: controller.previousStep,
        ),
      ],
    );
  }
}

/// Step 4 — 3a pillar: yes/no + balance in CHF (if yes). "See my
/// results" launches the calculations (loading state on the button).
class Pillar3aStep extends ConsumerStatefulWidget {
  const Pillar3aStep({super.key});

  @override
  ConsumerState<Pillar3aStep> createState() => _Pillar3aStepState();
}

class _Pillar3aStepState extends ConsumerState<Pillar3aStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(guidedCalculatorControllerProvider);
    _balanceController = TextEditingController(
      text: state.pillar3aBalance > 0
          ? centimesToChfInput(state.pillar3aBalance)
          : '',
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  void _finish() {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(guidedCalculatorControllerProvider.notifier);
    controller.updatePillar3a(
      has: ref.read(guidedCalculatorControllerProvider).hasPillar3a,
      balance: chfFieldToCentimes(_balanceController.text),
    );
    controller.calculate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(guidedCalculatorControllerProvider);
    final controller = ref.read(guidedCalculatorControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StepHeader(
          icon: Icons.payments,
          title: l10n.guided3aTitle,
          subtitle: l10n.guided3aSubtitle,
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.guided3aQuestion,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const HelpButton(termId: 'pillar_3a'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ToggleButton(
                        label: l10n.guidedYes,
                        selected: state.hasPillar3a,
                        onTap: () => controller.updatePillar3a(
                          has: true,
                          balance: chfFieldToCentimes(_balanceController.text),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToggleButton(
                        label: l10n.guidedNo,
                        selected: !state.hasPillar3a,
                        onTap: () =>
                            controller.updatePillar3a(has: false, balance: 0),
                      ),
                    ),
                  ],
                ),
                if (state.hasPillar3a) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: l10n.guided3aBalance,
                    controller: _balanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        validateChfField(l10n, value, required: false),
                    onFieldSubmitted: (_) => _finish(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        StepNavigation(
          primaryLabel: l10n.guidedSeeResults,
          onPrimary: _finish,
          onBack: controller.previousStep,
          primaryLoading: state.calculating,
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? accent
                : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
