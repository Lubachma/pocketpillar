import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/theme/components/primary_button.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/native_file_io.dart';
import '../../application/ocr_scan_providers.dart';
import '../../data/ocr_parsing.dart';
import '../../data/scan_image_picker.dart';
import '../profile_form_validators.dart';

/// Type of scanned document — determines which fields are extracted.
enum OcrScanKind { salaryCertificate, lppStatement }

/// Values chosen by the user in the scan sheet (amounts in
/// **centimes**, null = field not detected or cleared). The caller
/// fills its own controllers — **nothing is saved** here (assistive OCR).
class OcrScanResult {
  const OcrScanResult({
    this.grossAnnualIncome,
    this.currentCapital,
    this.insuredSalary,
    this.annualContribution,
  });

  final int? grossAnnualIncome;
  final int? currentCapital;
  final int? insuredSalary;
  final int? annualContribution;
}

enum _Stage { source, scanning, proposal, noText, noValues, error }

/// A detected field, prefilled and editable in the proposal card.
class _ProposedField {
  _ProposedField({required this.key, required this.label, required int value})
    : controller = TextEditingController(text: centimesToChfInput(value));

  /// 'gross' | 'capital' | 'insured' | 'contribution'.
  final String key;
  final String label;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

/// OCR scan sheet (batch 9): source choice (photo / image) →
/// **on-device** recognition → proposal card with editable extracted
/// values → "Apply" returns an [OcrScanResult] via `Navigator.pop`.
/// States: scan in progress, no text found, no values detected,
/// analysis failure — each with a way back to the source choice.
class OcrScanSheet extends ConsumerStatefulWidget {
  const OcrScanSheet({required this.kind, super.key});

  final OcrScanKind kind;

  /// Opens the sheet (pattern `Pillar2AccountSheet.show`).
  static Future<OcrScanResult?> show(
    BuildContext context, {
    required OcrScanKind kind,
  }) {
    return showModalBottomSheet<OcrScanResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: OcrScanSheet(kind: kind),
      ),
    );
  }

  @override
  ConsumerState<OcrScanSheet> createState() => _OcrScanSheetState();
}

class _OcrScanSheetState extends ConsumerState<OcrScanSheet> {
  final _formKey = GlobalKey<FormState>();
  _Stage _stage = _Stage.source;
  List<_ProposedField> _fields = [];

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _startScan(ScanImageSource source) async {
    // Captured before the async gap (the widget may be unmounted
    // during the pick or the analysis — a disposed State's provider
    // would throw).
    final picker = ref.read(scanImagePickerProvider);
    final ocr = ref.read(textRecognitionServiceProvider);

    // A single try/catch for both the pick (permission denied,
    // double-tap `already_active`) and the analysis (batch 9 review,
    // minor 6).
    final String text;
    String? path;
    try {
      path = await picker.pickImagePath(source);
      // Cancelled: silent return to the source choice (already displayed).
      if (path == null || !mounted) return;
      setState(() => _stage = _Stage.scanning);
      text = await ocr.recognizeText(path);
    } on Object {
      if (mounted) setState(() => _stage = _Stage.error);
      return;
    } finally {
      // The picker writes a temporary file: systematic cleanup.
      // deleteSync: deleting a file is FS metadata work (O(1)) — a
      // real I/O `await` would never resolve within the widget tests'
      // fake-async zone. No-op on web (OCR hidden, never run);
      // best-effort, never masks the result.
      final picked = path;
      if (picked != null) deleteFileSync(picked);
    }
    if (!mounted) return;
    if (text.trim().isEmpty) {
      setState(() => _stage = _Stage.noText);
      return;
    }

    final fields = _extractFields(text);
    if (fields.isEmpty) {
      setState(() => _stage = _Stage.noValues);
      return;
    }
    setState(() {
      for (final previous in _fields) {
        previous.dispose();
      }
      _fields = fields;
      _stage = _Stage.proposal;
    });
  }

  /// Fields detected based on the document type (localized labels
  /// reused from the profile form).
  List<_ProposedField> _extractFields(String text) {
    final l10n = context.l10n;
    return switch (widget.kind) {
      OcrScanKind.salaryCertificate => [
        if (parseSalaryCertificateScan(text).grossAnnualIncome
            case final gross?)
          _ProposedField(
            key: 'gross',
            label: l10n.profileGrossAnnualIncome,
            value: gross,
          ),
      ],
      OcrScanKind.lppStatement => () {
        final scan = parseLppStatementScan(text);
        return [
          if (scan.retirementAssets case final capital?)
            _ProposedField(
              key: 'capital',
              label: l10n.profileCurrentCapital,
              value: capital,
            ),
          if (scan.insuredSalary case final insured?)
            _ProposedField(
              key: 'insured',
              label: l10n.profileInsuredSalary,
              value: insured,
            ),
          if (scan.annualContribution case final contribution?)
            _ProposedField(
              key: 'contribution',
              label: l10n.profileAnnualContribution,
              value: contribution,
            ),
        ];
      }(),
    };
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    int? valueOf(String key) {
      for (final field in _fields) {
        if (field.key == key) return tryParseMoneyField(field.controller.text);
      }
      return null;
    }

    Navigator.of(context).pop(
      OcrScanResult(
        grossAnnualIncome: valueOf('gross'),
        currentCapital: valueOf('capital'),
        insuredSalary: valueOf('insured'),
        annualContribution: valueOf('contribution'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final title = widget.kind == OcrScanKind.salaryCertificate
        ? l10n.ocrScanSalaryTitle
        : l10n.ocrScanLppTitle;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            // Scan privacy note: 100% on-device analysis (true with ML
            // Kit — distinct from the global privacy keys, unchanged).
            Text(
              l10n.ocrPrivacyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            switch (_stage) {
              _Stage.source => _buildSourceChoice(l10n),
              _Stage.scanning => _buildScanning(l10n),
              _Stage.proposal => _buildProposal(l10n),
              _Stage.noText => _buildMessage(l10n, l10n.ocrNoTextFound),
              _Stage.noValues => _buildMessage(l10n, l10n.ocrNoValuesFound),
              _Stage.error => _buildMessage(l10n, l10n.ocrScanError),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildSourceChoice(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.photo_camera_outlined),
          title: Text(l10n.ocrSourceCamera),
          onTap: () => _startScan(ScanImageSource.camera),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(l10n.ocrSourceGallery),
          onTap: () => _startScan(ScanImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildScanning(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.ocrScanning),
        ],
      ),
    );
  }

  Widget _buildProposal(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.ocrProposalTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.ocrProposalBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            AppTextField(
              label: _fields[i].label,
              controller: _fields[i].controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: i == _fields.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              validator: (value) =>
                  validateMoneyField(context.l10n, value, required: false),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(label: l10n.ocrApply, onPressed: _apply),
          TextButton(
            onPressed: () => setState(() => _stage = _Stage.source),
            child: Text(l10n.commonRetry),
          ),
        ],
      ),
    );
  }

  /// "No text", "no values", "failure" states: message + return to
  /// the source choice.
  Widget _buildMessage(AppLocalizations l10n, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _stage = _Stage.source),
            child: Text(l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}
