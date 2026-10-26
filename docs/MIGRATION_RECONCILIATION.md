# Migration reconciliation report

**Date:** 2026-10-24  
**Task:** BJ-DB-001  
**Target:** Supabase project `phdssyexhfyxsmhmmcgb`  
**Repository HEAD inspected:** `b4d23d1b6a5d5a3a629e2f32485ce4c233abe824`

## Current inventory addendum — 2026-10-26

The Library archive `blackjee-foundation.zip` yielded five exact-version migration bodies, restored byte-for-byte to the repository. Current reconciliation is **20 live applied versions, 24 repository SQL files, 18 exact filename/version matches, two applied bodies still missing, and six repository-only SQL files**. The unresolved applied bodies are `20261024081337_numeric_answers_and_admin_review` (archive has only the similar-purpose `20261024081110` file) and `20261024112132_require_pyq_source_page_before_publish`. Older counts below are historical snapshots. See the recovery log and chain inventory for exact hashes and version-by-version details.

## Findings from read-only inspection

### Migration history mismatch

The live Supabase migration history contains 20 applied versions. Five of the seven bodies previously missing from the repository have now been restored byte-for-byte from `blackjee-foundation.zip`:

- `20261024080824_foundation_schema`
- `20261024080924_tighten_rpc_grants_and_policy`
- `20261024081041_daily_solution_release_rpc`
- `20261024081603_secure_daily_attempt_sessions`
- `20261024081731_restrict_anon_rpc_execution`

Two applied bodies remain unresolved:

- `20261024081337_numeric_answers_and_admin_review` — the archive contains `20261024081110_numeric_answers_and_admin_review.sql`, but the version differs and it is not accepted as the applied body.
- `20261024112132_require_pyq_source_page_before_publish` — no exact body was found in the inspected archives.

The live history also records the following 14 later versions, in order:

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

The current repository contains 24 SQL migration files, of which 18 match live migration versions exactly. Six repository files are not recorded as applied in the live history:

1. `20261024112500_require_pyq_source_page_before_publish.sql` — overlaps the applied publication-gate purpose but is not the `20261024112132` original.
2. `20261024120000_require_pyq_source_and_solution_before_publish.sql` — similar publication checks; not recorded as applied.
3. `20261024130000_harden_mock_test_input_nulls.sql` — CI-tested only; not verified applied to production.
4. `20261025100000_enforce_unique_pyq_option_labels.sql` — CI-tested only; not verified applied to production.
5. `20261025110000_harden_daily_challenge_authoring_integrity.sql` — CI-tested only; not verified applied to production.
6. `20261025120000_add_mock_test_response_question_id_index.sql` — CI-tested only; not verified applied to production.

The archive's `20261024081110_numeric_answers_and_admin_review.sql` is retained as a near-match, not added to the active migration directory, because it is not the applied `20261024081337` version. Do not rename, delete, or apply local-only files until the canonical sequence is reviewed. Do not alter the production ledger to mask these gaps.

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

## Recovery recheck — 2026-10-26 continuation

The exact paths for the two unresolved applied bodies were checked again on `chore/schema-reconstruction` through the GitHub contents API and both are absent (404). A fresh Git commit search showed documentation updates but no evidence of either original SQL body being restored. The Library semantic search did not return the ZIP itself as a directly inspectable result, so this pass recovered no additional source bytes.

The owner's supplied latest green CI reference is [run #679 / 40243919626](https://github.com/black-jee/blackjee/actions/runs/40243919626); its full job conclusions were not independently retrieved during this pass. A documentation-only recovery-log update was committed as `3657bf634259e47720d77e29c591457da43f7753`; its newly reported Vercel status was pending at last check, and the workflow-run lookup returned no PR-triggered runs for that commit. Do not infer the quality/reconstruction CI result from the Vercel status.

**Disposition unchanged:** two applied bodies remain unresolved; do not substitute `20261024081110`, `20261024112500`, or `20261024120000`. No production database change, migration repair, paid resource, PR merge, or content publication was performed.

## Direct archive inspection addendum — 2026-10-26

All five ZIP archives visible in the ChatGPT Library were inspected by entry path. `blackjee-foundation.zip` (SHA-256 `f0bfe458bdf81f7f84f34ef00e4e1d33c734f231eb31777c9397f659c9ce0433`) contains only the `20261024081110_numeric_answers_and_admin_review.sql` near-match for the numeric/admin migration. The four `BLACK-JEE-main*.zip` files are byte-identical to each other (SHA-256 `8e5abd749a3a6dac6f785cf320d1d23f9ba6c2c02d3df311a89cc1bfd939c44e`) and contain neither missing migration path. Thus no additional original SQL body was recovered from the Library archives inspected.

