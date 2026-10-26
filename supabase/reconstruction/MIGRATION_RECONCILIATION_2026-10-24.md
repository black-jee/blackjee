# Migration reconciliation note — 2026-10-24

## Verified ledger and file facts

The live Supabase migration ledger has 20 entries. The applied versions relevant to PYQ publication are:

- `20261024111533 / require_pyq_source_and_solution_before_publish`
- `20261024112132 / require_pyq_source_page_before_publish`

The repository contains:

- `20261024111533_require_pyq_source_and_solution_before_publish.sql`
- `20261024112500_require_pyq_source_page_before_publish.sql` — not present in the live ledger
- `20261024120000_require_pyq_source_and_solution_before_publish.sql` — not present in the live ledger

The live definition of `public.admin_review_jee_pyq_question` currently requires a source document, a positive source page, a non-empty question statement, a private answer key, a worked solution, and an option-label match for single-correct questions. The function is `SECURITY DEFINER`, pins an empty `search_path`, and checks the server-managed admin role.

## Comparison

The checked-in `20261024111533` file requires a non-empty source reference, statement, private answer key, worked solution, and answer/option match, but it does not check that `source_page` is positive.

The local-only `20261024112500` file adds the source-page requirement while retaining the same answer-key/solution checks. The local-only `20261024120000` file expresses substantially the same publication requirements again, in a compressed format. Neither local-only file is evidence of the exact SQL body that was applied under live version `20261024112132`.

## Safe conclusion

**Verified:** the live function has all the checks described above, and the ledger/file mismatch exists.

**Inference only:** the most plausible intended sequence is that `20261024111533` introduced source/answer/solution checks and the applied `20261024112132` added the positive source-page check. This inference is consistent with the migration names and current function body, but the original `20261024112132` SQL body has not been recovered.

Do not rename a local-only file to `20261024112132`, mark a file as applied, or modify the live ledger to force a match. Preserve the live function and ledger. If a replay baseline is assembled later, label the reconstructed migration body explicitly as inferred reconstruction and verify it against a disposable database.

## Remaining migration recovery

The other six missing applied bodies remain unrecovered:

- `20261024080824_foundation_schema`
- `20261024080924_tighten_rpc_grants_and_policy`
- `20261024081041_daily_solution_release_rpc`
- `20261024081337_numeric_answers_and_admin_review`
- `20261024081603_secure_daily_attempt_sessions`
- `20261024081731_restrict_anon_rpc_execution`

No production schema or migration history was changed during this inspection.
