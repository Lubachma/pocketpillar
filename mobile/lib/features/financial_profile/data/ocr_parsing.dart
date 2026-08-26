// Extracts amounts from raw OCR text of Swiss financial documents
// (salary certificate, LPP statement) — pure Dart, no dependency on
// the native plugin: the testable core of the OCR scan (batch 9).
//
// OCR is **assistive**: these values are proposed to the user, who
// confirms or corrects them before saving. Golden rule: never a
// fabricated value — each field is `null` when nothing plausible is
// found.

import '../../../core/utils/text_normalization.dart';

/// Result of scanning a salary certificate (amounts in **centimes**).
class SalaryCertificateScan {
  const SalaryCertificateScan({this.grossAnnualIncome});

  /// Detected gross annual salary, in centimes — null if not detected.
  final int? grossAnnualIncome;

  bool get isEmpty => grossAnnualIncome == null;
}

/// Result of scanning an LPP statement (amounts in **centimes**).
class LppStatementScan {
  const LppStatementScan({
    this.retirementAssets,
    this.insuredSalary,
    this.annualContribution,
  });

  /// Retirement assets (Altersguthaben) → current account capital.
  final int? retirementAssets;

  /// Insured salary (Versicherter Lohn).
  final int? insuredSalary;

  /// Annual contribution (Jahresbeitrag).
  final int? annualContribution;

  bool get isEmpty =>
      retirementAssets == null &&
      insuredSalary == null &&
      annualContribution == null;
}

/// Parses the OCR text of a salary certificate (Lohnausweis).
SalaryCertificateScan parseSalaryCertificateScan(String ocrText) =>
    SalaryCertificateScan(grossAnnualIncome: _extract(ocrText, _grossSalary));

/// Parses the OCR text of an LPP statement (pension certificate).
LppStatementScan parseLppStatementScan(String ocrText) => LppStatementScan(
  retirementAssets: _extract(ocrText, _retirementAssets),
  insuredSalary: _extract(ocrText, _insuredSalary),
  annualContribution: _extract(ocrText, _annualContribution),
);

// ─── Recognized fields ──────────────────────────────────────────────────────

/// Specification of a field: labels (fr/de/en, **already normalized** —
/// lowercase without diacritics, see [normalizeDiacritics]) and a
/// plausibility window in centimes.
class _FieldSpec {
  const _FieldSpec({
    required this.labels,
    required this.minCentimes,
    required this.maxCentimes,
    this.windowDenylist = const [],
  });

  final List<String> labels;
  final int minCentimes;
  final int maxCentimes;

  /// Keywords that invalidate a window: the label shares its line with
  /// one of them → the value isn't the one expected. Uses: projection/
  /// buy-in lines ("Avoir de vieillesse projeté" ≠ current assets),
  /// legal caps ("Maximal versicherter Lohn" ≠ insured salary), monthly
  /// context ("Bruttolohn pro Monat" ≠ annual income), employer share
  /// ("Jahresbeitrag Arbeitgeber" ≠ total contribution).
  final List<String> windowDenylist;
}

/// Salary window decided for batch 9: 1'000–10'000'000 CHF.
const _salaryMin = 1000 * 100;
const _salaryMax = 10000000 * 100;

const _grossSalary = _FieldSpec(
  labels: [
    // fr
    'salaire brut',
    'salaire annuel brut',
    'salaire total brut',
    'revenu brut',
    // de
    'jahresbruttolohn',
    'bruttolohn',
    'bruttosalar',
    'bruttoverdienst',
    // en
    'gross annual salary',
    'gross salary',
    // Document titles: weak signal, only useful if an amount follows
    // immediately (the title's year is discarded as such).
    'certificat de salaire',
    'lohnausweis',
    'salary certificate',
  ],
  minCentimes: _salaryMin,
  maxCentimes: _salaryMax,
  // Explicit monthly context → the amount isn't an annual income
  // (batch 9 review: "Bruttolohn pro Monat 6'500" → null, never a
  // wrong extrapolated annual figure).
  windowDenylist: ['mensuel', 'monatlich', 'pro monat', 'mens.', 'monthly'],
);

