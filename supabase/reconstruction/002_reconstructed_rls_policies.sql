-- BLACK-JEE RECONSTRUCTED RLS POLICIES — REVIEW DRAFT ONLY.
-- Reconstructed from read-only pg_policies inspection on 2026-10-24.
-- Apply only after 001_reconstructed_table_shapes.sql in a disposable database.
-- NOT production migration history and NOT a complete security baseline.
-- This file intentionally does not grant table/column privileges, create RPCs,
-- or alter private-table policies. Capture and review those separately.
begin;

create policy "Users read their own challenge attempts"
  on public.daily_challenge_attempts
  for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
  );

create policy "Admins delete challenges"
  on public.daily_challenges
  for delete
  to authenticated
  using (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create policy "Admins insert challenges"
  on public.daily_challenges
  for insert
  to authenticated
  with check (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create policy "Admins update challenges"
  on public.daily_challenges
  for update
  to authenticated
  using (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin')
  with check (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create policy "Live challenge schedule is readable"
  on public.daily_challenges
  for select
  to anon, authenticated
  using (
    is_live = true
    or ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
  );

create policy "Admins delete PYQs"
  on public.jee_pyq_questions
  for delete
  to authenticated
  using (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create policy "Admins insert PYQs"
  on public.jee_pyq_questions
  for insert
  to authenticated
  with check (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create policy "Admins update PYQs"
  on public.jee_pyq_questions
  for update
  to authenticated
  using (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin')
  with check (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create policy "Published PYQs and admin review queue are readable"
  on public.jee_pyq_questions
  for select
  to anon, authenticated
  using (
    (is_published and review_status = 'approved')
    or ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
  );

create policy "Users can read own mock test attempts"
  on public.mock_test_attempts
  for select
  to authenticated
  using (user_id = (select auth.uid()));

commit;

-- Review gates:
-- 1. Confirm policy expressions/names against pg_policies during replay.
-- 2. Column-level grants are a separate requirement: policies do not grant SQL
--    privileges by themselves. Do not add broad grants to make this draft work.
-- 3. Private answer/session tables intentionally have no direct browser policies;
--    access must remain via reviewed SECURITY DEFINER RPCs.
-- 4. This draft has not been replayed or executed and must not be applied to prod.
