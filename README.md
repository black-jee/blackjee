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

CI runs these gates on pushes to `main` and pull requests. The first successful runtime execution is still pending; repository files existing is not proof that checks pass.

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
