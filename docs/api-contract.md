# API Contract — mobile client reference

Date: 2026-08-05 (§10 revised 2026-08-06; §1 corrected 2026-08-26 — `POST /providers/best-match` is Premium-gated, not public, see §11) · Branch: `main` · Reference: (internal planning docs, private repo)

This document is the contract the Flutter client must implement. It does not list
every field of every route (Swagger available in dev at `/docs`) but **the
cross-cutting rules and pitfalls** to know before any integration.

---

## 1. General conventions

- **Monetary units: centimes everywhere.** All amounts (inputs AND outputs)
  are integers in CHF **centimes** (`CHF 95'000 = 9_500_000`). No field
  is in CHF. Accepted upper bound: 10¹¹ centimes (CHF 1 billion).
- **Rates**: numbers in percent (`6.0` = 6%), not expressed in centimes.
- **Dates**: ISO 8601 UTC (`createdAt`, `uploadedAt`, …).
- **i18n**: error messages are localized via `Accept-Language`
  (`fr` by default, `de`, `en` supported; `fr-CH` → `fr`, etc.).
- **Auth**: `Authorization: Bearer <JWT Supabase>` on every route except
  `GET /health*`, `POST /calculator/*` **except the four Premium scenarios
  (couple, staggered-withdrawal, property-purchase, divorce-impact — §7/§11)**,
  `GET /calculator/municipalities`,
  `GET /providers*`. *(Correction, 2026-08-26: `POST /providers/best-match`
  was previously listed here as exempt from auth. It is in fact
  **Premium-gated** — authenticated + active subscription required,
  otherwise **402** — like the other §11 premium routes; see §11.)*
  The `userId` always comes from the token, never from the body or the URL.

## 2. Unified error format

**Every** error response (4xx/5xx), including native Fastify errors
(unknown route, rate-limit, validation, 500), has the shape:

```json
{ "error": "human-readable, localized message" }
```

- 400: Zod validation (`{ error: "Erreur de validation" }` — French, follows
  `Accept-Language`; + `details` in dev). Exception: native Fastify 400s
  (`auth`/`document` routes validated by embedded JSON-schema) keep the
  native English message (e.g. `"body must have required property
  'supabaseId'"`) — the **shape** `{ error }` is guaranteed, not the
  message language.
- 401: missing/invalid token or unknown user.
- 403: token subject ≠ body `supabaseId` (register).
- 404: unknown route or resource not found (`{ error: "Ressource non trouvée" }`).
- 409: email already linked to another Supabase account (register).
- 422: incomplete profile (`GET /recommendations`, `GET /score`: canton/birth
  year/financial profile missing).
- 429: rate-limit exceeded (native English message kept, e.g.
  `"Rate limit exceeded, retry in 1 minute"`).
- 500: `{ error: "Une erreur interne est survenue" }` — details never leak.

The client must parse **only** this format. (Old native format
`{ statusCode, error, message }`: removed by the global `setErrorHandler`.)

## 3. Enums

- `maritalStatus`: `SINGLE | MARRIED | REGISTERED_PARTNERSHIP | DIVORCED | WIDOWED`.
  ⚠️ The client must normalize to **`REGISTERED_PARTNERSHIP`** (iOS used to emit
  `PARTNERSHIP`, rejected with 400). Exception: `POST /calculator/staggered-withdrawal`
  only accepts `SINGLE | MARRIED` (treat `REGISTERED_PARTNERSHIP` as `MARRIED`).
- `canton`: 2-letter uppercase codes (`ZH`, `VD`, `GE`, … — 26 cantons).
- `employmentStatus`: `EMPLOYED | SELF_EMPLOYED | UNEMPLOYED | RETIRED`.
- `pillar3aAccountType`: `BANK | INSURANCE`.
- `documentType`: `SALARY_SLIP | BVG_STATEMENT | PILLAR3A_STATEMENT | TAX_DECLARATION | OTHER`.

## 4. 1:1 resources — 404 on first access

`GET /financial-profile` and `GET /financial-profile/tax` return **404** until
the resource exists. The first `PUT` creates the resource (**201**), subsequent
`PUT`s update it (**200**). This is the expected flow: 404 → full PUT.
Later `PUT /financial-profile` calls accept **partial** updates
(only the fields provided are changed — no defaults are injected).

