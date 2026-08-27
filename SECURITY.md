# Security Policy

If you believe you have found a security vulnerability in PocketPillar
(this repository or the public demo at app.pocketpillar.ch), please
report it privately to **privacy@pocketpillar.ch** — do not open a
public issue. You should get a first reply within a few days.

Please note the public demo uses a shared account with fictional data
that is reset nightly; abuse of the shared demo account is not a
vulnerability, but ways to escalate from it definitely are.

## Known advisories (tracked, not fixable yet)

- `deepmerge-ts` (stack exhaustion on recursive object graphs), pulled in
  by the Prisma 7 CLI via `@prisma/config`. The vulnerable code only
  processes THIS repository's own `prisma.config.ts` during builds and
  migrations — never runtime or attacker-controlled input. No upstream
  fix exists for Prisma 7 as of 2026-08-27 (npm's proposed "fix" is a
  downgrade to Prisma 6); Dependabot will surface the patched release.