const _retirementAssets = _FieldSpec(
  labels: [
    // fr
    'avoir de vieillesse',
    'capital de vieillesse',
    'capital-vieillesse',
    'avoir de prevoyance',
    'avoir lpp',
    // de
    'altersguthaben',
    'alterskapital',
    'vorsorgeguthaben',
    'vorsorgekapital',
    // en
    'retirement assets',
    'retirement capital',
    'retirement savings',
  ],
  // Retirement assets can be modest (young employee) or very high.
  minCentimes: 100 * 100,
  maxCentimes: 100000000 * 100,
  windowDenylist: [
    'projet', // projected / projiziert
    'projiz',
    'a terme',
    'rachat',
    'einkauf',
    'sortie', // termination benefit
    'austritt', // Austrittsleistung
    'libre passage',
    'freizug', // Freizügigkeit
  ],
);

const _insuredSalary = _FieldSpec(
  labels: [
    // fr
    'salaire assure',
    'salaire annuel assure',
    'salaire coordonne',
    // de
    'versicherter lohn',
    'versicherter jahreslohn',
    'versichertes gehalt',
    'versichertes jahresgehalt',
    'koordinierter lohn',
    // en
    'insured salary',
    'coordinated salary',
  ],
  minCentimes: _salaryMin,
  maxCentimes: _salaryMax,
  // Legal caps shown on statements (batch 9 review): "Maximal
  // versicherter Lohn: 90'720" is the LPP ceiling, not the insured
  // salary.
  windowDenylist: [
    'maximal',
    'maximum',
    'max.',
    'minimal',
    'limite',
    'obergrenze',
    'plafond',
  ],
);

const _annualContribution = _FieldSpec(
  labels: [
    // fr
    'cotisation annuelle',
    'cotisations annuelles',
    'cotisation totale',
    'cotisations totales',
    // de
    'jahresbeitrag',
    'jahresbeitrage',
    'gesamtbeitrag',
    // en
    'annual contribution',
  ],
  minCentimes: 100 * 100,
  maxCentimes: 1000000 * 100,
  // Employer share alone ≠ total contribution (batch 9 review): the
  // "Jahresbeitrag Arbeitgeber" line is ignored — the total is still
  // captured via "cotisation totale" / "Gesamtbeitrag".
  windowDenylist: ['employeur', 'arbeitgeber'],
);

// ─── Extraction engine ──────────────────────────────────────────────────────

/// All known labels, across every spec (normalized).
final _allLabels = [
  ..._grossSalary.labels,
  ..._retirementAssets.labels,
  ..._insuredSalary.labels,
  ..._annualContribution.labels,
];

/// Extracts a field's amount: the **largest plausible amount** found
/// in the windows following its labels (handles duplicates like
/// "monthly 7'916 / annual 95'000" and mandatory/supra-mandatory/total
/// columns). Null if no label or no plausible amount is found.
int? _extract(String ocrText, _FieldSpec spec) {
  final text = _normalize(ocrText);
  // Label matching ignores case and diacritics (noisy OCR).
  final searchable = normalizeDiacritics(text.toLowerCase());
  final lines = text.split('\n');
  final searchableLines = searchable.split('\n');

  int? best;
  for (final label in spec.labels) {
    for (var i = 0; i < searchableLines.length; i++) {
      var from = 0;
      while (true) {
        final at = searchableLines[i].indexOf(label, from);
        if (at < 0) break;
        from = at + label.length;

        // Window: end of the label's line, extended to the next line
        // when it contains no plausible amount (columnar OCR: label
        // alone, amount below). Never when the next line carries a
        // known label (batch 9 review: "Avoir de vieillesse / Salaire
        // assuré : 68'250" → assets null, not the neighboring field's
        // amount).
        var window = lines[i].substring(at + label.length);
        // The denylist is evaluated on the whole line (+ the next one
        // if extended): the keyword ("projeté", "Einkauf") can precede
        // the label — "Möglicher Einkauf ins Altersguthaben".
        var context = lines[i];
        var candidates = _plausibleAmounts(window, context, spec);
        if (candidates.isEmpty &&
            i + 1 < lines.length &&
            !_allLabels.any(searchableLines[i + 1].contains)) {
          window = '$window ${lines[i + 1]}';
          context = '$context ${lines[i + 1]}';
          candidates = _plausibleAmounts(window, context, spec);
        }
        for (final value in candidates) {
          if (best == null || value > best) best = value;
        }
      }
    }
  }
  return best;
}

