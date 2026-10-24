# Migration reconciliation report

**Date:** 2026-10-24  
**Task:** BJ-DB-001  
**Target:** Supabase project `phdssyexhfyxsmhmmcgb`  
**Repository HEAD inspected:** `2195242d7b78cf52447ea2cd4fab83d30c834440`

## Findings from read-only inspection

### Migration history mismatch

The live Supabase migration history contains 20 applied versions. The first six are the missing baseline bodies:

- `20261024080824_foundation_schema`
- `20261024080924_tighten_rpc_grants_and_policy`
- `20261024081041_daily_solution_release_rpc`
- `20261024081337_numeric_answers_and_admin_review`
- `20261024081603_secure_daily_attempt_sessions`
- `20261024081731_restrict_anon_rpc_execution`

The live history then records these 14 versions, in order:

- `20261024095050_harden_public_schedule_rpc_and_index`
- `20261024100007_daily_challenge_question_assets`
- `20261024100245_pyq_question_image_paths`
- `20261024100341_question_image_path_read_grants`
- `20261024100524_admin_save_daily_challenge`
- `20261024101157_secure_mock_test_attempts`
- `20261024101243_resume_mock_test_attempt`
- `20261024101313_pyq_mock_metadata_read_grants`
- `20261024101531_preserve_pyq_source_provenance`
- `20261024102206_require_auth_for_daily_solution`
- `20261024102525_stable_mock_question_order`
- `20261024103715_admin_pyq_authoring_review`
- `20261024111533_require_pyq_source_and_solution_before_publish`
- `20261024112132_require_pyq_source_page_before_publish`

### Repository migration directory drift

The current repository contains 15 SQL files, but only 13 filenames exactly match versions in live migration history. Three discrepancies require resolution:

1. Live version `20261024112132_require_pyq_source_page_before_publish` has no matching repository file. The repository instead contains `20261024112500_require_pyq_source_page_before_publish.sql`, which has the same page-number guard but a different version.
2. `20261024120000_require_pyq_source_and_solution_before_publish.sql` is present in the repository but is not recorded as applied in the live history. It duplicates the stricter source-page gate and must not be assumed to have run.
3. The source-page guard appears both under the unapplied `112500` filename and inside the unapplied `120000` file. Do not rename, delete, or apply either file until the repository history and intended release sequence are reviewed.

This is more than the original six-file gap: the current migration directory is not an exact representation of the live applied chain. A clean replay must use a reviewed, ordered chain and explicitly document how the original six versions and the version drift are represented. Do not rewrite applied version identifiers in the live project.

### Live schema snapshot (read-only)

The public base tables currently visible are:

- `public.daily_challenge_attempts`
- `public.daily_challenges`
- `public.jee_pyq_questions`
- `public.mock_test_attempts`

The live schema also has private tables used for answer keys, answer attempts/responses, and daily challenge sessions. Read-only inspection returned public functions for daily challenge scheduling, starting/submitting attempts, mock-test lifecycle/results, PYQ grading and admin authoring/review. Policies inspected on public tables constrain admin writes to authenticated users whose server-managed `app_metadata.role` is `admin`, limit attempt reads by owner, and expose only live challenge metadata/published approved PYQs to ordinary readers.

The current `admin_review_jee_pyq_question` definition requires a source PDF and page, non-empty question statement, private answer key, worked solution, and a matching option label for single-correct questions before publishing. Existing production records must not be used as destructive test fixtures.

This is a partial snapshot, not a complete schema dump. Constraint definitions, all column-level grants, private-schema grants, storage policies/buckets, function owners/configuration, triggers, extensions, and all foreign keys still need to be exported and compared before a replay can be considered equivalent.

## Safe next procedure

1. Keep all work read-only on the target while capturing complete schema metadata and object definitions.
2. Retrieve migration history from Git history or other authoritative backup if available; do not invent historical SQL from names alone.
3. Build a clearly labelled reconstruction chain in a separate branch or isolated directory. If historical bodies cannot be recovered, mark reconstructed equivalents as reconstructions and document why they are semantically equivalent; do not silently pretend they are original bodies.
4. Provision a disposable isolated PostgreSQL/Supabase-compatible environment. Replay from empty state and compare tables, columns, constraints, indexes, triggers, RLS policies, grants, functions, and storage configuration with the target.
5. Resolve the `112132` / `112500` / `120000` drift in review before merging a canonical migration directory.
6. Run role-based security tests as anonymous, ordinary student, owner, and admin using disposable fixtures. Confirm answer keys never become public.
7. Update `docs/DATABASE_PLAN.md`, `docs/TASKS.md`, `docs/VERIFICATION_LOG.md`, and the session handover with concrete evidence.
8. Obtain explicit owner approval before any potentially risky migration against the target. Never reset the target project as a way to fix history.

## Actions taken in this session

- Re-queried live migration history and repository migration filenames.
- Queried live public table columns, public routine names/definitions (partial), public RLS policies, and public indexes.
- Verified CI run [40092001380](https://github.com/black-jee/blackjee/actions/runs/40092001380) completed successfully, including lint, typecheck, unit tests, Playwright E2E, format check, and production build.
- No DDL, migration apply, reset, row mutation, publication, or deployment action was performed.


## Expanded read-only security/storage inventory

A follow-up catalog query found:

- **RLS:** enabled on all four application tables in `public` and all five application tables in `private`. RLS is not forced on these tables.
- **Private-schema policies:** zero explicit policies. Private tables have table ACLs owned by `postgres` and no direct grants to `anon` or `authenticated` in the inspected ACLs; access is intended through guarded functions.
- **Application triggers:** zero non-internal triggers on `public` and `private` tables.
- **Storage buckets:** zero rows in `storage.buckets`; no storage policies were returned. This means no application bucket is currently configured in this project. Do not assume question images can be served from Supabase Storage until a bucket and its access model are intentionally provisioned.
- **Function hardening:** inspected security-sensitive admin functions are owned by `postgres`, marked `SECURITY DEFINER`, and set `search_path` to empty. Their bodies use schema-qualified objects and validate `auth.uid()` plus server-managed `app_metadata.role = admin`. The PYQ review function checks source PDF/page, private answer key, worked solution, and option-label consistency before publishing. The function ACL shown for that review RPC grants execute to `authenticated` and `service_role`, not `anon` or `PUBLIC`.
- **Public RLS policies:** student attempt reads are owner-scoped (or admin-scoped for daily challenge attempts); live daily challenge schedule and approved/published PYQs are the ordinary-reader paths; challenge/PYQ write policies require authenticated admin role; mock attempt reads are owner-scoped.

### Remaining caveats

This is catalog inspection, not a schema dump. Full function bodies were truncated in some tool output and must be captured per function; column-level grants, sequence grants, schema ACLs, extension versions, storage API configuration, and auth/storage platform configuration still need validation. A disposable database has not yet been provisioned, so migration replay equivalence remains untested.

