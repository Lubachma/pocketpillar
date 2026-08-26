-- Add the user's target replacement rate (50-100 %, default 70).
ALTER TABLE "users" ADD COLUMN "replacement_rate_goal" INTEGER NOT NULL DEFAULT 70;
