# BLACK-JEE database hardening rollout and rollback plan

Status: **proposal only — not authorized for production execution**  
Branch: `chore/schema-reconstruction`  
Draft PR: https://github.com/black-jee/blackjee/pull/2

## Preconditions

- Keep PR #2 draft and unmerged pending review.
- Confirm a recoverable database backup/restore point and maintenance window before any production rollout.
- Review migration SQL and current definitions against the live catalog immediately before deployment.
- Run CI and disposable replay against the exact proposed commit.
- Confirm the intended daily-challenge solution-release behavior; do not silently change it as part of hardening.
- No migration-ledger edits or historical migration rewrites.

## Proposed forward-only order

1. **Mock-test NULL input guard** — `20261024130000_harden_mock_test_input_nulls.sql`. Replaces `public.start_mock_test` with explicit validation before question selection. Verify function signature, owner, SECURITY DEFINER, empty search_path, and EXECUTE ACLs remain unchanged after deployment.
2. **Daily-challenge authoring guard** — `20261025110000_harden_daily_challenge_authoring_integrity.sql`. Explicitly rejects NULL schedule fields and validates options/answer consistency. Verify the admin role check and ACLs.
3. **PYQ option-label trigger** — `20261025100000_enforce_unique_pyq_option_labels.sql`. Rejects invalid or duplicate labels on insert/update. Before rollout, run a read-only preflight that counts existing single-correct questions whose options are not arrays, have fewer than two options, have blank labels, or duplicate normalized labels. Do not rewrite existing question content automatically.
4. **Response question index** — `20261025120000_add_mock_test_response_question_id_index.sql`. Review table size, available disk, and lock impact; prefer `CREATE INDEX CONCURRENTLY` in a separately managed non-transactional deployment if operationally appropriate. The current branch migration uses ordinary `CREATE INDEX`, so adjust and test the deployment approach before production.

## Post-deploy checks

- Re-read function definitions, SECURITY DEFINER status, function configuration, ownership and effective EXECUTE privileges.
- Verify trigger presence and definition, index validity/definition, and exact migration-ledger entries created by the approved deployment process.
- Run bounded smoke tests with genuine Supabase-issued anonymous, student and admin JWTs. Confirm anonymous/unauthorized calls fail, authorized admin authoring works, invalid NULL inputs fail before expensive selection, and valid calls behave normally.
- Re-check application health, logs, error rates and query latency. Do not expose answer keys or private rows through public endpoints.
- Save before/after catalog snapshots and deployment timestamps in the PR.

## Rollback principles

- Do not drop the new index/trigger or restore older function bodies automatically just because a smoke test fails; first assess impact and data written after rollout.
- If the new trigger blocks legitimate existing application writes, disable/remove only the new trigger after review, preserving the function and existing data until root cause is understood.
- If an RPC replacement causes regressions, restore the exact pre-deploy function definition and ACL captured in the approved backup/snapshot; do not reconstruct the old body from memory or overwrite historical migration files.
- The index can be dropped only after confirming the exact index name, no dependent operation, and acceptable FK-query performance impact.
- Do not delete or modify migration-ledger rows during rollback. Record forward repair migrations if a later correction is required.
- If rollback is needed, stop further schema changes, preserve logs/catalog snapshots, and validate production behavior before resuming rollout.

## Explicit non-goals

No direct production change is made by this document. Do not apply any migration, change grants, alter data, repair historical migration history, add broad private-table policies, or merge PR #2 without explicit approval.
