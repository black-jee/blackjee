# BLACK-JEE project status

**Last updated:** 2026-10-24  
**Overall status:** In progress — audit and foundation. Not production-ready.

## Environment

| Item | Observed status |
|---|---|
| New GitHub repository | `black-jee/blackjee`, public, default branch `main`; empty before this foundation commit |
| New Supabase | `phdssyexhfyxsmhmmcgb`, ACTIVE_HEALTHY, PostgreSQL 17.11, Tokyo region |
| Supabase migrations | 6 existing migration-history entries |
| Supabase tables | 7 inspected public/private tables; empty at inspection |
| Supabase Edge Functions | None deployed at inspection |
| Legacy source ZIP | Readable; 84 files total |
| Live website comparison | Blocked/incomplete; direct fetch did not return page content |

## Work log

- **Verified:** ZIP opens successfully and file inventory enumerated.
- **Verified:** Identified 17 HTML pages, SQL schema/migrations, two Edge Function sources, manifests, question images, Python audits and GitHub workflows.
- **Verified:** Read `docs/SYSTEM_MAP.md`, buyer due-diligence notes, import standard, source schema and question-package notes.
- **Verified:** Target Supabase project metadata, tables/columns, six migration records, deployed Edge Functions list and security/performance advisor findings.
- **In progress:** New repository scaffold and required project documentation.
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
2. Capture the target Supabase baseline DDL, grants, policies and function definitions in version control.
3. Complete the Next.js foundation and CI; run type/lint/test/build checks.
4. Add a safe question renderer and initial smoke tests.
5. Reconcile database naming and permissions before feature-by-feature migration.

## Status vocabulary

- **Not started:** no implementation yet.
- **In progress:** implementation or audit underway.
- **Implemented:** code exists, but not yet proven.
- **Tested:** relevant automated/runtime tests have run.
- **Verified:** prescribed checks passed and evidence is recorded.
- **Blocked:** missing source, permissions, configuration or authoritative content prevents safe completion.
