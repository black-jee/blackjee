# SQL security contract test status

Date: 2026-10-24

## Current verified boundary

The repository contains `supabase/tests/security_definer_rpc_contracts.sql`. It asserts that 11 expected exposed RPC signatures exist, are SECURITY DEFINER, pin an empty search_path, deny execution to anon, allow authenticated invocation, and reference `auth.uid()`. The three admin RPCs must also reference server-managed app metadata and the admin role.

The current GitHub Actions workflow in `.github/workflows/ci.yml` runs continuity validation, npm install, lint, typecheck, unit tests, Playwright E2E, formatting, and build. It does **not** invoke the SQL contract file. A green CI result therefore does not prove that this SQL contract was executed.

## Safe next steps

1. Recover the missing applied migration SQL or finish a clearly labelled reconstruction from verified live definitions.
2. Establish a disposable local PostgreSQL/Supabase-compatible replay environment at no cost. Do not create a paid Supabase branch/project.
3. Replay the reconciled migration chain in that disposable environment and record the exact command and PostgreSQL/Supabase versions.
4. Execute `supabase/tests/security_definer_rpc_contracts.sql` there and preserve the output as test evidence.
5. Add runtime negative tests with two authenticated student identities, an ordinary non-admin identity, and a challenge before/after its solution release time. Verify cross-user reads/writes are denied and unreleased answers/solutions are withheld.
6. Only after those tests are repeatable should CI be extended to run the SQL contract. Avoid tests that require production credentials or mutate the live project.

## Current status

- SQL contract file exists: verified by repository inspection.
- Contract is wired into GitHub Actions CI: **no**, based on the current workflow file.
- Clean migration replay: **unverified**, blocked by missing historical migration bodies.
- Authenticated multi-user runtime isolation tests: **unverified**.
- Live database changed during this review: **no**.
