# BLACK-JEE schema reconstruction status

**Status: incomplete, reconstructed, and not replay-verified.** This folder is a best-effort reconstruction from read-only catalog inspection; it is not recovered historical migration SQL.

## Safety boundaries

- Never apply this draft to production.
- Do not edit production schema or migration history to make this draft fit.
- Replay only in an explicitly disposable database, then compare catalogs.
- No JEE question, answer, or solution content is included in this work.

## Artifacts

- `001_reconstructed_table_shapes.sql`: labelled nine-table structural draft, including selected catalog-confirmed constraints and secondary indexes.
- `002_reconstructed_rls_policies.sql`: review draft of the 10 catalog-observed public-table RLS policies. It deliberately does not add table/column grants or private-table policies.
- `tests/001_reconstruction_catalog_smoke.sql`: read-only catalog assertions for a disposable replay after applying drafts 001 and 002. It checks the nine tables, every reconstructed column, RLS flags, the 10 policy names, catalog-observed foreign keys, selected check/unique constraints, and observed secondary indexes. It does not insert application data or prove full production parity.

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
4. The live public policies use `auth.jwt()->'app_metadata'->>'role' = 'admin'` for admin authorization and row ownership predicates for user records. Policy definitions and grants still need to be represented in a separate, reviewed security layer before a replay baseline is complete.
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

## Foreign-key cross-check — read-only checkpoint (2026-10-24)

A fresh catalog query enumerated 14 foreign-key constraints across the nine reconstructed tables. The reconstruction draft includes the observed relationships and delete behavior: user-owned attempts cascade with user deletion; answer-key/session rows cascade with their parent question/challenge; mock-test responses cascade with attempt deletion and restrict question deletion; author/reviewer references on public content become null when a user is deleted. The smoke test now asserts the presence of all 14 observed foreign-key constraint names, alongside column, RLS, selected check/unique constraint, and index checks. It does not yet compare every FK's exact referenced relation and delete action, so the disposable replay remains necessary.
