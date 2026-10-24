# Live foundation audit — 2026-10-24

## Scope and safety

Read-only inspection of the connected GitHub repository and target Supabase project `phdssyexhfyxsmhmmcgb`. This audit did not change database schema or data, create branches/projects, deploy the app, or publish questions. The original/reference Supabase project remains out of scope.

## Verified state

- GitHub repository: `black-jee/blackjee`, default branch `main`.
- Latest observed commit when this note was refreshed: `73f7609da67348bc0d23ab8ef46a250c5613402e`; CI run [40103034856](https://github.com/black-jee/blackjee/actions/runs/40103034856) was still running at the time of observation. The previous commit `295121b7` passed CI [40102874087](https://github.com/black-jee/blackjee/actions/runs/40102874087) and Pages workflow [40102873650](https://github.com/black-jee/blackjee/actions/runs/40102873650).
- Supabase project: active/healthy, PostgreSQL 17.11, region `ap-northeast-1`.
- Live migration ledger: **20 applied versions**. Repository migration directory: **15 SQL files**, with **13 exact filename/version matches**, **7 missing applied SQL bodies**, and **2 local-only files** not recorded as applied.
- Public and private schemas include nine application tables: four principal public tables plus other public tables and five private answer/session/response tables. Catalog inspection confirms public policies exist for the main student/admin workflows; five private tables have RLS enabled without policies.
- The five private tables have no direct SELECT/INSERT grants for `anon`, `authenticated`, or `service_role` according to the prior read-only privilege checks. Intended access is mediated by narrowly scoped database functions.
- Security advisor findings: five informational RLS-enabled/no-policy notices on private tables; eleven warnings for authenticated execution of SECURITY DEFINER functions; one informational unindexed FK on `private.mock_test_responses.question_id`; seven informational unused-index suggestions.
- The current CI workflow checks continuity, dependency installation, lint, TypeScript, unit tests, Playwright E2E, Prettier, and production build. A passing CI run is not proof of production deployment or real authenticated database workflows.

## Migration reproducibility blocker

The missing applied SQL bodies are:

- `20261024080824_foundation_schema`
- `20261024080924_tighten_rpc_grants_and_policy`
- `20261024081041_daily_solution_release_rpc`
- `20261024081337_numeric_answers_and_admin_review`
- `20261024081603_secure_daily_attempt_sessions`
- `20261024081731_restrict_anon_rpc_execution`
- `20261024112132_require_pyq_source_page_before_publish`

Two local-only files (`20261024112500` and `20261024120000`) overlap in purpose with the later publication gate but do not prove the content of the applied `20261024112132` migration. See [migration chain inventory](./MIGRATION_CHAIN_INVENTORY.md) and [migration discipline](../supabase/migrations/README.md).

Searches of the current repository's indexed code and exact-path Git history did not recover the missing bodies. The older reference repository `bhavishyacodz/BLACK-JEE` contains a different, earlier schema and migration lineage; those files are useful historical context but are **not** substitutes for the missing applied SQL bodies in the new target.

## Security review guidance

1. Do not blanket-revoke authenticated execution or switch SECURITY DEFINER functions to invoker mode. Review each function's intended call path, pinned search path, `auth.uid()` binding, admin metadata check, ownership filter, and answer-release boundary first.
2. Add isolated negative tests for student A versus student B, ordinary-user admin denial, and unreleased solution withholding before changing privileges.
3. The `mock_test_responses.question_id` FK lacks a covering index; assess workload and add a versioned migration only after the migration lineage is reconciled. Do not drop unused indexes solely because the advisor reports low observed usage on a young/small database.
4. Re-run Supabase advisors after reviewed backend changes.

## Safe next actions

1. Continue recovering original SQL from authoritative history, local clones, backups, or captured artifacts.
2. If originals are unavailable, construct a clearly labelled reconstructed baseline from verified live object definitions. Do not misrepresent it as original migration history.
3. Capture tables/columns/defaults, constraints, indexes, policies, grants, function definitions/owners/configuration/ACLs, triggers, extensions, and storage state.
4. Reconcile the local-only publication-gate files before designing a canonical replay chain.
5. Test only in a disposable, no-cost PostgreSQL-compatible environment. The owner has no budget for paid infrastructure; do not create a paid Supabase branch/project.
6. Do not reset, repair, or apply reconstruction SQL to the live target during this work.

## Status

**Inventory: verified read-only. Historical SQL recovery: blocked/not found in accessible repository history. Clean replay: unverified. Authenticated student/admin browser workflows and production deployment runtime: unverified.** No production-impacting action was taken.
