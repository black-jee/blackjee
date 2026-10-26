-- RECONSTRUCTION CANDIDATE ONLY — NOT AN ORIGINAL HISTORICAL MIGRATION.
-- Applied ledger version 20261024081337 is missing from available sources.
-- This candidate is a verbatim copy of the similar-purpose archived file
-- 20261024081110_numeric_answers_and_admin_review.sql from blackjee-foundation.zip.
-- Source archive SHA-256: f0bfe458bdf81f7f84f34ef00e4e1d33c734f231eb31777c9397f659c9ce0433
-- This file is deliberately outside supabase/migrations/ so Supabase CLI will not
-- treat it as an applied migration. Do not run against production or use to repair
-- the migration ledger. Replay only in a disposable PostgreSQL database and compare
-- the resulting constraints and policy expression with the recorded live snapshot.

alter table private.jee_pyq_answer_keys
  drop constraint if exists jee_pyq_answer_keys_correct_answer_check;
alter table private.jee_pyq_answer_keys
  drop constraint if exists jee_pyq_answer_keys_correct_answer_nonempty;
alter table private.jee_pyq_answer_keys
  add constraint jee_pyq_answer_keys_correct_answer_nonempty
  check (length(trim(correct_answer)) > 0);

alter table private.daily_challenge_answer_keys
  drop constraint if exists daily_challenge_answer_keys_correct_answer_check;
alter table private.daily_challenge_answer_keys
  drop constraint if exists daily_challenge_answer_keys_correct_answer_nonempty;
alter table private.daily_challenge_answer_keys
  add constraint daily_challenge_answer_keys_correct_answer_nonempty
  check (length(trim(correct_answer)) > 0);

drop policy if exists "Published and approved PYQs are readable"
  on public.jee_pyq_questions;
drop policy if exists "Published PYQs and admin review queue are readable"
  on public.jee_pyq_questions;

create policy "Published PYQs and admin review queue are readable"
  on public.jee_pyq_questions
  for select to anon, authenticated
  using (
    (is_published and review_status = 'approved')
    or (select auth.jwt())->'app_metadata'->>'role' = 'admin'
  );
