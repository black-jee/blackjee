
alter table private.jee_pyq_answer_keys drop constraint if exists jee_pyq_answer_keys_correct_answer_check;
alter table private.jee_pyq_answer_keys add constraint jee_pyq_answer_keys_correct_answer_nonempty check (length(trim(correct_answer)) > 0);
alter table private.daily_challenge_answer_keys drop constraint if exists daily_challenge_answer_keys_correct_answer_check;
alter table private.daily_challenge_answer_keys add constraint daily_challenge_answer_keys_correct_answer_nonempty check (length(trim(correct_answer)) > 0);

drop policy if exists "Published and approved PYQs are readable" on public.jee_pyq_questions;
create policy "Published PYQs and admin review queue are readable" on public.jee_pyq_questions
for select to anon, authenticated
using ((is_published and review_status='approved') or (select auth.jwt())->'app_metadata'->>'role'='admin');
