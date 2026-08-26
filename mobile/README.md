# PocketPillar — Flutter App (mobile/)

Flutter iOS/Android app for Swiss pension planning, replacing the SwiftUI
iOS app (see the repository README).

## Prerequisites

- Flutter 3.44+ (`flutter doctor` fully green)
- For Android: emulator or device. Flutter is configured with JDK 26
  (`--jdk-dir=/opt/homebrew/opt/openjdk`) — do not change it; the Android
  toolchain is therefore pinned to **Gradle 9.6.1** + **AGP 9.3.1** (the
  template's Gradle 9.1.0 / AGP 9.0.1 are incompatible with Java 26).
- For iOS: Xcode + simulators (CocoaPods)

## Configuration (dart-defines)

The app reads its configuration at compile time via `--dart-define`.
**No real value is ever committed**: ask the project owner for them, or
retrieve them from the project's Supabase dashboard.

> **Two separate environment files**: the `.env` at the repo root serves
> the **backend** (database, Redis, **Supabase service role key** — admin
> secrets); `mobile/.env` serves **the app** and contains only
> `SUPABASE_URL` and `SUPABASE_ANON_KEY` (public keys). Never pass the
> root `.env` to `--dart-define-from-file`: the service role key would end
> up embedded in the app binary.

| Variable          | Role                                              | Default                  |
| ----------------- | ------------------------------------------------- | ----------------------- |
| `API_BASE_URL`    | Fastify backend URL                               | `http://localhost:3000` |
| `SUPABASE_URL`    | Supabase project URL (auth)                       | _(empty — auth inactive)_ |
| `SUPABASE_ANON_KEY` | Supabase public key (anon/publishable)          | _(empty — auth inactive)_ |
| `REVENUECAT_API_KEY_IOS` | RevenueCat public SDK key (iOS purchases)   | _(empty — purchases unavailable)_ |
| `REVENUECAT_API_KEY_ANDROID` | RevenueCat public SDK key (Android)     | _(empty — purchases unavailable)_ |
| `DEV_LOGIN_EMAIL` | Dev credentials for the "Dev Login" button        | _(empty — bypass)_       |
| `DEV_LOGIN_PASSWORD` | (see below)                                     | _(empty — bypass)_       |

Without `SUPABASE_URL`/`SUPABASE_ANON_KEY`, the app still starts (useful
for tests and UI development) but signing in is not possible.

**Dev Login** (button visible only in debug builds): with Supabase
configured **and** `DEV_LOGIN_EMAIL`/`DEV_LOGIN_PASSWORD` provided, it
fills in the form and submits the sign-in. Otherwise it bypasses
authentication without a session (equivalent to iOS's `devSignIn()` —
handy for UI development without a backend; signing out in Settings
resets the bypass).

## Sign in with Apple

iOS only (SHA-256 nonce → Supabase `signInWithIdToken`, same flow as the
SwiftUI app). **No Android web OAuth flow for now** (it requires an Apple
Service ID — decision logged in the project journal, phase 3.1).

Native configuration required **once, manually, in Xcode**:
open `ios/Runner.xcworkspace`, target **Runner** → tab
**Signing & Capabilities** → **+ Capability** → **Sign in with Apple**.
Without this capability, the button fails at runtime (no compilation
error).

Tip: copy `.env.example` to `.env` (**not committed**, gitignored) at the
root of `mobile/` and fill in the two public keys:

```bash
cp .env.example .env   # from mobile/
```

then run with `--dart-define-from-file=.env` — this is what the
`make ios` / `make android` targets do (they check its presence via
`mobile-env-check`). A `secrets.json` (JSON format, also gitignored)
works as well.

> **Android**: the emulator cannot see the host machine's `localhost` —
> use `http://10.0.2.2:<PORT>` to reach the local backend (cleartext HTTP
> is allowed in debug/profile builds only, via those variants' manifests).
> **iOS simulator**: `http://localhost:<PORT>` works directly.
> The `make ios` / `make android` targets derive this port from the root
> `.env`'s `PORT` (default 3000).

## Local Notifications (annual reminders)

Two recurring annual reminders at 10 a.m. (parity with the iOS
`NotificationService.swift`): year-end checklist on **December 15**, 3a
contribution on **November 1**. Opt-in via the "Annual reminders" toggle
in Settings (persisted, `core/notifications/`); rescheduled on every
startup as long as the toggle is on (refreshes the language). Fixed
`Europe/Zurich` timezone.

Native configuration:

- **Android** (`android/app/src/main/AndroidManifest.xml`) — already in
  place:
  - `POST_NOTIFICATIONS`: merged from the plugin's manifest; the
    **runtime** permission is requested when the toggle is turned on
    (Android 13+);
  - `RECEIVE_BOOT_COMPLETED` + `ScheduledNotificationReceiver` /
    `ScheduledNotificationBootReceiver` receivers: rescheduling after a
    device reboot or app update;
  - reminders scheduled as an **inexact alarm** (`inexactAllowWhileIdle`):
    **do not** declare `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`
    (unnecessary here, and subject to Play review).
- **iOS**: nothing to configure — the permission (alert + sound) is
  requested at runtime when the toggle is turned on; no capability or
  `Info.plist` key is required for local notifications.

## Document OCR Scan (profile pre-fill)

The "Scan a salary certificate" button (profile form, Financial situation
section) and the "Scan an LPP statement" button (LPP account add/edit
sheet): photo or image → **100% on-device** text recognition (no image
ever leaves the phone) → proposal card with the extracted values,
**editable** → "Apply" fills in the form fields **without saving
anything** (assistive OCR: the user checks, then saves). States handled:
scan in progress, no text found, no value recognized, analysis failure —
each with a way back to source selection.

Extracted fields (fr/de/en, pure Dart parsing in
`features/financial_profile/data/ocr_parsing.dart`):

- **salary certificate**: gross salary ("Salaire brut", "Bruttolohn",
  "Gross salary"…);
- **LPP statement**: retirement savings ("Avoir de vieillesse",
  "Altersguthaben"…), insured salary ("Salaire assuré", "Versicherter
  Lohn"…), annual contribution ("Cotisation annuelle", "Jahresbeitrag"…).

Extraction rules: Swiss formats `95'000.00`, `95 000`, `95'000.-`
(typographic apostrophes, thin/non-breaking spaces, `O`→`0` noise)
normalized; per-field plausibility windows (salaries 1'000–10'000'000
CHF); dates and years are never mistaken for amounts; projection/buyback
lines ("projeté", "Einkauf", "libre passage"…) ignored for the current
balance; **largest plausible amount** after the label (handles
monthly/annual and mandatory/supplementary/total columns); `null` if
nothing is plausible — never a fabricated value.

Testable abstraction: `TextRecognitionService` and `ScanImagePicker`
(`image_picker`) sit behind interfaces injected by providers
(`application/ocr_scan_providers.dart`) — tests mock them, the native
plugin is never touched off-device.

Per-platform OCR engine (same custom MethodChannel
`ch.pocketpillar.app/ocr`, same `recognizeText(imagePath)` → raw text
contract):

- **iOS = Apple Vision** (`ios/Runner/OcrPlugin.swift`,
  `VNRecognizeTextRequest` `.accurate`, languages `fr-CH`/`de-CH`/`en`,
  `usesLanguageCorrection = true` — verified to have no effect on
  amounts). System framework: **no pod**, native arm64 simulator.
  Replaces `google_mlkit_text_recognition`, whose binaries have no arm64
  simulator slice — and since iOS 26 no longer runs x86_64, the simulator
  refused the install ("must be updated by the developer").
- **Android = ML Kit** (custom binding
  `android/app/src/main/kotlin/ch/pocketpillar/app/OcrPlugin.kt`, Gradle
  dependency `com.google.mlkit:text-recognition` — Gradle only affects
  Android: nothing is linked on iOS). Since Flutter doesn't support
  platform-conditional pub dependencies, keeping the
  `google_mlkit_text_recognition` pub package for Android would have kept
  linking its pods on iOS: hence the custom binding on both sides.

Native configuration:

- **Android**: minSdk `flutter.minSdkVersion` (24) is sufficient (ML Kit
  requires 21+). Photo capture delegates to the device's camera app: no
  `CAMERA` permission to declare.
- **iOS**: deployment target **13.0** (Flutter's minimum — Vision requires
  iOS 13+; ML Kit's 15.5 constraint disappeared along with it) and
  `NSCameraUsageDescription` in `ios/Runner/Info.plist` (photo capture;
  the gallery goes through the system picker, no key needed). `pod
  install` required after `flutter pub get`. **Simulator**: native arm64
  build, install, and OCR — no more Rosetta fallback.

## PocketPillar Premium (paywall, CHF 39/year)

Freemium monetization "option B" (contract `docs/api-contract.md` §11):
free = profile + basic calculators + checklist/reminders + 3a-catchup
preview + 1 document; **Premium** = detailed 3a-catchup, 4 scenarios
(couple, staggered withdrawal, home purchase, divorce), OCR, PDF export,
recommendations + best-match, unlimited documents.

- **Purchases**: `purchases_flutter` (RevenueCat), `premium` entitlement,
  annual subscription. SDK configured **lazily** from
  `REVENUECAT_API_KEY_IOS` / `REVENUECAT_API_KEY_ANDROID` (dart-defines) —
  without a key, the app works fully and the paywall (`/paywall`) shows
  "Purchase unavailable". `Purchases.logIn(<users.id>)` (the **backend**
  uuid from `GET /users/me`, never the Supabase id) as soon as the user is
  known; `logOut()` on sign-out (`app.dart`).
- **Displayed status**: `premium` block from `GET /users/me` (source of
  truth), merged with an **optimistic unlock** after purchase while
  waiting for the RevenueCat webhook to feed the backend
  (`features/premium/application/premium_providers.dart`).
- **UI gates**: lock icon on the 4 Premium scenarios, OCR buttons, PDF
  export; upsell on the 3a-catchup preview, recommendations, the
  best-match, and document upload. Every backend **402** is mapped to a
  `PremiumRequiredException` (`core/api/`) → opens the paywall.
- **iOS**: `pod install` required after `flutter pub get` (RevenueCat
  pods).

## Icon and Splash Screen

The icon (white plate + 3 cyan/blue/purple pillar bars on a `#007AFF`
blue background) and the splash screen are generated — **no PNG is
hand-edited**:

```bash
# 1. Regenerates the 1024×1024 sources in assets/icon/
#    (Dart script + image package; design documented in the script)
dart run tool/generate_icons.dart

# 2. Regenerates native iOS + Android icons (all sizes,
#    Android adaptive icons: foreground + #007AFF background)
dart run flutter_launcher_icons

# 3. Regenerates native iOS + Android splash screens (#007AFF background,
#    centered logo; Android 12+: icon on a white disc)
dart run flutter_native_splash:create
```

The configuration for both generators lives in `pubspec.yaml`
(`flutter_launcher_icons` / `flutter_native_splash` keys). After changing
the theme colors (`lib/core/theme/app_colors.dart`), carry the values
over into `tool/generate_icons.dart` then rerun the 3 commands.

## Commands

```bash
flutter pub get                 # install dependencies

# Run (with local .env):
flutter run --dart-define-from-file=.env
# or explicitly:
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...

flutter analyze                 # static analysis (zero issues expected)
flutter test                    # unit + widget tests
flutter gen-l10n                # regenerate translations after editing ARB files
flutter build apk --debug       # verification Android build
```

### Web Build (PWA)

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define-from-file=.env
```

Prod: `--dart-define=API_BASE_URL=https://api.pocketpillar.ch` + `--dart-define=REVENUECAT_WEB_PURCHASE_LINK=…`.
Deployment: `wrangler pages deploy build/web --project-name=pocketpillar-app`
(see the repository README).
Native features missing from web (v1): OCR, biometric lock, local reminders, Sign in with Apple.

## E2E (Smoke) Tests

`integration_test/smoke_test.dart` covers the critical end-to-end path
(real app + real router, all infrastructure providers mocked — **no
backend/Supabase required**):

1. first launch → 4-page onboarding → "Get started" → login → "Dev
   Login" (debug bypass) → dashboard → Check-up tab → 4-step wizard
   filled in → results displayed;
2. navigation across the 6 tabs.

These tests run on a **started device, emulator, or simulator** (the
`integration_test` binding requires a target; `flutter test
integration_test/` without a device fails with "No supported devices
connected"):

```bash
flutter devices                              # find the target's id
flutter test integration_test/ -d <id>

# Example targets:
flutter emulators --launch pixel_7_api36     # Android emulator
open -a Simulator                            # booted iOS simulator
```

The first run compiles the app for the target (several minutes);
subsequent runs are much faster (incremental builds).

## Structure

```
lib/
├── main.dart               # entry point (Supabase init, ProviderScope)
├── app/                    # MaterialApp.router, go_router router, tab shell
├── core/
│   ├── api/                # dio client (JWT, refresh on 401, typed errors)
│   ├── auth/               # Supabase session, biometric lock
│   ├── notifications/      # annual reminders (flutter_local_notifications)
│   ├── storage/            # flutter_secure_storage
│   ├── theme/              # Theme.swift palette, Material 3, shared components
│   ├── l10n/               # fr/de/en ARB files (+ gen/ generated by flutter gen-l10n)
│   └── utils/              # CHF formatting (centimes → 1'234'567.89)
└── features/               # one feature = one {application,data,presentation} folder
    ├── auth/                   onboarding/   dashboard/   financial_profile/
    ├── calculator/             scenarios/    couple/      providers/
    └── documents/              checklist/    settings/
```

Architecture rules (spec §3.2): every feature has `application/`, `data/`,
`presentation/`; a feature never imports another feature's `data/` layer;
no business logic on the app side (everything goes through the backend
API).

## Foundation Highlights

- **API**: `core/api/api_client.dart` attaches the Supabase JWT to every
  request, sends `Accept-Language`, refreshes the token once on 401 then
  signs out on failure. Every 4xx/5xx error is parsed per the contract's
  `{ "error": "…" }` format (`docs/api-contract.md`).
- **Amounts**: the API speaks in **centimes**; `formatChf` formats with
  the Swiss apostrophe (`CHF 1'234'567.89`).
- **Biometric lock**: after > 60 s in the background, a lock screen
  appears (can be disabled in Settings — preference persisted).
- **i18n**: fr (default), de, en. Edit `lib/core/l10n/app_*.arb` then run
  `flutter gen-l10n`.

## App Identity

- **Bundle id / applicationId**: `ch.pocketpillar.app` (iOS and Android —
  continuity with the archived SwiftUI app).
- **Version**: `1.0.0+1` (`pubspec.yaml`, `version` key).

## Status

Redesign shipped (v1.0.0-refonte): 10 features ported, 400+ unit/widget
tests green, smoke E2E green on iOS and Android, icons and splash
generated. See the repository README for phase details and feature
parity with the SwiftUI app.
