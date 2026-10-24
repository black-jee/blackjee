# BLACK-JEE schema reconstruction status

**Status: incomplete, reconstructed, and not replay-verified.** This folder is a best-effort reconstruction from read-only catalog inspection; it is not recovered historical migration SQL.

## Safety boundaries

- Never apply this draft to production.
- Do not edit production schema or migration history to make this draft fit.
- Replay only in an explicitly disposable database, then compare catalogs.
- No JEE question, answer, or solution content is included in this work.

## Artifacts

- `SECURITY_CHECKPOINT_2026-10-24.md`: read-only live security/catalog findings, assertion execution results, and explicit remaining gates.
- `MIGRATION_RECONCILIATION_2026-10-24.md`: verified facts and clearly labelled inference for the publication-gate migration mismatch.
- `001_reconstructed_table_shapes.sql`: labelled nine-table structural draft, including selected catalog-confirmed constraints and secondary indexes.
- `002_reconstructed_rls_policies.sql`: review draft of the 10 catalog-observed public-table RLS policies. It deliberately does not add table/column grants or private-table policies.
- `003_reconstructed_rpc_definitions.sql`: current live definitions for 12 RPCs, with source-body fingerprints and reviewed execute ACLs. This is a catalog snapshot, not recovered historical migration SQL.
- `004_reconstructed_access_grants.sql`: current browser/service-role schema, table, and column grant snapshot, preserving private-schema isolation and the daily-challenge content boundary.
- `tests/001_reconstruction_catalog_smoke.sql`: read-only catalog assertions for a disposable replay after applying drafts 001 and 002. It checks the nine tables, all expected columns and an exact total of 93 columns, key column defaults/nullability, RLS flags, the 10 policy names, all 14 foreign-key names plus delete/update/match actions and validation/deferrability flags, all 49 observed constraint names and kinds plus an exact total of 49 constraints, selected check/unique constraints, and all 11 observed secondary indexes. It does not insert application data or prove full production parity.
- `tests/002_security_catalog_inventory.sql`: read-only inventory of schema/table/column grants, function ACLs/security attributes, policies, and triggers.
- `tests/bootstrap_supabase_compat.sql`: minimal auth schema/roles used only by CI's disposable PostgreSQL service; it is not a production Supabase bootstrap.
- `tests/003_security_regression_assertions.sql`: read-only catalog assertions for the 11 known privileged RPCs, empty search paths, no anon/PUBLIC execution, in-function authentication/admin guards, all 10 public policy identities/commands/roles plus key predicates, column-level access boundaries, and browser-role isolation from the private schema. The full script passed against both the live catalog and the disposable replay; it is static catalog validation, not a real-user negative RPC test.

## Disposable replay in CI

The CI workflow now starts a temporary PostgreSQL 17 service, bootstraps only the minimum `auth.users`, `auth.uid()`, and `auth.jwt()` surface, applies drafts 001–004, and runs both the catalog smoke test and security catalog assertions. CI run `40113101703` passed both the quality job and disposable replay job. This is a no-cost ephemeral CI container, not a paid Supabase branch or production connection. It does not emulate Supabase Auth fully, replay the missing historical migration chain, or replace real-user end-to-end authorization tests.

## Migration-history reconciliation — read-only inventory (2026-10-24)

A fresh comparison of the live Supabase migration ledger (20 entries) against `supabase/migrations/` (15 SQL files) found:

- **7 live migration versions have no same-version SQL file in the repository:** `20261024080824` (`foundation_schema`), `20261024080924` (`tighten_rpc_grants_and_policy`), `20261024081041` (`daily_solution_release_rpc`), `20261024081337` (`numeric_answers_and_admin_review`), `20261024081603` (`secure_daily_attempt_sessions`), `20261024081731` (`restrict_anon_rpc_execution`), and `20261024112132` (`require_pyq_source_page_before_publish`).
- **2 repository SQL files are not present in the live ledger:** `20261024112500_require_pyq_source_page_before_publish.sql` and `20261024120000_require_pyq_source_and_solution_before_publish.sql`. Their overlapping publication-validation intent requires review; do not apply or delete them merely to reconcile counts.
- The other 13 repository SQL files match versions in the live ledger.

