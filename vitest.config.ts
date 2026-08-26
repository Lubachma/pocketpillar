import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['tests/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      include: ['src/modules/calculator/**', 'src/lib/**'],
      thresholds: {
        // Baseline measured 2026-08 (calculator ≈ 93 %, lib ≈ 86 % — the untested
        // infra clients prisma/redis/supabase still weigh src/lib down; the dead
        // data-source stubs were removed in the 2026-08 review). Floors are set
        // just below the baseline to catch regressions.
        'src/modules/calculator/**': { statements: 80, lines: 80 },
        'src/lib/**': { statements: 85, lines: 85 },
      },
    },
  },
});
