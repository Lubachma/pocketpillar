-- CreateEnum
CREATE TYPE "InvestmentCategory" AS ENUM ('SAVINGS_ACCOUNT', 'PASSIVE_INDEX', 'ACTIVE_MANAGED', 'MIXED', 'INSURANCE');

-- CreateEnum
CREATE TYPE "RiskLevel" AS ENUM ('CONSERVATIVE', 'MODERATE', 'BALANCED', 'GROWTH', 'AGGRESSIVE');

-- CreateTable
CREATE TABLE "pillar3a_providers" (
    "id" UUID NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "website" TEXT,
    "is_digital" BOOLEAN NOT NULL DEFAULT true,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pillar3a_providers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pillar3a_products" (
    "id" UUID NOT NULL,
    "provider_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "investment_category" "InvestmentCategory" NOT NULL,
    "risk_level" "RiskLevel" NOT NULL,
    "equity_allocation" INTEGER NOT NULL,
    "sustainable_esg" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pillar3a_products_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pillar3a_product_fees" (
    "id" UUID NOT NULL,
    "product_id" UUID NOT NULL,
    "ter_percent" DOUBLE PRECISION NOT NULL,
    "custody_fee_percent" DOUBLE PRECISION,
    "all_in_fee_percent" DOUBLE PRECISION NOT NULL,
    "entry_fee_percent" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "exit_fee_percent" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pillar3a_product_fees_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pillar3a_performance" (
    "id" UUID NOT NULL,
    "product_id" UUID NOT NULL,
    "year" INTEGER NOT NULL,
    "return_percent" DOUBLE PRECISION NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pillar3a_performance_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "pillar3a_providers_slug_key" ON "pillar3a_providers"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "pillar3a_products_slug_key" ON "pillar3a_products"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "pillar3a_product_fees_product_id_key" ON "pillar3a_product_fees"("product_id");

-- CreateIndex
CREATE UNIQUE INDEX "pillar3a_performance_product_id_year_key" ON "pillar3a_performance"("product_id", "year");

-- AddForeignKey
ALTER TABLE "pillar3a_products" ADD CONSTRAINT "pillar3a_products_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "pillar3a_providers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pillar3a_product_fees" ADD CONSTRAINT "pillar3a_product_fees_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "pillar3a_products"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pillar3a_performance" ADD CONSTRAINT "pillar3a_performance_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "pillar3a_products"("id") ON DELETE CASCADE ON UPDATE CASCADE;
