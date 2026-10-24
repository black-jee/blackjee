# Database plan

## New project baseline observed

Project: `phdssyexhfyxsmhmmcgb` (Tokyo / `ap-northeast-1`, PostgreSQL 17.11).  
Observed migration history before hardening: six entries, versions from `20261024080824` to `20261024081731`. The seventh migration `20261024095050_harden_public_schedule_rpc_and_index` and eighth migration `20261024100007_daily_challenge_question_assets` are now applied and verified. The latter adds a safe optional question-diagram path and returns it from the challenge-start RPC.  
Observed tables: 3 public tables and 4 private tables; all reported empty. RLS is enabled on the inspected tables. No Edge Functions are deployed in this project at the time of inspection.

### Public tables

- `public.daily_challenges`
- `public.daily_challenge_attempts`
- `public.jee_pyq_questions`

### Private tables

- `private.daily_challenge_answer_keys`
- `private.daily_challenge_sessions`
- `private.jee_pyq_answer_attempts`
- `private.jee_pyq_answer_keys`

Five public security-definer RPCs were found: `get_current_daily_challenge()`, `get_daily_challenge_result(uuid)`, `grade_jee_pyq(uuid,text)`, `start_daily_challenge(uuid)`, and `submit_daily_challenge(uuid,text)`.

## Source schema mismatch

The uploaded original `supabase/schema.sql` defines `daily_questions`, `active_question_links`, and `attempt_submissions`; its migration history includes 18 SQL migrations plus schema and Edge Function source. The new project has a different, already-applied six-migration baseline. Do not apply the original schema blindly and do not assume the original database rows/users/uploads exist.

## Target logical model (to finalize after schema mapping)

- Identity/roles: Supabase Auth plus server-managed administrator role.
- Daily challenges: schedule, question statement/options/assets, publication state, start/end times and solution-release time.
- Private challenge answer keys and attempt sessions: inaccessible directly to browser roles; exposed only through vetted RPCs.
- Challenge attempts/submissions: one per eligible student/challenge where required; private photo path; review and publication state.
- PYQ question bank: source identifiers, exam/year/shift, subject/chapter/topic, question content, typed options, asset references, review state, publication state and audit metadata.
- Private PYQ answer keys and grading attempts: no direct browser reads of answer keys; grading RPC enforces retry/solution-release rules.
- Content audit trail: actor, action, target, timestamp and minimal safe metadata for sensitive admin operations.
- Storage metadata / ownership where needed; private uploads use non-guessable paths and policy-enforced access.

## Migration rules

1. Commit each migration to `supabase/migrations/` before applying it.
2. Never drop or rename existing tables/columns until dependent functions, grants, policies and app consumers have been inventoried.
3. Keep all exposed-schema tables RLS-enabled and grant only necessary Data API privileges. Supabase no longer automatically exposes every new table in all project configurations; check Data API exposure explicitly.
4. Prefer invoker-security functions. Where `SECURITY DEFINER` is required to enforce trusted logic across private tables, use a fixed empty/known `search_path`, fully qualify object names, validate `auth.uid()` and role, and explicitly revoke/grant execute privileges.
5. Test policies as anonymous, ordinary authenticated student, owner/admin, and a different student.
6. Add indexes based on access patterns and foreign keys, not blindly based on advisor suggestions.
7. Re-run security and performance advisors after each database stage.
8. Seed only fixtures or content with provenance. Never seed invented answer keys or treat unresolved source assets as verified.

## Current advisor findings (after first hardening migration)

- Security: private tables have RLS enabled but no policies; verified grants show only `postgres` has table privileges on those four private tables. Four security-definer RPCs remain callable by authenticated users and require per-function grant/body review. The public schedule RPC was changed to invoker security and the advisor warning for anon-executable security-definer was removed.
- Performance: added `private.daily_challenge_sessions(user_id)` index for its foreign key. Unused-index notices may be expected on an empty project; evaluate after representative queries before removing indexes.

## Required next checks

- Export definitions of all baseline tables, policies, grants, constraints, triggers, functions and storage buckets into a reproducible migration baseline.
- Compare baseline to the original source schema and the actual HTML/RPC consumers.
- Add the next additive migration only after the target mapping is agreed and regression tests exist.
- Verify no service-role or secret key is committed or returned to the browser.
