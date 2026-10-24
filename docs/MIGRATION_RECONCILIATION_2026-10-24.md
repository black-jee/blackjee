# BLACK-JEE Migration Reconciliation
Date: 2026-10-24
Scope: repository documentation only. No production SQL applied.

## Findings
The ten supplied historical SQL files are evidence of an older schema generation, not safe replacements for missing same-version migrations. Legacy objects include `public.daily_questions`, `public.attempt_submissions`, `public.active_question_links`, and `private.challenge_attempt_sessions`. Current reconstructed objects include `public.jee_pyq_questions`, `public.daily_challenges`, `public.daily_challenge_attempts`, `public.mock_test_attempts`, and private answer/session tables.

## Historical evidence disposition
- `20261021000100_enforce_one_attempt_per_signed_in_user.sql`: single-attempt invariant and owner-scoped policies; do not port blindly.
- `20261021000200_daily_results_archive.sql`: session lifecycle and archive/result RPC boundaries; signatures differ.
- `20261021000300_launch_readiness_hardening.sql`: schedule and archive hardening; reuse only verified invariants.
- `20261021000400_protect_live_question_content.sql`: privileged live-content retrieval; compare with current private answer keys.
- `20261021000500_restrict_anon_table_level_grants.sql`: least-privilege grants; compare exact current table/column privileges.
- `20261021000600_index_foreign_keys_and_optimize_policies.sql`: FK indexes and policy optimization; assess current indexes and workload first.
- `20261021000700_admin_rpc_prefers_active_challenge.sql`: admin challenge selection behavior; legacy RPC only.
- `20261021000800_restrict_truncate_and_photo_paths.sql`: destructive privilege and path restrictions; revalidate current targets.
- `20261021135935_harden_private_attempt_sessions.sql`: private session isolation; no broad current policies.
- `20261021141955_allow_public_read_of_approved_submission_columns.sql`: narrow public column access; legacy submission table.

## Ledger baseline
Previously recorded: live ledger 20 entries; repo migration files 15; seven live versions lack matching original SQL; two repo migration files do not match the live ledger. Recheck exact version/name pairs before any history repair. Never alter the live ledger during reconstruction. These counts do not establish missing migration contents.

## Security review gates
1. Keep answer keys and solutions private; do not trust client-submitted correctness.
2. RLS and SQL grants are separate; review table/column privileges and function EXECUTE grants together.
3. Confirm product semantics before changing single-attempt behavior.
4. Privileged RPCs need role/ownership checks, safe search_path, and reviewed execute grants.
5. Separate public question/schedule data from private answers and unreleased solutions.
6. Validate asset paths and authorize storage access independently.
7. Do not add legacy indexes without checking current indexes, query patterns, and write costs.

Known open points: `get_daily_challenge_result` was observed to expose released solutions to authenticated callers who know a challenge ID; confirm intent before changing. Five private tables have RLS but no policies and are intentionally inaccessible via direct client grants. The candidate index on `private.mock_test_responses.question_id` needs review. Storage remains design-only. Do not create, import, or publish JEE question/solution content.

## Next steps
1. Compare exact live ledger version/name pairs with branch migration filenames and classify every mismatch.
2. Mark each item as original recovered, catalog reconstruction only, different schema generation, or unresolved.
3. Add repository tests only for behavior supported by current definitions and grants.
4. Recheck CI on the current branch.
5. Keep reconstructed SQL outside `supabase/migrations/` until separately reviewed.

No production database, ledger, schema, policy, grant, storage, or data changes. Draft PR #2 remains unmerged.
