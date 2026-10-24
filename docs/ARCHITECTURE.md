# BLACK-JEE target architecture

## Status

**Proposed foundation; implementation is in progress.** The source-of-truth for behavior is the uploaded archive plus the original public repository/site when accessible. The new GitHub repository and Supabase project are the only implementation targets.

## Application structure

- **Next.js App Router + React + strict TypeScript** for routes, server components, layouts, and typed modules.
- **Tailwind CSS** and reusable accessible components for a consistent mobile-first design system.
- **Server-side boundaries:** server actions / route handlers perform privileged workflows only after validating the current user and their server-managed role. Client-side role checks are presentation only.
- **Supabase Auth** for identity and cookie-backed SSR sessions. Never use user-editable metadata for authorization.
- **PostgreSQL + RLS** for student ownership, private answer keys, challenge sessions, and published content. High-risk grading, attempt limits, release windows and admin operations stay in trusted database functions or server code.
- **Supabase Storage** for private solution photos and question assets where suitable, with explicit bucket policies and server-side validation.
- **Zod** at API, import, form, and content boundaries.
- **KaTeX** through one shared question renderer for statements, choices, explanations, and math-bearing images.
- **Vitest** for unit/integration logic; **Playwright** for real browser workflows.
- **GitHub Actions** for formatting/lint, type-check, tests, dependency/security checks and production build.

## Proposed module boundaries

```text
app/
  (student)/             dashboard, profile, daily challenge, archive
  (practice)/            PYQ browse, chapter practice, mock tests
  admin/                 protected administration and review queues
  api/                   narrow server-side endpoints where needed
components/
  layout/                navigation, shells, responsive primitives
  questions/             statement, option, image and KaTeX rendering
  forms/                 validated reusable form fields
lib/
  auth/                  session and server-side role checks
  supabase/               browser/server clients
  questions/              schemas, import normalization, rendering helpers
  security/               audit helpers and safe error handling
supabase/
  migrations/             version-controlled schema changes
  functions/              deployable Edge Functions, when required
tests/                     Vitest and Playwright
docs/                      source inventory, decisions, runbooks and status
```

## Important data-flow rules

1. Public pages may read only intentionally public schedule/question metadata.
2. The answer key and unreleased solution must not be included in student payloads before release.
3. Students can read/write only their own private attempts, sessions, profiles and uploads.
4. Admin authority comes from server-controlled `app_metadata.role` or an equivalent protected role table, never `user_metadata` or a submitted client flag.
5. Challenge start/submission is server-authoritative: timestamp, uniqueness and closing time are checked in the database, not trusted from the browser clock.
6. Imports enter a draft/review state. No manifest or status flag alone authorizes publication.
7. Asset references are validated; missing images receive an accessible fallback rather than an unlabelled broken image.
8. Any destructive bulk operation must require server-side admin authorization and explicit confirmation; export-before-delete is retained where the source supports it.

## Existing database compatibility note

The new Supabase project currently contains a baseline with `daily_challenges`, `daily_challenge_attempts`, `jee_pyq_questions` and private key/session tables. The source archive describes a different naming model around `daily_questions` and `attempt_submissions`. These schemas must be reconciled with an explicit migration/mapping. Do not replay the original schema wholesale or delete existing project objects.

## Deployment

Use a host that supports Next.js server rendering and route handlers (for example, Vercel or another compatible Node/serverless platform). GitHub Pages is only the old static deployment and is not the target for server-side authorization. Production traffic stays on the original website until staging is tested and the owner explicitly approves cutover.
