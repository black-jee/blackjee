-- BLACK JEE foundation schema. Apply only to the new project phdssyexhfyxsmhmmcgb.
create extension if not exists pgcrypto;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists public.jee_pyq_questions (
  id uuid primary key default gen_random_uuid(),
  source_id text unique,
  title text not null,
  exam text not null default 'JEE Main',
  year integer check (year between 2002 and 2100),
  subject text not null check (subject in ('Physics','Chemistry','Mathematics')),
  chapter text,
  difficulty text not null default 'Main' check (difficulty in ('Main','Advanced','Mixed')),
  statement text not null,
  options jsonb not null default '[]'::jsonb check (jsonb_typeof(options) = 'array'),
  tags text[] not null default '{}',
  asset_paths text[] not null default '{}',
  review_status text not null default 'draft' check (review_status in ('draft','in_review','approved','rejected')),
  is_published boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint published_questions_must_be_approved check (not is_published or review_status = 'approved')
);
create index if not exists jee_pyq_subject_year_idx on public.jee_pyq_questions(subject, year desc) where is_published;
create index if not exists jee_pyq_review_queue_idx on public.jee_pyq_questions(review_status, created_at desc);

create table if not exists private.jee_pyq_answer_keys (
  question_id uuid primary key references public.jee_pyq_questions(id) on delete cascade,
  correct_answer text not null check (length(trim(correct_answer)) > 0),
  solution text,
  updated_at timestamptz not null default now()
);
create table if not exists private.jee_pyq_answer_attempts (
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.jee_pyq_questions(id) on delete cascade,
  wrong_attempts integer not null default 0 check (wrong_attempts between 0 and 2),
  first_attempt_at timestamptz not null default now(),
  last_attempt_at timestamptz not null default now(),
  solution_unlocked_at timestamptz,
  primary key (user_id, question_id)
);

