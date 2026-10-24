# BLACK-JEE project status

**Last updated:** 2026-10-24  
**Overall status:** In progress — foundation committed; database reconciliation and runtime verification remain open. Not production-ready.

## Environment

| Item | Observed status |
|---|---|
| New GitHub repository | `black-jee/blackjee`, public, default branch `main`; empty before this foundation commit |
| New Supabase | `phdssyexhfyxsmhmmcgb`, ACTIVE_HEALTHY, PostgreSQL 17.11, Tokyo region |
| Supabase migrations | 7 entries after first hardening migration; migration SQL is being reconciled into Git |
| Supabase tables | 7 inspected public/private tables; empty at inspection |
| Supabase Edge Functions | None deployed at inspection |
| Legacy source ZIP | Readable; 84 files total |
| Live website comparison | Blocked/incomplete; direct fetch did not return page content |

## Work log

- **Verified:** ZIP opens successfully and file inventory enumerated.
- **Verified:** Identified 17 HTML pages, SQL schema/migrations, two Edge Function sources, manifests, question images, Python audits and GitHub workflows.
- **Verified:** Read `docs/SYSTEM_MAP.md`, buyer due-diligence notes, import standard, source schema and question-package notes.
- **Verified:** Target Supabase project metadata, tables/columns, six migration records, deployed Edge Functions list and security/performance advisor findings.
- **Implemented:** Initial Next.js/React/TypeScript/Tailwind scaffold, Supabase SSR/browser client helpers, Zod question schema, shared safe prose/KaTeX renderer, email/Google sign-in, OAuth callback, password reset/update, initial daily challenge route/server actions, Vitest/Playwright tests and CI workflow committed to `main`.
- **Implemented and database-verified:** `get_current_daily_challenge()` now uses invoker privileges; anonymous role can read only schedule columns, not question statement; session `user_id` index added. New migration version `20261024095050` is recorded in Supabase and its SQL is checked into the repository.
- **Tested:** SQL regression assertions for the schedule RPC security and index passed against the target Supabase project. This does not substitute for application runtime or browser tests.
- **Blocked for local runtime checks:** this execution environment cannot resolve `github.com`, so the repository could not be cloned and dependencies could not be installed; no npm test/build result is claimed.
- **Not started:** Full app migration, database compatibility migrations, content import, browser tests and staging deployment.

## Important findings / blockers

1. Original and target schemas differ. Source schema uses `daily_questions` and `attempt_submissions`; target baseline uses `daily_challenges`, `daily_challenge_attempts` and `jee_pyq_questions`. Reconcile before adding or changing tables.
2. Target database has no rows. No old production records, Auth users, storage objects or secrets were supplied in the ZIP.
3. Security advisors flag five browser-callable `SECURITY DEFINER` RPCs, including one callable by `anon`. Each requires body/grant review; do not blindly revoke necessary flows.
4. Four private tables have RLS enabled without policies. Verify grants and exposure; absence of policies is expected only when direct access is denied.
5. One private foreign key lacks a covering index; unused-index notices may be expected while the project is empty.
6. The source has two Edge Function implementations (`admin-cleanup`, `released-solution`), but neither is deployed to the target project.
7. April 4 Shift 1 includes unresolved source questions/visuals; the source README explicitly prohibits publishing it as a complete set.
8. The original live website could not yet be successfully compared in a browser.

## Next actions

1. Finish the source page/RPC/dependency map.
2. Reconstruct the six pre-existing target Supabase migration bodies and capture baseline DDL, grants, policies and function definitions in version control.
3. Complete the Next.js foundation and CI; run type/lint/test/build checks.
4. Complete baseline migration reconstruction and add the shared KaTeX question renderer.
5. Reconcile database naming and permissions before feature-by-feature migration.

## Status vocabulary

- **Not started:** no implementation yet.
- **In progress:** implementation or audit underway.
- **Implemented:** code exists, but not yet proven.
- **Tested:** relevant automated/runtime tests have run.
- **Verified:** prescribed checks passed and evidence is recorded.
- **Blocked:** missing source, permissions, configuration or authoritative content prevents safe completion.
