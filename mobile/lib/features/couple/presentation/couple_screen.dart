import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/components/primary_button.dart';
import '../../../../core/utils/currency.dart';
import '../../calculator/presentation/widgets/wizard_steps.dart';
import '../../financial_profile/application/financial_profile_providers.dart';
import '../../financial_profile/presentation/profile_form_validators.dart';
import '../../premium/presentation/widgets/premium_widgets.dart';
import '../../scenarios/application/scenario_prefill.dart';
import '../../scenarios/presentation/widgets/scenario_widgets.dart';
import 'widgets/couple_form_cards.dart';
import 'widgets/couple_results.dart';
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
  final _conversionRate1Controller = TextEditingController();
  final _balance3a1Controller = TextEditingController();
  int _age1 = _defaultSpouseAge;
  bool _has3a1 = false;

  // Spouse 2 ("Partner") — free-form entry.
  final _income2Controller = TextEditingController();
  final _pillar2Capital2Controller = TextEditingController();
  final _pillar2Contribution2Controller = TextEditingController();
  final _conversionRate2Controller = TextEditingController();
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
    _conversionRate1Controller.dispose();
    _balance3a1Controller.dispose();
    _income2Controller.dispose();
    _pillar2Capital2Controller.dispose();
    _pillar2Contribution2Controller.dispose();
    _conversionRate2Controller.dispose();
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
              conversionRate: tryParsePercentField(
                _conversionRate1Controller.text,
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
              conversionRate: tryParsePercentField(
                _conversionRate2Controller.text,
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
          CoupleSituationCard(
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
          CoupleSpouseFormCard(
            title: l10n.coupleYou,
            age: _age1,
            onAgeChanged: (value) => setState(() => _age1 = value),
            incomeController: _income1Controller,
            pillar2CapitalController: _pillar2Capital1Controller,
            pillar2ContributionController: _pillar2Contribution1Controller,
            conversionRateController: _conversionRate1Controller,
            has3a: _has3a1,
            has3aLabel: l10n.profileHas3a,
            onHas3aChanged: (value) => setState(() => _has3a1 = value),
            balance3aController: _balance3a1Controller,
            onSubmitted: _submit,
          ),
          const SizedBox(height: 16),
          CoupleSpouseFormCard(
            title: l10n.couplePartner,
            age: _age2,
            onAgeChanged: (value) => setState(() => _age2 = value),
            incomeController: _income2Controller,
            pillar2CapitalController: _pillar2Capital2Controller,
            pillar2ContributionController: _pillar2Contribution2Controller,
            conversionRateController: _conversionRate2Controller,
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
            CoupleResultsSection(result: _result!),
        ],
      ),
    );
  }
}
