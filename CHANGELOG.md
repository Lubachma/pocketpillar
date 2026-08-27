# Changelog

All notable changes are documented here. Format inspired by
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.1] — 2026-08-27 — External-review hardening

Fixes from an independent code review of the public repo — every claim
was re-verified against the code before acting on it.

### Fixed
- **Auth no longer converts a Supabase outage into 401s**: availability
  errors (network failure, 5xx, `AuthRetryableFetchError`) now return
  **503** with a retry message instead of caching the token as invalid
  for 10 minutes — a transient outage could previously sign everyone
  out until the negative cache expired.
- **Cross-account data leak in the app**: dashboard, recommendations,
  score and documents providers are invalidated on account change —
  user B logging in after user A in the same run no longer sees A's
  cached data (the financial-profile aggregate was already covered).
- **Malformed `:id` params return 404, not 500** (Prisma P2023 mapped
  in the global error handler).
- **Money bounds match the database**: Zod (and the app's inline
  validators) now cap amounts at int4 max centimes (CHF 21,474,836.47)
  instead of 10¹¹ — over-limit values were previously accepted by
  validation and crashed at the driver with a 500.
- **Biometric lock arms at cold start**: with the toggle ON, killing
  and relaunching the app now locks it (it only armed on background
  return before). A fresh password login does not prompt.
- **Upload send timeout** (30 s) on the API client — a stalled upload
  no longer hangs indefinitely.

### Security
- CI: gitleaks secret scan on every push/PR; all GitHub Actions pinned
  to commit SHAs; CI runs Node 24 (production parity).
- `SECURITY.md`: known-advisories section (deepmerge-ts via Prisma CLI,
  dev-only, no fix released).

### Changed
- Removed dead codegen dependencies (freezed, json_serializable,
  build_runner) — nothing in the app used them.
- HTTP contract tests for the financial-profile and provider routes
  (the two core modules the integration harness was missing).

## [1.1.0] — 2026-08-27 — Practitioner review & pedagogy release

Shaped by a working insurance advisor's review of the live demo (see
`docs/fiscal-accuracy.md`, "Practitioner review").

### Added
- **Couple retirement timeline** (`POST /calculator/couple` → `timeline`):
  dated phases with both spouses' ages — full individual pension until the
  second retirement, then the pro-rata AVS couple cap (LAVS art. 35);
  Argo-style timeline card in the app.
- **Per-spouse capped income view** (`person1Income`/`person2Income`,
  cap allocated pro rata — two max pensions → CHF 2,047.50/month each).
- **3a withdrawal-tax estimate** on `POST /calculator/retirement`
  (optional `canton`/`maritalStatus`/`municipality` → official FTA 2026
  tables) — shown with the net capital in the results.
- **Per-spouse BVG conversion-rate input** with an explicit 6.8%-legal-
  minimum warning.
- **"Understand your pension"** in-app hub (the 3 pillars + plain-words
  methodology, linked from settings and the results) and **help bubbles**
  across the dashboard, forms, results and scenarios (x3 languages).
- **Cold-start resilience**: GET retry interceptor + `/health` warm-up
  (the demo API scales to zero).
- Repo hygiene: Dependabot, CodeQL, 30-min uptime probe with ntfy alert.

### Changed
- **Stepped BVG retirement credits** in the LPP-gap projection
  (7/10/15/18% by age bracket instead of freezing the current age's rate
  — young profiles were understated by up to ~1.8×).
- Score benchmarks requalified as indicative orders of magnitude (no
  citable per-age source exists — verified) with official sanity bounds.
- The couple handler propagates the couple's residence/tax status into
  each spouse projection (consistent withdrawal-tax schedule).
- Trust-proxy policy validates the immediate peer (`uniquelocal` et al.)
  instead of a spoofable hop count.

### Documented limits (roadmap)
- AVS assumed drawn from the chosen retirement age (no anticipation
  reduction below 63, no deferral supplement).
- The couple withdrawal plan optimizes tax years without an LPP
  availability constraint — a sketch, not an executable schedule.

## [1.0.0] — 2026-08 — Initial public release

Swiss pension planning app (2nd & 3rd pillar): guided retirement
calculator anchored to official FTA tax data, life scenarios, provider
comparison, recommendations engine, document vault — Flutter (iOS,
Android, web/PWA) + Fastify/TypeScript API. Trilingual (FR/DE/EN).
Live demo: https://app.pocketpillar.ch
