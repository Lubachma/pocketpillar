-- CreateEnum
CREATE TYPE "EmploymentStatus" AS ENUM ('EMPLOYED', 'SELF_EMPLOYED', 'UNEMPLOYED', 'RETIRED');

-- CreateEnum
CREATE TYPE "MaritalStatus" AS ENUM ('SINGLE', 'MARRIED', 'REGISTERED_PARTNERSHIP', 'DIVORCED', 'WIDOWED');

-- CreateEnum
CREATE TYPE "Pillar3aAccountType" AS ENUM ('BANK', 'INSURANCE');

-- CreateTable
CREATE TABLE "financial_profiles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "employment_status" "EmploymentStatus" NOT NULL,
    "marital_status" "MaritalStatus" NOT NULL,
    "number_of_children" INTEGER NOT NULL DEFAULT 0,
    "gross_annual_income" INTEGER NOT NULL,
    "net_annual_income" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "financial_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pillar2_accounts" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "provider_name" TEXT,
    "current_capital" INTEGER NOT NULL,
    "projected_capital_at_retirement" INTEGER,
    "conversion_rate" DOUBLE PRECISION,
    "insured_salary" INTEGER,
    "coordination_deduction" INTEGER,
    "annual_bvg_contribution" INTEGER,
    "annual_supra_contribution" INTEGER,
    "is_vested_benefits" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pillar2_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pillar3a_accounts" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "provider_name" TEXT NOT NULL,
    "account_type" "Pillar3aAccountType" NOT NULL,
    "current_balance" INTEGER NOT NULL,
    "annual_contribution" INTEGER,
    "interest_rate_or_return" DOUBLE PRECISION,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pillar3a_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tax_situations" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "taxable_income" INTEGER NOT NULL,
    "total_deductions" INTEGER,
    "church_tax" BOOLEAN NOT NULL DEFAULT false,
    "taxable_wealth" INTEGER,
    "municipality" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tax_situations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "financial_profiles_user_id_key" ON "financial_profiles"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "tax_situations_user_id_key" ON "tax_situations"("user_id");

-- AddForeignKey
ALTER TABLE "financial_profiles" ADD CONSTRAINT "financial_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pillar2_accounts" ADD CONSTRAINT "pillar2_accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pillar3a_accounts" ADD CONSTRAINT "pillar3a_accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tax_situations" ADD CONSTRAINT "tax_situations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