This is a version/name inventory only; it does not recover the seven missing historical SQL bodies or prove that the overlapping files are equivalent. Preserve the live ledger and production schema. Reconstruct missing bodies from verified catalog/function definitions and repository history, label inferred SQL clearly, and only validate replay in a disposable database.

## Security checkpoint — read-only live-catalog comparison (2026-10-24)

A fresh live catalog query confirmed all 11 expected privileged RPCs exist once each, are `SECURITY DEFINER`, pin an empty `search_path`, have no `anon` or `PUBLIC` execute grant, and contain an `auth.uid()` authentication check. The three admin authoring/review RPCs also contain the server-managed `app_metadata` admin-role guard. Browser roles still have no `USAGE` on `private`; direct private-table access remains blocked by the current privilege model.

The full regression script passed against the live catalog and a disposable replay. Real negative tests with anon, ordinary authenticated, cross-user, and admin identities remain a separate gate. Do not revoke authenticated execution from the RPCs wholesale: the intended pattern is authenticated invocation plus authorization enforced inside each function.

The migration source review also found the repository's `20261024111533` function body checks for a non-empty source PDF but not a positive source page, while `20261024112500` and `20261024120000` both require a source document and page plus a private answer key and worked solution. The latter two are not in the live migration ledger under those exact versions; do not apply them just to align history. Confirm the actual live function body and ledger ordering before resolving these overlapping files.

## What was inspected

Read-only catalog inspection of Supabase project `phdssyexhfyxsmhmmcgb` covered the nine known application tables, RLS policies, table grants, indexes, constraints, function signatures/ACLs/security-definer flags, triggers, and Supabase security/performance advisors.

## Improvements made in this branch

- Added observed constraints missing from the first structural draft: positive correct marks/non-positive wrong marks, published questions must be approved, daily challenge time ordering, one attempt per user per challenge, and consistency between mock-test status and submitted timestamp.
- Added observed secondary indexes for challenge scheduling/attempt lookup, question review and paper lookup, and private answer/session lookups.
- Did not add an index merely because an advisor recommended it: the current catalog does not show an index covering `private.mock_test_responses.question_id`, so that remains a performance finding rather than being mislabelled as recovered.
- Added a catalog smoke test that checks the nine expected tables, RLS flags, selected constraints, and observed secondary indexes without inserting data.

## Important audit findings — not production changes

1. The security advisor reports **five private tables with RLS enabled but no policies**. That may be intentional for service/function-only tables; verify schema usage and function access in an isolated replay before deciding whether policies are needed.
2. The security advisor reports **11 SECURITY DEFINER functions executable by authenticated users**, including admin-writing functions. Their bodies must be reviewed for robust authorization checks before the reconstructed backend is considered secure. The current catalog shows these functions are not executable by `anon`; `get_current_daily_challenge()` is not SECURITY DEFINER and is executable by anon.
3. The performance advisor reports a missing covering index on `private.mock_test_responses.question_id`, plus several indexes reported as unused. Unused-index observations on a small/quiet database are not enough to justify dropping indexes.
4. The live public policies use `auth.jwt()->'app_metadata'->>'role' = 'admin'` for admin authorization and row ownership predicates for user records. The ten observed public-table policies are represented in `002_reconstructed_rls_policies.sql`; table/column grants, sequence grants, function definitions/ACLs, storage configuration, and exact full-catalog parity still need a separate reviewed layer before a replay baseline is complete.
5. The structural draft does not yet reconstruct exact grants, function bodies/ACLs, trigger definitions, owners, storage configuration, or every catalog object.

## Verification status

