# BLACK-JEE

A full rebuild of the BLACK-JEE JEE preparation platform using Next.js App Router, React, strict TypeScript, Tailwind CSS, Supabase, Zod, KaTeX, Vitest and Playwright.

> **Status: foundation in progress.** This repository does not yet reproduce all legacy features and is not a production replacement. The original public website remains untouched.

## Environments

- New application repository: https://github.com/black-jee/blackjee
- New Supabase project: https://supabase.com/dashboard/project/phdssyexhfyxsmhmmcgb
- Original reference repository: https://github.com/bhavishyacodz/BLACK-JEE
- Original reference website: https://bhavishyacodz.github.io/BLACK-JEE/

The original Supabase project is reference-only and must not be connected to or modified.

## Local development

1. Install Node.js 22 or newer.
2. Install dependencies with `npm install`.
3. Copy `.env.example` to `.env.local`.
4. Set the new project's Supabase publishable key in `.env.local`. Do not add secret/service-role keys to any `NEXT_PUBLIC_*` variable.
5. Run `npm run dev` and open http://localhost:3000.

## Quality commands

- `npm run format:check`
- `npm run lint`
- `npm run typecheck`
- `npm run test`
- `npm run test:e2e`
- `npm run build`

CI has passed these configured quality gates on commit `ffc1437b1381bb000c6a1417210e9891182509a0`; see [the successful CI run](https://github.com/black-jee/blackjee/actions/runs/40101661444). The latest documentation commit also passed CI: [run 40101879382](https://github.com/black-jee/blackjee/actions/runs/40101879382). This verifies the configured repository checks, not a production deployment or live Supabase runtime. Production runtime and deployment linkage remain unverified.

## Project documentation

- [Feature inventory](docs/FEATURE_INVENTORY.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Database plan](docs/DATABASE_PLAN.md)
- [Security plan](docs/SECURITY_PLAN.md)
- [Migration plan](docs/MIGRATION_PLAN.md)
- [Test plan](docs/TEST_PLAN.md)
- [Project status](docs/PROJECT_STATUS.md)

## Security principles

Never trust client-provided roles, clocks, answer keys, attempt counts or publication state. Keep privileged operations server-side, protect student-owned data with RLS, and keep answer keys separate from public question content. Do not commit secrets.
