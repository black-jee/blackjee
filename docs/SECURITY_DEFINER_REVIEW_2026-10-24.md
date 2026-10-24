# SECURITY DEFINER review — 2026-10-24

## Scope

Read-only review of the live Supabase catalog for project `phdssyexhfyxsmhmmcgb`. This document records what the catalog proves; it is not a substitute for authenticated integration tests. No schema, grant, row, or migration changes were made.

## Verified catalog facts

- Eleven functions in the exposed `public` schema use `SECURITY DEFINER`.
- All eleven are owned by `postgres` and pin `search_path` to the empty string.
- Their function ACLs list `authenticated`, `service_role`, and the owner; anonymous execution is not granted. The repository's `supabase/tests/security_definer_rpc_contracts.sql` checks the expected signatures, definer mode, pinned search path, anonymous denial, authenticated callability, `auth.uid()` presence, and server-managed admin metadata checks for the three admin functions.
- The three authoring/review RPCs check both a non-null `auth.uid()` and `auth.jwt()->'app_metadata'->>'role' = 'admin'` before performing admin work.
- The five `private` answer/session/response tables have RLS enabled and no policies. Direct SELECT and INSERT privilege checks returned false for `anon`, `authenticated`, and `service_role` on all five tables. This supports the intended design in which privileged functions mediate access to private answer keys and attempt state.

The eleven functions are:

- `admin_review_jee_pyq_question`
- `admin_save_daily_challenge`
- `admin_save_jee_pyq_question`
- `get_daily_challenge_result`
- `get_mock_test_result`
- `grade_jee_pyq`
- `resume_mock_test`
- `start_daily_challenge`
- `start_mock_test`
- `submit_daily_challenge`
- `submit_mock_test`

## What this does not prove

- Static presence of `auth.uid()` does not by itself prove that every student RPC checks the correct owner for every referenced attempt/session.
- The catalog contract does not execute the functions as anonymous, student A, student B, or admin users.
- It does not prove answer keys remain withheld across every time/state edge case, or that all invalid state transitions are rejected.
- The private-table privilege checks above explicitly tested SELECT and INSERT. They are not a full privilege matrix for every SQL operation or sequence.

## Next verification gates

1. Add isolated integration tests for cross-user attempt/session IDs and confirm user A cannot read, resume, submit, or retrieve results for user B.
2. Test that anonymous callers cannot execute each RPC, ordinary authenticated users cannot call admin RPCs successfully, and a dedicated admin can save/review only safe draft fixtures.
3. Test daily-solution release boundaries and PYQ answer/solution withholding before release; never publish production content as a test.
4. Re-run security and performance advisors after any reviewed backend migration.
5. Review the unindexed foreign key `private.mock_test_responses.question_id` against existing indexes and query workload before proposing a versioned index migration. Do not drop the seven informational unused-index candidates without workload evidence.

## Current assessment

The advisor's authenticated-`SECURITY DEFINER` warning requires continued scrutiny, but it is not by itself proof that anonymous users or ordinary students can bypass the guards. The current catalog evidence shows an intentional authenticated RPC surface with server-side checks and no direct browser-role table access to private answer/session tables. Runtime cross-user and release-boundary tests remain **UNVERIFIED**.
