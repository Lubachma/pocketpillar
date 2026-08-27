/**
 * Upper bound for every monetary input, in centimes: the Postgres
 * `INTEGER` (int4) maximum. The previous CHF-1-billion bound (10^11)
 * passed validation and then blew up as a Prisma 500 on persisted fields
 * — Prisma maps `Int` to int4 (review 08.2026). CHF 21'474'836.47 is
 * comfortably above any real pension input.
 */
export const MAX_MONEY_CENTIMES = 2_147_483_647;
