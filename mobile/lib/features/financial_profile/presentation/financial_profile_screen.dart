import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/components/app_card.dart';
import '../../../core/theme/components/app_text_field.dart';
import '../../../core/theme/components/canton_picker_sheet.dart';
import '../../../core/theme/components/primary_button.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/debug_log.dart';
import '../../../core/utils/swiss_canton.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../premium/application/premium_providers.dart';
import '../application/financial_profile_providers.dart';
import '../data/financial_profile_dtos.dart';
import '../data/financial_profile_repository.dart';
import '../../calculator/presentation/widgets/help_sheet.dart';
import 'profile_form_validators.dart';
import 'widgets/account_sheets.dart';
import 'widgets/municipality_picker_sheet.dart';
import 'widgets/ocr_scan_sheet.dart';

/// Localized error message: network → generic message, otherwise the
/// backend's `{ error }` message (already localized via Accept-Language).
String _errorMessage(AppLocalizations l10n, Object error) => switch (error) {
  NetworkException() => l10n.errorNetwork,
  ApiException(:final message) => message,
  _ => l10n.errorUnknown,
};

/// Financial profile (`/settings/profile`): canton, birth year,
/// replacement rate goal (`PATCH /users/me`), financial situation
/// (`PUT /financial-profile` — created on first submit, contract
/// §4), and LPP/3a accounts (CRUD `financial-profile/pillar2|pillar3a`).
class FinancialProfileScreen extends ConsumerWidget {
  const FinancialProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final base = ref.watch(profileBaseProvider);
    final data = base.valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.financialProfileTitle)),
      body: data != null
          ? ProfileForm(key: ValueKey(data.loadedAt), data: data)
          : base.hasError
          ? _ErrorBody(
              message: _errorMessage(l10n, base.error!),
              onRetry: () => ref.invalidate(profileAggregateProvider),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Profile form — rebuilt (key `loadedAt`) when data is reloaded,
/// never while typing.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({required this.data, super.key});

  final ProfileBaseData data;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  static const _employmentStatuses = [
    'EMPLOYED',
    'SELF_EMPLOYED',
    'UNEMPLOYED',
    'RETIRED',
  ];
  static const _maritalStatuses = [
    'SINGLE',
    'MARRIED',
    'REGISTERED_PARTNERSHIP',
    'DIVORCED',
    'WIDOWED',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _birthYearController;
  late final TextEditingController _childrenController;
  late final TextEditingController _grossIncomeController;
  late final TextEditingController _netIncomeController;
  late String? _canton;
  late String? _municipality;
  late double _replacementRateGoal;
  late String _employmentStatus;
  late String _maritalStatus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    final profile = data.profile;
    _canton = data.canton;
    _municipality = data.municipality;
    _birthYearController = TextEditingController(
      text: data.birthYear?.toString() ?? '',
    );
    _replacementRateGoal = data.replacementRateGoal.toDouble();
    _employmentStatus = profile?.employmentStatus ?? 'EMPLOYED';
    _maritalStatus = profile?.maritalStatus ?? 'SINGLE';
    _childrenController = TextEditingController(
      text: (profile?.numberOfChildren ?? 0).toString(),
    );
    _grossIncomeController = TextEditingController(
      text: profile != null ? centimesToChfInput(profile.grossAnnualIncome) : '',
    );
    _netIncomeController = TextEditingController(
      text: profile?.netAnnualIncome != null
          ? centimesToChfInput(profile!.netAnnualIncome!)
          : '',
    );
  }

  @override
  void dispose() {
    _birthYearController.dispose();
    _childrenController.dispose();
    _grossIncomeController.dispose();
    _netIncomeController.dispose();
    super.dispose();
  }

  String _employmentLabel(AppLocalizations l10n, String status) =>
      switch (status) {
        'EMPLOYED' => l10n.profileEmploymentEmployed,
        'SELF_EMPLOYED' => l10n.profileEmploymentSelfEmployed,
        'UNEMPLOYED' => l10n.profileEmploymentUnemployed,
        _ => l10n.profileEmploymentRetired,
      };

  String _maritalLabel(AppLocalizations l10n, String status) =>
      switch (status) {
        'SINGLE' => l10n.guidedMaritalSingle,
        'MARRIED' => l10n.guidedMaritalMarried,
        // Contract value: REGISTERED_PARTNERSHIP (iOS used to emit
        // PARTNERSHIP, rejected with 400 — iOS bug fixed at port time).
        'REGISTERED_PARTNERSHIP' => l10n.guidedMaritalPartnership,
        'DIVORCED' => l10n.profileMaritalDivorced,
        _ => l10n.profileMaritalWidowed,
      };

  Future<void> _pickCanton() async {
    final code = await CantonPickerSheet.show(context, selectedCode: _canton);
    if (code != null && code != _canton) {
      setState(() {
        _canton = code;
        // The municipality depends on the canton: the previous
        // selection no longer applies to the new canton.
        _municipality = null;
      });
    }
  }

  Future<void> _pickMunicipality() async {
    final canton = _canton;
    if (canton == null) return;
    final name = await MunicipalityPickerSheet.show(
      context,
      cantonCode: canton,
      selectedName: _municipality,
    );
    if (name != null) {
      setState(() {
        // "Cantonal average" sentinel → deselection (null).
        _municipality =
            name == municipalityCantonalAverageSentinel ? null : name;
      });
    }
  }

  /// OCR scan of a salary certificate (on-device): the proposed value
  /// fills the gross income field **without saving** — the user
  /// verifies then saves via the form's button.
  ///
  /// Premium feature (app-side gate, contract §11): non-subscriber →
  /// paywall.
  Future<void> _scanSalaryCertificate() async {
    if (!ref.read(premiumActiveProvider)) {
      await context.push(Routes.paywall);
      return;
    }
    if (!mounted) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await OcrScanSheet.show(
      context,
      kind: OcrScanKind.salaryCertificate,
    );
    final gross = result?.grossAnnualIncome;
    if (gross == null || !mounted) return;
    setState(() => _grossIncomeController.text = centimesToChfInput(gross));
    messenger.showSnackBar(SnackBar(content: Text(l10n.ocrApplied)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final repository = ref.read(financialProfileRepositoryProvider);
      await Future.wait([
        repository.updateUser(
          canton: _canton,
          birthYear: int.tryParse(_birthYearController.text.trim()),
          replacementRateGoal: _replacementRateGoal.round(),
          municipality: _municipality,
          // Municipality cleared (e.g. canton change) while a value
          // was saved → explicit null, the only clearing method
          // accepted by the backend.
          clearMunicipality:
              _municipality == null && widget.data.municipality != null,
        ),
        repository.upsertProfile(
          employmentStatus: _employmentStatus,
          maritalStatus: _maritalStatus,
          numberOfChildren: int.parse(_childrenController.text.trim()),
          grossAnnualIncome: parseChfToCentimes(
            _grossIncomeController.text,
          )!,
          netAnnualIncome: parseChfToCentimes(_netIncomeController.text),
        ),
      ]);
      // The screen may have been left during saving: `ref` is then no
      // longer usable (disposed). NB: in a State method, it's the
      // `mounted` getter (not `context.mounted`) — accessing `context`
      // after unmount throws.
      if (!mounted) return;
      // The shared aggregate (I9) reloads the 4 endpoints; the
      // dashboard (projection, recommendations) derives from it via
      // its watches.
      ref
        ..invalidate(profileAggregateProvider)
        ..invalidate(recommendationsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorNetwork)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final canton = findSwissCanton(_canton);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Personal information (PATCH /users/me) ──────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileSectionPersonal,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.profileCanton),
                  subtitle: Text(
                    canton?.displayName(languageCode) ??
                        l10n.profileSelectCanton,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickCanton,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.profileMunicipality),
                  subtitle: Text(
                    _municipality ??
                        (_canton == null
                            ? l10n.municipalitySelectCantonFirst
                            : l10n.municipalityCantonalAverageOption),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  // Without a canton, the municipality list is undetermined.
                  onTap: _canton == null ? null : _pickMunicipality,
                ),
                AppTextField(
                  label: l10n.profileBirthYear,
                  controller: _birthYearController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) => validateBirthYearField(l10n, value),
                ),
                const SizedBox(height: 16),
                Text(
                  '${l10n.profileTargetRate} : '
                  '${_replacementRateGoal.round()} %',
                ),
                Slider(
                  value: _replacementRateGoal,
                  min: 50,
                  max: 100,
                  divisions: 10,
                  label: '${_replacementRateGoal.round()} %',
                  onChanged: (value) =>
                      setState(() => _replacementRateGoal = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Financial situation (PUT /financial-profile) ──────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileSectionSituation,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _employmentStatus,
                  decoration: InputDecoration(
                    labelText: l10n.profileEmploymentStatus,
                  ),
                  items: [
                    for (final status in _employmentStatuses)
                      DropdownMenuItem(
                        value: status,
                        child: Text(_employmentLabel(l10n, status)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _employmentStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _maritalStatus,
                  decoration: InputDecoration(
                    labelText: l10n.profileMaritalStatus,
                  ),
                  items: [
                    for (final status in _maritalStatuses)
                      DropdownMenuItem(
                        value: status,
                        child: Text(_maritalLabel(l10n, status)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _maritalStatus = value);
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: l10n.profileChildren,
                  controller: _childrenController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) => validateChildrenField(l10n, value),
                ),
                const SizedBox(height: 12),
                // Assistive OCR scan: proposes the gross salary from
                // the certificate, the user confirms (nothing is saved
                // here). Premium: lock icon for non-subscribers (tap →
                // paywall). Native only (Vision/ML Kit) — hidden on web.
                if (!kIsWeb)
                  OutlinedButton.icon(
                    onPressed: _scanSalaryCertificate,
                    icon: Icon(
                      ref.watch(premiumActiveProvider)
                          ? Icons.document_scanner_outlined
                          : Icons.lock_outline,
                    ),
                    label: Text(l10n.ocrScanSalaryButton),
                  ),
                const SizedBox(height: 12),
                AppTextField(
                  label: l10n.profileGrossAnnualIncome,
                  controller: _grossIncomeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      validateMoneyField(l10n, value, required: true),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: l10n.profileNetAnnualIncome,
                  controller: _netIncomeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      validateMoneyField(l10n, value, required: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── LPP / 3a accounts (CRUD, standalone sections) ─────────
          const _Pillar2Section(),
          const SizedBox(height: 16),
          const _Pillar3aSection(),
          const SizedBox(height: 24),

          PrimaryButton(
            label: l10n.commonSave,
            onPressed: _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}

/// "LPP accounts" section: list + add/edit/delete. States
/// (loading/error) local to the card — the form isn't rebuilt when
/// the section reloads.
class _Pillar2Section extends ConsumerWidget {
  const _Pillar2Section();

  Future<void> _editAccount(
    BuildContext context,
    WidgetRef ref, {
    Pillar2AccountDto? account,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await Pillar2AccountSheet.show(context, account: account);
    if (result == null || !context.mounted) return;
    try {
      final repository = ref.read(financialProfileRepositoryProvider);
      if (account == null) {
        await repository.createPillar2Account(
          providerName: result.providerName,
          currentCapital: result.currentCapital,
          conversionRate: result.conversionRate,
          annualBvgContribution: result.annualBvgContribution,
          insuredSalary: result.insuredSalary,
          coordinationDeduction: result.coordinationDeduction,
          annualSupraContribution: result.annualSupraContribution,
          isVestedBenefits: result.isVestedBenefits,
        );
      } else {
        await repository.updatePillar2Account(
          account.id,
          providerName: result.providerName,
          currentCapital: result.currentCapital,
          conversionRate: result.conversionRate,
          annualBvgContribution: result.annualBvgContribution,
          insuredSalary: result.insuredSalary,
          coordinationDeduction: result.coordinationDeduction,
          annualSupraContribution: result.annualSupraContribution,
          isVestedBenefits: result.isVestedBenefits,
        );
      }
      if (!context.mounted) return;
      // Targeted section reload (I9): the aggregate's base — and thus
      // the form — isn't rebuilt; the dashboard rebuilds via its watch
      // of the aggregate. Silent on failure (2026-08 review, minor
      // #6): the CRUD succeeded — the aggregate will resync on the
      // next invalidation, no misleading error snackbar.
      try {
        await ref
            .read(profileAggregateProvider.notifier)
            .refreshPillar2Accounts();
      } on Object catch (e) {
        debugLog('LPP accounts reload after CRUD failed: $e');
      }
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileAccountSaved)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorNetwork)));
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    Pillar2AccountDto account,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileDeleteAccountTitle),
        content: Text(l10n.profileDeleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.authCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.docDelete,
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(financialProfileRepositoryProvider)
          .deletePillar2Account(account.id);
      if (!context.mounted) return;
      try {
        await ref
            .read(profileAggregateProvider.notifier)
            .refreshPillar2Accounts();
      } on Object catch (e) {
        debugLog('LPP accounts reload after delete failed: $e');
      }
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileAccountDeleted)),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorNetwork)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accounts = ref.watch(pillar2AccountsProvider);
    final list = accounts.valueOrNull;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.profileSectionPillar2,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const HelpButton(termId: 'pillar_2_bvg'),
            ],
          ),
          if (list != null)
            list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(l10n.profileEmptyPillar2),
                  )
                : Column(
                    children: [
                      for (final account in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            account.providerName ??
                                l10n.profilePillar2DefaultName,
                          ),
                          subtitle: Text(
                            [
                              formatChf(account.currentCapital),
                              if (account.isVestedBenefits)
                                l10n.profileVestedBenefits,
                            ].join(' · '),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: l10n.docDelete,
                            onPressed: () =>
                                _deleteAccount(context, ref, account),
                          ),
                          onTap: () =>
                              _editAccount(context, ref, account: account),
                        ),
                    ],
                  )
          else if (accounts.hasError)
            _SectionError(
              message: _errorMessage(l10n, accounts.error!),
              onRetry: () => ref.invalidate(profileAggregateProvider),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          TextButton.icon(
            onPressed: () => _editAccount(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.profileAddPillar2),
          ),
        ],
      ),
    );
  }
}

