/**
 * Public demo account — fictional but realistic profile (35 years old, Vaud,
 * salary close to the median, 3a started below the deductible max): visible
 * LPP gap, meaningful tax savings, relevant 3a catch-up.
 * Amounts in centimes, as everywhere.
 */

export const DEMO_USER_PATCH = {
  canton: 'VD' as const,
  birthYear: 1991,
  replacementRateGoal: 70,
  municipality: 'Lausanne',
};

export const DEMO_FINANCIAL_PROFILE = {
  employmentStatus: 'EMPLOYED' as const,
  maritalStatus: 'SINGLE' as const,
  numberOfChildren: 0,
  grossAnnualIncome: 9_500_000, // 95'000 CHF
};

export const DEMO_PILLAR2 = {
  providerName: 'Caisse de pension employeur',
  currentCapital: 8_500_000, // 85'000 CHF
  annualBvgContribution: 600_000, // 6'000 CHF/year
  isVestedBenefits: false,
};

export const DEMO_PILLAR3A = {
  providerName: 'Banque Cantonale Vaudoise',
  accountType: 'BANK' as const,
  currentBalance: 2_400_000, // 24'000 CHF
  annualContribution: 350_000, // 3'500 CHF/year — below the max → useful catch-up
  interestRateOrReturn: 0.8,
};

export const DEMO_TAX = {
  taxableIncome: 8_200_000, // 82'000 CHF
  churchTax: false,
};

// ─── Example PDF: FICTITIOUS 3a statement, readable, generated with no dependency ────────
//
// Clearly marked "demonstration" and issued by a made-up bank
// ("Banque Exemple SA") — never an imitation of a real institution.
// Figures consistent with the demo profile: 20'336 + 3'500 + 164 = 24'000
// (= currentBalance), interest 0.8 % (= interestRateOrReturn).

/** Escapes a PDF string and converts accented characters to octal WinAnsi. */
function pdfText(text: string): string {
  const octal: Record<string, string> = {
    é: '\\351',
    è: '\\350',
    ê: '\\352',
    à: '\\340',
    ç: '\\347',
    ô: '\\364',
    '—': '\\227',
    '–': '\\226',
  };
  return text.replace(/[\\()]/g, (c) => `\\${c}`).replace(/[éèêàçô—–]/g, (c) => octal[c]);
}

function buildDemoPdf(): string {
  const t = (x: number, y: number, size: number, text: string): string =>
    `BT /F1 ${size} Tf ${x} ${y} Td (${pdfText(text)}) Tj ET\n`;
  const hr = (y: number): string => `72 ${y} m 523 ${y} l S\n`;

  const stream =
    t(72, 780, 16, 'Relevé de prévoyance — pilier 3a') +
    t(72, 758, 10, 'Banque Exemple SA — document fictif de démonstration') +
    t(72, 710, 11, 'Titulaire : Compte de démonstration PocketPillar') +
    t(72, 692, 11, 'Compte : 3A-0000.0000.00 (fictif)') +
    t(72, 674, 11, 'Période : 01.01.2026 – 31.12.2026') +
    hr(652) +
    t(72, 630, 11, "Solde d'ouverture au 01.01.2026") +
    t(400, 630, 11, "CHF 20'336.00") +
    t(72, 610, 11, "Versements de l'année") +
    t(400, 610, 11, "CHF 3'500.00") +
    t(72, 590, 11, 'Intérêts crédités (0.8 %)') +
    t(400, 590, 11, 'CHF 164.00') +
    hr(576) +
    t(72, 554, 12, 'Solde au 31.12.2026') +
    t(400, 554, 12, "CHF 24'000.00") +
    t(
      72,
      80,
      8,
      'Document fictif généré automatiquement pour la démonstration publique de PocketPillar.',
    ) +
    t(72, 68, 8, 'Aucune valeur contractuelle. Ne représente aucune institution existante.');

  const objects = [
    '<</Type/Catalog/Pages 2 0 R>>',
    '<</Type/Pages/Kids[3 0 R]/Count 1>>',
    '<</Type/Page/Parent 2 0 R/MediaBox[0 0 595 842]' +
      '/Resources<</Font<</F1 4 0 R>>>>/Contents 5 0 R>>',
    '<</Type/Font/Subtype/Type1/BaseFont/Helvetica/Encoding/WinAnsiEncoding>>',
    `<</Length ${stream.length}>>stream\n${stream}endstream`,
  ];

  let pdf = '%PDF-1.4\n';
  const offsets: number[] = [];
  objects.forEach((body, i) => {
    offsets.push(pdf.length);
    pdf += `${i + 1} 0 obj${body}endobj\n`;
  });
  const xrefStart = pdf.length;
  pdf += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (const offset of offsets) {
    pdf += `${String(offset).padStart(10, '0')} 00000 n \n`;
  }
  pdf += `trailer<</Size ${objects.length + 1}/Root 1 0 R>>\n` + `startxref\n${xrefStart}\n%%EOF\n`;
  return pdf;
}

export const DEMO_DOCUMENT = {
  filename: 'releve-3a-demo.pdf',
  mimeType: 'application/pdf',
  type: 'PILLAR3A_STATEMENT' as const,
  // Uint8Array<ArrayBuffer>: required by BlobPart (TextEncoder always
  // allocates a non-shared ArrayBuffer — the cast is safe). The built PDF
  // is pure ASCII (accents in octal): UTF-8 encoding = 1:1 bytes.
  bytes: (): Uint8Array<ArrayBuffer> =>
    new TextEncoder().encode(buildDemoPdf()) as Uint8Array<ArrayBuffer>,
};

const DEMO_PREMIUM_DAYS = 400; // "rolling": reset on every nightly reset

/** `subscriptions` row written directly — the backend is the source of truth. */
export function demoSubscriptionData(now: Date): {
  store: string;
  productId: string;
  environment: string;
  expiresAt: Date;
  lastEventType: string;
  lastEventAt: Date;
} {
  return {
    store: 'PROMOTIONAL',
    productId: 'demo_premium',
    environment: 'PRODUCTION',
    expiresAt: new Date(now.getTime() + DEMO_PREMIUM_DAYS * 24 * 60 * 60 * 1000),
    lastEventType: 'DEMO_RESET',
    lastEventAt: now,
  };
}