The inventory and disposition remain unchanged: preserve the two unresolved entries as unresolved, do not relabel near-matches, and do not change production schema/data/grants/migration history. Details and hashes are recorded in `docs/MIGRATION_RECOVERY_SEARCH_2026-10-24.md`.

## Task follow-up — inventory, candidate replay, and current disposition (2026-10-26)

- The read-only ledger counts remain **20 live applied versions**, **24 SQL migration files**, **18 exact version/name matches**, **two unresolved applied bodies**, and **six repository-only files**. No change to production history was made.
- The two unresolved applied bodies remain `20261024081337_numeric_answers_and_admin_review` and `20261024112132_require_pyq_source_page_before_publish`. The similar-purpose archived `20261024081110` is not the original applied body and must not be relabelled.
- A non-deployable candidate remains under `docs/reconstructions/`, outside the Supabase migration directory. Its first disposable replay attempt failed because the reconstructed baseline already had the candidate constraint name; CI did not execute the following assertion step. The candidate was adjusted to replace the existing named constraints and candidate policy in the disposable replay. The next matching CI run must verify the correction before it is called passing.
- The replay is an internal shape check only. Even when green, it does not prove historical provenance or equivalence to the unavailable applied migration body. Do not apply it to production or repair the migration ledger.
- Storage planning now lives in `docs/STORAGE_ASSET_SECURITY_PLAN.md`. It is design-only: the last recorded read-only catalog inspection found no application Storage buckets or policies. No bucket, policy, or asset upload has been created.
- A gated real Supabase Auth test harness is present in `tests/real-supabase-auth.integration.test.ts`; it requires pre-seeded synthetic users and fixture IDs in a dedicated disposable environment. The connected project inventory currently exposes only the production project, so real signed-token execution remains blocked. A skipped suite is not a passing security test.

**Safe disposition:** keep production read-only and PR #2 draft/unmerged. Continue with no-cost isolated CI verification; do not create a billable Supabase project/branch, invent original SQL, or treat candidate CI as proof of live parity.

## Authoritative historical SQL recovery — 2026-10-26

The two previously unresolved applied bodies are no longer missing from the repository. A read-only query of `supabase_migrations.schema_migrations` recovered the single stored SQL statement for each version; those strings were copied into their exact versioned paths under `supabase/migrations/`. See the recovery log for names and stored byte lengths.

The reconstructed numeric-answer candidate and its candidate-only contract check are no longer part of active CI. CI should verify the restored migration chain through the repository's normal isolated reconstruction process, not use the candidate as a substitute for historical SQL.

The production ledger remains untouched. Six repository-only migration files still need a separate reconciliation decision; matching all 20 applied versions does not imply that those six files should be applied.

The six repository-only migration files have now been reviewed in `docs/MIGRATION_REPO_ONLY_REVIEW_2026-10-26.md`. Two are redundant admin-review function rewrites, three are unverified forward hardening changes, and one is an index proposal. No file has been applied to production; other environment ledgers remain unknown, so no file was deleted or renumbered.


## Superseding reconciliation status — 2026-10-26

The historical investigation entries above are retained as a dated log. Any earlier statement that the applied bodies for `20261024081337` and `20261024112132` are still missing is superseded: their stored SQL statement text was recovered through a read-only query of `supabase_migrations.schema_migrations.statements[1]` and copied into the exact versioned migration paths. The archive's `20261024081110` file remains a near-match only and was not used as a substitute.

Current inventory is **20 live applied versions, 26 repository SQL migration files, 20 exact filename/version matches, zero applied versions without a matching file, and six repository-only files**. The six local-only migrations have a separate review in `docs/MIGRATION_REPO_ONLY_REVIEW_2026-10-26.md`; do not delete, renumber, or apply them until other-environment histories and the intended canonical chain are reviewed. Source-text recovery does not itself prove full clean replay or live catalog parity. CI #783 passed on `a5f8bebf346bb68eb9f3310b928e4f2bc62a961b` ([run](https://github.com/black-jee/blackjee/actions/runs/40285101550)). Production schema/data/grants and migration ledger remain unchanged.
