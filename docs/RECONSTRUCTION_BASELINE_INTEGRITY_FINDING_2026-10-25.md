# Reconstruction baseline integrity finding — 2026-10-25

## Status

**Review finding; no production change.** Branch: `chore/schema-reconstruction`. Latest verified CI commit before this note: `1cd8b589f227c4b53f39a2a16372dd03fe3dc0d4`; [run 40164930912](https://github.com/black-jee/blackjee/actions/runs/40164930912) passed both quality and reconstruction-replay jobs.

## Finding: reconstructed RPC file mixes live snapshot and hardening

File: `supabase/reconstruction/003_reconstructed_rpc_definitions.sql`

The file header describes the file as a current live catalog snapshot. However, its `public.admin_save_daily_challenge` body contains explicit reconstructed hardening:

- live challenge requires a non-empty worked solution;
- explicit schedule comparisons;
- options JSON-array and count validation;
- non-empty and unique option-label checks;
- correct answer must match an option label.

The same function block labels `ebdff78aa677719515c9e500fc576562` as the **original live definition fingerprint before reconstruction-only hardening**. That means this function body is not an exact copy of the live definition represented by that fingerprint. The baseline and proposed fix are mixed in one replay artifact.

### Why it matters

- A successful replay proves the chosen reconstructed state is internally valid; it does not prove the reconstructed RPC file faithfully represents the production snapshot.
- A reviewer may mistake a branch-only fix for existing production behavior.
- If the forward migration repeats the same guards, the replay may not adequately demonstrate the difference between pre-fix and post-fix state.
- Historical migration provenance cannot be inferred from the fingerprint comment.

### Required repair before claiming exact RPC parity

1. Capture the exact live `pg_get_functiondef` body for `admin_save_daily_challenge` into a clearly labelled baseline artifact, retaining its observed fingerprint.
2. Move hardening exclusively into `20261025110000_harden_daily_challenge_authoring_integrity.sql` (or another explicitly proposed forward migration), not the baseline snapshot.
3. Add a replay assertion that checks the baseline fingerprint/body before hardening, then checks the post-migration guard behavior after hardening.
4. Ensure docs and CI distinguish **baseline parity** from **post-hardening expected state**.
5. Re-run disposable replay and the full quality workflow; review the exact diff before treating this as release-ready.

## Additional focused check

The live privilege check showed `anon`, `authenticated`, and `service_role` all lack `USAGE` on schema `private`; all three also lack direct SELECT on `private.mock_test_responses` and `private.jee_pyq_answer_keys`. They have `USAGE` on `public` and lack `CREATE` on `public`. This is consistent with the reconstructed grant file's private-schema isolation for these roles, but it does not replace a full effective-grants comparison across all tracked objects and inherited privileges.

## Safety boundary

This finding is documentation only. No live schema, grants, data, or migration ledger was changed. PR #2 remains draft/open/unmerged. No JEE content was added.
