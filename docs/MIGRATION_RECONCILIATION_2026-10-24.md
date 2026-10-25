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

Current read-only inventory (2026-10-25): live ledger 20 entries; repository migration SQL files 19 (excluding README); 13 exact filename/version matches; seven live versions lack matching SQL bodies; six repository SQL files are not recorded in the live ledger. Recheck exact version/name pairs before any history repair. Never alter the live ledger during reconstruction. These counts do not establish missing migration contents.

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

Repository migration files without a matching live ledger entry (six as of 2026-10-25):

- `20261024112500_require_pyq_source_page_before_publish.sql`
- `20261024120000_require_pyq_source_and_solution_before_publish.sql`
- `20261024130000_harden_mock_test_input_nulls.sql`
- `20261025100000_enforce_unique_pyq_option_labels.sql`
- `20261025110000_harden_daily_challenge_authoring_integrity.sql`
- `20261025120000_add_mock_test_response_question_id_index.sql`

The 20261024112500 file has the same source-page publication gate as the missing 20261024112132 ledger version, but the version differs; do not silently rename it or treat it as proven original history. The 20261024120000 file implements a similar source/page/answer-key/solution gate to the 20261024111533 migration. The four later hardening/index files are CI-tested only and are not recorded in the live ledger; they must not be treated as production-applied. This is a potential duplicate/overlap in repository history that requires Git history and intended sequencing review before any repository migration edits. No files were renamed or deleted in this reconciliation.

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

- **`20261024080824` foundation schema**
  - Evidence: Current catalog shape snapshot and reconstructed table-shape SQL exist; no matching path history found.
  - Classification: Catalog reconstruction only; original migration body unresolved.
- **`20261024080924` grants/policies**
  - Evidence: Current RLS and privilege snapshots exist; no matching path history found.
  - Classification: Current-state evidence only; original migration body unresolved.
- **`20261024081041` daily solution release RPC**
  - Evidence: Current RPC definitions snapshot exists, but its current challenge schema is not the legacy daily-question schema.
  - Classification: Current-state evidence only; historical equivalence unproven.
- **`20261024081337` numeric answers/admin review**
  - Evidence: Current PYQ schema supports numerical question types and current admin RPC definitions exist.
  - Classification: Current-state evidence only; original migration body unresolved.
- **`20261024081603` daily attempt sessions**
  - Evidence: Current schema has `private.daily_challenge_sessions`; historical source uses `private.challenge_attempt_sessions`.
  - Classification: Different schema generation; do not transplant.
- **`20261024081731` anon RPC execution restrictions**
  - Evidence: Current function ACL snapshot exists; no matching path history found.
  - Classification: Current-state evidence only; original migration body unresolved.

These classifications are conservative and do not claim that GitHub history proves the files never existed elsewhere. The live migration ledger records versions/names, not the exact SQL text that ran. The reconstruction files remain explicitly non-original and outside `supabase/migrations/`.

No production SQL was executed for this investigation; the Supabase calls used were catalog/list reads. No question/answer rows were opened or reviewed.

## Latest verification update (2026-10-25)