## 5. Documents — multipart field order

`POST /documents` (multipart/form-data): **`@fastify/multipart` only populates
`data.fields` with fields received BEFORE the file part.** The client must
send the **`type` then `year` (optional) fields BEFORE the `file` field**,
otherwise validation fails with 400.

- Accepted MIME types: `application/pdf`, `image/jpeg`, `image/png` (magic bytes checked).
- Max size: 10 MB. `year`: 2000 → current year (dynamic).
- `GET /documents/:id/download` → signed URL valid for 300 s.
- `DELETE /documents/:id` → 204; deletes the Storage file then the row.

## 6. Auth & account

- `POST /auth/register` (rate-limit 3/min): body `{ supabaseId }` — the body's
  `email` field is **optional and ignored** (if provided, it must still be a
  valid email). The email that is kept is **the one from the verified token**,
  never the body's; an existing account with a different `supabaseId` for that
  email → **409** (no re-linking).
- `GET /users/me` → `{ id, email, canton, birthYear, replacementRateGoal, municipality, premium, createdAt }`
  — `premium: { active: boolean, expiresAt: string|null }` (see §11). `PATCH` returns the same object.
- `PATCH /users/me`: `canton`, `birthYear` (1930 → current year − 16),
  `replacementRateGoal` (**replacement-rate target, integer 50–100,
  default 70**), `municipality` (municipality of residence, free text 1–100
  characters — **explicit `null` to clear it**, absent field = unchanged).
- `DELETE /users/me` → **204**. Purges the Storage objects for documents
  (best-effort: a Storage failure is logged, the 204 is not blocked), deletes
  the account and all data (Prisma cascade: profile, LPP/3a accounts, tax
  situation, documents) then the Supabase account. Required by App Store
  5.1.1 / GDPR.

## 7. Calculators (`POST /calculator/*`)

- **Access**: lpp-gap, tax-savings, retirement, municipalities → public
  (try-before-signup). couple, staggered-withdrawal, property-purchase,
  divorce-impact → **Premium** (authenticated + subscription, otherwise **402**, §11).
  3a-catchup → public with a **free preview** (§11).
- Amounts in centimes; `retirementAge` must be **strictly greater than**
  `currentAge`/`age` (otherwise 400).
- **`municipality` field (optional, 1–100 characters)** accepted by
  **tax-savings**, **staggered-withdrawal**, and **couple**: when the
  municipality is one of the ~100 covered municipalities (real ESTV communal
  multipliers, 2026 tax year), its multiplier replaces the cantonal average
  in the communal share of the tax. Matching is case-insensitive,
  accent-insensitive, and separator-insensitive (spaces/hyphens/dots —
  "St. Gallen" = "St.Gallen"), and the BFS cantonal suffix can be omitted
  ("Wetzikon" = "Wetzikon (ZH)"). **Unknown municipality, from another
  canton, or absent → silent fallback to the cantonal average** (historical
  behavior, never an error).
- **`GET /calculator/municipalities?canton=ZH`** (public): list of the
  municipalities covered for a canton, `[{ name, multiplier }]` sorted
  alphabetically (multiplier as % of the base cantonal tax). `[]` for
  cantons with no covered municipality (JU, UR, OW, NW, AI). **400** if
  `canton` is missing or invalid. Feeds the client's "Municipality" picker.
- **Pillar 3a cap (OPP3 art. 7)** — applied by **tax-savings** and
  **3a-catchup** (`src/lib/pillar3a-max-contribution.ts`): with a 2nd
  pillar (`hasSecondPillar: true`) → CHF 7'258; **without a 2nd pillar →
  20% of taxable income, capped at CHF 36'288** (never negative).
  `maxContribution` (tax-savings) and `maxPerYear` (3a-catchup) return this
  **effective** cap, and the deduction taken into account is bounded by it.
  Assumed approximation: taxable income is used as a proxy for *net income
  from gainful employment* (the legal basis is not an API input); for
  3a-catchup, current income is used as the basis for all retroactive years
  (past income is not captured).
