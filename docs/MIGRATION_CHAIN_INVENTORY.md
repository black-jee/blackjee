## Recovery status update — 2026-10-26 (five archived bodies restored)

The Library archive `blackjee-foundation.zip` (SHA-256 `f0bfe458bdf81f7f84f34ef00e4e1d33c734f231eb31777c9397f659c9ce0433`) supplied five SQL migration files whose Git blob IDs match the archived bytes exactly. They were restored unchanged into `supabase/migrations/`:

- `20261024080824_foundation_schema.sql` — blob `8f21bc901173963de9569bd2b24bb27fae1851b7`
- `20261024080924_tighten_rpc_grants_and_policy.sql` — blob `7bab53a3c94194f5b75ed3811703529207dcc31e`
- `20261024081041_daily_solution_release_rpc.sql` — blob `bd3afd3728b7ad9f53abec4f0663ea039dbd1a5a`
- `20261024081603_secure_daily_attempt_sessions.sql` — blob `5b70c7e130718cc7730f16b6468f4620d8c9c89d`
- `20261024081731_restrict_anon_rpc_execution.sql` — blob `e53dda77762d7d62fc3b4df41632e6789ab6b4bb`

Two applied bodies remain unresolved:

- `20261024081337_numeric_answers_and_admin_review`: the archive contains a similar-purpose `20261024081110_numeric_answers_and_admin_review.sql`, but its version differs. It was not renamed or treated as the applied body.
- `20261024112132_require_pyq_source_page_before_publish`: no exact file was found in the archive or the other four Library ZIPs. Local `20261024112500`/`20261024120000` files are not substitutes.

