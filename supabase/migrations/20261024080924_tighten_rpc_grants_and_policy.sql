revoke execute on function public.grade_jee_pyq(uuid,text) from anon, public;
grant execute on function public.grade_jee_pyq(uuid,text) to authenticated;
revoke execute on function public.submit_daily_challenge(uuid,text,integer) from anon, public;
grant execute on function public.submit_daily_challenge(uuid,text,integer) to authenticated;
-- Public schedule RPC intentionally serves only the live challenge statement/options, never its answer key.
revoke execute on function public.get_current_daily_challenge() from public;
grant execute on function public.get_current_daily_challenge() to anon, authenticated;

drop policy if exists "Admins manage PYQs" on public.jee_pyq_questions;
drop policy if exists "Published and approved PYQs are readable" on public.jee_pyq_questions;
create policy "Admins insert PYQs" on public.jee_pyq_questions for insert to authenticated
with check ((select auth.jwt())->'app_metadata'->>'role'='admin');
create policy "Admins update PYQs" on public.jee_pyq_questions for update to authenticated
using ((select auth.jwt())->'app_metadata'->>'role'='admin')
with check ((select auth.jwt())->'app_metadata'->>'role'='admin');
create policy "Admins delete PYQs" on public.jee_pyq_questions for delete to authenticated
using ((select auth.jwt())->'app_metadata'->>'role'='admin');

drop policy if exists "Admins manage challenges" on public.daily_challenges;
create policy "Admins insert challenges" on public.daily_challenges for insert to authenticated
with check ((select auth.jwt())->'app_metadata'->>'role'='admin');
create policy "Admins update challenges" on public.daily_challenges for update to authenticated
using ((select auth.jwt())->'app_metadata'->>'role'='admin')
with check ((select auth.jwt())->'app_metadata'->>'role'='admin');
create policy "Admins delete challenges" on public.daily_challenges for delete to authenticated
using ((select auth.jwt())->'app_metadata'->>'role'='admin');

create index if not exists jee_pyq_answer_attempts_question_idx on private.jee_pyq_answer_attempts(question_id);
create index if not exists jee_pyq_created_by_idx on public.jee_pyq_questions(created_by);
create index if not exists jee_pyq_reviewed_by_idx on public.jee_pyq_questions(reviewed_by);
create index if not exists daily_challenges_created_by_idx on public.daily_challenges(created_by);
