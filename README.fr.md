<p align="center">🇬🇧 <a href="README.md"><strong>English version available here</strong></a></p>

<h1 align="center">🏛️ PocketPillar</h1>

<hr>

<p align="center"><strong>Ta prévoyance suisse, enfin claire.</strong> Un optimiseur indépendant des 2e et 3e piliers — bilan retraite guidé, vraies économies d'impôt, scénarios de vie.</p>

<p align="center">▶ <a href="https://app.pocketpillar.ch"><strong>Essayer en ligne</strong></a> — rien à installer, aucune inscription : « Se connecter avec le compte démo ».</p>

<p align="center">Moteur fiscal ancré aux <strong>données officielles de l'AFC</strong>, validé au franc près.<br>
Trilingue (français · allemand · anglais) — même les libellés calculés côté serveur suivent <code>Accept-Language</code>.</p>

<p align="center">
  <a href="https://github.com/Lubachma/pocketpillar/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/Lubachma/pocketpillar/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/Lubachma/pocketpillar/actions/workflows/codeql.yml"><img alt="CodeQL" src="https://github.com/Lubachma/pocketpillar/actions/workflows/codeql.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="Licence : PolyForm Noncommercial 1.0.0" src="https://img.shields.io/badge/license-PolyForm--NC%201.0.0-blue"></a>
</p>

<p align="center">
  <img alt="Flutter 3.44" src="https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white">
  <img alt="Dart 3.12" src="https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white">
  <img alt="TypeScript 5" src="https://img.shields.io/badge/TypeScript-5-3178C6?logo=typescript&logoColor=white">
  <img alt="Fastify 5" src="https://img.shields.io/badge/Fastify-5-000000?logo=fastify&logoColor=white">
  <img alt="Prisma 7" src="https://img.shields.io/badge/Prisma-7-2D3748?logo=prisma&logoColor=white">
  <img alt="Supabase" src="https://img.shields.io/badge/Supabase-3FCF8E?logo=supabase&logoColor=white">
</p>

| Tableau de bord | Bilan guidé | Scénarios | Documents |
|---|---|---|---|
| ![Tableau de bord](docs/screenshots/dashboard.png) | ![Bilan guidé](docs/screenshots/wizard.png) | ![Scénarios de vie](docs/screenshots/scenarios.png) | ![Coffre-fort documents](docs/screenshots/documents.png) |

<sub>Captures en interface anglaise ; le compte démo est partagé et public — données fictives, réinitialisées chaque nuit.</sub>

<p align="center">
  <img src="docs/screenshots/demo.gif" width="280" alt="Tour du produit en 30 secondes : connexion, tableau de bord avec bulles d'aide, check-up guidé, résultats, scénarios, méthodologie intégrée, coffre à documents">
</p>

## Ce que fait l'app

