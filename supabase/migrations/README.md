# Supabase migration discipline

The target Supabase project has **20 applied migration versions** in its live ledger. The repository currently contains 24 SQL migration files: 18 exact filename/version matches, two applied SQL bodies still missing, and six repository-only migration files not recorded as applied. See [the migration chain inventory](../../docs/MIGRATION_CHAIN_INVENTORY.md) for the version-by-version ledger.

## Archive recovery — 2026-10-26

Five exact-version bodies were restored byte-for-byte from Library archive `blackjee-foundation.zip`: `20261024080824_foundation_schema.sql`, `20261024080924_tighten_rpc_grants_and_policy.sql`, `20261024081041_daily_solution_release_rpc.sql`, `20261024081603_secure_daily_attempt_sessions.sql`, and `20261024081731_restrict_anon_rpc_execution.sql`. Their Git blob IDs match the source archive exactly; see `docs/MIGRATION_RECOVERY_SEARCH_2026-10-24.md`.

## Reconstruction candidate — 2026-10-26

A **non-deployable, explicitly labelled candidate** was added at
[`docs/reconstructions/20261024081337_numeric_answers_and_admin_review.candidate.sql`](../../docs/reconstructions/20261024081337_numeric_answers_and_admin_review.candidate.sql).
It copies the SQL body from the archived near-match `20261024081110_numeric_answers_and_admin_review.sql`; it does **not** claim to be the missing `20261024081337` original. It is outside `supabase/migrations/`, so it is not part of the deployable migration chain.

This is progress toward an isolated comparison, **not completion**: the candidate still needs replay in a disposable PostgreSQL database and a definition-level comparison of both answer-key constraints and the PYQ SELECT policy against the recorded live snapshot. Until those checks pass and the canonical sequence is reviewed, keep the applied body marked unresolved. Never run this candidate against production or use it to repair the migration ledger.

## Applied versions whose SQL bodies remain missing

- `20261024081337_numeric_answers_and_admin_review` — archive has a similar-purpose `20261024081110_numeric_answers_and_admin_review.sql`, but the version differs; do not relabel it.
- `20261024112132_require_pyq_source_page_before_publish` — no exact body recovered. The local `20261024112500` file is not a substitute.

Do not recreate these under their original version identifiers unless the original SQL is recovered. Any replacement inferred from live definitions must be explicitly labelled a reconstruction, not original historical SQL.

## Repository migration files not present in live history

The following six repository SQL files are not recorded as applied in the live ledger:

- `20261024112500_require_pyq_source_page_before_publish.sql`
- `20261024120000_require_pyq_source_and_solution_before_publish.sql`
- `20261024130000_harden_mock_test_input_nulls.sql`
- `20261025100000_enforce_unique_pyq_option_labels.sql`
- `20261025110000_harden_daily_challenge_authoring_integrity.sql`
- `20261025120000_add_mock_test_response_question_id_index.sql`

These overlap with the applied publication-gate migration's purpose, but they are not proof of what the applied `20261024112132` body contained. Do not apply, rename, delete, or mark these as applied until their intent and the canonical migration sequence are reviewed.

## Additional recovery search — 2026-10-24

The accessible repository search was extended beyond the active reconstruction branch: checked the other available branch `chore/sql-security-test-plan` for all seven exact missing migration paths, and searched repository commit metadata for `20261024080824`, `foundation_schema`, and `20261024112132`. The exact migration files were not present on that branch, and those commit searches returned no matches. This is evidence that the accessible GitHub history did not yield the original bodies; it does not prove no external clone, archive, backup, or Supabase migration artifact exists. Keep the seven gaps open rather than inventing historical SQL.

## Important current limitation

**Do not run `supabase db reset` against this incomplete migration directory.** The chain cannot currently recreate the live database from zero. The live target project has not been reset or repaired as part of this reconstruction work.

## Required reconciliation procedure

1. Recover original SQL bodies from authoritative Git history, a local clone, archive, backup, or captured migration artifacts where possible.
2. Read-only inspect and record current table definitions, constraints, indexes, policies, grants, function definitions/owners/configuration/ACLs, triggers, extensions, and storage configuration.
3. If original bodies are unavailable, write separately labelled reconstructed baseline SQL from verified live object definitions; never present it as recovered original history.
4. Reconcile the two local-only publication-gate files with the applied `20261024112132` version before preparing a canonical ordered chain.
5. Replay only in a disposable, no-cost PostgreSQL-compatible environment. Do not create a paid Supabase branch/project; the owner has no budget for paid infrastructure.
6. Compare the replayed schema and ACLs to the recorded target snapshot, then run anonymous/student/owner/admin negative-permission tests and Supabase advisors.
7. Never reset, repair, or apply reconstruction migrations to the live target during this work. Any future production change must be separately reviewed and explicitly approved.

## Current status

**Inventory: verified read-only. Five original-version SQL bodies were recovered from the Library archive; two remain unresolved. Reconstructed disposable replay is verified in CI, but full original-chain replay and Supabase Auth/runtime parity remain unverified.** No production database changes, migration repairs, resets, question publication, or paid infrastructure were used for this inventory.
