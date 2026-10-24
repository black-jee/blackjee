# SQL security test execution plan — 2026-10-24

## Purpose

Define the safe route to run the existing SQL contract checks and add runtime authorization tests without touching the live Supabase project. This is a plan, not evidence that the tests have run.

## Current verified constraints

- The GitHub Actions CI workflow runs application checks but does not execute `supabase/tests/*.sql`.
- Existing SQL tests are primarily `DO $$ ... $$` catalog assertions. They are not yet demonstrated to be compatible with `supabase test db` / pgTAP TAP output.
- The applied migration history has 20 versions; seven original SQL bodies are missing from the repository. A clean replay is therefore not currently reproducible.
- No paid Supabase branch/project is permitted. No reset, migration repair, ad hoc production DDL, or production content mutation is part of this plan.

## Gate 0 — resolve schema reproducibility

1. Recover the seven original migration bodies from an authoritative archive/clone if available.
2. If they cannot be recovered, create a separately named reconstructed baseline from read-only catalog definitions and label every reconstructed file; never present it as original history.
3. Reconcile the local-only publication guard migrations with the applied `20261024112132` record.
4. Verify the complete replay against a disposable no-cost PostgreSQL-compatible environment before wiring SQL tests into CI.

**Do not proceed to a replay claim while this gate is unresolved.**

## Gate 1 — preserve static contract checks

Run the existing SQL assertions against the reconstructed disposable database and confirm expected objects/signatures exist:
- `security_definer_rpc_contracts.sql`
- `private_table_access.sql`
- `mock_test_security.sql`
- `public_schedule_rpc_security.sql`
- `daily_challenge_assets.sql`

Because these files use exception-raising DO blocks rather than pgTAP assertions, first determine the correct runner. Do not claim `supabase test db` compatibility without an actual successful run.

## Gate 2 — add isolated runtime authorization tests

Use synthetic fixtures and separate identities only. Never create or publish production questions/challenges to test security.

### Mock tests
- Student A cannot resume, submit, or retrieve results for Student B's attempt ID.
- Unsubmitted attempts cannot return final results.
- Submission rejects question IDs not belonging to the attempt.
- Repeated submission follows the documented idempotency policy and never crosses user ownership.

### Daily challenge
- Anonymous callers cannot execute protected result/start/submit RPCs.
- Before `solution_release_at`, the answer and solution are absent from the response.
- Test just before, at, and after release time using a controlled test clock/fixtures where possible.
- Confirm the intended post-release rule: may any authenticated learner read the released solution, or must the learner have started/submitted an attempt? Current RPC behavior permits any authenticated caller who knows a live challenge ID after release. Do not change that behavior until the product rule is decided.

### PYQ authoring and grading
- Ordinary authenticated users cannot successfully invoke admin save/review operations.
- An admin can save a synthetic draft but cannot publish it without a source reference, valid source page, non-empty statement, private answer key, worked solution, and a matching single-correct option label.
- Student A's grading attempts do not expose or mutate Student B's records.
- Answer keys remain inaccessible through direct browser-role table grants.

## Gate 3 — CI integration

After the clean replay gate passes:
1. Add a separate SQL-test job using a disposable database service and no production secrets.
2. Apply the canonical migration chain from zero.
3. Run static SQL contracts and runtime integration tests.
4. Make failures block pull requests.
5. Verify the workflow on a branch before merge; never connect CI to the production Supabase URL or service-role key.

## Performance candidate (not approved to apply)

`private.mock_test_responses` has a composite primary key beginning with `attempt_id`, which does not provide a leading-key index for its `question_id` foreign key. The table was observed empty, so workload benefit is not demonstrated. Review expected scale and add a versioned index only after the canonical migration chain is reconciled; do not execute ad hoc DDL on production.

## Completion criteria

- [ ] Original migrations recovered or reconstructed baseline clearly labelled and reviewed
- [ ] Fresh replay succeeds in disposable environment
- [ ] Existing SQL contract checks run successfully
- [ ] Cross-user and release-boundary runtime tests pass
- [ ] SQL tests run in CI with no production credentials
- [ ] Advisors reviewed after any approved schema changes

No questions or solutions are added, approved, or published as part of this work.
