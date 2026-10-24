# Live foundation audit — 2026-10-24

## Scope and safety

Read-only inspection of the connected GitHub repository and target Supabase project `phdssyexhfyxsmhmmcgb`. No database schema/data changes, branch creation, project creation, deployment, or production cutover were performed during this audit. The original/reference Supabase project remains out of scope.

## Verified current state

- GitHub repository: `black-jee/blackjee`, default branch `main`; connected GitHub permissions include push.
- Supabase project: active/healthy, PostgreSQL 17.11, region `ap-northeast-1`.
- Supabase migration API: 20 recorded versions.
- Public schema inspection: `jee_pyq_questions` (5 rows), `daily_challenges` (0), `daily_challenge_attempts` (0), and `mock_test_attempts` (0) were returned; inspected public tables have RLS enabled.
- The five imported PYQs remain unpublished according to the existing project status record. This audit did not inspect or change their content.
- Repository quality gates are configured in `.github/workflows/ci.yml`: continuity validation, `npm ci`, lint, typecheck, Vitest, Playwright, Prettier check, and Next.js build. A current-head CI run was not checked in this audit.

## Security advisor findings requiring review

The live Supabase security advisor returned these groups:

1. **Five private tables with RLS enabled and no policies:** `private.daily_challenge_answer_keys`, `private.daily_challenge_sessions`, `private.jee_pyq_answer_attempts`, `private.jee_pyq_answer_keys`, and `private.mock_test_responses`. An RLS-without-policy finding is not by itself proof of exposure. Verify table grants and all access paths; private schema plus no browser-role grants is the intended defense described in `docs/SECURITY_PLAN.md`.
2. **Eleven SECURITY DEFINER functions callable by authenticated users:** includes admin authoring/review functions and student challenge/PYQ/mock-test workflows. Do not blanket-revoke these or switch them to invoker mode without reviewing each function body, authorization predicate, ownership checks, and intended client call path. Confirm admin functions enforce server-managed `app_metadata.role = admin`; confirm student functions enforce `auth.uid()` ownership and never expose unreleased answer keys.
3. **One unindexed foreign key:** `private.mock_test_responses.question_id`. Assess workload and existing indexes, then add a versioned migration if justified.
4. **Seven unused-index notices:** these are informational on a young/small database and are not a reason to drop indexes without workload evidence.

Advisor findings can change after migrations; rerun the advisors after each relevant backend change and record the date/results.

## Migration reproducibility blocker

The repository's `docs/PROJECT_STATUS.md` records 20 live migration versions, 15 SQL migration files in Git, six missing original migration bodies, and one overlapping file not in live history. The live migration API still reports 20 versions. Reconcile the full version/name list against every file in `supabase/migrations/` before replaying anything. Never invent missing SQL from migration names and never reset the live database to reconstruct history.

## Next safe actions

1. Build a version/name/file inventory from the live migration API and repository; classify every entry as matching, missing body, local-only, or name/version mismatch.
2. Recover the missing migration SQL from authoritative repository history, source archives, or verified database definitions. Mark anything unrecoverable as a blocker rather than guessing.
3. Keep staging replay zero-cost: do not create a Supabase branch or paid project unless its actual cost is known and explicitly accepted. Prefer local PostgreSQL/Supabase CLI replay if a suitable local environment is available.
4. Review the 11 function warnings individually and add/execute negative authorization tests before changing grants.
5. Add the foreign-key index only after checking existing indexes and preparing a reviewed, versioned migration.
6. Verify the latest GitHub Actions run and authenticated student/admin journeys before claiming the application is production-ready.

## Status

Audit completed; no production-impacting action taken. Database replay, current-head CI, real authenticated browser journeys, and deployment runtime remain unverified.
