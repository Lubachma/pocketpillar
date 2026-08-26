import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/utils/currency.dart';
import 'calculator_payloads.dart';
import 'calculator_repository.dart';

/// Generates the A4 PDF summary — ported from
/// `ios/PocketPillar/Services/PDFReportGenerator.swift` (same sections,
/// `pdf*` keys). The `pdf` package's `MultiPage` handles pagination
/// (equivalent to iOS's `ensureSpace`).
///
/// Pure function (no platform channel): unit-testable.
/// [dateLabel] is pre-formatted by the caller (`DateFormat` + the app's
/// locale) to keep the generator synchronous and outside the Flutter context.
///
/// Not carried over from iOS: the /100 score gauge (no endpoint — P2-11,
/// and no `pdf*` key for the score).
Future<List<int>> buildPensionReportPdf({
  required AppLocalizations l10n,
  required String dateLabel,
  required GuidedCalculatorInput input,
  required CalculatorResults results,
}) async {
  const accent = PdfColor.fromInt(0xFF007AFF);
  const pillar1 = PdfColor.fromInt(0xFF00C7BE);
  const pillar2 = PdfColor.fromInt(0xFF007AFF);
  const pillar3a = PdfColor.fromInt(0xFFAF52DE);
  const grey = PdfColor.fromInt(0xFF6E6E73);
  const rowShade = PdfColor.fromInt(0xFFF2F2F7);

  final retirement = results.retirement;
  final tax = results.taxSavings;

  final doc = pw.Document();

  pw.Widget sectionTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      title,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    ),
  );

  // ─── Header ───────────────────────────────────────────────────────
  final header = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        l10n.pdfTitle,
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: accent,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        dateLabel,
        style: const pw.TextStyle(fontSize: 11, color: grey),
      ),
      pw.SizedBox(height: 12),
      pw.Container(height: 2, color: accent),
      pw.SizedBox(height: 12),
      pw.Text(
        '${l10n.pdfAge}: ${input.age}  |  '
        '${l10n.pdfSalary}: ${formatChf(input.grossAnnualIncome)}  |  '
        '${l10n.pdfCanton}: ${input.canton}',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );

  // ─── 3-pillar bars ────────────────────────────────────────────────
  // A4 = 595 pt, margins 40 → content ≈ 515 pt; label 110 + value 130.
  const barMaxWidth = 515.0 - 110 - 130 - 16;
  final pillarRows = [
    (l10n.pdfPillar1, retirement.estimatedAnnualAvsPension, pillar1),
    (l10n.pdfPillar2, retirement.annualPillar2Pension, pillar2),
    (l10n.pdfPillar3a, retirement.projectedPillar3aBalance, pillar3a),
  ];
  final maxValue = pillarRows.fold<int>(
    1,
    (max, p) => p.$2 > max ? p.$2 : max,
  );
  final pillars = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      sectionTitle(l10n.pdfPillarsTitle),
      for (final (label, value, color) in pillarRows)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 110,
                child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
              ),
              pw.Container(
                width: (barMaxWidth * value / maxValue).clamp(4, barMaxWidth),
                height: 18,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  formatChf(value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );

  // ─── Projection table ─────────────────────────────────────────────
  final tableRows = [
    (l10n.pdfRetirementAge, '$calculatorRetirementAge'),
    (l10n.pdfYearsRemaining, '${retirement.yearsToRetirement}'),
    (l10n.pdfReplacementRate, '${retirement.replacementRate.round()} %'),
    (
      l10n.pdfAnnualIncome,
      formatChf(retirement.totalAnnualRetirementIncome),
    ),
    (
      l10n.pdfMonthlyIncome,
      formatChf(retirement.totalAnnualRetirementIncome ~/ 12),
    ),
  ];
  final projectionTable = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      sectionTitle(l10n.pdfProjectionTitle),
      for (final (index, row) in tableRows.indexed)
        pw.Container(
          color: index.isEven ? rowShade : null,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(row.$1, style: const pw.TextStyle(fontSize: 11)),
              pw.Text(
                row.$2,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
    ],
  );

  // ─── Tax savings ──────────────────────────────────────────────────
  final taxSection = tax.totalTaxSaving > 0
      ? pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            sectionTitle(l10n.pdfTaxTitle),
            pw.Text(
              l10n.pdfTaxDetail(formatChf(tax.totalTaxSaving)),
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        )
      : null;

  // ─── Recommendations (same conditions as iOS) ─────────────────────
  final recommendations = <String>[
    if (!input.hasPillar3a)
      l10n.pdfRecOpen3a
    else
      // Effective cap (with/without 2nd pillar), not just 7'258.
      l10n.pdfRecMax3a(formatChf(input.pillar3aMaxContribution)),
    if (retirement.replacementRate < 60) l10n.pdfRecIncreaseCoverage,
    if (retirement.replacementRate >= 70) l10n.pdfRecGoodTrack,
  ];
  final recommendationsSection = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      sectionTitle(l10n.pdfRecommendationsTitle),
      for (final rec in recommendations)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text('• $rec', style: const pw.TextStyle(fontSize: 11)),
        ),
    ],
  );

  // ─── Disclaimer ───────────────────────────────────────────────────
  final disclaimer = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(height: 0.5, color: grey),
      pw.SizedBox(height: 8),
      pw.Text(
        l10n.pdfDisclaimer,
        style: const pw.TextStyle(fontSize: 9, color: grey),
      ),
    ],
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        header,
        pw.SizedBox(height: 20),
        pillars,
        pw.SizedBox(height: 20),
        projectionTable,
        if (taxSection != null) ...[pw.SizedBox(height: 20), taxSection],
        pw.SizedBox(height: 20),
        recommendationsSection,
        pw.SizedBox(height: 20),
        disclaimer,
      ],
    ),
  );

  return doc.save();
}
