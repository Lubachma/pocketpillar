# Production image of the PocketPillar API (Phase 3 — Fly.io deployment).
# Local build : docker build -t pocketpillar-api .
# Local run   : docker run --env-file .env -p 3000:3000 pocketpillar-api

# ── Build: full dependencies, TS compilation, Prisma client ──
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
# prisma/ before npm ci: the postinstall hook (prisma generate) needs the schema.
COPY prisma ./prisma
RUN npm ci
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
# Dummy DATABASE_URL: prisma.config.ts reads it at load time, generate doesn't need it.
RUN DATABASE_URL=postgresql://dummy npx prisma generate --config prisma/prisma.config.ts \
    && npm run build

# ── Runtime: prod dependencies + generated Prisma client ──
FROM node:24-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
COPY prisma ./prisma
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
# --ignore-scripts skipped @prisma/engines' postinstall: bring the engine
# binaries from the build stage (migrate deploy needs the schema engine, and
# the runtime user cannot write into the root-owned node_modules).
COPY --from=build /app/node_modules/@prisma/engines ./node_modules/@prisma/engines
COPY --from=build /app/dist ./dist
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
