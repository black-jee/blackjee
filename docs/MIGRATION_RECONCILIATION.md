# Migration reconciliation report

**Date:** 2026-10-24  
**Task:** BJ-DB-001  
**Target:** Supabase project `phdssyexhfyxsmhmmcgb`  
**Repository HEAD inspected:** `b4d23d1b6a5d5a3a629e2f32485ce4c233abe824`

## Current inventory addendum — 2026-10-25

A fresh recursive repository-tree count confirms **19 SQL migration files**, not the 15 stated in the historical snapshot below. The current reconciliation is **20 live applied versions, 13 exact filename/version matches, seven applied bodies missing from the repository, and six repository-only SQL files absent from the live ledger**. The dated inventory at [`MIGRATION_CHAIN_INVENTORY.md`](./MIGRATION_CHAIN_INVENTORY.md) contains the full version-by-version lists. The 15-file count below is retained as part of the original 2026-10-24 report and should not be used as the current count.

## Findings from read-only inspection

### Migration history mismatch

The live Supabase migration history contains 20 applied versions. The first six are the missing baseline bodies:

- `20261024080824_foundation_schema`
- `20261024080924_tighten_rpc_grants_and_policy`
- `20261024081041_daily_solution_release_rpc`
- `20261024081337_numeric_answers_and_admin_review`
- `20261024081603_secure_daily_attempt_sessions`
- `20261024081731_restrict_anon_rpc_execution`

The live history then records these 14 versions, in order:

- `20261024095050_harden_public_schedule_rpc_and_index`
- `20261024100007_daily_challenge_question_assets`
- `20261024100245_pyq_question_image_paths`
- `20261024100341_question_image_path_read_grants`
- `20261024100524_admin_save_daily_challenge`
- `20261024101157_secure_mock_test_attempts`
- `20261024101243_resume_mock_test_attempt`
- `20261024101313_pyq_mock_metadata_read_grants`
- `20261024101531_preserve_pyq_source_provenance`
- `20261024102206_require_auth_for_daily_solution`
- `20261024102525_stable_mock_question_order`
- `20261024103715_admin_pyq_authoring_review`
- `20261024111533_require_pyq_source_and_solution_before_publish`
- `20261024112132_require_pyq_source_page_before_publish`

### Repository migration directory drift

The current repository contains 15 SQL files, but only 13 filenames exactly match versions in live migration history. Three discrepancies require resolution:

1. Live version `20261024112132_require_pyq_source_page_before_publish` has no matching repository file. The repository instead contains `20261024112500_require_pyq_source_page_before_publish.sql`, which has the same page-number guard but a different version.
2. `20261024120000_require_pyq_source_and_solution_before_publish.sql` is present in the repository but is not recorded as applied in the live history. It duplicates the stricter source-page gate and must not be assumed to have run.
3. The source-page guard appears both under the unapplied `112500` filename and inside the unapplied `120000` file. Do not rename, delete, or apply either file until the repository history and intended release sequence are reviewed.

This is more than the original six-file gap: the current migration directory is not an exact representation of the live applied chain. A clean replay must use a reviewed, ordered chain and explicitly document how the original six versions and the version drift are represented. Do not rewrite applied version identifiers in the live project.

### Live schema snapshot (read-only)

The public base tables currently visible are:

- `public.daily_challenge_attempts`
- `public.daily_challenges`
- `public.jee_pyq_questions`
- `public.mock_test_attempts`

The live schema also has private tables used for answer keys, answer attempts/responses, and daily challenge sessions. Read-only inspection returned public functions for daily challenge scheduling, starting/submitting attempts, mock-test lifecycle/results, PYQ grading and admin authoring/review. Policies inspected on public tables constrain admin writes to authenticated users whose server-managed `app_metadata.role` is `admin`, limit attempt reads by owner, and expose only live challenge metadata/published approved PYQs to ordinary readers.

The current `admin_review_jee_pyq_question` definition requires a source PDF and page, non-empty question statement, private answer key, worked solution, and a matching option label for single-correct questions before publishing. Existing production records must not be used as destructive test fixtures.