**Current inventory:** live ledger 20 versions; repository 24 SQL files; 18 exact filename/version matches; two live versions without matching SQL bodies; six repository-only SQL files. CI run [#674 / 40242836656](https://github.com/black-jee/blackjee/actions/runs/40242836656) passed both `quality` and `reconstruction-replay` on the commit that restored the five files. The complete historical chain is still not replayable from zero. No production database or migration ledger was changed.

# Migration chain inventory — 2026-10-24

**Task:** BJ-DB-001  
**Target project:** `phdssyexhfyxsmhmmcgb`  
**Repository:** `black-jee/blackjee`  
**Observed main HEAD at inventory time:** `5b9e6a0a6c22c690b47c76699fc1766383b64ce7`  
**Latest observed CI for that HEAD:** [run 40099607199 — success](https://github.com/black-jee/blackjee/actions/runs/40099607199)

This is a reconciliation manifest, not a reconstructed migration chain. It does not authorize replay, reset, repair, or apply operations against the target database.

## Summary

- Live Supabase migration history: **20 applied versions**.
- SQL files currently in `supabase/migrations/`: **24** (excluding `README.md`).
- Exact filename/version matches between live history and repository: **18**.
- Applied live versions whose SQL body remains missing: **2**.
- Repository SQL files not recorded as applied in live history: **6**.
- Result: repository is **not replayable from zero as-is**. Do not run `supabase db reset` against the target.

## Applied versions whose SQL bodies remain missing

| Live version     | Live migration name                      | Status                                                                                                            |
| ---------------- | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `20261024081337` | `numeric_answers_and_admin_review`       | Archive contains similar-purpose `20261024081110` file, but the version differs; applied body remains unresolved. |
| `20261024112132` | `require_pyq_source_page_before_publish` | No exact body recovered. Same-purpose local files use different versions and are not substitutes.                 |

## Applied versions with exact repository filename matches

These 18 versions are present in both live history and the repository:

1. `20261024080824_foundation_schema.sql`
2. `20261024080924_tighten_rpc_grants_and_policy.sql`
3. `20261024081041_daily_solution_release_rpc.sql`
4. `20261024081603_secure_daily_attempt_sessions.sql`
5. `20261024081731_restrict_anon_rpc_execution.sql`
6. `20261024095050_harden_public_schedule_rpc_and_index.sql`
7. `20261024100007_daily_challenge_question_assets.sql`
8. `20261024100245_pyq_question_image_paths.sql`
9. `20261024100341_question_image_path_read_grants.sql`
10. `20261024100524_admin_save_daily_challenge.sql`
11. `20261024101157_secure_mock_test_attempts.sql`
12. `20261024101243_resume_mock_test_attempt.sql`
13. `20261024101313_pyq_mock_metadata_read_grants.sql`
14. `20261024101531_preserve_pyq_source_provenance.sql`
15. `20261024102206_require_auth_for_daily_solution.sql`
16. `20261024102525_stable_mock_question_order.sql`
17. `20261024103715_admin_pyq_authoring_review.sql`
18. `20261024111533_require_pyq_source_and_solution_before_publish.sql`

The five restored bodies match the archived Git blob IDs recorded above. Full original-chain replay remains blocked by the two unresolved versions.

## Local-only SQL files

A fresh read-only comparison on 2026-10-25 found six repository SQL files not recorded in the live migration ledger:

- `20261024112500_require_pyq_source_page_before_publish.sql` — no matching applied version. Do not apply or rename; current function behavior overlaps this file, but the original historical body remains unverified.
- `20261024120000_require_pyq_source_and_solution_before_publish.sql` — no matching applied version. It overlaps publication checks; do not assume it ran.
- `20261024130000_harden_mock_test_input_nulls.sql` — CI-tested only; not verified applied to production.
- `20261025100000_enforce_unique_pyq_option_labels.sql` — CI-tested only; not verified applied to production.
- `20261025110000_harden_daily_challenge_authoring_integrity.sql` — CI-tested only; not verified applied to production.
- `20261025120000_add_mock_test_response_question_id_index.sql` — CI-tested only; not verified applied to production.

The applied version `20261024112132` and the two publication-gate files with different versions must be reconciled deliberately. The four later hardening/index migrations were added after the original inventory and are also not present in the live ledger. Do not rewrite live migration history or use `migration repair` as a substitute for missing SQL: repair changes migration records; it does not execute or recover SQL bodies.

## Recovery and replay gate

1. Continue searching authoritative Git history, uploaded source archives, backups, or captured migration artifacts for the two remaining missing bodies. The current repository's code-index search did not find the six baseline identifiers or `20261024112132`.
2. If original bodies cannot be recovered, author a separately labelled **reconstructed baseline** from verified live object definitions. Do not label reconstructed SQL as original history.
3. Capture a complete target snapshot: schemas and ACLs, tables/columns, defaults, constraints, indexes, RLS policies, table/column/sequence grants, full function definitions/owners/configuration/ACLs, triggers, extensions, and storage configuration.
4. Reconcile the two local-only files and the applied `112132` version before preparing a canonical ordered replay chain.
5. Use only a disposable, no-cost PostgreSQL-compatible environment. The owner has no budget for a paid Supabase branch/project; do not provision billable infrastructure.
6. Compare replay output to the target snapshot and run anonymous/student/owner/admin negative permission tests before proposing any production action.
7. Do not reset, repair, or apply migrations to the target Supabase project during reconstruction.

## Current result

**Inventory: VERIFIED read-only. Historical SQL recovery: five exact bodies recovered from the Library archive; two remain unresolved. Reconstructed disposable replay: VERIFIED in CI; replay of the complete original historical chain and full Supabase Auth/runtime parity remain UNVERIFIED.** No database changes, migration repairs, resets, question publication, or paid infrastructure were used to produce this manifest.

## Additional recovery check — Git path history

A follow-up query checked GitHub commit history for each of the seven expected missing migration paths (the six baseline files and the live `20261024112132_require_pyq_source_page_before_publish.sql` path). All seven exact-path history queries returned no commits. Commit-message searches for `foundation_schema`, `tighten_rpc_grants_and_policy`, and `20261024112132` also returned no matches in this repository. The other accessible branch, `chore/sql-security-test-plan`, was also checked for the seven exact missing paths; none was present. This makes recovery from the currently accessible GitHub repository less likely; it does **not** rule out an external backup, local clone, artifact, or another repository. CI run `40114187027` (#357) has passed the reconstruction replay job; its quality job was still in progress at the time of this update.

No SQL was inferred or fabricated from these names. The clean-replay gate remains blocked until authoritative bodies are recovered or separately labelled reconstructed equivalents are assembled and reviewed.
