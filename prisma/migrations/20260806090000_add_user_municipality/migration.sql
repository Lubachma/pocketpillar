-- Add the user's municipality of residence (free text) — used for real
-- communal tax multipliers in the calculators when the municipality is covered.
ALTER TABLE "users" ADD COLUMN "municipality" TEXT;