This is a partial snapshot, not a complete schema dump. Constraint definitions, all column-level grants, private-schema grants, storage policies/buckets, function owners/configuration, triggers, extensions, and all foreign keys still need to be exported and compared before a replay can be considered equivalent.

## Safe next procedure

1. Keep all work read-only on the target while capturing complete schema metadata and object definitions.
2. Retrieve migration history from Git history or other authoritative backup if available; do not invent historical SQL from names alone.
3. Build a clearly labelled reconstruction chain in a separate branch or isolated directory. If historical bodies cannot be recovered, mark reconstructed equivalents as reconstructions and document why they are semantically equivalent; do not silently pretend they are original bodies.
4. Provision a disposable isolated PostgreSQL/Supabase-compatible environment. Replay from empty state and compare tables, columns, constraints, indexes, triggers, RLS policies, grants, functions, and storage configuration with the target.
5. Resolve the `112132` / `112500` / `120000` drift in review before merging a canonical migration directory.
6. Run role-based security tests as anonymous, ordinary student, owner, and admin using disposable fixtures. Confirm answer keys never become public.
7. Update `docs/DATABASE_PLAN.md`, `docs/TASKS.md`, `docs/VERIFICATION_LOG.md`, and the session handover with concrete evidence.
8. Obtain explicit owner approval before any potentially risky migration against the target. Never reset the target project as a way to fix history.

## Actions taken in this session

