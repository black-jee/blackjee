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

