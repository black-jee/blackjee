# Migration recovery search log — 2026-10-24

## Purpose

Record the exact recovery checks performed for the BLACK-JEE Supabase migration chain. This is evidence tracking only. It does not reconstruct SQL, authorize replay, or authorize changes to the live Supabase project.

## Current facts

- Target project: `phdssyexhfyxsmhmmcgb`.
- Live migration history currently contains 20 versions.
- Current repository inventory (rechecked 2026-10-25): 19 SQL files under `supabase/migrations/` (excluding README).
- Thirteen migration versions have exact filename/version matches.
- Seven applied migration bodies are missing from the current migration directory.
- Six repository SQL files are not recorded as applied in the live history.
- Only the `main` branch was returned by the repository branch listing at the time of this check.

## Recovery checks performed

1. Queried the current repository's migration directory history. It contains 24 directory-affecting commits from the recorded history window, starting at `2026-10-24 09:50 UTC`; the missing baseline bodies do not appear as recovered files in the current directory history.
2. Repeated repository-wide GitHub code searches for the exact identifiers below. No indexed matches were returned:
   - `20261024080824 foundation_schema`
   - `20261024080924 tighten_rpc_grants_and_policy`
   - `20261024081603 secure_daily_attempt_sessions`
   - `20261024112132 require_pyq_source_page_before_publish`
3. Previously checked exact missing paths and relevant commit-message terms in this repository; no matching original bodies or commits were found.
4. Rechecked the live Supabase migration list. It still contains all 20 versions, including the seven versions whose source bodies are missing locally.

These checks do not search private repositories, local device folders, unuploaded archives, backups, deployment artifacts, or other collaborators' clones. A no-result code search is not proof that no copy exists elsewhere.

## Local-device recovery scope

No Termux or owner-device commands are required for this workflow. This session cannot inspect files stored only on the owner's phone, local clone, or private backup, so that evidence remains unavailable unless it is later attached or made accessible through an approved integration. Continue repository-side and database-side checks without asking the owner to run shell commands.

## Repository/ledger count recheck — 2026-10-25

The live ledger still has 20 applied versions. The branch now has 19 SQL migration files: 13 exact version/name matches and six local-only files. The four later files below were added after the initial 2026-10-24 inventory; none is recorded as applied in the current live ledger:

- `20261024130000_harden_mock_test_input_nulls.sql`
- `20261025100000_enforce_unique_pyq_option_labels.sql`
- `20261025110000_harden_daily_challenge_authoring_integrity.sql`
- `20261025120000_add_mock_test_response_question_id_index.sql`

