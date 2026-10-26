# Repository-only migration review — 2026-10-26

## Scope and safety

Read-only comparison of the six repository migration files absent from the connected production migration ledger. Production migration history lists 20 applied versions through `20261024112132`. No SQL from this review was executed against production. This review is not approval to apply any repository-only migration.

## Findings

| File | Observed difference / purpose | Disposition |
|---|---|---|
| `20261024112500_require_pyq_source_page_before_publish.sql` | Its Git blob is identical to the recovered applied migration `20261024112132_require_pyq_source_page_before_publish.sql`. Same body under a second version means a fresh replay replaces the same RPC twice. | **Redundant duplicate.** Do not treat it as historical. Keep out of a canonical chain unless another environment's migration ledger proves it was applied there. |
| `20261024120000_require_pyq_source_and_solution_before_publish.sql` | Replaces the same admin-review RPC with source document + page, statement, private answer, worked-solution and option-label checks. The recovered applied `20261024112132` already contains these checks. | **Redundant relative to the recovered applied body.** Preserve for now; do not apply merely because it exists in Git. |
| `20261024130000_harden_mock_test_input_nulls.sql` | Replaces `start_mock_test` with explicit required-input checks, including NULL mode/count/duration and shift filters. Current production function was inspected read-only; explicit `IS NULL` guards for these arguments were not found. | **Potentially useful forward hardening, not historical recovery.** Add focused RPC negative tests and disposable replay before considering deployment. |
| `20261025100000_enforce_unique_pyq_option_labels.sql` | Adds a trigger to reject single-correct options with fewer than two entries, missing labels or duplicate labels. No corresponding trigger was found in the current production catalog. | **New integrity behavior.** Test malformed/non-array JSON, duplicate labels with case/whitespace variants, updates and existing content before deployment. Review trigger error behavior for non-array JSON so it always raises the intended validation error. |
| `20261025110000_harden_daily_challenge_authoring_integrity.sql` | Replaces `admin_save_daily_challenge` with explicit required date/timestamp checks, ordering checks, option label/uniqueness checks, answer-label match and a required worked solution for live challenges. Current production definition does not contain these new schedule NULL guards. | **Potentially useful forward hardening.** Add tests for NULL schedule values, empty/duplicate options, incorrect answer label, live challenge without solution, non-admin JWT and missing challenge ID; replay in disposable DB before deployment. Review whether live challenges should require at least two options (current SQL permits an empty array). |
| `20261025120000_add_mock_test_response_question_id_index.sql` | Adds an index on `private.mock_test_responses(question_id)`. A read-only performance-advisor finding previously identified this FK as unindexed. | **Low-risk performance candidate**, but confirm existing indexes/plan in a disposable database and verify migration replay before deployment. Do not change production under this task. |

## Chain recommendation

1. Treat the two source-page/source-and-solution entries dated 11:25 and 12:00 as repository-only redundant rewrites, not as evidence of the historical chain.
2. Keep the three forward hardening migrations (NULL handling, option-label validation, daily-challenge integrity) as **proposals** until focused negative tests pass and their behavior is reviewed.
3. Keep the index migration as a separate performance change.
4. Do not delete or renumber these files until any non-production environment ledgers are inventoried; production is the only connected environment known in this workflow.
5. Run the standard disposable reconstruction and CI against the exact commit before claiming the repository-only changes are verified.

**Important:** no production schema, data, grants, indexes, policies, or migration ledger were changed.
