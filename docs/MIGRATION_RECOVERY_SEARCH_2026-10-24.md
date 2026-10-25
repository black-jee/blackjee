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

## Optional local recovery check (Termux / Android)

If an older clone or downloaded archive may exist on the owner's device, run these read-only commands in Termux. They only print matching paths; they do not edit or upload files.

```sh
# Search Termux home for the exact missing migration filenames.
find "$HOME" -type f \( -name '20261024080824*' -o -name '20261024080924*' -o -name '20261024081041*' -o -name '20261024081337*' -o -name '20261024081603*' -o -name '20261024081731*' -o -name '20261024112132*' \) -print 2>/dev/null

# If Android shared storage permission was already granted, search Downloads too.
find "$HOME/storage/shared/Download" -type f \( -iname '*.zip' -o -iname '*.tar' -o -iname '*.tar.gz' -o -iname '*.tgz' -o -iname '*.7z' -o -name '20261024*.sql' \) -print 2>/dev/null
```

If the shared Download folder does not exist, do not change permissions just for this check; run `termux-setup-storage` only if the owner chooses to grant Termux shared-storage access. Inspect candidate archives before extracting them, and do not upload secrets or `.env` files. A matching filename is only a candidate: compare SQL content and provenance before treating it as original history.

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
