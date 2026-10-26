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
- No Storage buckets or Storage RLS policies currently exist. Supabase-managed internal triggers in the `storage` schema are not BLACK-JEE application triggers. No views/materialized views or sequences were found in `public`/`private`; the only non-internal triggers found were Supabase-managed triggers on `storage.buckets` and `storage.objects`. Schema ownership/usage was also checked: `private` is owned by `postgres` and has no `USAGE` for `anon`, `authenticated`, or `service_role`; `public` is owned by `pg_database_owner`; `storage` and `auth` are Supabase-managed.

## Assertion execution

A fresh read-only metadata inventory also returned empty results for Storage buckets, Storage policies, application-schema views/materialized views, and application-schema sequences. The only triggers returned were Supabase-managed Storage internals; no BLACK-JEE application triggers were found.

A catalog-only assertion block was executed against the live database and returned:

`PASS: privileged RPC attributes, admin guards, private-schema isolation, and column grants`

A second read-only check returned:

`PASS: anonymous schedule RPC remains metadata-only; column-level grants preserve challenge content boundary`

The committed regression file `tests/003_security_regression_assertions.sql` returned PASS against the live catalog and the disposable PostgreSQL 17 replay in CI run `40113487978`, including the daily-challenge image-path boundary and pinned function-definition fingerprints. CI also passed four negative authorization checks against the disposable replay. The current branch head `c22031f07c688a47a046b83d65866a6e3155fdf3` was subsequently verified in CI run `40113673941` (#353): both `quality` and `reconstruction-replay` completed successfully. Real Supabase-issued user-token tests remain outstanding.

## What this does not prove

- Disposable replay: CI run `40113101703` successfully applied reconstructed tables, policies, 12 current RPC definitions, and access grants to a fresh PostgreSQL 17 container, then passed schema/security assertions, exact RPC body fingerprints, and four negative authorization checks. This validates structural compatibility, not the full Supabase runtime.
- No negative RPC calls were made against the live Supabase project or with real Supabase-issued user tokens. CI now performs four negative checks against the disposable replay using synthetic identities and stub auth functions.
- No Storage bucket or access policy exists yet, so asset migration and its security model remain unfinished.
- The seven missing historical migration bodies remain unrecovered. Do not manufacture a false historical chain or alter the live migration ledger to make counts match.
- CI run `40113673941` (#353) on the current branch head completed successfully for both jobs. This confirms the configured CI suite, not full Supabase Auth/runtime parity or production readiness.

## Next safe steps

1. Keep the seven missing historical migration bodies and two overlapping repository migration files explicitly unresolved until authoritative source bodies or verifiable history are found.
2. Design and review a Storage bucket/policy plan before copying any of the 21 source image assets; the live project currently has no buckets or Storage policies.
3. Add real Supabase-issued user-token tests for non-admin writes, cross-user attempt access, and private answer isolation; disposable stub-auth tests are not a substitute.
4. Review `private.mock_test_responses.question_id` indexing and the seven unused-index advisor findings using workload evidence before changing indexes.
5. Keep all production schema and migration-ledger changes blocked until reviewed, isolated replay and explicit approval.

## Publication-readiness aggregate (read-only)

An aggregate-only query inspected counts, not question text or answers:

- Total question records: 5.
- Published questions: 0.
- Approved questions: 0.
- Records missing a source document, positive source page, non-empty statement, private answer key, or worked solution: 0 in each category.

This does not make the records publish-ready by itself. They remain drafts; approval, option/answer consistency, asset checks, and real workflow tests are separate gates.

## Reconstruction smoke-test execution (read-only)

The full `tests/001_reconstruction_catalog_smoke.sql` was also executed against the live catalog after correcting two column-reporting references. It returned PASS for the nine tables, key defaults/nullability, RLS flags, 10 policies, 14 foreign keys/actions, 49 constraints, and 11 secondary indexes.

The live-catalog pass confirms the assertions match the current project. Separately, CI run `40113487978` successfully replayed reconstructed tables, policies, RPCs, and grants from zero in a disposable PostgreSQL 17 database; neither check proves full Supabase Auth/runtime parity.

## Fresh Supabase advisor pass (read-only, 2026-10-24)

- Security advisor: five private tables still have RLS enabled without policies. The current design isolates them behind the `private` schema, which browser roles cannot use directly; do not add broad policies just to silence this advisory.
- Security advisor: 11 authenticated-callable `SECURITY DEFINER` RPCs remain flagged. The catalog assertions verify their pinned empty `search_path`, absence of anon/PUBLIC execute grants, and in-function authentication guards; the three admin RPCs also check server-managed admin metadata. Real-user negative RPC tests remain outstanding.
- Performance advisor: `private.mock_test_responses.question_id` still has no covering index. Keep this as a deliberate performance review item; do not mislabel an unverified index as historical schema.
- Performance advisor also lists seven indexes as unused. With only five draft PYQ records and no student/mock-test attempts, usage statistics are too small to justify dropping them.

References: [RLS-enabled tables without policies](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy), [authenticated SECURITY DEFINER advisory](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable), and [unindexed foreign-key advisory](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys).