create table if not exists public.daily_challenges (
  id uuid primary key default gen_random_uuid(),
  challenge_date date not null unique,
  title text not null,
  subject text not null check (subject in ('Physics','Chemistry','Mathematics','Mixed')),
  statement text not null,
  options jsonb not null default '[]'::jsonb check (jsonb_typeof(options) = 'array'),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  solution_release_at timestamptz not null,
  is_live boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  check (starts_at < ends_at and ends_at <= solution_release_at)
);
create index if not exists daily_challenges_live_idx on public.daily_challenges(is_live, starts_at, ends_at);
create table if not exists private.daily_challenge_answer_keys (
  challenge_id uuid primary key references public.daily_challenges(id) on delete cascade,
  correct_answer text not null check (length(trim(correct_answer)) > 0),
  solution text
);
create table if not exists public.daily_challenge_attempts (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.daily_challenges(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  selected_answer text not null,
  is_correct boolean not null,
  elapsed_seconds integer not null check (elapsed_seconds between 0 and 86400),
  submitted_at timestamptz not null default now(),
  unique (challenge_id, user_id)
);
create index if not exists daily_attempt_user_idx on public.daily_challenge_attempts(user_id, submitted_at desc);

alter table public.jee_pyq_questions enable row level security;
alter table private.jee_pyq_answer_keys enable row level security;
alter table private.jee_pyq_answer_attempts enable row level security;
alter table public.daily_challenges enable row level security;
alter table private.daily_challenge_answer_keys enable row level security;
alter table public.daily_challenge_attempts enable row level security;

revoke all on public.jee_pyq_questions from public, anon, authenticated;
grant select (id, source_id, title, exam, year, subject, chapter, difficulty, statement, options, tags, asset_paths, review_status, is_published, created_at, updated_at) on public.jee_pyq_questions to anon, authenticated;
grant insert, update, delete on public.jee_pyq_questions to authenticated;
revoke all on all tables in schema private from public, anon, authenticated;
revoke all on public.daily_challenges from public, anon, authenticated;
grant select (id, challenge_date, title, subject, starts_at, ends_at, is_live) on public.daily_challenges to anon, authenticated;
grant insert, update, delete on public.daily_challenges to authenticated;
revoke all on public.daily_challenge_attempts from public, anon, authenticated;
grant select on public.daily_challenge_attempts to authenticated;
-- Attempts are inserted only by submit_daily_challenge(), which grades server-side.
revoke insert on public.daily_challenge_attempts from anon, authenticated;

create policy "Published and approved PYQs are readable" on public.jee_pyq_questions
  for select to anon, authenticated using (is_published and review_status = 'approved');
create policy "Admins manage PYQs" on public.jee_pyq_questions
  for all to authenticated
  using ((select auth.jwt())->'app_metadata'->>'role' = 'admin')
  with check ((select auth.jwt())->'app_metadata'->>'role' = 'admin');
create policy "Live challenge schedule is readable" on public.daily_challenges
  for select to anon, authenticated using (is_live = true or (select auth.jwt())->'app_metadata'->>'role' = 'admin');
create policy "Admins manage challenges" on public.daily_challenges
  for all to authenticated
  using ((select auth.jwt())->'app_metadata'->>'role' = 'admin')
  with check ((select auth.jwt())->'app_metadata'->>'role' = 'admin');
create policy "Users read their own challenge attempts" on public.daily_challenge_attempts
  for select to authenticated using (user_id = (select auth.uid()) or (select auth.jwt())->'app_metadata'->>'role' = 'admin');
create policy "Users insert own challenge attempt" on public.daily_challenge_attempts
  for insert to authenticated with check (user_id = (select auth.uid()));

create or replace function public.grade_jee_pyq(p_question_id uuid, p_answer text)
returns jsonb language plpgsql security definer set search_path = '' as $function$
declare
  v_user uuid := auth.uid(); v_key text; v_solution text; v_wrong integer := 0; v_unlocked_at timestamptz; v_correct boolean;
begin
  if v_user is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  if not exists (select 1 from public.jee_pyq_questions q where q.id = p_question_id and q.is_published and q.review_status = 'approved') then
    raise exception 'Question is not available for grading' using errcode = 'P0002';
  end if;
  select k.correct_answer, k.solution into v_key, v_solution from private.jee_pyq_answer_keys k where k.question_id = p_question_id;
  if not found then raise exception 'Answer key is not available' using errcode = 'P0002'; end if;
  v_correct := upper(trim(coalesce(p_answer,''))) = upper(trim(v_key));
  insert into private.jee_pyq_answer_attempts as existing (user_id, question_id, wrong_attempts, first_attempt_at, last_attempt_at)
  values (v_user, p_question_id, case when v_correct then 0 else 1 end, now(), now())
  on conflict (user_id, question_id) do update set
    wrong_attempts = case when existing.solution_unlocked_at is not null or v_correct then existing.wrong_attempts else least(existing.wrong_attempts + 1, 2) end,
    last_attempt_at = now(),
    solution_unlocked_at = coalesce(existing.solution_unlocked_at, case when not v_correct and existing.wrong_attempts + 1 >= 2 then now() else null end)
  returning wrong_attempts, solution_unlocked_at into v_wrong, v_unlocked_at;
  return jsonb_build_object(
    'is_correct', v_correct,
    'solution_unlocked', v_unlocked_at is not null,
    'wrong_attempts', v_wrong,
    'attempts_until_solution', greatest(0, 2-v_wrong),
    'correct_answer', case when v_unlocked_at is not null then v_key else null end,
    'solution', case when v_unlocked_at is not null then coalesce(v_solution,'') else null end,
    'message', case when v_correct then 'Correct answer.' when v_unlocked_at is not null then 'Incorrect. The worked solution is now unlocked.' else 'Incorrect answer. The worked solution unlocks after two incorrect attempts.' end
  );
end;
$function$;
revoke all on function public.grade_jee_pyq(uuid,text) from public, anon;
grant execute on function public.grade_jee_pyq(uuid,text) to authenticated;

create or replace function public.get_current_daily_challenge()
returns jsonb language sql stable security definer set search_path = '' as $function$
  select jsonb_build_object('id', c.id, 'challenge_date', c.challenge_date, 'title', c.title, 'subject', c.subject,
    'statement', c.statement, 'options', c.options, 'starts_at', c.starts_at, 'ends_at', c.ends_at,
    'solution_release_at', c.solution_release_at)
  from public.daily_challenges c
  where c.is_live and now() >= c.starts_at and now() < c.ends_at
  order by c.starts_at desc limit 1;
$function$;
revoke all on function public.get_current_daily_challenge() from public;
grant execute on function public.get_current_daily_challenge() to anon, authenticated;

create or replace function public.submit_daily_challenge(p_challenge_id uuid, p_answer text, p_elapsed_seconds integer)
returns jsonb language plpgsql security definer set search_path = '' as $function$
declare v_user uuid := auth.uid(); v_key text; v_correct boolean; v_challenge public.daily_challenges%rowtype;
begin
  if v_user is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  if p_elapsed_seconds < 0 or p_elapsed_seconds > 86400 then raise exception 'Invalid elapsed time'; end if;
  select * into v_challenge from public.daily_challenges c where c.id = p_challenge_id and c.is_live and now() >= c.starts_at and now() < c.ends_at;
  if not found then raise exception 'Challenge is not currently open' using errcode = 'P0002'; end if;
  select k.correct_answer into v_key from private.daily_challenge_answer_keys k where k.challenge_id = p_challenge_id;
  if not found then raise exception 'Challenge answer key is not configured'; end if;
  v_correct := upper(trim(coalesce(p_answer,''))) = upper(trim(v_key));
  insert into public.daily_challenge_attempts(challenge_id,user_id,selected_answer,is_correct,elapsed_seconds)
  values (p_challenge_id,v_user,upper(trim(p_answer)),v_correct,p_elapsed_seconds);
  return jsonb_build_object('submitted',true,'is_correct',v_correct,'solution_released',now() >= v_challenge.solution_release_at,
    'message',case when v_correct then 'Answer submitted. Good work.' else 'Answer submitted. Review the solution when it is released.' end);
exception when unique_violation then raise exception 'You have already submitted an attempt for this challenge' using errcode = '23505';
end;
$function$;
revoke all on function public.submit_daily_challenge(uuid,text,integer) from public, anon;
grant execute on function public.submit_daily_challenge(uuid,text,integer) to authenticated;

-- Intentional: answer keys live in the non-exposed private schema and never have client grants.
