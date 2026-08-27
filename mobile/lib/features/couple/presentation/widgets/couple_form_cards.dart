import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/utils/swiss_canton.dart';
import '../../../calculator/data/calculator_payloads.dart';
import '../../../calculator/presentation/widgets/help_sheet.dart';
import '../../../calculator/presentation/widgets/wizard_steps.dart';
import '../../../financial_profile/presentation/profile_form_validators.dart';
import '../../../financial_profile/presentation/widgets/municipality_picker_sheet.dart';
import '../../../scenarios/presentation/widgets/scenario_widgets.dart';

/// Input cards of the couple form, extracted from `couple_screen.dart`
/// (readability refactor 08.2026 — the screen file had grown to ~1000
/// lines). Pure widgets: all state stays in the screen.

/// Input card for a spouse: age (slider), gross income, LPP capital,
/// contribution and conversion rate (optional — certificate figure),
/// 3a (switch + balance). CHF validators reused from
/// the calculator (`validateChfField`).
class CoupleSpouseFormCard extends StatelessWidget {
  const CoupleSpouseFormCard({
    required this.title,
    required this.age,
    required this.onAgeChanged,
    required this.incomeController,
    required this.pillar2CapitalController,
    required this.pillar2ContributionController,
    required this.conversionRateController,
    required this.has3a,
    required this.has3aLabel,
    required this.onHas3aChanged,
    required this.balance3aController,
    required this.onSubmitted,
    super.key,
  });

  final String title;
  final int age;
  final ValueChanged<int> onAgeChanged;
  final TextEditingController incomeController;
  final TextEditingController pillar2CapitalController;
  final TextEditingController pillar2ContributionController;
  final TextEditingController conversionRateController;
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) =>
                validateChfField(l10n, value, required: true, allowZero: false),
            onFieldSubmitted: (_) => onSubmitted(),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: l10n.calculatorBvgCapital,
            controller: pillar2CapitalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) =>
                validateChfField(l10n, value, required: false),
            onFieldSubmitted: (_) => onSubmitted(),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: l10n.calculatorAnnualContribution,
                  controller: pillar2ContributionController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      validateChfField(l10n, value, required: false),
                  onFieldSubmitted: (_) => onSubmitted(),
                ),
              ),
              // Employee + employer shares — the sheet spells it out
              // (practitioner review 08.2026).
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: HelpButton(termId: 'annual_contribution'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Optional — empty: the backend applies the 6.8% legal minimum,
          // guaranteed on the mandatory part only (practitioner review
          // 08.2026: 6.8% on the FULL capital overstates the LPP pension).
          AppTextField(
            label: l10n.coupleConversionRate,
            controller: conversionRateController,
            helperText: l10n.coupleConversionRateHint,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) =>
                validatePercentField(l10n, value, min: 0, max: 100),
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

/// "Your situation" card: canton (shared by the couple — taxation at
/// the shared residence), municipality (search picker, actual communal
/// multiplier server-side) and simulated marital status, which drive the
/// tax and the AVS cap server-side.
class CoupleSituationCard extends StatelessWidget {
  const CoupleSituationCard({
    required this.canton,
    required this.onCantonChanged,
    required this.municipality,
    required this.onMunicipalityChanged,
    required this.coupleStatus,
    required this.onStatusChanged,
    required this.statuses,
    super.key,
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
