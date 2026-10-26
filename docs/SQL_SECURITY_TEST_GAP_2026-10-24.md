# SQL security contract test status

Date: 2026-10-24

## Current verified boundary

The repository contains `supabase/tests/security_definer_rpc_contracts.sql`. It asserts that 11 expected exposed RPC signatures exist, are SECURITY DEFINER, pin an empty search_path, deny execution to anon, allow authenticated invocation, and reference `auth.uid()`. The three admin RPCs must also reference server-managed app metadata and the admin role.

The current GitHub Actions workflow in `.github/workflows/ci.yml` runs continuity validation, npm install, lint, typecheck, unit tests, Playwright E2E, formatting, build, and a disposable PostgreSQL 17 reconstruction replay. The workflow now explicitly invokes this SQL contract immediately after reconstructed access grants are replayed. A green CI result proves the contract executed in that disposable replay for the tested commit; it does not prove production catalog parity or real Supabase-issued JWT behavior.

## Safe next steps

1. Recover the missing applied migration SQL or finish a clearly labelled reconstruction from verified live definitions.
2. Establish a disposable local PostgreSQL/Supabase-compatible replay environment at no cost. Do not create a paid Supabase branch/project.
3. Replay the explicitly labelled reconstruction in that disposable environment and record the exact command and PostgreSQL/Supabase compatibility versions. Historical migration equivalence remains blocked by missing applied migration bodies.
4. **Completed:** CI now executes `supabase/tests/security_definer_rpc_contracts.sql` after replaying reconstructed access grants.
5. Add runtime negative tests using real Supabase-issued JWTs for two authenticated student identities, an ordinary non-admin identity, and a challenge before/after its solution release time. Verify cross-user reads/writes are denied and unreleased answers/solutions are withheld.
6. Keep all database tests isolated from production credentials and live data.

## Current status

- SQL contract file exists: verified by repository inspection.
- Contract is wired into GitHub Actions CI: **yes**, via the disposable PostgreSQL 17 reconstruction replay; confirmation requires the new workflow run to pass.
- Clean historical migration replay: **unverified**, blocked by missing historical migration bodies; current CI validates the labelled reconstruction plus branch-only hardening.
- Authenticated multi-user runtime isolation tests: **unverified**.
- Live database changed during this review: **no**.

## 2026-10-25 — CI wiring follow-up

- Workflow change: commit `797bc8680f539a5ba59790f50c7fd115cfc9aa74` adds an explicit `psql -v ON_ERROR_STOP=1 -f supabase/tests/security_definer_rpc_contracts.sql` step after reconstructed access grants in the disposable PostgreSQL replay.
- Outcome: the dedicated SQL contract passed in reconstruction-replay on run #543. The overall run failed only at Prettier because this document had an extra blank line; that formatting defect is corrected in the current commit. This closes the test-wiring gap only; it does not recover historical migrations, prove full live-catalog parity, or test real Supabase-issued JWTs.