- **Projection retraite complète** — AVS + LPP + pilier 3a, taux de remplacement, projection année par année, export PDF.
- **Économies fiscales 3a** — barèmes fédéraux, cantonaux et communaux réels pour les 26 cantons.
- **Scénarios de vie** — simulation couple avec chronologie datée des retraites (rente pleine jusqu'à la seconde retraite, puis plafond AVS), retrait échelonné, achat immobilier (EPL), impact divorce, rachat rétroactif 3a (réforme suisse — lacunes dès 2025).
- **Moteur de recommandations** — règles côté serveur, priorisées par impact annuel estimé.
- **Comparaison de prestataires** — frais, performance, ESG, meilleur choix scoré côté serveur.
- **Coffre-fort documents** — stockage privé (chiffré au repos), liens de téléchargement signés (5 minutes).
- **Checklist de fin d'année** — ce qu'il reste à verser avant le 31 décembre.
- **Pédagogie intégrée** — fiches d'aide au toucher partout (les 3 piliers, taux de conversion, impôt au retrait…) et une page « comment calculons-nous ? » en mots simples, miroir de la [doc de méthodologie](docs/fiscal-accuracy.md) de ce repo.

## Précision suisse

Le moteur fiscal est ancré au **calculateur officiel de l'Administration
fédérale des contributions (AFC)** : tables cantonales échantillonnées via
10 686 appels à l'API officielle (26 cantons, célibataire + marié,
interpolation sur une grille de 1 000 CHF jusqu'à 150 000 CHF, plus large au-delà), multiplicateurs cantonaux et
communaux réels, impôt sur les retraits en capital selon les vraies tables par
canton, et tarif fédéral officiel 2026. Les ancres de validation reproduisent
le calculateur officiel **au franc près** et sont re-vérifiables en une
commande (`node scripts/regen-cantonal-tax-tables.mjs --check`).

Méthode, paramètres légaux, approximations documentées et process annuel :
**[docs/fiscal-accuracy.md](docs/fiscal-accuracy.md)** (en anglais).

> PocketPillar fournit de l'information et des simulations indicatives — pas
> du conseil en placement au sens de la LSFin.

## Architecture

```
App Flutter (iOS · Android · web/PWA)
  Riverpod · go_router · dio (intercepteur JWT) · i18n ARB (fr/de/en)
        │  HTTPS + JWT Supabase
        ▼
API Fastify 5 (Fly.io) ── source de vérité unique : aucun calcul
  │        │              métier ne s'exécute côté client
  │        ├─ PostgreSQL (Supabase) — données
  │        ├─ Supabase Auth + Storage — comptes, documents
  │        └─ Redis (Upstash) — cache JWT & premium
  └─ Prisma v7 (adapter-pg), schémas Zod, format { error } unifié
```

Détails : [docs/architecture.md](docs/architecture.md) ·
Référence API : [docs/api-contract.md](docs/api-contract.md) (en anglais)

## Qualité

- **411 tests backend** (Vitest) — fonctions de calcul pures, testées contre les valeurs d'ancrage officielles.
- **521 tests Flutter** (unitaires + widget) et parcours E2E mockés ; `flutter analyze` à **0 issue**.
- CI à chaque push/PR vers `main` (typecheck, lint, format, tests avec seuils de couverture, build APK debug).
- Smoke test en conditions réelles contre n'importe quel déploiement : `scripts/smoke-api.sh <base-url>` (7 étapes, auto-nettoyant).
- La démo publique est réinitialisée chaque nuit par une tâche planifiée qui rejoue la vraie API de bout en bout.

## Démarrage rapide

Prérequis : Node.js ≥ 22, Docker (PostgreSQL + Redis), Flutter 3.44+.
Les cibles `make` supposent macOS ; les commandes `npm`/`flutter` brutes fonctionnent partout.

### Backend

```bash
cp .env.example .env         # configurer les variables d'environnement
make setup                   # npm install + Docker + migrations + seed

make dev                     # serveur de dev avec hot reload
make check                   # typecheck + lint + format
npm test                     # suite Vitest
```

### Mobile (Flutter)

```bash
cd mobile
cp .env.example .env         # SUPABASE_URL + SUPABASE_ANON_KEY (clés publiques uniquement)
flutter pub get && flutter gen-l10n

flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define-from-file=.env

flutter analyze && flutter test
```

Voir [mobile/README.md](mobile/README.md) (en anglais) pour les dart-defines,
le build web/PWA, les tests E2E et les notes par plateforme. `make help` liste
toutes les commandes backend.

## Monétisation (en veille)

Une pile d'abonnement freemium complète est implémentée — webhook RevenueCat,
gating premium (HTTP 402), paywall, restauration d'achat — mais volontairement
**dormante** : la démo publique donne accès à tout et aucun compte de store
n'est connecté. Elle démontre l'architecture d'abonnement de bout en bout.

## Licence

[PolyForm Noncommercial 1.0.0](LICENSE) — code source consultable ; tout usage
commercial est réservé.
