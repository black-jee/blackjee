# BLACK-JEE schema reconstruction status

**Status: incomplete, reconstructed, and not replay-verified.** This folder is a best-effort reconstruction from read-only catalog inspection; it is not recovered historical migration SQL.

## Safety boundaries

- Never apply this draft to production.
- Do not edit production schema or migration history to make this draft fit.
- Replay only in an explicitly disposable database, then compare catalogs.
- No JEE question, answer, or solution content is included in this work.

## Artifacts

- `001_reconstructed_table_shapes.sql`: labelled nine-table structural draft, including selected catalog-confirmed constraints and secondary indexes.
- `tests/001_reconstruction_catalog_smoke.sql`: read-only catalog assertions for a disposable replay. It does not insert application data and does not prove full production parity.

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
