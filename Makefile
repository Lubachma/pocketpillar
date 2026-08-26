.PHONY: help dev start build check typecheck lint lint-fix format format-fix clean \
       db-up db-migrate db-seed db-generate db-studio db-reset \
       docker-up docker-down docker-reset docker-logs docker-ps \
       setup up test ios android mobile-env-check api-check

# ──────────────────────────────────────────────
#  PocketPillar — Makefile
# ──────────────────────────────────────────────

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ─── Dev ──────────────────────────────────────

dev: ## Start dev server (hot reload)
	npm run dev

start: ## Start production server
	npm run start

build: ## Compile TypeScript
	npm run build

check: typecheck lint format ## Run all checks (typecheck + lint + format)

typecheck: ## TypeScript type checking
	npm run typecheck

lint: ## ESLint
	npm run lint

lint-fix: ## ESLint auto-fix
	npm run lint:fix

format: ## Prettier check
	npm run format:check

format-fix: ## Prettier write
	npm run format

clean: ## Remove build artifacts
	rm -rf dist

# ─── Docker ───────────────────────────────────

docker-up: ## Start PostgreSQL + Redis containers (starts OrbStack if needed, waits for healthy)
	@if ! docker info > /dev/null 2>&1; then \
		echo "→ Docker unreachable — starting OrbStack…"; \
		open -a OrbStack; \
		for i in $$(seq 1 30); do docker info > /dev/null 2>&1 && break; sleep 1; done; \
		docker info > /dev/null 2>&1 || { echo "❌ Docker still unreachable after 30s"; exit 1; }; \
	fi
	docker compose up -d --wait

docker-down: ## Stop containers
	docker compose down

docker-reset: ## Stop containers and delete volumes
	docker compose down -v

docker-logs: ## Tail container logs
	docker compose logs -f

docker-ps: ## Show container status
	docker compose ps

# ─── Database ─────────────────────────────────

db-migrate: ## Run Prisma migrations
	npx prisma migrate dev --config prisma/prisma.config.ts

db-seed: ## Seed the database
	npm run db:seed

db-generate: ## Regenerate Prisma client
	npx prisma generate

db-studio: ## Open Prisma Studio
	npx prisma studio --config prisma/prisma.config.ts

db-reset: ## Reset DB (drop + migrate + seed)
	npx prisma migrate reset --config prisma/prisma.config.ts

db-up: docker-up db-migrate db-seed ## Full DB setup (docker + migrate + seed)

# ─── Quick start ──────────────────────────────

setup: ## First-time project setup
	npm install
	cp -n .env.example .env || true
	$(MAKE) docker-up
	sleep 3
	$(MAKE) db-generate
	$(MAKE) db-migrate
	$(MAKE) db-seed
	@echo "\n✅ Ready — run 'make dev' to start"

up: docker-up dev ## Start everything (docker + dev server)

test: ## Full stack for manual testing: OrbStack + Docker healthy + migrations + backend (NOT the unit tests — see npm test)
	$(MAKE) docker-up
	$(MAKE) db-migrate
	@if curl -s -m 2 -o /dev/null http://localhost:$(API_PORT)/health; then \
		echo "✅ Backend already listening on :$(API_PORT) — stack ready, run 'make ios' or 'make android'."; \
	else \
		echo "→ Starting the backend on :$(API_PORT) (keep this terminal open)…"; \
		$(MAKE) dev; \
	fi

# ─── Mobile (Flutter) ─────────────────────────

IOS_SIM := iPhone 17 Pro
ANDROID_AVD := pixel_7_api36
ADB := $(HOME)/Library/Android/sdk/platform-tools/adb

# Backend port read from the root .env (default 3000): injected into
# API_BASE_URL so the app stays aligned with `make dev` when PORT changes.
API_PORT := $(shell sed -n 's/^PORT=//p' .env 2>/dev/null | tail -n 1 | tr -d ' \r"' || true)
API_PORT := $(if $(API_PORT),$(API_PORT),3000)

mobile-env-check:
	@test -f mobile/.env || { echo "❌ mobile/.env missing — cp mobile/.env.example mobile/.env then fill in SUPABASE_URL and SUPABASE_ANON_KEY (public keys only, never the service role key)"; exit 1; }

api-check: ## Warns if the local backend is not responding
	@curl -s -m 2 -o /dev/null http://localhost:$(API_PORT)/health || \
		echo "⚠️  Backend unreachable at http://localhost:$(API_PORT) — run 'make test' first (terminal 1), otherwise the app will show network errors."

ios: mobile-env-check api-check ## Launch the Flutter app on the iOS simulator
	xcrun simctl boot '$(IOS_SIM)' 2>/dev/null || true
	open -a Simulator
	cd mobile && flutter run -d iphone \
		--dart-define=API_BASE_URL=http://localhost:$(API_PORT) \
		--dart-define-from-file=.env

android: mobile-env-check api-check ## Launch the Flutter app on the Android emulator
	flutter emulators --launch $(ANDROID_AVD) > /dev/null 2>&1 || true
	$(ADB) wait-for-device
	@DEVICE=""; \
	while [ -z "$$DEVICE" ]; do \
		DEVICE=$$($(ADB) devices | awk 'NR>1 && $$2=="device" {print $$1; exit}'); \
		[ -n "$$DEVICE" ] || sleep 1; \
	done; \
	echo "→ Android device: $$DEVICE (API: http://10.0.2.2:$(API_PORT))"; \
	cd mobile && flutter run -d $$DEVICE \
		--dart-define=API_BASE_URL=http://10.0.2.2:$(API_PORT) \
		--dart-define-from-file=.env
