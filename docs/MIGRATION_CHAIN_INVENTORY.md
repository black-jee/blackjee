## Recovery status update — 2026-10-26

A fresh read-only check confirmed that none of the seven missing applied migration paths exists in the recursive tree for any of the three current GitHub branches (`main`, `chore/sql-security-test-plan`, `chore/schema-reconstruction`). Exact-name file searches and repository-scoped commit searches returned no matches. The live Supabase ledger still has 20 versions; the reconstruction branch has 19 SQL migration files, 13 exact matches, seven missing applied bodies, and six repository-only SQL files. Supabase development branches list is empty. This does not search private clones, local device folders, backups, or archives; historical bodies remain unrecovered. No production mutation or paid resource was used. See [the recovery search log](./MIGRATION_RECOVERY_SEARCH_2026-10-24.md).

# Migration chain inventory — 2026-10-24

**Task:** BJ-DB-001  
**Target project:** `phdssyexhfyxsmhmmcgb`  
**Repository:** `black-jee/blackjee`  
**Observed main HEAD at inventory time:** `5b9e6a0a6c22c690b47c76699fc1766383b64ce7`  
**Latest observed CI for that HEAD:** [run 40099607199 — success](https://github.com/black-jee/blackjee/actions/runs/40099607199)

This is a reconciliation manifest, not a reconstructed migration chain. It does not authorize replay, reset, repair, or apply operations against the target database.

## Summary

- Live Supabase migration history: **20 applied versions**.
- SQL files currently in `supabase/migrations/`: **19** (excluding `README.md`).
- Exact filename/version matches between live history and repository: **13**.
- Applied live versions whose SQL body is missing from the repository: **7** (six baseline versions plus one later version).
- Repository SQL files not recorded as applied in live history: **6**.
- Result: repository is **not replayable from zero as-is**. Do not run `supabase db reset` against the target.

## Applied versions with missing SQL bodies

| Live version     | Live migration name                      | Status                                                                                                  |
| ---------------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `20261024080824` | `foundation_schema`                      | Applied; original SQL not found in current repository                                                   |
| `20261024080924` | `tighten_rpc_grants_and_policy`          | Applied; original SQL not found in current repository                                                   |
| `20261024081041` | `daily_solution_release_rpc`             | Applied; original SQL not found in current repository                                                   |
| `20261024081337` | `numeric_answers_and_admin_review`       | Applied; original SQL not found in current repository                                                   |
| `20261024081603` | `secure_daily_attempt_sessions`          | Applied; original SQL not found in current repository                                                   |
| `20261024081731` | `restrict_anon_rpc_execution`            | Applied; original SQL not found in current repository                                                   |
| `20261024112132` | `require_pyq_source_page_before_publish` | Applied; same-purpose local file uses a different version and is not a substitute for the original body |

## Applied versions with exact repository filename matches

These 13 versions are present in both live history and the repository:

1. `20261024095050_harden_public_schedule_rpc_and_index.sql`
2. `20261024100007_daily_challenge_question_assets.sql`
3. `20261024100245_pyq_question_image_paths.sql`
4. `20261024100341_question_image_path_read_grants.sql`
5. `20261024100524_admin_save_daily_challenge.sql`
6. `20261024101157_secure_mock_test_attempts.sql`
7. `20261024101243_resume_mock_test_attempt.sql`
8. `20261024101313_pyq_mock_metadata_read_grants.sql`
9. `20261024101531_preserve_pyq_source_provenance.sql`
10. `20261024102206_require_auth_for_daily_solution.sql`
11. `20261024102525_stable_mock_question_order.sql`
12. `20261024103715_admin_pyq_authoring_review.sql`
13. `20261024111533_require_pyq_source_and_solution_before_publish.sql`

A filename match does not alone prove that its contents are byte-for-byte identical to the SQL originally applied. Historical body verification is still required.

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

1. Search authoritative Git history, uploaded source archives, backups, or captured migration artifacts for the seven missing bodies. The current repository's code-index search did not find the six baseline identifiers or `20261024112132`.
2. If original bodies cannot be recovered, author a separately labelled **reconstructed baseline** from verified live object definitions. Do not label reconstructed SQL as original history.
3. Capture a complete target snapshot: schemas and ACLs, tables/columns, defaults, constraints, indexes, RLS policies, table/column/sequence grants, full function definitions/owners/configuration/ACLs, triggers, extensions, and storage configuration.
4. Reconcile the two local-only files and the applied `112132` version before preparing a canonical ordered replay chain.
5. Use only a disposable, no-cost PostgreSQL-compatible environment. The owner has no budget for a paid Supabase branch/project; do not provision billable infrastructure.
6. Compare replay output to the target snapshot and run anonymous/student/owner/admin negative permission tests before proposing any production action.
7. Do not reset, repair, or apply migrations to the target Supabase project during reconstruction.

## Current result

**Inventory: VERIFIED read-only. Historical SQL recovery: not found in accessible GitHub branches/commit search. Reconstructed disposable replay: VERIFIED in CI; replay of the complete original historical chain and full Supabase Auth/runtime parity remain UNVERIFIED.** No database changes, migration repairs, resets, question publication, or paid infrastructure were used to produce this manifest.

## Additional recovery check — Git path history

A follow-up query checked GitHub commit history for each of the seven expected missing migration paths (the six baseline files and the live `20261024112132_require_pyq_source_page_before_publish.sql` path). All seven exact-path history queries returned no commits. Commit-message searches for `foundation_schema`, `tighten_rpc_grants_and_policy`, and `20261024112132` also returned no matches in this repository. The other accessible branch, `chore/sql-security-test-plan`, was also checked for the seven exact missing paths; none was present. This makes recovery from the currently accessible GitHub repository less likely; it does **not** rule out an external backup, local clone, artifact, or another repository. CI run `40114187027` (#357) has passed the reconstruction replay job; its quality job was still in progress at the time of this update.

No SQL was inferred or fabricated from these names. The clean-replay gate remains blocked until authoritative bodies are recovered or separately labelled reconstructed equivalents are assembled and reviewed.
