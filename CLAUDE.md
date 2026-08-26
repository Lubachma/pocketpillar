# PocketPillar — Development Guidelines

## Project Structure

- **Backend API** (repo root): Node.js + TypeScript + Fastify
- **Mobile App** (`mobile/`): Flutter (iOS + Android + web/PWA)
- Legacy iOS SwiftUI app: archived on branch `archive/ios-swift`

## Backend

- Fastify 5, Prisma v7 (adapter-pg), Redis (ioredis), Supabase Auth
- All monetary values in **centimes** (Int)
- Canton-specific tax calculations, anchored to official FTA data (see `docs/fiscal-accuracy.md`)
- ESM imports with `.js` extensions
- Prisma migrations need `--config prisma/prisma.config.ts`
- Unified error format `{ error }` via the global error-handler plugin — keep it consistent
- Run `make help` for available commands
- Tests: Vitest in `tests/` (mirror of `src/`), `npm test` — calculation functions must stay pure (testable without DB)
- Production: `Dockerfile` + `fly.toml` (Fly.io, region `lhr`); `prisma` stays a runtime dependency (release_command = `migrate deploy`)
- Real-conditions API smoke (Supabase cloud auth + backend + Storage): `scripts/smoke-api.sh [base-url]`

## Mobile / Flutter

- Flutter 3.44 (stable), Dart 3.12 — feature-first architecture under `mobile/lib/features/<feature>/{application,data,presentation}`
- Riverpod (state/DI), go_router (navigation, protected routes), dio (API client with Supabase JWT interceptor)
- Backend is the single source of truth: **no business calculation in the app** — amounts come from the API (see `docs/api-contract.md`)
- Secrets/config via `--dart-define` (SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL) — never committed
- `flutter analyze` must stay at 0 issues; `flutter test` green; E2E smoke in `mobile/integration_test/` (mocked); `live_smoke_test.dart` = full journey against the real local backend (command in the file header)
- Android release: signing via `mobile/android/key.properties` (gitignored) — falls back to the debug key when absent
- Web/PWA: `flutter build web` (build flags in `mobile/README.md`); native-only features (OCR, biometrics, local reminders) degrade gracefully behind `kIsWeb` guards
- CI runs analyze + test + debug APK build (see `.github/workflows/ci.yml`)

## i18n

- 3 languages: French (fr), German (de), English (en) — default: French
- Backend: `t(locale, key, params)` with Accept-Language header
- Mobile: ARB files in `mobile/lib/core/l10n/` + `flutter gen-l10n`

## Quality

- `make check` runs backend typecheck + lint + format
- Never commit secrets (.env, credentials, Supabase keys)
- Code review before each feature commit
