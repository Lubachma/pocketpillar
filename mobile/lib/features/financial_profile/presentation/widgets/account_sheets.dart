import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/theme/components/primary_button.dart';
import '../../../../core/utils/currency.dart';
import '../../../calculator/presentation/widgets/help_sheet.dart';
import '../../../premium/application/premium_providers.dart';
import '../../data/financial_profile_dtos.dart';
import '../profile_form_validators.dart';
import 'ocr_scan_sheet.dart';

/// Result of the LPP account form (amounts in **centimes**).
class Pillar2AccountFormResult {
  const Pillar2AccountFormResult({
    this.providerName,
    required this.currentCapital,
    this.conversionRate,
    this.annualBvgContribution,
    this.insuredSalary,
    this.coordinationDeduction,
    this.annualSupraContribution,
    required this.isVestedBenefits,
  });

  final String? providerName;
  final int currentCapital;
  final double? conversionRate;
  final int? annualBvgContribution;

  /// Insured salary, in centimes ("advanced" section).
  final int? insuredSalary;

  /// Coordination deduction, in centimes ("advanced" section).
  final int? coordinationDeduction;

  /// Annual supra-mandatory contribution, in centimes ("advanced" section).
  final int? annualSupraContribution;

  final bool isVestedBenefits;
}

/// Result of the 3a account form (amounts in **centimes**).
class Pillar3aAccountFormResult {
  const Pillar3aAccountFormResult({
    required this.providerName,
    required this.accountType,
    required this.currentBalance,
    this.annualContribution,
    this.interestRateOrReturn,
  });

  final String providerName;
  final String accountType;
  final int currentBalance;
  final int? annualContribution;
  final double? interestRateOrReturn;
}

/// Add/edit sheet for an LPP account (`account` null = creation).
/// Validates then returns a [Pillar2AccountFormResult] via
/// `Navigator.pop`; the caller performs the API call.
class Pillar2AccountSheet extends ConsumerStatefulWidget {
  const Pillar2AccountSheet({this.account, super.key});

  final Pillar2AccountDto? account;

  static Future<Pillar2AccountFormResult?> show(
    BuildContext context, {
    Pillar2AccountDto? account,
  }) {
    return showModalBottomSheet<Pillar2AccountFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Pillar2AccountSheet(account: account),
      ),
    );
  }

  @override
  ConsumerState<Pillar2AccountSheet> createState() =>
      _Pillar2AccountSheetState();
}