/// "3a accounts" section — same pattern as [_Pillar2Section].
class _Pillar3aSection extends ConsumerWidget {
  const _Pillar3aSection();

  Future<void> _editAccount(
    BuildContext context,
    WidgetRef ref, {
    Pillar3aAccountDto? account,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await Pillar3aAccountSheet.show(context, account: account);
    if (result == null || !context.mounted) return;
    try {
      final repository = ref.read(financialProfileRepositoryProvider);
      if (account == null) {
        await repository.createPillar3aAccount(
          providerName: result.providerName,
          accountType: result.accountType,
          currentBalance: result.currentBalance,
          annualContribution: result.annualContribution,
          interestRateOrReturn: result.interestRateOrReturn,
        );
      } else {
        await repository.updatePillar3aAccount(
          account.id,
          providerName: result.providerName,
          accountType: result.accountType,
          currentBalance: result.currentBalance,
          annualContribution: result.annualContribution,
          interestRateOrReturn: result.interestRateOrReturn,
        );
      }
      if (!context.mounted) return;
      try {
        await ref
            .read(profileAggregateProvider.notifier)
            .refreshPillar3aAccounts();
      } on Object catch (e) {
        debugLog('3a accounts reload after CRUD failed: $e');
      }
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileAccountSaved)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorNetwork)));
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    Pillar3aAccountDto account,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileDeleteAccountTitle),
        content: Text(l10n.profileDeleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.authCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.docDelete,
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(financialProfileRepositoryProvider)
          .deletePillar3aAccount(account.id);
      if (!context.mounted) return;
      try {
        await ref
            .read(profileAggregateProvider.notifier)
            .refreshPillar3aAccounts();
      } on Object catch (e) {
        debugLog('3a accounts reload after delete failed: $e');
      }
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileAccountDeleted)),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorNetwork)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accounts = ref.watch(pillar3aAccountsProvider);
    final list = accounts.valueOrNull;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.profileSectionPillar3a,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const HelpButton(termId: 'pillar_3a'),
            ],
          ),
          if (list != null)
            list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(l10n.profileEmptyPillar3a),
                  )
                : Column(
                    children: [
                      for (final account in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(account.providerName),
                          subtitle: Text(
                            [
                              formatChf(account.currentBalance),
                              account.accountType == 'BANK'
                                  ? l10n.profileAccountTypeBank
                                  : l10n.profileAccountTypeInsurance,
                            ].join(' · '),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: l10n.docDelete,
                            onPressed: () =>
                                _deleteAccount(context, ref, account),
                          ),
                          onTap: () =>
                              _editAccount(context, ref, account: account),
                        ),
                    ],
                  )
          else if (accounts.hasError)
            _SectionError(
              message: _errorMessage(l10n, accounts.error!),
              onRetry: () => ref.invalidate(profileAggregateProvider),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          TextButton.icon(
            onPressed: () => _editAccount(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.profileAddPillar3a),
          ),
        ],
      ),
    );
  }
}

/// Full-screen error body (initial load failed).
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}

/// Inline error for an accounts section, with local retry.
class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
