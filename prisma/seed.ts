import dotenv from 'dotenv';
dotenv.config();

import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import type { InvestmentCategory, RiskLevel } from '@prisma/client';

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

// ─── Helpers ──────────────────────────────────

interface ProviderData {
  slug: string;
  name: string;
  description: string;
  website: string;
  isDigital: boolean;
}

interface ProductData {
  name: string;
  slug: string;
  investmentCategory: InvestmentCategory;
  riskLevel: RiskLevel;
  equityAllocation: number;
  sustainableEsg?: boolean;
  fee: { ter: number; custody?: number; allIn: number };
  returns: Record<number, number>; // year -> return %
}

async function seedProvider(data: ProviderData, products: ProductData[]) {
  const provider = await prisma.pillar3aProvider.upsert({
    where: { slug: data.slug },
    update: { name: data.name },
    create: { ...data },
  });

  for (const p of products) {
    const product = await prisma.pillar3aProduct.upsert({
      where: { slug: p.slug },
      update: { name: p.name },
      create: {
        providerId: provider.id,
        name: p.name,
        slug: p.slug,
        investmentCategory: p.investmentCategory,
        riskLevel: p.riskLevel,
        equityAllocation: p.equityAllocation,
        sustainableEsg: p.sustainableEsg ?? false,
      },
    });

    await prisma.pillar3aProductFee.upsert({
      where: { productId: product.id },
      update: { allInFeePercent: p.fee.allIn },
      create: {
        productId: product.id,
        terPercent: p.fee.ter,
        custodyFeePercent: p.fee.custody ?? null,
        allInFeePercent: p.fee.allIn,
      },
    });

    for (const [yearStr, returnPercent] of Object.entries(p.returns)) {
      const year = Number(yearStr);
      const existing = await prisma.pillar3aPerformance.findUnique({
        where: { productId_year: { productId: product.id, year } },
      });
      if (!existing) {
        await prisma.pillar3aPerformance.create({
          data: { productId: product.id, year, returnPercent },
        });
      }
    }
  }

  console.log(`  Seeded ${data.name} (${products.length} products)`);
}

// ─── Main ─────────────────────────────────────