class _Pillar2AccountSheetState extends ConsumerState<Pillar2AccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _advancedTileController = ExpansibleController();
  late final TextEditingController _providerController;
  late final TextEditingController _capitalController;
  late final TextEditingController _conversionRateController;
  late final TextEditingController _contributionController;
  late final TextEditingController _insuredSalaryController;
  late final TextEditingController _coordinationDeductionController;
  late final TextEditingController _supraContributionController;
  late bool _isVestedBenefits;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _providerController = TextEditingController(text: account?.providerName);
    _capitalController = TextEditingController(
      text: account != null ? centimesToChfInput(account.currentCapital) : '',
    );
    _conversionRateController = TextEditingController(
      text: account?.conversionRate?.toString() ?? '',
    );
    _contributionController = TextEditingController(
      text: account?.annualBvgContribution != null
          ? centimesToChfInput(account!.annualBvgContribution!)
          : '',
    );
    _insuredSalaryController = TextEditingController(
      text: account?.insuredSalary != null
          ? centimesToChfInput(account!.insuredSalary!)
          : '',
    );
    _coordinationDeductionController = TextEditingController(
      text: account?.coordinationDeduction != null
          ? centimesToChfInput(account!.coordinationDeduction!)
          : '',
    );
    _supraContributionController = TextEditingController(
      text: account?.annualSupraContribution != null
          ? centimesToChfInput(account!.annualSupraContribution!)
          : '',
    );
    _isVestedBenefits = account?.isVestedBenefits ?? false;
  }

  @override
  void dispose() {
    _advancedTileController.dispose();
    _providerController.dispose();
    _capitalController.dispose();
    _conversionRateController.dispose();
    _contributionController.dispose();
    _insuredSalaryController.dispose();
    _coordinationDeductionController.dispose();
    _supraContributionController.dispose();
    super.dispose();
  }

  /// True if an advanced field is non-empty but invalid (e.g. negative).
  /// A collapsed ExpansionTile removes its FormFields from the tree:
  /// [_formKey]'s inline validation then no longer covers them.
  bool _advancedInvalid() =>
      [
        _insuredSalaryController.text,
        _coordinationDeductionController.text,
        _supraContributionController.text,
      ].any(
        (text) =>
            validateMoneyField(context.l10n, text, required: false) != null,
      );

  /// OCR scan of an LPP statement (on-device): the proposed values
  /// fill the fields **without validating the sheet** — the user
  /// verifies then saves via "Save". The advanced section expands if
  /// an insured salary is applied.
  ///
  /// Premium feature (app-side gate, contract §11): non-subscriber →
  /// paywall (on top of the sheet, which stays open).
  Future<void> _scanLppStatement() async {
    if (!ref.read(premiumActiveProvider)) {
      await context.push(Routes.paywall);
      return;
    }
    if (!mounted) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await OcrScanSheet.show(
      context,
      kind: OcrScanKind.lppStatement,
    );
    if (result == null || !mounted) return;
    var applied = false;
    setState(() {
      if (result.currentCapital case final capital?) {
        _capitalController.text = centimesToChfInput(capital);
        applied = true;
      }
      if (result.insuredSalary case final insured?) {
        _insuredSalaryController.text = centimesToChfInput(insured);
        applied = true;
      }
      if (result.annualContribution case final contribution?) {
        _contributionController.text = centimesToChfInput(contribution);
        applied = true;
      }
    });
    if (!applied) return;
    if (result.insuredSalary != null) _advancedTileController.expand();
    messenger.showSnackBar(SnackBar(content: Text(l10n.ocrApplied)));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // Collapsed-section guard: blocks client-side (never a server
    // 400), expands the section then revalidates to show the inline
    // error once the fields are back in the tree.
    if (_advancedInvalid()) {
      _advancedTileController.expand();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
      return;
    }
    Navigator.of(context).pop(
      Pillar2AccountFormResult(
        providerName: _providerController.text.trim().isEmpty
            ? null
            : _providerController.text.trim(),
        currentCapital: parseChfToCentimes(_capitalController.text)!,
        conversionRate: tryParsePercentField(_conversionRateController.text),
        annualBvgContribution: tryParseMoneyField(_contributionController.text),
        insuredSalary: tryParseMoneyField(_insuredSalaryController.text),
        coordinationDeduction: tryParseMoneyField(
          _coordinationDeductionController.text,
        ),
        annualSupraContribution: tryParseMoneyField(
          _supraContributionController.text,
        ),
        isVestedBenefits: _isVestedBenefits,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.account == null
                  ? l10n.profilePillar2New
                  : l10n.profilePillar2Edit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // Assistive OCR scan of an LPP statement (prefills without
            // validating). Premium: lock icon for non-subscribers (tap
            // → paywall). Native only (Vision/ML Kit) — hidden on web.
            if (!kIsWeb)
              OutlinedButton.icon(
                onPressed: _scanLppStatement,
                icon: Icon(
                  ref.watch(premiumActiveProvider)
                      ? Icons.document_scanner_outlined
                      : Icons.lock_outline,
                ),
                label: Text(l10n.ocrScanLppButton),
              ),
            const SizedBox(height: 16),
            AppTextField(
              label: l10n.profileProviderName,
              controller: _providerController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: l10n.profileCurrentCapital,
              controller: _capitalController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  validateMoneyField(l10n, value, required: true),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: l10n.profileConversionRate,
                    controller: _conversionRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        validatePercentField(l10n, value, min: 0, max: 100),
                  ),
                ),
                // 6.8% = legal minimum on the mandatory part only — the
                // sheet explains where the certificate rate lives
                // (practitioner review 08.2026).
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: HelpButton(termId: 'conversion_rate'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: l10n.profileAnnualContribution,
                    controller: _contributionController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        validateMoneyField(l10n, value, required: false),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: HelpButton(termId: 'annual_contribution'),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.profileVestedBenefits),
              value: _isVestedBenefits,
              onChanged: (value) => setState(() => _isVestedBenefits = value),
            ),
            // Advanced fields (LPP certificate): optional, collapsible.
            ExpansionTile(
              controller: _advancedTileController,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(l10n.profileAdvancedSection),
              children: [
                AppTextField(
                  label: l10n.profileInsuredSalary,
                  controller: _insuredSalaryController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      validateMoneyField(l10n, value, required: false),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: l10n.profileCoordinationDeduction,
                  controller: _coordinationDeductionController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      validateMoneyField(l10n, value, required: false),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: l10n.profileAnnualSupraContribution,
                  controller: _supraContributionController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      validateMoneyField(l10n, value, required: false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: l10n.commonSave, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

/// Add/edit sheet for a 3a account (`account` null = creation).
/// Validates then returns a [Pillar3aAccountFormResult] via `Navigator.pop`.
class Pillar3aAccountSheet extends StatefulWidget {
  const Pillar3aAccountSheet({this.account, super.key});

  final Pillar3aAccountDto? account;

  static Future<Pillar3aAccountFormResult?> show(
    BuildContext context, {
    Pillar3aAccountDto? account,
  }) {
    return showModalBottomSheet<Pillar3aAccountFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Pillar3aAccountSheet(account: account),
      ),
    );
  }

  @override
  State<Pillar3aAccountSheet> createState() => _Pillar3aAccountSheetState();
}

class _Pillar3aAccountSheetState extends State<Pillar3aAccountSheet> {
  static const _accountTypes = ['BANK', 'INSURANCE'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _providerController;
  late final TextEditingController _balanceController;
  late final TextEditingController _contributionController;
  late final TextEditingController _rateController;
  late String _accountType;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _providerController = TextEditingController(text: account?.providerName);
    _accountType = account?.accountType ?? 'BANK';
    _balanceController = TextEditingController(
      text: account != null ? centimesToChfInput(account.currentBalance) : '',
    );
    _contributionController = TextEditingController(
      text: account?.annualContribution != null
          ? centimesToChfInput(account!.annualContribution!)
          : '',
    );
    _rateController = TextEditingController(
      text: account?.interestRateOrReturn?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _providerController.dispose();
    _balanceController.dispose();
    _contributionController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      Pillar3aAccountFormResult(
        providerName: _providerController.text.trim(),
        accountType: _accountType,
        currentBalance: parseChfToCentimes(_balanceController.text)!,
        annualContribution: tryParseMoneyField(_contributionController.text),
        interestRateOrReturn: tryParsePercentField(_rateController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.account == null
                  ? l10n.profilePillar3aNew
                  : l10n.profilePillar3aEdit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: l10n.profileProviderName,
              controller: _providerController,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.profileFieldRequired
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _accountType,
              decoration: InputDecoration(labelText: l10n.profileAccountType),
              items: [
                for (final type in _accountTypes)
                  DropdownMenuItem(
                    value: type,
                    child: Text(
                      type == 'BANK'
                          ? l10n.profileAccountTypeBank
                          : l10n.profileAccountTypeInsurance,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _accountType = value);
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: l10n.profileCurrentBalance,
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  validateMoneyField(l10n, value, required: true),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: l10n.profileAnnualContribution,
              controller: _contributionController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  validateMoneyField(l10n, value, required: false),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: l10n.profileInterestRate,
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  validatePercentField(l10n, value, min: -50, max: 100),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: l10n.commonSave, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