/// Plausible amounts within a window, in centimes. Dates are stripped
/// before the search, and windows whose [context] contains a denylist
/// keyword (projection, buy-in, vested benefits) are ignored.
List<int> _plausibleAmounts(String window, String context, _FieldSpec spec) {
  if (spec.windowDenylist.isNotEmpty) {
    final searchable = normalizeDiacritics(context.toLowerCase());
    if (spec.windowDenylist.any(searchable.contains)) return const [];
  }
  final withoutDates = window.replaceAll(_datePattern, ' ');
  final result = <int>[];
  for (final match in _amountPattern.allMatches(withoutDates)) {
    final centimes = _parseAmount(match);
    if (centimes != null &&
        centimes >= spec.minCentimes &&
        centimes <= spec.maxCentimes) {
      result.add(centimes);
    }
  }
  return result;
}

/// Dates `31.12.2025`, `01/01/25` — never amounts.
final _datePattern = RegExp(r'\d{1,2}[./]\d{1,2}[./]\d{2,4}');

/// Swiss amount: `95'000.00`, `95 000`, `95'000.-`, `95'000,00`,
/// `128'540.75`, `95000`. The thousands separator is the apostrophe or
/// a space; decimals (dot or comma) are 2 digits or `–`.
final _amountPattern = RegExp(
  r"(\d{1,3}(?:[' ]\d{3})+|\d+)(?:[.,](\d{2}|[-–]))?",
);

/// Converts an [_amountPattern] capture to centimes. Rejected (OCR
/// noise, never amounts): bare years (4 digits 1900–2100 with no
/// separator or decimals — document year references) and bare
/// integers under 4 digits (phone numbers, line numbers — an
/// extracted amount is at least a thousand or carries
/// separators/decimals).
int? _parseAmount(RegExpMatch match) {
  final intPart = match.group(1)!;
  final hasSeparators = intPart.contains("'") || intPart.contains(' ');
  final decimals = match.group(2);
  final francs = int.tryParse(intPart.replaceAll("'", '').replaceAll(' ', ''));
  if (francs == null) return null;
  if (!hasSeparators && decimals == null) {
    if (intPart.length < 4) return null;
    if (intPart.length == 4 && francs >= 1900 && francs <= 2100) return null;
  }
  final cents = switch (decimals) {
    null || '-' || '–' => 0,
    final digits => int.parse(digits),
  };
  return francs * 100 + cents;
}

/// Normalizes OCR text: typographic apostrophes (U+2019) and
/// non-breaking/thin spaces → plain forms, and `O`/`o` adjacent to
/// digits (classic OCR noise `95'OOO.OO`) → `0`.
String _normalize(String text) {
  var result = text
      .replaceAll('\u2019', "'") // typographic apostrophe
      .replaceAll('\u00A0', ' ') // non-breaking space
      .replaceAll('\u202F', ' ') // thin non-breaking space
      .replaceAll('\u2013', '-'); // en dash (« .– »)
  // Each pass converts `O`s that became adjacent to a digit in the
  // previous pass — the loop converges on runs (`OOO`).
  for (var i = 0; i < 8; i++) {
    final next = result.replaceAllMapped(
      RegExp(r"[Oo](?=[0-9'.])|(?<=[0-9'.])[Oo]"),
      (_) => '0',
    );
    if (next == result) break;
    result = next;
  }
  return result;
}