The latest inspected GitHub Actions run is [run 40153559507](https://github.com/black-jee/blackjee/actions/runs/40153559507), associated with branch `chore/schema-reconstruction` at commit `7bc9694c5feeba5739a15d6fbcfe7a5a4bd36744`. Both CI jobs completed successfully.

- **Disposable database reconstruction/replay: PASS.** The job completed reconstructed catalog, RLS, RPC, grant, security-regression, mock-test NULL validation, PYQ option-label integrity, daily-challenge authoring integrity, mock-test response question-index, application security regression, and RPC authorization-denial checks.
- **Runtime regression coverage: PASS.** The RPC authorization script called the admin challenge-save function with a NULL challenge date, start time, end time, and solution-release time separately. Each was rejected with the intended required-schedule validation error. Existing authorization and option-integrity negative tests passed as well.
- **Quality checks: PASS.** Static security-contract checks, `npm ci`, lint, typecheck, unit tests, Playwright E2E, strict Prettier formatting, and the production build all passed on this commit.
- The PR remains draft, open, and unmerged. No production SQL or migration repair was performed, no paid Supabase infrastructure was created, and no JEE questions, answers, or solutions were added.

This green run verifies the current branch's automated checks and disposable PostgreSQL reconstruction. It does not recover missing historical migration bodies, prove production migration-chain replay, establish exact equivalence with the live production catalog, or replace real Supabase-issued user-token tests. The previously observed Vercel deployment-rate-limit/upgrade status is separate from this GitHub Actions result; no paid upgrade was attempted.

The run exercises the forward-only hardening migrations only in the disposable CI PostgreSQL service. It does not recover missing historical migration bodies, prove production migration-chain replay, or replace real Supabase-issued user-token tests.

New forward-only hardening files present on the working branch:

- `supabase/migrations/20261025100000_enforce_unique_pyq_option_labels.sql`
- `supabase/migrations/20261025110000_harden_daily_challenge_authoring_integrity.sql`
- `supabase/migrations/20261025120000_add_mock_test_response_question_id_index.sql`

The daily-challenge authoring guard checks live-solution completeness and option integrity at the database boundary. The solution-release behavior remains unchanged: after its configured release timestamp, the RPC releases the answer and worked solution to authenticated callers. Whether release should additionally require a submitted attempt remains an unresolved product/security decision; do not change this behavior without confirming the intended access rule.

## Latest complete CI verification (2026-10-25)

The latest inspected GitHub Actions run is [run 40154165240](https://github.com/black-jee/blackjee/actions/runs/40154165240), on commit `e41759c1ad47429d44a1ea1982b514db0a943db3`. Both jobs completed successfully.

- **Disposable database reconstruction/replay: PASS.** Catalog/RLS/RPC/grant assertions, mock-test NULL validation, PYQ option-label integrity, daily-challenge authoring integrity, the mock-test response question index, application security regression assertions, and RPC authorization-denial tests all passed.
- **Quality job: PASS.** Static security checks, `npm ci`, production dependency vulnerability audit, lint, typecheck, unit tests, Playwright end-to-end tests, Prettier formatting, and the production build all passed.
- **Dependency audit scope:** `npm audit --omit=dev --audit-level=high` checks production dependencies and fails on high/critical findings. It does not claim that every development dependency or every lower-severity advisory is absent.

## Publication-gate migration comparison (2026-10-25)

A focused comparison of the applied repository migration `20261024111533_require_pyq_source_and_solution_before_publish.sql`, the local-only `20261024112500_require_pyq_source_page_before_publish.sql`, the local-only `20261024120000_require_pyq_source_and_solution_before_publish.sql`, and the live `public.admin_review_jee_pyq_question` definition produced this result:

- The live function requires a non-empty source document and `source_page >= 1`, a non-empty statement, a private non-empty answer key, a worked solution, and an answer label that matches an option for single-correct questions.
- The live function body matches the source-page-checking logic in local-only `20261024112500`; the applied `20261024111533` body does not contain the source-page condition.
- The local-only `20261024120000` implements the same publication checks with formatting/statement-layout differences. Its filename is not in the live ledger.
- This is strong evidence for the **current behavior** and supports a candidate reconstruction of the missing `20261024112132` migration body. It does **not** recover the exact original SQL bytes or prove which exact file contents were applied at that historical version.
- Do not rename either local-only file, mark a version applied, or run migration repair on the strength of this comparison. Preserve the ledger; if a canonical replay chain is later assembled, label any reconstructed historical body as reconstructed and separately review it.

## Read-only production recheck (2026-10-25)

A fresh read-only Supabase check confirmed the live migration ledger still contains 20 applied versions. The seven ledger entries without same-version SQL bodies and the two repository-only migration files remain unresolved; no migration repair or production DDL was run.

The live `public.admin_save_daily_challenge` definition fingerprint remains `ebdff78aa677719515c9e500fc576562`, which differs from the branch's forward-only hardening definition. Therefore the new authoring-integrity guard and mock-test response index are **not verified as applied to production**. This is expected: they were tested only in the disposable CI database. The read-only check also confirmed the reviewed admin RPCs retain `SECURITY DEFINER`, an empty `search_path`, no `anon` execute grant, and an `authenticated` execute grant.

## Boundaries and next gate

This green CI run verifies committed source checks and the disposable PostgreSQL reconstruction. It does not recover the missing historical migration bodies, prove production migration-chain replay, establish full equivalence with the live catalog, or replace real Supabase-issued user-token tests.

PR #2 remains open, draft, and unmerged. No production SQL or migration repair was performed, no paid infrastructure was created, and no JEE question/answer/solution content was added.


## Live catalog parity checkpoint — 2026-10-25 (read-only)

A focused read-only query of PostgreSQL catalogs inspected constraints, indexes, table grants, and RLS policy expressions for the current `public` and `private` application tables. This records the observed live state; it is not a claim that the seven missing historical migration bodies have been recovered.

### Constraints observed

- `public.daily_challenges` has a unique challenge date, subject/options/path checks, and a schedule check `starts_at < ends_at AND ends_at <= solution_release_at`. PostgreSQL CHECK constraints accept an UNKNOWN result, so this expression alone does not reject every NULL schedule value; the branch-only authoring RPC NULL guard addresses the RPC input path but is not yet production-deployed.
- `public.daily_challenge_attempts` has a unique `(challenge_id, user_id)` constraint and elapsed-time bounds.
- `public.jee_pyq_questions` has source-ID uniqueness, type/year/subject/difficulty/marks/status checks, safe image-path checks, and a constraint preventing publication unless review status is approved. The live table catalog does not show the branch's new unique-option-label trigger.
- `public.mock_test_attempts` constrains mode, status/submission timestamp consistency, total questions (1–75), and duration (0–10800 seconds).
- Private answer-key tables require non-empty answer values; attempt/session tables include ownership foreign keys and the recorded primary/unique constraints.
- This is a focused catalog summary, not a substitute for a complete schema dump or comparison of every constraint against every reconstruction file.

### Index observations

- The live index inventory includes primary/unique indexes, challenge schedule/author indexes, PYQ paper/review/subject lookup indexes, and the user/creation-time mock-attempt index.
- `private.mock_test_responses` has its primary key on `(attempt_id, question_id)` and a foreign key on `question_id`, but the live index inventory does **not** include the branch's proposed standalone `question_id` index. The migration `20261025120000_add_mock_test_response_question_id_index.sql` remains branch-only. An index may help FK deletes/updates and question-based joins, but deployment should follow the separately reviewed migration plan rather than an ad hoc production DDL action.

### Grants and row-level security observations

- The live public policies include owner-scoped reads for daily and mock-test attempts, an admin override for daily-attempt reads, public reads limited to live challenge schedule metadata, and published/approved PYQ reads with an admin review-queue override. Direct challenge/PYQ writes have admin-role RLS policies.
- `authenticated` has direct `SELECT` grants on the two attempt tables; the live catalog also reports authenticated table-level `INSERT`/`UPDATE`/`DELETE` grants on the challenge and PYQ authoring tables, constrained by the observed admin RLS policies. Grants and RLS are separate controls and must be reviewed together.
- The queried table-grant inventory did not show direct `anon` or `authenticated` table grants on the `private` application tables. No direct private-table policies were returned. Do not add broad private-schema grants or policies as a shortcut.
- The branch's negative RPC tests use synthetic identities in disposable PostgreSQL. Real Supabase-issued JWT/user-token authorization and a dedicated machine-generated live-versus-replay diff remain open gates.

### Decision

The current catalog evidence supports documenting the observed live behavior, not recreating historical SQL byte-for-byte. Keep branch-only NULL guards, option-label enforcement, and the response-question index marked **not production-deployed**. Continue the catalog diff in a separate, reviewable artifact; do not repair migration history, apply migrations, or alter production data as part of reconstruction.