- **retirement**: **pillar 3a is EXCLUDED from retirement income** (business
  rule) — withdrawn as a lump sum (`pillar3aAsLumpSum`) and taxed separately.
  `totalAnnualRetirementIncome = AVS pension + LPP pension`. Pillar 3a is
  still projected in `yearByYearProjection` and `projectedPillar3aBalance`.
  **13th AVS pension payment** (vote of 3.3.2024, first payment December 2026):
  `estimatedAvsPension` (input) is the annual pension over **12 monthly
  payments** (scale 44: max CHF 30'240 = 12 × 2'520); the output
  `estimatedAnnualAvsPension` (and the total) is annualized over **13
  monthly payments (×13/12) as soon as the retirement year ≥ 2026**
  (`AVS_13TH_PENSION_FIRST_YEAR`). For **couple**, the 150% cap (LAVS
  art. 35) remains a MONTHLY cap (CHF 3'780): the annual cap served is
  also ×13/12 from 2026 (CHF 49'140 instead of 45'360).
  `estimatedAvsPension` **omitted → dynamic default**: simplified estimate
  from scale 44 (`src/lib/avs-pension-estimate.ts`) — interpolation between
  the min pension of CHF 15'120/year and max of CHF 30'240/year based on
  income (max reached at CHF 90'720/year average income), prorated by
  contribution years **projected to retirement**
  `min(retirementAge − 20, 44)`, rounded to the centime. **Indicative
  estimate**, not an official calculation. If the field is provided, it is
  used as-is (base ×12).
- **lpp-gap**: coordinated salary = 0 below the LPP entry threshold
  (CHF 22'680); otherwise `gross − CHF 26'460` (fixed coordination
  deduction, 7/8 of the max AVS pension), bounded between CHF 3'780
  (legal minimum) and CHF 64'260 (legal maximum); credits of 7/10/15/18%
  (25-34/35-44/45-54/55-65), with the 18% rate extended beyond age 65;
  both projections start from `currentBvgCapital`, and the gaps
  (`contributionGap`, `capitalGap`, `pensionGap`) are clamped to 0.
- **property-purchase**: a withdrawal below the EPL minimum (CHF 20'000),
  or one that cannot be reached given the capital, is **rejected with 400**
  (`{ error: "Le retrait minimum pour l'achat immobilier est de CHF 20'000." }`),
  never silently adjusted. After age 50: max = max(balance at 50, 50% of
  the current balance).
- **staggered-withdrawal**: tax on the lump-sum withdrawal is computed from
  the **official 2026 AFC tables per canton** (`src/lib/cantonal-tax.ts` —
  sampled from the AFC calculator, interpolated; federal art. 38 LIFD
  included, communal adjustment via multiplier ratio, separate married
  scale if `maritalStatus` = MARRIED).
  Strategies: `lump_sum`, `stagger_2_years`, `stagger_N_years` (N =
  min(accounts, 5, years before retirement)); in case of a tax tie, the
  **first** strategy (the simplest) is kept.
- **couple**: simulation for two spouses/partners. Input: `canton`,
  `maritalStatus` ∈ `MARRIED | REGISTERED_PARTNERSHIP | CONCUBINAGE` (the
  only statuses accepted — the others are not applicable to a couple),
  `person1`/`person2` reusing **exactly** the **retirement** inputs (same
  defaults, same `retirementAge > currentAge` refinement, same dynamic
  scale-44 AVS default when `estimatedAvsPension` is omitted). Response:
  - `person1`/`person2`: full individual projections (shape of
    **retirement** — pillar 3a excluded from income).
  - Couple AVS 150% cap (`combinedAvsAnnualRaw`, `combinedAvsAnnual`,
    `avsCapApplied`, `avsCapAnnual` = CHF 45'360 in 2026) applied **only**
    to `MARRIED`/`REGISTERED_PARTNERSHIP` (LAVS art. 35; unmarried
    cohabitants keep two full pensions). `combinedTotalAnnualIncome` = capped
    AVS + LPP pensions; `combinedReplacementRate` on the sum of gross incomes.
  - `taxEstimate`: annual comparison **always provided** — `married`
    (combined income at the married federal scale + cantonal + communal)
    vs. `unmarried` (2 × single scale), each broken down into
    `federalTax`/`cantonalTax`/`communalTax`/`totalTax`;
    `annualDifference` = married − unmarried (> 0 = marriage penalty);
    `cheaperStatus` ∈ `MARRIED | CONCUBINAGE | EQUAL`. Gross income is used
    as a proxy for taxable income, and the cantonal tables (sampled AFC
    single scale) do not distinguish marital status —
    **indicative estimate**.
  - `withdrawalPlan`: pillar 3a the year before retirement, LPP capital at
    retirement, **tax-year anti-collision** (push back one year as long as
    possible, never before the current year, otherwise push later); capital
    amounts are **projected** to retirement (pillar 3a included); tax per
    withdrawal = same model as staggered-withdrawal (married scale if
    married, single otherwise). `simultaneousEstimatedTax` = tax if
    everything is withdrawn in the same year (jointly if married, per
    partner if unmarried cohabitants); `taxSavingsVsSimultaneous` = savings
    from staggering. Plan is empty if there is no capital.
- **3a-catchup**: `currentYear` defaults to the current year (dynamic).
  `maxPerYear` follows the effective OPP3 art. 7 cap (see the "Pillar 3a
  cap" point above) — it applies to the **current year's ordinary
  contribution** (`currentYearGap`). The **retroactive buy-in**, however,
  is capped at the **"small contribution" (OPP3 art. 7b — CHF 7'258 in
  2025 as in 2026) per gap-year, for all profiles** (including
  self-employed people without a 2nd pillar): `yearDetails[].maxContribution`
  and `totalCatchupPotential` are bounded by this amount (bsv.admin.ch —
  "The third pillar"). Documented assumption: the current small
  contribution is applied to past gap years — exact as long as 2025 = 2026.
  `canton`/`maritalStatus`/`municipality` are **optional**:
  when present → `estimatedTaxSavings` is computed on the real scales
  (year by year, each buy-in deducted in its payment year, current income
  as a proxy for future income) and `estimatedMarginalRate` = resulting
  effective rate; when absent → historical flat-rate estimate (marginal
  rate 25/30/35%).

## 8. Recommendations (`GET /recommendations`)

- 422 if the profile is incomplete (see §2).
- Pillar 3a products **with no fee data are excluded** from the compared
  catalog (never treated as free).
- `PROVIDER_SWITCH` is only emitted if the main account's provider is found
  in the catalog (real fees, no invented estimate) and if the fee gap
  is ≥ 0.15%.
- `BVG_VOLUNTARY_PURCHASE`: default conversion rate = **6.8%** (legal LPP
  minimum in force — the drop to 6.0% was part of the reform rejected in
  the 22.09.2024 vote). Never emitted without a declared LPP account — a
  self-employed person with no pension fund (no optional LPP) therefore
  does not receive a buy-in recommendation.
- `OPEN_FIRST_3A` / `MAX_3A_CONTRIBUTION`: the pillar 3a cap follows the
  **20%** rule (OPP3 art. 7 — see §7 "Pillar 3a cap"): for a profile
  without a 2nd pillar (`hasSecondPillar` = false: not `EMPLOYED` and no
  LPP account), min(CHF 36'288, 20% of persisted taxable income — falling
  back to gross); CHF 7'258 otherwise. The computed gap never exceeds the
  real deductible amount.
- `OPEN_ADDITIONAL_3A` (multi-account 3a strategy, batch 11): emitted if
  there are **1 or 2 pillar-3a accounts**, total balance ≥ **CHF 50'000**,
  and retirement is **strictly more than 5 years** away. Recommends opening
  an additional account (2 or 3 total — beyond that, staggering is already
  possible and the marginal gain becomes small; usual practice is 3–5
  accounts). `estimatedLifetimeImpact` = tax savings on the capital between
  a single withdrawal and one staggered over (accounts + 1) years of the
  **balance projected to retirement** (current balance compounded at
  3%/year, with no future contributions — a conservative assumption),
  computed with the real scale from `POST /calculator/staggered-withdrawal`
  (persisted municipality taken into account, married scale for
  married/registered partners); `estimatedAnnualImpact` = 0 (one-time gain
  at retirement). Replaces the former `STAGGERED_WITHDRAWAL` rule (flat 8%
  estimate), which covered the "1 account" case — only a single
  multi-account recommendation is now emitted.

## 8 bis. Retirement-readiness score (`GET /score`)

- Authenticated; **422** if the profile is incomplete (same conditions as
  `/recommendations`, see §2).
- Response: `{ score, breakdown, benchmark, generatedAt }`:
  - `score`: integer 0–100 = sum of 3 criteria (`breakdown[].points`, with
    `maxPoints` 40/30/30 and `label` **already localized** via
    Accept-Language): replacement rate (0–40), pillar 3a savings (0–30),
    retirement horizon (0–30).
  - `benchmark`: age-bracket averages (`bracket: { minAge, maxAge }`,
    **null** outside 25–65 — fallback averages are then returned):
    `averagePillar3aBalance`, `averageReplacementRate` (%), `averageBvgCapital`,
    plus the user's own values used in the calculation
    (`userPillar3aBalance`, `userReplacementRate`, `userBvgCapital`) for
    display comparison.
- The replacement rate is computed server-side with the **same assumptions
  as the `POST /calculator/retirement` schema defaults** (LPP interest
  1.25%, conversion rate 6.8%, pillar 3a return 3%, AVS pension estimated
  from income — simplified dynamic scale-44 default, §7, 3a excluded from
  income): the score and the dashboard summary card show the same rate.

## 9. Health

- `GET /health` → `{ status: "ok", timestamp, version, uptime }` — `version` is
  read **dynamically from `package.json`**.
- `GET /health/ready` → 200 `{ status: "ok", checks… }` or 503
  `{ status: "degraded", checks… }` (DB/Redis). Usable for online/offline status.

## 10. Not covered by this contract (known)

- Score /100 history (monthly delta) and end-of-year checklist: no
  endpoints (client-local for now). The **couple simulation**, on the other
  hand, is covered: see `POST /calculator/couple` (§7).
- JWT cache in `authenticate`: **implemented** (batch 5) — **positive**
  Redis cache: key `auth:jwt:<sha256(token)>` (the raw token is never
  stored), TTL ≤ 300 s bounded by the token's `exp`, fail-open (a Redis
  outage falls back to calling Supabase). A **negative cache** also bounds
  401s: key `auth:jwt:invalid:<sha256>`, TTL 30 s (Supabase network errors
  are never cached). Accepted consequence: a token revoked on the Supabase
  side may remain accepted for up to 5 min. The Prisma resolution of the
  user is **not** cached: a deleted account immediately stops authenticating.

## 11. Premium subscription (launch sprint, 2026-08)

"Option B" paywall: **free** = profile + base calculators (lpp-gap,
tax-savings, retirement) + checklist/reminders + **3a-catchup preview** +
1 document. **Premium (CHF 39/year)** = full 3a-catchup detail, 4 other
scenarios, OCR (gated client-side), recommendations, best-match, PDF export
(gated client-side), unlimited documents.

- **Upsell signal: HTTP 402** `{ error }` (localized) on any premium
  endpoint called without an active subscription → the client opens the
  paywall. Endpoints concerned: `POST /calculator/{couple,staggered-withdrawal,property-purchase,divorce-impact}`,
  `GET /recommendations`, `POST /providers/best-match` (see the §1
  correction — this route is Premium-gated, not public), and document
  uploads beyond 1 (`sub.document_limit`). `GET /score` stays free.
- **`POST /calculator/3a-catchup`** (public): response enriched with a
  `premiumRequired` field. Anonymous/free → `premiumRequired: true` and
  `yearDetails: []` (the totals `totalCatchupPotential`, `estimatedTaxSavings`,
  `maxPerYear`, `currentYearGap`, `mustMaxCurrentYearFirst` are still served
  — an honest preview). Premium → `premiumRequired: false` + full plan.
- **Source of truth**: `subscriptions` table (1 row/user), entitlement
  active iff `expiresAt > now`. Fed by `POST /webhooks/revenuecat` (auth via
  shared header `REVENUECAT_WEBHOOK_AUTH`, accepted forms: raw value or
  `Bearer <value>`; 503 if not configured). Idempotent and tolerant: `TEST`
  event ignored, unknown user → 200 `unknown_user` (no RevenueCat retry),
  reordered events → `stale_ignored` via `lastEventAt`, an event with no
  expiry does not downgrade the entitlement. Redis cache `premium:<userId>`
  TTL 60 s, invalidated by the webhook.
- **App side**: `Purchases.logIn(<users.id>)` after login (the RevenueCat
  `app_user_id` is the local uuid; anonymous ids are resolved via
  `aliases`). The displayed status comes from `GET /users/me` (`premium`),
  with optimistic client-side unlocking right after a successful purchase
  while waiting for the webhook to arrive.