- Live catalog reads: completed.
- Draft constraints/indexes update: committed to `chore/schema-reconstruction`.
- Smoke test file: committed to `chore/schema-reconstruction`.
- Disposable-database replay: **not run**.
- Smoke test execution against a replayed schema: **not run**.
- Production schema and migration history: untouched by this workflow.

## Function-body and ACL review — read-only checkpoint (2026-10-24)

Reviewed the definitions and ACLs of the 11 SECURITY DEFINER functions named by the security advisor. This was inspection only; no live SQL was changed.

- All 11 functions have an empty pinned `search_path` setting.
- Their explicit ACLs list `authenticated`, `service_role`, and the owner; no `anon` or `PUBLIC` execute grant was present in the catalog output.
- The three authoring/review functions (`admin_save_jee_pyq_question`, `admin_save_daily_challenge`, `admin_review_jee_pyq_question`) check `auth.uid()` and the `app_metadata.role = 'admin'` claim inside the function body.
- The student-facing grading, challenge, and mock-test functions check for a signed-in user. The mock-test resume, submission, and result functions scope attempts to `auth.uid()`; result retrieval requires the attempt to be submitted.
- Question publishing has explicit gates for source document/page, a private answer key, a worked solution, and option-label matching for single-correct questions.
- Daily challenge submission requires a valid active session and enforces the challenge time window. Daily challenge solution retrieval waits until `solution_release_at`.

These observations reduce the likelihood that the advisor warnings represent a direct unauthenticated entry point, but they do **not** prove the whole app is secure. Keep the functions in the review scope, add negative/ownership regression tests in an isolated environment, and verify the private schema is not exposed through API settings or grants. The five private tables without policies may be intentionally function-only; do not add broad policies without proving the access model.

## Remaining verification gates

- Review exact table/schema grants and storage policies/settings against the expected client access model.
- Inspect trigger definitions and all function callers; test non-admin rejection and cross-user attempt access in an isolated database.
- Add an index for `private.mock_test_responses.question_id` only after confirming expected query patterns and validating it as a deliberate performance change—not as recovered historical schema.
- Run the reconstruction smoke test and a full catalog comparison only against a disposable replay database. No disposable replay has been run yet.

## Schema/table grants and trigger check — read-only checkpoint (2026-10-24)

- The `private` schema ACL grants `USAGE` only to its owner; `anon` and `authenticated` do not have schema usage. This is consistent with keeping answer keys and session records behind the reviewed RPC functions.
- The catalog query found no non-internal triggers on tables in `public` or `private`.
- Direct `SELECT` privilege checks for `anon` and `authenticated` on `public.daily_challenges` and `public.jee_pyq_questions` returned false, even though read policies are defined. Public/client reads therefore appear intended to go through granted RPCs rather than direct table reads; confirm the frontend call path before changing grants. Do not grant direct table access just to silence an advisor.
- The table-grant inventory showed authenticated direct `SELECT` on challenge attempts and mock-test attempts, while the answer/session tables in `private` have no client schema usage. The admin-write policies on public authoring tables still need negative role tests and full grant/policy replay comparison.

This remains a catalog observation, not a migration recommendation. No production schema or grants were changed.

## Client data-access contract — verified against frontend callers

The live public-function inventory exposes `get_current_daily_challenge()` to `anon` and `authenticated`, plus authenticated grading/mock-test/challenge RPCs. The frontend PYQ and mock-test pages also query `public.jee_pyq_questions` directly. Table-level `SELECT` checks return false, but column-level grants exist: `anon` and `authenticated` can select the 25 public question columns used for published question content/metadata. For `public.daily_challenges`, `anon` can select only eight schedule/metadata columns, not `statement` or `options`; the authenticated challenge flow obtains the question through `start_daily_challenge()`. This matches the inspected frontend access patterns. Preserve column-level access and do not add broad table grants; verify requested columns whenever frontend queries change.

## Expanded metadata checks — read-only checkpoint (2026-10-24)