- Re-queried live migration history and repository migration filenames.
- Queried live public table columns, public routine names/definitions (partial), public RLS policies, and public indexes.
- Verified CI run [40092001380](https://github.com/black-jee/blackjee/actions/runs/40092001380) completed successfully, including lint, typecheck, unit tests, Playwright E2E, format check, and production build.
- No DDL, migration apply, reset, row mutation, publication, or deployment action was performed.

## Expanded read-only security/storage inventory

A follow-up catalog query found:

- **RLS:** enabled on all four application tables in `public` and all five application tables in `private`. RLS is not forced on these tables.
- **Private-schema policies:** zero explicit policies. Private tables have table ACLs owned by `postgres` and no direct grants to `anon` or `authenticated` in the inspected ACLs; access is intended through guarded functions.
- **Application triggers:** zero non-internal triggers on `public` and `private` tables.
- **Storage buckets:** zero rows in `storage.buckets`; no storage policies were returned. This means no application bucket is currently configured in this project. Do not assume question images can be served from Supabase Storage until a bucket and its access model are intentionally provisioned.
- **Function hardening:** inspected security-sensitive admin functions are owned by `postgres`, marked `SECURITY DEFINER`, and set `search_path` to empty. Their bodies use schema-qualified objects and validate `auth.uid()` plus server-managed `app_metadata.role = admin`. The PYQ review function checks source PDF/page, private answer key, worked solution, and option-label consistency before publishing. The function ACL shown for that review RPC grants execute to `authenticated` and `service_role`, not `anon` or `PUBLIC`.
- **Public RLS policies:** student attempt reads are owner-scoped (or admin-scoped for daily challenge attempts); live daily challenge schedule and approved/published PYQs are the ordinary-reader paths; challenge/PYQ write policies require authenticated admin role; mock attempt reads are owner-scoped.

### Remaining caveats

This is catalog inspection, not a schema dump. Full function bodies were truncated in some tool output and must be captured per function; column-level grants, sequence grants, schema ACLs, extension versions, storage API configuration, and auth/storage platform configuration still need validation. A disposable database has not yet been provisioned, so migration replay equivalence remains untested.

## Follow-up read-only catalog pass — 2026-10-24

A subsequent aggregate catalog query against the same target confirmed the following counts for the `public` and `private` application schemas:

| Catalog item          | Observed |
| --------------------- | -------: |
| Base tables           |        9 |
| Columns               |       93 |
| Constraints           |       49 |
| Indexes               |       23 |
| RLS policies          |       10 |
| Functions             |       12 |
| Non-internal triggers |        0 |

RLS is enabled on all nine application tables; `FORCE ROW LEVEL SECURITY` is false on all nine. Installed extensions observed were `pg_stat_statements 1.11`, `pgcrypto 1.3`, `plpgsql 1.0`, `supabase_vault 0.3.1`, and `uuid-ossp 1.1`.

The query was read-only. These counts improve the inventory baseline but do not establish replay equivalence: full function bodies, ACLs/grants, sequences, auth/storage platform configuration, and a clean isolated replay still require review. The owner has no budget for a billable Supabase branch, so no paid branch/project is to be provisioned. Continue exploring no-cost replay options only.

## Follow-up provenance search — 2026-10-24

- Searched the repository's GitHub code index for all six missing baseline migration identifiers; no matching indexed results were returned.
- Inspected the repository migration-path commit history and current branch list. The migration-path history contains the recent migration work, but no authoritative baseline bodies for the six missing versions were found; the only branch returned was `main`.
- This is evidence of an unsuccessful search in the currently accessible repository, not proof that no backup exists elsewhere. Do not treat similarly named migrations from the legacy/reference repository as authoritative because its schema and migration sequence differ.
- Supabase's official migration guidance explains that Git migration files and the remote `supabase_migrations.schema_migrations` records are separate sources, and that `migration repair` changes history records rather than executing or reverting SQL. Therefore, a repair command cannot recover missing SQL bodies and is not an appropriate fix for this repository gap. See [Supabase Database Migrations](https://supabase.com/docs/guides/deployment/database-migrations) and [Supabase CLI migration reference](https://supabase.com/docs/reference/cli/supabase-inspect-db-role-configs).
- Latest observed workflow status at this pass: CI run [40094999185](https://github.com/black-jee/blackjee/actions/runs/40094999185) was still in progress for handover commit `857d781868302a9cff5b8b5ecb7d948440c99de8`; GitHub Pages run [40094999467](https://github.com/black-jee/blackjee/actions/runs/40094999467) was also in progress. Re-check before claiming those checks passed.
- No production database writes, migration repairs, paid branches, or project creation were performed.

## Routine inventory follow-up — 2026-10-24

A targeted read-only query captured all 12 application routines in `public` with identity arguments, owner, security-definer flag, `proconfig`, definition length, and effective ACL entries. All 12 are owned by `postgres` and pin `search_path` to the empty string. Eleven routines are `SECURITY DEFINER`; `get_current_daily_challenge()` is the sole invoker-security routine and is executable by `anon` and `authenticated` to return the public schedule view. The other eleven are executable by `authenticated`, `service_role`, and the owner; no `anon` execute grant appeared in this result.

Routine list: `admin_review_jee_pyq_question`, `admin_save_daily_challenge`, `admin_save_jee_pyq_question`, `get_current_daily_challenge`, `get_daily_challenge_result`, `get_mock_test_result`, `grade_jee_pyq`, `resume_mock_test`, `start_daily_challenge`, `start_mock_test`, `submit_daily_challenge`, `submit_mock_test`.

This inventory confirms the routine-level ACL/configuration summary, but it is not a full semantic security review of all function bodies. Body-by-body checks and tests with disposable anonymous/student/admin identities remain required before declaring security verification complete.

## Latest security-advisor and CI follow-up — 2026-10-24

### Advisor results (read-only)

- Security advisor: five `rls_enabled_no_policy` informational findings for private tables (`private.daily_challenge_answer_keys`, `private.daily_challenge_sessions`, `private.jee_pyq_answer_attempts`, `private.jee_pyq_answer_keys`, and `private.mock_test_responses`). RLS is enabled and the inspected ACLs do not grant direct table access to `anon` or `authenticated`. Keep them private; do not add broad policies just to silence the linter. Re-check schema and grants whenever functions change. Reference: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy
- Security advisor: 11 authenticated-callable `SECURITY DEFINER` functions. These are intended RPC entry points, not automatically exploitable; their function bodies need role/ownership checks. Read-only body inspection confirmed `auth.uid()` checks in the six inspected student-facing routines (`get_daily_challenge_result`, `get_mock_test_result`, `grade_jee_pyq`, `resume_mock_test`, `start_daily_challenge`, and `submit_daily_challenge`). Mock-test RPC ownership checks and PYQ admin role checks also have existing SQL regression assertions. This does not replace live role-based negative tests. Reference: https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
- Performance advisor: one missing covering index on `private.mock_test_responses.question_id` (`mock_test_responses_question_id_fkey`). Add only after reviewing query/foreign-key access patterns and incorporating the index into the reviewed migration chain; do not apply an ad hoc production DDL change while migration history is inconsistent. Reference: https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys
- Performance advisor also reports seven indexes as unused. The project has very little attempt/question traffic, so these are not evidence that the indexes should be dropped. Retain until query patterns and production-like statistics justify a reviewed change.

### CI and code follow-up

- Formatting corrections were committed in `lib/time/ist-local-date-time.ts` and `tests/question-schema.test.ts` (commit `26288c3e44a39ddcd28c3cb5a34f96c8313237f3`).
- GitHub Pages workflow [40097368965](https://github.com/black-jee/blackjee/actions/runs/40097368965) completed successfully for that commit.
- CI workflow [40097368791](https://github.com/black-jee/blackjee/actions/runs/40097368791) was still running when this entry was written. Do not describe CI as green until its final conclusion is `success`.
- No production database writes, DDL, migration repairs, content publication, paid infrastructure, or deployment changes were performed during this follow-up.

## Latest repository verification — 2026-10-24

- CI run [40098020175](https://github.com/black-jee/blackjee/actions/runs/40098020175) completed successfully on `b4d23d1b6a5d5a3a629e2f32485ce4c233abe824`.
- GitHub Pages workflow [40098020314](https://github.com/black-jee/blackjee/actions/runs/40098020314) completed successfully for the same commit. This confirms that workflow completed, not that the Vercel production deployment or authenticated application flows are verified.
- Migration source recovery and clean isolated replay remain unverified. No production DDL, migration repair/apply, reset, data mutation, or paid infrastructure was used.

## Current reconciliation checkpoint — 2026-10-25

This checkpoint supersedes the older file-count statement above; earlier sections are retained as dated investigation history.

- A fresh read of the live migration API reports **20 applied versions**, from `20261024080824` through `20261024112132`.
- The repository migration directory currently contains **19 SQL files**. **13** have exact version/filename matches in the live ledger.
- **Seven applied versions lack same-version SQL bodies in the repository:** the six baseline versions listed above, plus live version `20261024112132_require_pyq_source_page_before_publish`.
- **Six repository migration files are absent from the live ledger:** `20261024112500_require_pyq_source_page_before_publish.sql`, `20261024120000_require_pyq_source_and_solution_before_publish.sql`, `20261024130000_harden_mock_test_input_nulls.sql`, `20261025100000_enforce_unique_pyq_option_labels.sql`, `20261025110000_harden_daily_challenge_authoring_integrity.sql`, and `20261025120000_add_mock_test_response_question_id_index.sql`.
- The `112500` and `120000` files overlap on the PYQ source/page/solution publishing guard. Do not infer that either ran in production or rename them to make the ledger appear aligned.
- CI run [40184792445](https://github.com/black-jee/blackjee/actions/runs/40184792445) (#608) completed successfully on branch head `724ad7fed30afe1c4893eb7ba6209afbdb31bdbf`; both `quality` and `reconstruction-replay` passed. This is repository CI evidence, not production migration-history recovery.

**Disposition:** keep the live database and migration ledger unchanged. Recover the seven missing historical bodies from an authoritative backup or source commit if one becomes available. If none can be found, maintain a separately labelled reconstructed baseline and require explicit review of the six repository-only files before selecting a canonical future migration chain.
