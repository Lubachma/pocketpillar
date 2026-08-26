-- CreateEnum
CREATE TYPE "DocumentType" AS ENUM ('SALARY_SLIP', 'BVG_STATEMENT', 'PILLAR3A_STATEMENT', 'TAX_DECLARATION', 'OTHER');

-- CreateTable
CREATE TABLE "documents" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" "DocumentType" NOT NULL,
    "filename" TEXT NOT NULL,
    "storage_path" TEXT NOT NULL,
    "mime_type" TEXT NOT NULL,
    "size_bytes" INTEGER NOT NULL,
    "year" INTEGER,
    "uploaded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "documents_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "documents_user_id_idx" ON "documents"("user_id");

-- AddForeignKey
ALTER TABLE "documents" ADD CONSTRAINT "documents_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
