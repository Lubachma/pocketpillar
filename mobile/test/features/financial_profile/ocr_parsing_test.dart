import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpillar/features/financial_profile/data/ocr_parsing.dart';

/// Realistic OCR text fixtures (fr/de/en) — Swiss salary certificates and
/// LPP statements, including typical noise (typographic apostrophes,
/// non-breaking spaces, `O` for `0`, amount on a line below the label).
void main() {
  group('parseSalaryCertificateScan', () {
    test('fr — gross salary with apostrophe and decimals', () {
      const text = '''
CERTIFICAT DE SALAIRE 2025
Canton de Vaud — Période du 01.01.2025 au 31.12.2025
1. Salaire brut 95'000.00
2. Prestations en nature 0.00
''';
      final scan = parseSalaryCertificateScan(text);
      expect(scan.grossAnnualIncome, 9500000);
      expect(scan.isEmpty, isFalse);
    });

    test('fr — gross salary with « .- »', () {
      const text = 'Salaire brut : 102\'500.-';
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, 10250000);
    });

    test('fr — space separator and decimal comma', () {
      const text = 'Salaire brut 95 000,00';
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, 9500000);
    });

    test('de — Bruttolohn', () {
      const text = "LOHNAUSWEIS 2025\nBruttolohn CHF 88'000.00";
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, 8800000);
    });

    test('de — Jahresbruttolohn with en dash', () {
      const text = "Jahresbruttolohn 102'500.–";
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, 10250000);
    });

    test('typographic apostrophes (U+2019)', () {
      const text = 'Salaire brut 95\u2019000.00';
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, 9500000);
    });

    test('OCR noise — O for 0', () {
      const text = "Salaire brut 95'OOO.OO";
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, 9500000);
    });

    test('monthly and annual amount → the larger one (annual) is kept', () {
      const text =
          "Salaire brut mensuel 7'916.66\nSalaire brut annuel 95'000.-";
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, 9500000);
    });

    test('amount on the line below the label', () {
      const text = "Salaire brut\n95'000.00";
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, 9500000);
    });

    test('en — gross salary', () {
      const text = "Salary certificate 2025\nGross salary 95'000.00";
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, 9500000);
    });

    test('no known label → null (no value invented)', () {
      const text = "Relevé de compte 3a\nSolde au 31.12.2025 : 25'000.00";
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, isNull);
      expect(parseSalaryCertificateScan(text).isEmpty, isTrue);
    });

    test('label without amount → null', () {
      const text = 'Salaire brut : selon contrat de travail';
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, isNull);
    });

    test('amount outside plausible range (< 1\'000 CHF) → null', () {
      const text = 'Salaire brut 950.-';
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, isNull);
    });

    test('the year in the title is not an amount', () {
      const text = 'CERTIFICAT DE SALAIRE 2025\nEmployeur : Exemple SA';
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, isNull);
    });

    // Regression, batch 9 review (Important 2): monthly context → null,
    // never a wrong annual income extrapolated from a monthly statement.
    test('monthly context (pro Monat) → null', () {
      const text = "Bruttolohn pro Monat: 6'500.–";
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, isNull);
    });

    test('monthly context (mensuel) → null', () {
      const text = "Salaire brut mensuel : 6'500.00";
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, isNull);
    });

    test('monthly line ignored, annual line kept', () {
      const text = "Bruttolohn monatlich 6'500.–\nJahresbruttolohn 78'000.–";
      expect(parseSalaryCertificateScan(text).grossAnnualIncome, 7800000);
    });
  });

  group('parseLppStatementScan', () {
    test('fr — complete statement (assets, insured salary, contribution)', () {
      const text = '''
RELEVÉ DE PRÉVOYANCE 2025
Caisse de pensions Exemple
Avoir de vieillesse au 31.12.2025 : 128'540.75
Salaire assuré : 68'250.00
Cotisation annuelle : 9'550.00
''';
      final scan = parseLppStatementScan(text);
      expect(scan.retirementAssets, 12854075);
      expect(scan.insuredSalary, 6825000);
      expect(scan.annualContribution, 955000);
      expect(scan.isEmpty, isFalse);
    });

    test('de — complete Ausweis', () {
      const text = '''
VORSORGEAUSWEIS 2025
Altersguthaben per 31.12.2025: CHF 45'600.–
Versicherter Lohn: CHF 61'000.–
Jahresbeitrag: CHF 8'540.–
''';
      final scan = parseLppStatementScan(text);
      expect(scan.retirementAssets, 4560000);
      expect(scan.insuredSalary, 6100000);
      expect(scan.annualContribution, 854000);
    });

    test('partial detection — only the assets, the rest null', () {
      const text = "Altersguthaben: 45'600.–";
      final scan = parseLppStatementScan(text);
      expect(scan.retirementAssets, 4560000);
      expect(scan.insuredSalary, isNull);
      expect(scan.annualContribution, isNull);
    });

    test('the retirement projection is not the current assets', () {
      const text = '''
Avoir de vieillesse au 31.12.2025 : 45'600.-
Avoir de vieillesse projeté à l'âge de la retraite : 385'000.-
''';
      expect(parseLppStatementScan(text).retirementAssets, 4560000);
    });

    test('buy-in (Einkauf) ignored for the assets', () {
      const text = '''
Altersguthaben: 45'600.–
Möglicher Einkauf ins Altersguthaben: 120'000.–
''';
      expect(parseLppStatementScan(text).retirementAssets, 4560000);
    });

    test('date without amount → null (the date is not an amount)', () {
      const text = 'Avoir de vieillesse au 31.12.2025';
      expect(parseLppStatementScan(text).retirementAssets, isNull);
    });

    test('assets with 7 digits and double apostrophe', () {
      const text = "Avoir de vieillesse 1'234'567.89";
      expect(parseLppStatementScan(text).retirementAssets, 123456789);
    });

    test('narrow non-breaking spaces (U+202F) as separators', () {
      const text = 'Salaire assuré : 68\u202F250.00';
      expect(parseLppStatementScan(text).insuredSalary, 6825000);
    });

    test('en — insured salary / annual contribution', () {
      const text = "Insured salary 61'000.00\nAnnual contribution 8'540.00";
      final scan = parseLppStatementScan(text);
      expect(scan.insuredSalary, 6100000);
      expect(scan.annualContribution, 854000);
    });

    test('mandatory/supra-mandatory/total columns → the total (largest)', () {
      const text = "Avoir de vieillesse 80'000.- 20'000.- 100'000.-";
      expect(parseLppStatementScan(text).retirementAssets, 10000000);
    });

    // Regression, batch 9 review (Important 1): the LPP legal cap is
    // never the insured salary.
    test('legal cap « Maximal versicherter Lohn » ignored, real insured '
        'salary kept', () {
      const text = '''
Maximal versicherter Lohn: 90'720.–
Versicherter Lohn: CHF 61'000.–
''';
      expect(parseLppStatementScan(text).insuredSalary, 6100000);
    });

    test('only the legal cap is present → null', () {
      const text = "Maximal versicherter Lohn: 90'720.–";
      expect(parseLppStatementScan(text).insuredSalary, isNull);
    });

    test('cap « plafond » (fr) ignored', () {
      const text = "Salaire assuré plafond : 90'720.00";
      expect(parseLppStatementScan(text).insuredSalary, isNull);
    });

    // Regression, batch 9 review (Important 3): extending to the next
    // line never absorbs a line carrying another known label.
    test('extension: the next line carries another label → assets '
        'null (not the amount of the neighboring field)', () {
      const text = "Avoir de vieillesse\nSalaire assuré : 68'250.00";
      final scan = parseLppStatementScan(text);
      expect(scan.retirementAssets, isNull);
      expect(scan.insuredSalary, 6825000);
    });

    // Regression, batch 9 review (Recommendation): the employer share alone
    // is not the annual contribution — the total is still captured.
    test('employer share ignored, total captured via « Gesamtbeitrag »', () {
      const text = "Jahresbeitrag Arbeitgeber: 4'750.–\nGesamtbeitrag: 9'500.–";
      expect(parseLppStatementScan(text).annualContribution, 950000);
    });

    test('employer annual contribution without total → null', () {
      const text = "Cotisation annuelle employeur : 4'750.00";
      expect(parseLppStatementScan(text).annualContribution, isNull);
    });
  });
}
