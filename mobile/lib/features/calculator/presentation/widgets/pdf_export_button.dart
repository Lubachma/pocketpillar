import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../premium/application/premium_providers.dart';
import '../../data/calculator_payloads.dart';
import '../../data/calculator_repository.dart';
import '../../data/pdf_report.dart';

/// PDF summary export button — equivalent to iOS's `PDFExportButton`:
/// generation (loading indicator) then sharing via the native sheet
/// (`printing.sharePdf`, successor to `UIActivityViewController`).
///
/// Premium feature (app-side gate, contract §11): padlock for
/// non-subscribers, tapping then opens the paywall.
class PdfExportButton extends ConsumerStatefulWidget {
  const PdfExportButton({required this.input, required this.results, super.key});

  final GuidedCalculatorInput input;
  final CalculatorResults results;

  @override
  ConsumerState<PdfExportButton> createState() => _PdfExportButtonState();
}

class _PdfExportButtonState extends ConsumerState<PdfExportButton> {
  bool _generating = false;

  Future<void> _export() async {
    // Premium gate: non-subscriber → paywall, no generation.
    if (!ref.read(premiumActiveProvider)) {
      await context.push(Routes.paywall);
      return;
    }
    if (!mounted) return;
    // Captured before the async gap (context not reused after await).
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final dateLabel = DateFormat.yMMMMd(l10n.localeName).format(DateTime.now());

    setState(() => _generating = true);
    try {
      final bytes = await buildPensionReportPdf(
        l10n: l10n,
        dateLabel: dateLabel,
        input: widget.input,
        results: widget.results,
      );
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'PocketPillar_Bilan.pdf',
      );
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final premium = ref.watch(premiumActiveProvider);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _generating ? null : _export,
        icon: _generating
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Icon(premium ? Icons.picture_as_pdf : Icons.lock_outline),
        label: Text(l10n.pdfExportButton),
      ),
    );
  }
}
