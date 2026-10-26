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

## Additional read-only ownership-path review

The live function bodies were inspected for the main student attempt paths:

- `get_mock_test_result` filters the attempt by both `a.id = p_attempt_id` and `a.user_id = auth.uid()`, and only returns submitted attempts.
- `resume_mock_test` filters by attempt ID, owner, and `status = 'in_progress'`.
- `submit_mock_test` selects the attempt by ID and owner with `FOR UPDATE`, rejects question IDs outside that attempt, and routes repeated submission through the owner-checked result function.
- `start_mock_test` stores the current `auth.uid()` as attempt owner.
- `start_daily_challenge` creates/looks up a session keyed by challenge and current user; `submit_daily_challenge` selects that user's active session with `FOR UPDATE`.
- `grade_jee_pyq` stores attempts keyed by current user and question.

These are positive static indicators for owner isolation, not proof from adversarial runtime tests. A specific policy question remains: `get_daily_challenge_result` returns the released answer/solution to any authenticated caller who knows a live challenge ID once `solution_release_at` has passed; it does not require that caller to have started or submitted the challenge. This may be intentional for post-release learning, but the product rule should be confirmed and tested explicitly. Before the release time, the function returns release metadata only, not the answer key.

Do not tighten or loosen this behavior without confirming the intended post-release access rule. Add tests for before/at/after release boundaries and, if product policy requires attempt participation, test denial for users without a matching session/attempt.

## Foreign-key index check

The live catalog shows `private.mock_test_responses` has only the composite primary-key index `(attempt_id, question_id)`. That supports lookups beginning with `attempt_id`, but does not provide a leading-key index for `question_id`, whose validated foreign key uses `ON DELETE RESTRICT`. The table currently has **zero rows**, so there is no demonstrated workload benefit yet. Keep this as a reviewed performance candidate: after the migration chain is reconciled, decide whether to add a versioned `question_id` index based on expected question deletion/update checks and response volume. Do not run ad hoc DDL on production or add another local-only migration before the canonical chain is fixed.

## Live advisor recheck — 2026-10-26 (read-only)

The Supabase advisor endpoints were re-run read-only against project `phdssyexhfyxsmhmmcgb` on 2026-10-26. No schema, grant, row, or migration-history changes were made.

- **Security advisor:** reports five `private` tables with RLS enabled and no policies, plus 11 authenticated-callable `SECURITY DEFINER` RPCs. These findings match the documented design: private tables are intended to be accessed through guarded RPCs, and the public RPCs have server-side identity/admin checks. The advisor warnings are not themselves proof of a bypass; preserve them as a runtime-test obligation, not as a reason to remove the guards or grant direct table access.
- **Performance advisor:** reports one unindexed foreign key, `private.mock_test_responses.question_id`, and seven unused-index candidates. The table's currently observed zero-row state and low/young workload mean the unused-index notices do not justify index removal. The FK index remains a candidate to review after migration lineage is reconciled; no ad hoc production DDL was applied.
- **Migration ledger:** the current read-only migration listing still returns 20 applied versions, including `20261024081337_numeric_answers_and_admin_review` and `20261024112132_require_pyq_source_page_before_publish`. This confirms the versions are recorded as applied, not the original SQL bodies. The two exact source bodies remain unresolved in the repository/archive evidence.
- **Next test design:** in an isolated disposable Supabase Auth environment, create synthetic student A, student B, and admin users; obtain real signed sessions through Auth rather than hand-built JWT claims; test anonymous RPC denial, ordinary-user admin denial, cross-user attempt/session isolation, safe draft-only authoring, and solution/PYQ release boundaries. Keep all fixtures synthetic and never publish production content. If a no-cost disposable Auth environment is unavailable, document the blocker rather than using production or creating billable infrastructure.