async function main() {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Seed script must not run in production');
  }

  // ── Test user ──
  const user = await prisma.user.upsert({
    where: { email: 'test@pocketpillar.ch' },
    update: {},
    create: {
      supabaseId: crypto.randomUUID(),
      email: 'test@pocketpillar.ch',
      canton: 'VD',
      birthYear: 1990,
    },
  });
  console.log('Seeded user:', user.email);

  // ── Financial data ──
  await prisma.financialProfile.upsert({
    where: { userId: user.id },
    update: {},
    create: {
      userId: user.id,
      employmentStatus: 'EMPLOYED',
      maritalStatus: 'SINGLE',
      numberOfChildren: 0,
      grossAnnualIncome: 10_000_000,
      netAnnualIncome: 8_200_000,
    },
  });

  const existingP2 = await prisma.pillar2Account.findFirst({ where: { userId: user.id } });
  if (!existingP2) {
    await prisma.pillar2Account.create({
      data: {
        userId: user.id,
        providerName: 'Caisse de pension cantonale',
        currentCapital: 12_000_000,
        conversionRate: 5.4,
        insuredSalary: 7_427_500,
        coordinationDeduction: 2_572_500,
        annualBvgContribution: 742_750,
        annualSupraContribution: 300_000,
        isVestedBenefits: false,
      },
    });
  }

  const existingP3a = await prisma.pillar3aAccount.findFirst({ where: { userId: user.id } });
  if (!existingP3a) {
    await prisma.pillar3aAccount.create({
      data: {
        userId: user.id,
        providerName: 'VIAC',
        accountType: 'BANK',
        currentBalance: 3_500_000,
        annualContribution: 705_600,
        interestRateOrReturn: 5.0,
      },
    });
  }

  await prisma.taxSituation.upsert({
    where: { userId: user.id },
    update: {},
    create: {
      userId: user.id,
      taxableIncome: 7_800_000,
      totalDeductions: 2_200_000,
      churchTax: false,
      taxableWealth: 5_000_000,
      municipality: 'Lausanne',
    },
  });
  console.log('Seeded financial data');

  // ── Providers ──
  console.log('Seeding providers...');

  const eq100Returns = { 2020: 5.2, 2021: 20.1, 2022: -17.8, 2023: 15.6, 2024: 18.2, 2025: 8.5 };
  const eq80Returns = { 2020: 4.1, 2021: 15.8, 2022: -13.5, 2023: 12.4, 2024: 14.6, 2025: 7.0 };
  const eq60Returns = { 2020: 3.2, 2021: 11.5, 2022: -9.8, 2023: 9.6, 2024: 10.8, 2025: 5.5 };
  const eq40Returns = { 2020: 2.4, 2021: 7.8, 2022: -6.2, 2023: 6.8, 2024: 7.5, 2025: 4.0 };
  const eq20Returns = { 2020: 1.5, 2021: 3.8, 2022: -2.8, 2023: 3.5, 2024: 4.2, 2025: 2.5 };

  await seedProvider(
    {
      slug: 'viac',
      name: 'VIAC',
      description: 'Pilier 3a digital avec fonds indiciels',
      website: 'https://viac.ch',
      isDigital: true,
    },
    [
      {
        name: 'VIAC Global 100',
        slug: 'viac-global-100',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'AGGRESSIVE',
        equityAllocation: 97,
        fee: { ter: 0, allIn: 0.44 },
        returns: eq100Returns,
      },
      {
        name: 'VIAC Global 80',
        slug: 'viac-global-80',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'GROWTH',
        equityAllocation: 80,
        fee: { ter: 0, allIn: 0.42 },
        returns: eq80Returns,
      },
      {
        name: 'VIAC Global 60',
        slug: 'viac-global-60',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'BALANCED',
        equityAllocation: 60,
        fee: { ter: 0, allIn: 0.4 },
        returns: eq60Returns,
      },
      {
        name: 'VIAC Global 40',
        slug: 'viac-global-40',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'MODERATE',
        equityAllocation: 40,
        fee: { ter: 0, allIn: 0.38 },
        returns: eq40Returns,
      },
      {
        name: 'VIAC Global 20',
        slug: 'viac-global-20',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'CONSERVATIVE',
        equityAllocation: 20,
        fee: { ter: 0, allIn: 0.36 },
        returns: eq20Returns,
      },
    ],
  );

  await seedProvider(
    {
      slug: 'frankly',
      name: 'Frankly',
      description: 'Pilier 3a de la Banque Cantonale de Zurich',
      website: 'https://frankly.ch',
      isDigital: true,
    },
    [
      {
        name: 'Frankly Extreme 95',
        slug: 'frankly-extreme-95',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'AGGRESSIVE',
        equityAllocation: 95,
        fee: { ter: 0, allIn: 0.44 },
        returns: { 2020: 4.8, 2021: 19.5, 2022: -18.2, 2023: 15.2, 2024: 17.9, 2025: 8.2 },
      },
      {
        name: 'Frankly Strong 85',
        slug: 'frankly-strong-85',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'GROWTH',
        equityAllocation: 85,
        fee: { ter: 0, allIn: 0.44 },
        returns: { 2020: 3.9, 2021: 15.2, 2022: -14.0, 2023: 12.0, 2024: 14.2, 2025: 6.8 },
      },
      {
        name: 'Frankly Moderate 55',
        slug: 'frankly-moderate-55',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'BALANCED',
        equityAllocation: 55,
        fee: { ter: 0, allIn: 0.44 },
        returns: { 2020: 2.8, 2021: 10.8, 2022: -9.5, 2023: 9.2, 2024: 10.5, 2025: 5.2 },
      },
      {
        name: 'Frankly Gentle 25',
        slug: 'frankly-gentle-25',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'MODERATE',
        equityAllocation: 25,
        fee: { ter: 0, allIn: 0.44 },
        returns: eq20Returns,
      },
    ],
  );

  await seedProvider(
    {
      slug: 'finpension',
      name: 'finpension',
      description: 'Pilier 3a digital a frais reduits',
      website: 'https://finpension.ch',
      isDigital: true,
    },
    [
      {
        name: 'finpension Equity 100',
        slug: 'finpension-equity-100',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'AGGRESSIVE',
        equityAllocation: 99,
        fee: { ter: 0, allIn: 0.39 },
        returns: { 2020: 5.5, 2021: 20.4, 2022: -17.5, 2023: 16.1, 2024: 18.5, 2025: 8.8 },
      },
      {
        name: 'finpension Equity 80',
        slug: 'finpension-equity-80',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'GROWTH',
        equityAllocation: 80,
        fee: { ter: 0, allIn: 0.39 },
        returns: { 2020: 4.3, 2021: 16.0, 2022: -13.2, 2023: 12.8, 2024: 14.9, 2025: 7.2 },
      },
      {
        name: 'finpension Equity 60',
        slug: 'finpension-equity-60',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'BALANCED',
        equityAllocation: 60,
        fee: { ter: 0, allIn: 0.39 },
        returns: { 2020: 3.4, 2021: 11.8, 2022: -9.5, 2023: 10.0, 2024: 11.2, 2025: 5.8 },
      },
      {
        name: 'finpension Equity 40',
        slug: 'finpension-equity-40',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'MODERATE',
        equityAllocation: 40,
        fee: { ter: 0, allIn: 0.39 },
        returns: eq40Returns,
      },
      {
        name: 'finpension Equity 20',
        slug: 'finpension-equity-20',
        investmentCategory: 'PASSIVE_INDEX',
        riskLevel: 'CONSERVATIVE',
        equityAllocation: 20,
        fee: { ter: 0, allIn: 0.39 },
        returns: eq20Returns,
      },
    ],
  );

  await seedProvider(
    {
      slug: 'postfinance',
      name: 'PostFinance',
      description: 'Compte et fonds 3a PostFinance',
      website: 'https://postfinance.ch',
      isDigital: false,
    },
    [
      {
        name: 'PostFinance Pension 75',
        slug: 'postfinance-pension-75',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'GROWTH',
        equityAllocation: 75,
        fee: { ter: 0.94, allIn: 0.94 },
        returns: { 2020: 3.5, 2021: 14.8, 2022: -14.5, 2023: 11.5, 2024: 13.8, 2025: 6.5 },
      },
      {
        name: 'PostFinance Pension 45',
        slug: 'postfinance-pension-45',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'BALANCED',
        equityAllocation: 45,
        fee: { ter: 0.89, allIn: 0.89 },
        returns: { 2020: 2.5, 2021: 9.8, 2022: -8.5, 2023: 8.0, 2024: 9.5, 2025: 4.5 },
      },
      {
        name: 'PostFinance Pension 25',
        slug: 'postfinance-pension-25',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'MODERATE',
        equityAllocation: 25,
        fee: { ter: 0.84, allIn: 0.84 },
        returns: { 2020: 1.8, 2021: 5.5, 2022: -4.5, 2023: 5.0, 2024: 5.8, 2025: 3.0 },
      },
    ],
  );

  await seedProvider(
    {
      slug: 'ubs',
      name: 'UBS',
      description: 'UBS Vitainvest fonds de prevoyance',
      website: 'https://ubs.com',
      isDigital: false,
    },
    [
      {
        name: 'UBS Vitainvest 100 World',
        slug: 'ubs-vitainvest-100',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'AGGRESSIVE',
        equityAllocation: 100,
        fee: { ter: 1.47, allIn: 1.47 },
        returns: { 2020: 3.8, 2021: 18.2, 2022: -19.5, 2023: 13.8, 2024: 16.1, 2025: 7.5 },
      },
      {
        name: 'UBS Vitainvest 75 World',
        slug: 'ubs-vitainvest-75',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'GROWTH',
        equityAllocation: 75,
        fee: { ter: 1.39, allIn: 1.39 },
        returns: { 2020: 2.8, 2021: 13.5, 2022: -14.2, 2023: 10.5, 2024: 12.5, 2025: 5.8 },
      },
      {
        name: 'UBS Vitainvest 50 World',
        slug: 'ubs-vitainvest-50',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'BALANCED',
        equityAllocation: 50,
        fee: { ter: 1.29, allIn: 1.29 },
        returns: { 2020: 1.8, 2021: 8.5, 2022: -8.5, 2023: 7.2, 2024: 8.5, 2025: 4.0 },
      },
    ],
  );

  await seedProvider(
    {
      slug: 'swisscanto',
      name: 'Swisscanto',
      description: 'Fonds de prevoyance Swisscanto (ZKB)',
      website: 'https://swisscanto.com',
      isDigital: false,
    },
    [
      {
        name: 'Swisscanto BVG 3 Equity 100',
        slug: 'swisscanto-bvg3-100',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'AGGRESSIVE',
        equityAllocation: 100,
        fee: { ter: 1.31, allIn: 1.31 },
        returns: { 2020: 4.1, 2021: 18.8, 2022: -18.9, 2023: 14.2, 2024: 16.5, 2025: 7.8 },
      },
      {
        name: 'Swisscanto BVG 3 Equity 75',
        slug: 'swisscanto-bvg3-75',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'GROWTH',
        equityAllocation: 75,
        fee: { ter: 1.21, allIn: 1.21 },
        returns: { 2020: 3.2, 2021: 14.2, 2022: -13.8, 2023: 11.0, 2024: 13.0, 2025: 6.2 },
      },
      {
        name: 'Swisscanto BVG 3 Equity 45',
        slug: 'swisscanto-bvg3-45',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'BALANCED',
        equityAllocation: 45,
        fee: { ter: 1.08, allIn: 1.08 },
        returns: { 2020: 2.2, 2021: 9.5, 2022: -8.8, 2023: 7.8, 2024: 9.2, 2025: 4.5 },
      },
    ],
  );

  // ── Insurance providers (linked 3a) ──

  await seedProvider(
    {
      slug: 'swiss-life',
      name: 'Swiss Life',
      description: 'Assurance-vie et pilier 3a lie',
      website: 'https://swisslife.ch',
      isDigital: false,
    },
    [
      {
        name: 'Swiss Life 3a Dynamic',
        slug: 'swiss-life-3a-dynamic',
        investmentCategory: 'INSURANCE',
        riskLevel: 'GROWTH',
        equityAllocation: 45,
        fee: { ter: 0, allIn: 1.85 },
        returns: { 2020: 1.8, 2021: 8.2, 2022: -7.5, 2023: 6.8, 2024: 8.0, 2025: 3.8 },
      },
      {
        name: 'Swiss Life 3a Balanced',
        slug: 'swiss-life-3a-balanced',
        investmentCategory: 'INSURANCE',
        riskLevel: 'BALANCED',
        equityAllocation: 30,
        fee: { ter: 0, allIn: 1.75 },
        returns: { 2020: 1.2, 2021: 5.5, 2022: -4.8, 2023: 4.5, 2024: 5.5, 2025: 2.8 },
      },
      {
        name: 'Swiss Life 3a Guaranteed',
        slug: 'swiss-life-3a-guaranteed',
        investmentCategory: 'INSURANCE',
        riskLevel: 'CONSERVATIVE',
        equityAllocation: 0,
        fee: { ter: 0, allIn: 1.6 },
        returns: { 2020: 0.5, 2021: 0.5, 2022: 0.5, 2023: 0.5, 2024: 0.5, 2025: 0.5 },
      },
    ],
  );

  await seedProvider(
    {
      slug: 'zurich',
      name: 'Zurich',
      description: 'Solutions de prevoyance 3a Zurich Assurance',
      website: 'https://zurich.ch',
      isDigital: false,
    },
    [
      {
        name: 'Zurich Vita Invest Dynamic',
        slug: 'zurich-vita-invest-dynamic',
        investmentCategory: 'INSURANCE',
        riskLevel: 'GROWTH',
        equityAllocation: 50,
        fee: { ter: 0, allIn: 1.9 },
        returns: { 2020: 2.0, 2021: 8.8, 2022: -8.2, 2023: 7.2, 2024: 8.5, 2025: 4.0 },
      },
      {
        name: 'Zurich Vita Invest Balanced',
        slug: 'zurich-vita-invest-balanced',
        investmentCategory: 'INSURANCE',
        riskLevel: 'BALANCED',
        equityAllocation: 30,
        fee: { ter: 0, allIn: 1.8 },
        returns: { 2020: 1.4, 2021: 5.8, 2022: -5.0, 2023: 4.8, 2024: 5.8, 2025: 2.9 },
      },
      {
        name: 'Zurich Vita Classic',
        slug: 'zurich-vita-classic',
        investmentCategory: 'INSURANCE',
        riskLevel: 'CONSERVATIVE',
        equityAllocation: 0,
        fee: { ter: 0, allIn: 1.55 },
        returns: { 2020: 0.6, 2021: 0.6, 2022: 0.6, 2023: 0.6, 2024: 0.6, 2025: 0.6 },
      },
    ],
  );

  await seedProvider(
    {
      slug: 'baloise',
      name: 'Baloise',
      description: 'Assurance prevoyance 3a Baloise',
      website: 'https://baloise.ch',
      isDigital: false,
    },
    [
      {
        name: 'Baloise 3a Perspectiv',
        slug: 'baloise-3a-perspectiv',
        investmentCategory: 'INSURANCE',
        riskLevel: 'BALANCED',
        equityAllocation: 35,
        fee: { ter: 0, allIn: 1.7 },
        returns: { 2020: 1.5, 2021: 6.2, 2022: -5.5, 2023: 5.0, 2024: 6.0, 2025: 3.0 },
      },
      {
        name: 'Baloise 3a Garantie',
        slug: 'baloise-3a-garantie',
        investmentCategory: 'INSURANCE',
        riskLevel: 'CONSERVATIVE',
        equityAllocation: 0,
        fee: { ter: 0, allIn: 1.5 },
        returns: { 2020: 0.4, 2021: 0.4, 2022: 0.4, 2023: 0.4, 2024: 0.4, 2025: 0.4 },
      },
    ],
  );

  // ── Savings accounts (3a savings account) ──

  await seedProvider(
    {
      slug: 'raiffeisen',
      name: 'Raiffeisen',
      description: 'Compte epargne et fonds 3a Raiffeisen',
      website: 'https://raiffeisen.ch',
      isDigital: false,
    },
    [
      {
        name: 'Raiffeisen Compte Epargne 3a',
        slug: 'raiffeisen-epargne-3a',
        investmentCategory: 'SAVINGS_ACCOUNT',
        riskLevel: 'CONSERVATIVE',
        equityAllocation: 0,
        fee: { ter: 0, allIn: 0 },
        returns: { 2020: 0.35, 2021: 0.35, 2022: 0.35, 2023: 0.65, 2024: 0.9, 2025: 1.0 },
      },
      {
        name: 'Raiffeisen Futura Pension Invest',
        slug: 'raiffeisen-futura-pension',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'BALANCED',
        equityAllocation: 45,
        sustainableEsg: true,
        fee: { ter: 1.15, allIn: 1.15 },
        returns: { 2020: 2.5, 2021: 10.2, 2022: -9.0, 2023: 8.2, 2024: 9.8, 2025: 4.8 },
      },
    ],
  );

  await seedProvider(
    {
      slug: 'migros-bank',
      name: 'Migros Bank',
      description: 'Compte epargne et fonds 3a Banque Migros',
      website: 'https://migrosbank.ch',
      isDigital: false,
    },
    [
      {
        name: 'Migros Bank Compte 3a',
        slug: 'migros-bank-compte-3a',
        investmentCategory: 'SAVINGS_ACCOUNT',
        riskLevel: 'CONSERVATIVE',
        equityAllocation: 0,
        fee: { ter: 0, allIn: 0 },
        returns: { 2020: 0.3, 2021: 0.3, 2022: 0.3, 2023: 0.6, 2024: 0.85, 2025: 0.95 },
      },
      {
        name: 'Migros Bank Fonds 45 V',
        slug: 'migros-bank-fonds-45',
        investmentCategory: 'ACTIVE_MANAGED',
        riskLevel: 'BALANCED',
        equityAllocation: 45,
        fee: { ter: 1.05, allIn: 1.05 },
        returns: { 2020: 2.3, 2021: 9.8, 2022: -8.5, 2023: 7.8, 2024: 9.2, 2025: 4.5 },
      },
    ],
  );

  await seedProvider(
    {
      slug: 'bcv',
      name: 'BCV',
      description: 'Compte epargne 3a Banque Cantonale Vaudoise',
      website: 'https://bcv.ch',
      isDigital: false,
    },
    [
      {
        name: 'BCV Compte 3a',
        slug: 'bcv-compte-3a',
        investmentCategory: 'SAVINGS_ACCOUNT',
        riskLevel: 'CONSERVATIVE',
        equityAllocation: 0,
        fee: { ter: 0, allIn: 0 },
        returns: { 2020: 0.25, 2021: 0.25, 2022: 0.25, 2023: 0.55, 2024: 0.8, 2025: 0.9 },
      },
    ],
  );

  console.log('Done!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
