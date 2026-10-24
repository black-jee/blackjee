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


## Exact filename reconciliation (verified 2026-10-24)

Live ledger versions without an exact matching repository filename:

- `20261024080824_foundation_schema.sql`
- `20261024080924_tighten_rpc_grants_and_policy.sql`
- `20261024081041_daily_solution_release_rpc.sql`
- `20261024081337_numeric_answers_and_admin_review.sql`
- `20261024081603_secure_daily_attempt_sessions.sql`
- `20261024081731_restrict_anon_rpc_execution.sql`
- `20261024112132_require_pyq_source_page_before_publish.sql`

Repository migration files without an exact matching live ledger entry:

- `20261024112500_require_pyq_source_page_before_publish.sql`
- `20261024120000_require_pyq_source_and_solution_before_publish.sql`

The 20261024112500 file has the same source-page publication gate as the missing 20261024112132 ledger version, but the version differs; do not silently rename it or treat it as proven original history. The 20261024120000 file implements a similar source/page/answer-key/solution gate to the 20261024111533 migration. This is a potential duplicate/overlap in repository history that requires Git history and intended sequencing review before any repository migration edits. No files were renamed or deleted in this reconciliation.

## CI snapshot

For the previously identified workflow run `40114721534`, the `reconstruction-replay` job reports success and the `quality` job reports cancelled. Therefore the replay job succeeded, but this run does not establish that the complete CI suite passed. The combined commit status also reports a Vercel failure linked to a build-rate-limit/upgrade page; no paid upgrade was attempted.


## Follow-up Git history review (2026-10-24)

Git history confirms:
- Commit `2c27d5e8dc0eb9be6fe23fece3949726a45ade6d` added `20261024112500_require_pyq_source_page_before_publish.sql` as a new file. Its body enforces source document + source page, private answer key, and worked solution before publication.
- Commit `190f33bedc0556fe0d7e45d09876d0ba1374ab0e` added `20261024120000_require_pyq_source_and_solution_before_publish.sql` with a source-reference and worked-solution gate.
- Commit `3ae28e9f795e0a6bdef5168c495def6ea8d42154` later modified the `20261024120000` file to require source page as well, explicitly describing it as keeping the later migration at least as strict as the source-page gate.
- A history query for the missing ledger filename `20261024112132_require_pyq_source_page_before_publish.sql` returned no commits.

Conclusion: the current branch has two separately versioned migrations with overlapping publication-gate logic, while the live ledger contains a third version/name pair that is absent from repository path history. Do not rename or delete either migration automatically: first establish the intended ledger lineage and whether the live ledger recorded a file that was later renamed outside Git history. These commits show branch history, not the exact SQL that was applied to production.


## Early missing migration history and schema-generation comparison (2026-10-24)

A path-specific GitHub commit-history query returned no commits for each of these six live-ledger paths:
- `20261024080824_foundation_schema.sql`
- `20261024080924_tighten_rpc_grants_and_policy.sql`
- `20261024081041_daily_solution_release_rpc.sql`
- `20261024081337_numeric_answers_and_admin_review.sql`
- `20261024081603_secure_daily_attempt_sessions.sql`
- `20261024081731_restrict_anon_rpc_execution.sql`

The ten historical SQL files preserved in the Library are from a different schema generation. They operate on legacy objects such as `public.daily_questions`, `public.attempt_submissions`, `public.active_question_links`, and `private.challenge_attempt_sessions`; the current live catalog instead includes `public.jee_pyq_questions`, `public.daily_challenges`, `public.daily_challenge_attempts`, `public.mock_test_attempts`, and `private.daily_challenge_sessions`. Therefore those old files are useful for security intent and design lessons, but are not replacements for the six missing current-generation migrations.

| Missing live-ledger version | Evidence available | Recovery classification |
| --- | --- | --- |
| `20261024080824` foundation schema | Current catalog shape snapshot and reconstructed table-shape SQL exist; no matching path history found | Catalog reconstruction only; original migration body unresolved |
| `20261024080924` grants/policies | Current RLS and privilege snapshots exist; no matching path history found | Current-state evidence only; original migration body unresolved |
| `20261024081041` daily solution release RPC | Current RPC definitions snapshot exists, but its current challenge schema is not the legacy daily-question schema | Current-state evidence only; historical equivalence unproven |
| `20261024081337` numeric answers/admin review | Current PYQ schema supports numerical question types and current admin RPC definitions exist | Current-state evidence only; original migration body unresolved |
| `20261024081603` daily attempt sessions | Current schema has `private.daily_challenge_sessions`; historical source uses `private.challenge_attempt_sessions` | Different schema generation; do not transplant |
| `20261024081731` anon RPC execution restrictions | Current function ACL snapshot exists; no matching path history found | Current-state evidence only; original migration body unresolved |

These classifications are conservative and do not claim that GitHub history proves the files never existed elsewhere. The live migration ledger records versions/names, not the exact SQL text that ran. The reconstruction files remain explicitly non-original and outside `supabase/migrations/`.

No production SQL was executed for this investigation; the Supabase calls used were catalog/list reads. No question/answer rows were opened or reviewed.