A live `information_schema.columns` query confirmed the reconstructed column counts per table: 31 PYQ question columns, 13 daily-challenge columns, 7 challenge-attempt columns, 19 mock-test-attempt columns, and 3/4/6/4/6 columns across the five private tables. The smoke test now rejects extra as well as missing columns by requiring exactly 93 columns across the nine-table set. It also checks representative high-impact defaults and nullability. This is still not a full column-by-column type/default parity proof, and it has not been run against a disposable replay.

## Foreign-key cross-check — read-only checkpoint (2026-10-24)

A fresh catalog query enumerated 14 foreign-key constraints across the nine reconstructed tables. The reconstruction draft includes the observed relationships and delete behavior: user-owned attempts cascade with user deletion; answer-key/session rows cascade with their parent question/challenge; mock-test responses cascade with attempt deletion and restrict question deletion; author/reviewer references on public content become null when a user is deleted. The smoke test now asserts the presence of all 14 observed foreign-key constraint names, alongside column, RLS, selected check/unique constraint, and index checks. It does not yet compare every FK's exact referenced relation and delete action, so the disposable replay remains necessary.

## Security catalog inventory query

`tests/002_security_catalog_inventory.sql` is a read-only report for schema privileges, table grants, column grants, function execute ACLs and security attributes, RLS policy expressions, and non-internal triggers. Run it against the disposable replay first and compare output with the saved live-catalog checkpoint. It intentionally reports rather than mutates; do not infer that a grant is safe or unsafe without checking the actual frontend call path and function authorization logic.

## Exact grant inventory — read-only live check (2026-10-24)

A grouped read-only query of `information_schema.role_table_grants`, `column_privileges`, and `has_schema_privilege` confirmed the following current access shape:

- `anon`, `authenticated`, and `service_role` have `USAGE` on `public`, but not `CREATE`.
- None of those three roles has `USAGE` or `CREATE` on `private`. Do not grant it as part of reconstruction.
- `authenticated` has table-level `SELECT` on `public.daily_challenge_attempts` and `public.mock_test_attempts`; corresponding read policies restrict rows. It has table-level `INSERT`, `UPDATE`, and `DELETE` on `public.daily_challenges` and `public.jee_pyq_questions`, with admin-only write policies.
- The public question table has column-level `SELECT` on 25 content/metadata columns for `anon` and `authenticated`; answer key and solution are not in this public table.
- `anon` has column-level `SELECT` on eight daily-challenge schedule/metadata columns (`challenge_date`, `ends_at`, `id`, `is_live`, `solution_release_at`, `starts_at`, `subject`, `title`). `authenticated` has a different eight-column set: `challenge_date`, `ends_at`, `id`, `is_live`, `starts_at`, `statement_image_path`, `subject`, `title`.
- `service_role` has broad table-level privileges on the four public tables listed in the grant inventory; this role must remain server-side and must never be exposed to browser code.
- The five private tables do not appear in client table-grant output. Continue routing answer/session access through the reviewed RPCs.

These are current catalog observations, not a proposed grant migration. The SQL inventory script can regenerate detailed per-column output. No grants were changed. Grant replay is still pending in a disposable database.

## Constraint/index exactness pass — read-only checkpoint (2026-10-24)

A full live catalog inventory returned 49 constraints across the nine reconstructed tables: 23 CHECK, 14 FOREIGN KEY, 9 PRIMARY KEY, and 3 UNIQUE. Comparing names against the SQL draft exposed three auto-generated constraint-name mismatches on the two answer-key nonempty checks and the two statement-image path safety checks; these are now explicitly named to match the catalog. The same comparison found the secondary index `mock_test_attempts_user_created_idx` missing from the draft; it has been added on `(user_id, created_at DESC)`.

The smoke test now asserts all 49 observed constraint names and kinds, and the complete 11-index secondary-index set. This is a source-level/catalog comparison only: the updated draft and test have not been executed against a disposable database. Foreign-key names are checked in the broad test and delete actions are described in the table draft, but a full definition-by-definition replay diff remains outstanding.
