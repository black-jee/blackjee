# Database plan

## New project baseline observed

Project: `phdssyexhfyxsmhmmcgb` (Tokyo / `ap-northeast-1`, PostgreSQL 17.11).

The target project had six applied migration records before the new repository was scaffolded. Eleven additional migrations are now recorded and checked into the repository:

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

The original six migration SQL bodies were not present in the new repository and still need to be reconstructed. Do not reset the target project until a replayable baseline is checked in and verified on an isolated database.

## Current logical tables

### Public schema

- `public.daily_challenges`
- `public.daily_challenge_attempts`
- `public.jee_pyq_questions`
- `public.mock_test_attempts`

### Private schema

- `private.daily_challenge_answer_keys`
- `private.daily_challenge_sessions`
- `private.jee_pyq_answer_attempts`
- `private.jee_pyq_answer_keys`
- `private.mock_test_responses`

All inspected tables have RLS enabled. Private tables have no browser-role policies and no direct browser-role table grants; trusted RPCs perform the needed operations.

## RPC contracts

- Public schedule metadata: `get_current_daily_challenge()` runs as invoker and does not return question content.
- Daily challenge attempts: `start_daily_challenge(uuid)` and `submit_daily_challenge(uuid,text)` validate the signed-in user, active schedule and attempt rules.
- Daily challenge results: `get_daily_challenge_result(uuid)` requires `auth.uid()` and enforces the configured release time.
- PYQ practice: `grade_jee_pyq(uuid,text)` is authenticated and enforces the answer/solution gate.
- Admin challenge authoring: `admin_save_daily_challenge(...)` checks server-managed `app_metadata.role = admin` and writes challenge content plus its private answer key atomically.
- Mock tests: `start_mock_test(...)`, `resume_mock_test(uuid)`, `submit_mock_test(uuid,jsonb)`, and `get_mock_test_result(uuid)` are ownership-bound. Focused-test JSON order is now tied explicitly to the stored question-ID order. The server chooses the question IDs, checks the 75-question shift structure, computes marks, and withholds answers until submission.

## Source schema mismatch

The uploaded original `supabase/schema.sql` defines `daily_questions`, `active_question_links`, and `attempt_submissions`; its migration history includes 18 SQL migrations plus schema and Edge Function source. The new project has a different baseline. Do not apply the original schema blindly and do not assume the original database rows/users/uploads exist.

## PYQ import state

The source ZIP contains 75 question slots for JEE Main 2026, April 4 Shift 1, along with source metadata, review notes, answer data and image references. Five Physics questions have been imported into the new database as `draft` rows with five answer keys in the private schema. **No question is published.** The remaining 70 rows and all image files still need migration. Source items marked `needs_review` must remain blocked and their answer keys withheld until reviewed.

## Migration rules

1. Keep all schema changes in version-controlled SQL migration files.
2. Do not reset the live target until the six missing baseline bodies are reconstructed and replay-tested elsewhere.
3. Never drop or rename existing tables/columns until dependent functions, grants, policies and app consumers have been inventoried.
4. Keep all exposed-schema tables RLS-enabled and grant only necessary Data API privileges.
5. Prefer invoker-security functions. Where `SECURITY DEFINER` is required to protect private tables, use a fixed `search_path`, fully qualify objects, validate `auth.uid()` and role, and explicitly revoke/grant execute.
6. Test policies as anonymous, ordinary authenticated student, owner/admin, and a different student.
7. Re-run security and performance advisors after each database stage.
8. Seed only content with provenance. Never publish unresolved questions or treat missing assets as verified.

## Current advisor findings

- **Security:** the advisor reports five private tables with RLS enabled and no policies (intentional because browser roles have no direct grants) and nine authenticated-callable `SECURITY DEFINER` RPCs. Each RPC has an explicit authenticated-user check; the admin save RPC also checks the server-managed admin role. These warnings remain documented and require ongoing review after each change.
- **Performance:** the daily challenge session foreign-key index and PYQ shift lookup index are present. Unused-index notices may be expected while the project is empty; evaluate after representative queries before removing indexes.

## Required next checks

- Reconstruct and replay the missing six baseline migrations on an isolated staging database.
- Complete the 70-question draft import and copy/verify image assets.
- Test start/resume/submit with seeded staging questions and real authenticated sessions.
- Verify storage buckets, access policies, and admin moderation functions.
- Verify no service-role or secret key is committed or returned to the browser.