The two publication-gate files remain local-only as well. CI run [40154542265](https://github.com/black-jee/blackjee/actions/runs/40154542265) passed both quality and disposable reconstruction replay jobs on commit `9f924ab40e369093153ed579fdaf8e3af22c7588`. These tests do not mean any of the six local-only migrations were applied to production.

## Missing applied bodies

- `20261024080824` — `foundation_schema`
- `20261024080924` — `tighten_rpc_grants_and_policy`
- `20261024081041` — `daily_solution_release_rpc`
- `20261024081337` — `numeric_answers_and_admin_review`
- `20261024081603` — `secure_daily_attempt_sessions`
- `20261024081731` — `restrict_anon_rpc_execution`
- `20261024112132` — `require_pyq_source_page_before_publish`

The live version `20261024112132` must not be replaced by either local-only file with a different version number. The later local files may overlap in purpose, but their existence does not establish what SQL was applied at the recorded version.

## Safe recovery path

1. Search user-controlled local folders, Termux working directories, downloaded archives, editor backups, and any other clone for `supabase/migrations` and the exact missing version prefixes.
2. Check any available database schema exports or deployment artifacts. Treat schema dumps as evidence for reconstructing current state, not as proof of historical migration contents.
3. If originals cannot be recovered, create a separately labelled **baseline reconstruction** from reviewed catalog evidence. Do not name it or describe it as an original migration.
4. Run any replay only against a disposable PostgreSQL service in GitHub Actions, with no production credentials and no paid Supabase branch/project.
5. Compare the isolated result to a read-only live schema snapshot and review every difference before considering any production change.

## Verification state

- Original SQL recovery: **BLOCKED / not found in the checked public repository history and indexed code search**.
- Clean replay from zero: **UNVERIFIED / not safe to attempt with the current chain**.
- Live production database changes during these checks: **NONE**.
- Paid infrastructure created: **NONE**.

## Next actionable recovery input

The highest-value next input is an archive, old clone, Termux folder, or backup containing the original `supabase/migrations/` files. Until one is found or a reconstruction is explicitly separated and reviewed, preserve the live migration ledger and do not run `db reset`, `migration repair`, or ad hoc DDL against the target.

## Read-only recovery recheck — 2026-10-25

- **Live ledger:** a fresh Supabase migration-list read returned 20 applied versions. The seven missing source bodies remain ledger entries, not reconstructed SQL.
- **Repository migration directory:** a fresh GitHub API directory listing on `chore/schema-reconstruction` returned 19 SQL files. Comparison with the live version/name list confirms 13 exact matches, seven live versions without matching SQL files, and six repository-only SQL files.
- **Path-specific Git history:** queried GitHub commit history for each of the seven exact missing paths on this repository. The API returned zero commits for all seven:
  - `20261024080824_foundation_schema.sql`
  - `20261024080924_tighten_rpc_grants_and_policy.sql`
  - `20261024081041_daily_solution_release_rpc.sql`
  - `20261024081337_numeric_answers_and_admin_review.sql`
  - `20261024081603_secure_daily_attempt_sessions.sql`
  - `20261024081731_restrict_anon_rpc_execution.sql`
  - `20261024112132_require_pyq_source_page_before_publish.sql`
- **Interpretation:** this establishes that the current public repository path history does not contain these exact files. It does not prove that originals do not exist in private backups, other repositories, local clones, or deployment artifacts. Do not infer SQL from migration names or catalog state and label it original.
- **CI reference:** [run 40166741350](https://github.com/black-jee/blackjee/actions/runs/40166741350) passed both quality and disposable PostgreSQL reconstruction jobs on commit `bb0d19bb58e09c7dba41892a7d0c571d08155579`. A documentation-only follow-up commit is separately queued for CI; it is not yet verified.
- **Safety:** all database checks in this recheck were read-only. No migration was applied or repaired, no database rows or schema were changed, no JEE content was added, no paid infrastructure was created, and PR #2 remains draft/unmerged.

## Additional public-repository recovery search — 2026-10-25

- **Alternate repository checked:** `black-jee/Sample` is public. Its current `main` tree contains a small `README.md` documenting that the repository was created to test GitHub write access; the tree contains no migration SQL or backup artifacts. Repository metadata reports size `0`, which is inconsistent with the returned tree, so the tree listing and README were used as the content evidence.
- **Indexed code search:** exact missing filename `20261024080824_foundation_schema.sql` returned no results within the `black-jee` owner scope.
- **Indexed commit search:** `foundation_schema` returned no matching commits within the `black-jee` owner scope.
- **Interpretation:** this narrows the public GitHub recovery paths checked, but does not inspect private repositories, local devices, cloud drives, editor backups, or external archives. The missing migration bodies remain **not recovered**.
- **Safety:** the `Sample` repository was only read during this recheck; no new file was created by this check, and no production database action was taken.

## Branch and indexed-search recheck — 2026-10-25

- Requeried path-specific GitHub commit history for each of the seven missing migration filenames; all seven returned zero commits.
- Checked the expected exact paths on the repository branches `main` and `chore/sql-security-test-plan`; none of the seven source files exists at those paths. The current `chore/schema-reconstruction` branch also has no original bodies at those paths.
- Searched indexed GitHub files for each exact version/name pair; no results were returned.
- **Conclusion:** no original SQL body was recovered from the public repository paths, branch checks, or indexed searches performed in this pass. This is not proof that private backups, local clones, external archives, or deployment artifacts do not exist.
- **Next action:** preserve the production ledger and keep the reconstruction labelled separately. Do not synthesize historical bodies or run `migration repair`, `db reset`, or production DDL to force parity.
- **Safety:** all checks were repository/API reads; no production database mutation, paid resource, question/solution addition, or PR merge occurred.
