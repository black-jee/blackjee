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

# Migration recovery search log — 2026-10-24

## Purpose

Record the exact recovery checks performed for the BLACK-JEE Supabase migration chain. This is evidence tracking only. It does not reconstruct SQL, authorize replay, or authorize changes to the live Supabase project.

## Current facts

- Target project: `phdssyexhfyxsmhmmcgb`.
- Live migration history contains 20 versions.
- Current reconstruction branch contains 24 SQL files under `supabase/migrations/` (README excluded).
- Eighteen versions have exact filename/version matches.
- Two applied bodies remain missing: `20261024081337_numeric_answers_and_admin_review` and `20261024112132_require_pyq_source_page_before_publish`.
- Six repository SQL files remain absent from the live migration ledger.
- Five formerly missing bodies were restored byte-for-byte from `blackjee-foundation.zip`; exact Git blob IDs are listed above.
- The archive's `20261024081110_numeric_answers_and_admin_review.sql` is a near-match only and is not represented as the applied `20261024081337` body.

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

## Applied bodies still missing

- `20261024081337` — `numeric_answers_and_admin_review` (archive contains similar-purpose `20261024081110`; do not rename it).
- `20261024112132` — `require_pyq_source_page_before_publish` (local same-purpose files use different versions).

The five recovered files retain their original names and byte contents. Do not fabricate, relabel, or repair production migration history for the two unresolved versions.

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

## Read-only continuation — 2026-10-26

- Re-read the branch's reconciliation report, chain inventory, recovery search log, and session handover before continuing; the documented inventory remains 20 live versions, 24 repository SQL files, 18 exact version/name matches, two unresolved applied bodies, and six repository-only files.
- Rechecked the exact expected paths for the two unresolved SQL files on `chore/schema-reconstruction` through the GitHub contents API. Both paths return 404 (no file at that exact path); this is consistent with the recorded missing-body status, not evidence about private/local backups.
- A GitHub commit search returned newer documentation commits, but did not establish that either missing SQL body was recovered. The existing archive near-match `20261024081110_numeric_answers_and_admin_review.sql` and local `20261024112500` / `20261024120000` publication-gate files remain non-substitutes.
- CI status check for the previously documented handover head `81e979207b39915b94c272780a9b1b810fb16380` reports the Vercel context as success; this status alone is not the quality/reconstruction CI result. The owner supplied CI run [#679 / 40243919626](https://github.com/black-jee/blackjee/actions/runs/40243919626) as the latest green CI evidence; this session did not independently retrieve its full job conclusions.
- Library semantic search for the archive name surfaced migration SQL snippets but did not expose the ZIP itself as a directly inspectable result in this pass. Therefore no new archive contents or historical body were recovered.
- No SQL was fabricated or relabelled. No Supabase schema/data/grants/ledger changes, paid resources, PR merge, or question/solution content changes were performed.

**Next action:** search the archive as a concrete Library file / inspect other authoritative attached backups, then compare any candidate source by exact version and Git blob bytes before changing the inventory. If no original appears, prepare a separately labelled reconstruction proposal for review rather than claiming original recovery.

## Direct Library archive inspection — 2026-10-26

The Library was browsed by filename and the following five ZIP archives were materialized for read-only inspection:

- `blackjee-foundation.zip` — SHA-256 `f0bfe458bdf81f7f84f34ef00e4e1d33c734f231eb31777c9397f659c9ce0433`; 71 entries. It contains `20261024081110_numeric_answers_and_admin_review.sql`, but no `20261024081337` original and no `20261024112132_require_pyq_source_page_before_publish` path.
- `BLACK-JEE-main.zip`, `BLACK-JEE-main (1).zip`, `BLACK-JEE-main(1).zip`, and `BLACK-JEE-main(2).zip` — each contains 100 entries and has the same SHA-256 `8e5abd749a3a6dac6f785cf320d1d23f9ba6c2c02d3df311a89cc1bfd939c44e`. None contains a matching path or filename for either unresolved migration.

This closes the direct inspection of all ZIP archives currently visible in the Library. It does not cover local-device folders, private repositories, cloud backups not uploaded to this Library, or external deployment artifacts. No original body was recovered. Do not substitute the near-match or infer historical SQL.

**Next step:** inspect authoritative migration artifacts outside the current Library only if they become available; otherwise prepare a separately labelled reconstruction proposal with provenance and explicit review gates. Keep production untouched.
