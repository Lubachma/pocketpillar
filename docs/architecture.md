# Architecture

## Overview

```
┌────────────────────────────────────────────────────────────┐
│  Flutter app — one codebase: iOS · Android · web (PWA)     │
│  Riverpod (state/DI) · go_router (guarded routes)          │
│  dio + Supabase JWT interceptor · ARB i18n (fr/de/en)      │
└──────────────────────────┬─────────────────────────────────┘
                           │ HTTPS — Bearer JWT (Supabase)
┌──────────────────────────▼─────────────────────────────────┐
│  Fastify 5 API (Node 20+, TypeScript, ESM) — Fly.io        │
│  modules: auth · user · financial-profile · calculator ·   │
│           recommendation · provider · document ·           │
│           subscription · health                            │
│  plugins: auth (JWT verify + Redis cache) · cors · helmet  │
│           rate-limit · error-handler · prisma · redis ·    │
│           swagger                                          │
├────────────┬───────────────────────┬───────────────────────┤
│ PostgreSQL │ Supabase Auth+Storage │ Redis (Upstash)       │
│ (Supabase) │ accounts · documents  │ JWT cache (≤ 5 min)   │
│ Prisma v7  │ (signed URLs, 5 min)  │ premium cache (60 s)  │
└────────────┴───────────────────────┴───────────────────────┘
```

## Key decisions

- **The backend is the single source of truth.** No business calculation
  ever runs in the client — every amount shown in the app comes from the
  API. This keeps the tax engine testable, auditable
  ([fiscal-accuracy.md](fiscal-accuracy.md)), and consistent across
  platforms.
- **All monetary values are integers in centimes.** No floating-point
  money anywhere in the API or the database.
- **Pure calculation functions.** The calculator modules
  (`src/modules/calculator/*`) are pure — testable without a database;
  the 390-test Vitest suite encodes official anchor values.
- **Unified error contract.** Every error is `{ "error": "<message>" }`
  (localized via `Accept-Language`), enforced by a global error-handler
  plugin.
- **i18n on both sides.** Backend: `t(locale, key, params)` keyed off
  `Accept-Language`. Mobile: ARB files + `flutter gen-l10n`
  (French default, German, English).
- **Auth.** Supabase issues JWTs; the API verifies them with a bounded
  Redis cache (never beyond the token's own `exp`, ≤ 5 min, fail-open to
  re-verification). A separate best-effort resolver serves public
  endpoints that enrich responses for logged-in users without ever
  returning 401.
- **Premium gating.** A `subscriptions` table is the source of truth;
  `requirePremium` returns HTTP 402 on gated routes. The RevenueCat
  webhook updates the table (event reordering guarded by
  `lastEventAt`); a 60-second Redis cache in front. Currently dormant in
  production (public demo grants full access).
- **Documents.** Uploaded via multipart to Supabase Storage through the
  API (private bucket); downloads use 5-minute signed URLs; free tier is
  limited to 1 document.

## Mobile structure (feature-first)

```
mobile/lib/
├── app/        MaterialApp, router (6 tabs, auth-guarded)
├── core/       api (dio + interceptors), auth, config, l10n,
│               notifications, purchases, storage, theme, utils
└── features/   one folder per feature:
    <feature>/{application,data,presentation}
    auth · calculator · checklist · couple · dashboard · documents ·
    financial_profile · onboarding · premium · providers · scenarios ·
    settings
```

- `application/` holds Riverpod providers and services, `data/` the DTOs
  and repositories (API calls), `presentation/` the screens and widgets.
- **Web/PWA degradations** are explicit: OCR, biometric lock, and local
  reminders are native-only and hidden behind `kIsWeb` guards; file I/O
  goes through a conditional-import trio (`native_file_io*.dart`) so the
  same code compiles on mobile and web.
- Infrastructure is abstracted behind providers, so widget tests and the
  mocked E2E journey (`integration_test/`) run without any backend.

## Deployment

- **API**: Docker multi-stage image on Fly.io (region `lhr`), Prisma
  `migrate deploy` as the release command, `/health` healthcheck,
  auto-stop machines (scale to zero at rest).
- **Web app**: `flutter build web` deployed to Cloudflare Pages
  (`app.pocketpillar.ch`).
- **Demo account**: a scheduled Fly machine resets it nightly by replaying
  the real API end to end (`src/scripts/reset-demo.ts`) and re-granting
  premium directly in the `subscriptions` table.
- **CI** (GitHub Actions): backend typecheck + lint + format + tests with
  coverage thresholds; mobile analyze + tests + debug APK build.

## API reference

See [api-contract.md](api-contract.md) for the full endpoint contract
(conventions, error format, enums, premium gating, calculators).
