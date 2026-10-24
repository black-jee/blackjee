# BLACK-JEE security checkpoint — 2026-10-24

## Scope and safety

This checkpoint records read-only catalog inspection of Supabase project `phdssyexhfyxsmhmmcgb` and a catalog-only assertion block executed against the live project. No DDL, grants, application rows, migration history, or deployment settings were changed. No JEE question, answer, or solution content was added.

## Verified in the live catalog

- The 11 known privileged RPCs exist with `SECURITY DEFINER`, an empty pinned `search_path`, no `anon` or `PUBLIC` execution grant, and an `auth.uid()` check.
- The three admin authoring/review RPCs contain the server-managed `app_metadata` admin-role check.
- Browser roles have no `USAGE` on the `private` schema and no direct table/column privileges on its tables.
- There are exactly 10 public RLS policies. The key published-PYQ, live-challenge schedule, and mock-test ownership predicates match the expected catalog shape.
- Column-level access boundaries match the frontend contract: browser roles can select the public PYQ statement column, but cannot directly select `daily_challenges.statement` or `daily_challenges.options`.
- `get_current_daily_challenge()` is invoker-rights, executable by `anon`, and its definition returns schedule metadata rather than question statement/options.
- The app schemas `public` and `private` have no non-internal triggers and no sequences in the current catalog.
- No Storage buckets or Storage RLS policies currently exist. Supabase-managed internal triggers in the `storage` schema are not BLACK-JEE application triggers.

## Assertion execution

A catalog-only assertion block was executed against the live database and returned:

`PASS: privileged RPC attributes, admin guards, private-schema isolation, and column grants`

A second read-only check returned:

`PASS: anonymous schedule RPC remains metadata-only; column-level grants preserve challenge content boundary`

The committed regression file `tests/003_security_regression_assertions.sql` was executed in full against the live catalog after its latest source edit, including the daily-challenge image-path boundary, and returned PASS. This verifies catalog assertions on the live project only; it is not a disposable replay or real-user negative RPC test.

## What this does not prove

- No disposable database replay has been run; reconstructed table and policy SQL is not yet a verified baseline.
- No real negative RPC calls were made as anonymous, ordinary authenticated, cross-user, or admin identities.
- No Storage bucket or access policy exists yet, so asset migration and its security model remain unfinished.
- The seven missing historical migration bodies remain unrecovered. Do not manufacture a false historical chain or alter the live migration ledger to make counts match.
- Latest CI must be checked after the current branch commits. A previous run failed only at Prettier for `docs/PROJECT_STATUS.md` and `supabase/reconstruction/README.md`; earlier lint, typecheck, unit, and browser smoke tests passed, while build was skipped.

## Next safe steps

1. Resolve the two Markdown formatting failures and confirm a fresh complete CI run.
2. Review all seven missing migration versions and repository migration overlaps against current function/table definitions; label inferred SQL as reconstruction, not recovered history.
3. Keep migration replay blocked until a truly disposable, no-cost environment is available. Do not create a paid Supabase branch.
4. Build a reviewed Storage bucket/policy plan before copying image assets.
5. Add authenticated negative tests for non-admin writes and cross-user attempt access before production readiness.

## Publication-readiness aggregate (read-only)

An aggregate-only query inspected counts, not question text or answers:

- Total question records: 5.
- Published questions: 0.
- Approved questions: 0.
- Records missing a source document, positive source page, non-empty statement, private answer key, or worked solution: 0 in each category.

This does not make the records publish-ready by itself. They remain drafts; approval, option/answer consistency, asset checks, and real workflow tests are separate gates.

## Reconstruction smoke-test execution (read-only)

The full `tests/001_reconstruction_catalog_smoke.sql` was also executed against the live catalog after correcting two column-reporting references. It returned PASS for the nine tables, key defaults/nullability, RLS flags, 10 policies, 14 foreign keys/actions, 49 constraints, and 11 secondary indexes.

This is useful catalog evidence, not a disposable replay: it confirms that the current live schema matches the assertions, but does not prove the reconstructed SQL files can recreate it from zero.

## Fresh Supabase advisor pass (read-only, 2026-10-24)

- Security advisor: five private tables still have RLS enabled without policies. The current design isolates them behind the `private` schema, which browser roles cannot use directly; do not add broad policies just to silence this advisory.
- Security advisor: 11 authenticated-callable `SECURITY DEFINER` RPCs remain flagged. The catalog assertions verify their pinned empty `search_path`, absence of anon/PUBLIC execute grants, and in-function authentication guards; the three admin RPCs also check server-managed admin metadata. Real-user negative RPC tests remain outstanding.
- Performance advisor: `private.mock_test_responses.question_id` still has no covering index. Keep this as a deliberate performance review item; do not mislabel an unverified index as historical schema.
- Performance advisor also lists seven indexes as unused. With only five draft PYQ records and no student/mock-test attempts, usage statistics are too small to justify dropping them.

References: [RLS-enabled tables without policies](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy), [authenticated SECURITY DEFINER advisory](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable), and [unindexed foreign-key advisory](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys).

