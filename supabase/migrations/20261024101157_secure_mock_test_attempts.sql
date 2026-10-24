-- Add paper metadata and database-authoritative mock-test attempts/results.
alter table public.jee_pyq_questions
  add column if not exists session text,
  add column if not exists question_type text not null default 'single_correct',
  add column if not exists marks_correct integer not null default 4,
  add column if not exists marks_wrong integer not null default -1;

do $$
begin
  if not exists (select 1 from pg_constraint where conname='jee_pyq_question_type_check' and conrelid='public.jee_pyq_questions'::regclass) then
    alter table public.jee_pyq_questions add constraint jee_pyq_question_type_check check (question_type in ('single_correct','numerical'));
  end if;
  if not exists (select 1 from pg_constraint where conname='jee_pyq_marks_check' and conrelid='public.jee_pyq_questions'::regclass) then
    alter table public.jee_pyq_questions add constraint jee_pyq_marks_check check (marks_correct > 0 and marks_wrong <= 0);
  end if;
end;
$$;

create index if not exists jee_pyq_paper_lookup_idx
  on public.jee_pyq_questions (year, session, subject, question_type)
  where is_published = true and review_status = 'approved';

create table if not exists public.mock_test_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mode text not null check (mode in ('shift','focused')),
  exam_year integer,
  session text,
  subject text,
  chapter text,
  duration_seconds integer not null check (duration_seconds between 0 and 10800),
  question_ids uuid[] not null,
  total_questions integer not null check (total_questions between 1 and 75),
  status text not null default 'in_progress' check (status in ('in_progress','submitted')),
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  attempted_count integer,
  correct_count integer,
  wrong_count integer,
  score integer,
  max_score integer,
  created_at timestamptz not null default now(),
  check ((status = 'in_progress' and submitted_at is null) or (status = 'submitted' and submitted_at is not null))
);

create index if not exists mock_test_attempts_user_created_idx
  on public.mock_test_attempts (user_id, created_at desc);

create table if not exists private.mock_test_responses (
  attempt_id uuid not null references public.mock_test_attempts(id) on delete cascade,
  question_id uuid not null references public.jee_pyq_questions(id) on delete restrict,
  selected_answer text,
  is_correct boolean not null default false,
  marks_awarded integer not null default 0,
  answered_at timestamptz not null default now(),
  primary key (attempt_id, question_id)
);

alter table public.mock_test_attempts enable row level security;
alter table private.mock_test_responses enable row level security;
revoke all on public.mock_test_attempts from public, anon, authenticated;
grant select on public.mock_test_attempts to authenticated;
drop policy if exists "Users can read own mock test attempts" on public.mock_test_attempts;
create policy "Users can read own mock test attempts"
  on public.mock_test_attempts for select to authenticated
  using (user_id = (select auth.uid()));
revoke all on private.mock_test_responses from public, anon, authenticated;

create or replace function public.start_mock_test(
  p_mode text,
  p_year integer default null,
  p_session text default null,
  p_subject text default null,
  p_chapter text default null,
  p_question_count integer default 20,
  p_duration_seconds integer default 1800
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_question_ids uuid[];
  v_questions jsonb;
  v_attempt_id uuid;
  v_total integer;
  v_physics_mcq integer;
  v_physics_num integer;
  v_chemistry_mcq integer;
  v_chemistry_num integer;
  v_math_mcq integer;
  v_math_num integer;
begin
  if v_user is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  if p_mode not in ('shift','focused') then raise exception 'Invalid mock test mode' using errcode = '22023'; end if;
  if p_question_count < 1 or p_question_count > 75 or p_duration_seconds < 0 or p_duration_seconds > 10800 then
    raise exception 'Question count or time limit is outside supported bounds' using errcode = '22023';
  end if;
  if p_subject is not null and p_subject not in ('Physics','Chemistry','Mathematics') then
    raise exception 'Invalid subject filter' using errcode = '22023';
  end if;
  if p_mode = 'shift' and (p_year is null or nullif(btrim(p_session), '') is null) then
    raise exception 'Choose a year and shift for shift mode' using errcode = '22023';
  end if;

  if p_mode = 'shift' and p_question_count = 75 then
    select count(*),
      count(*) filter (where q.subject = 'Physics' and q.question_type = 'single_correct'),
      count(*) filter (where q.subject = 'Physics' and q.question_type = 'numerical'),
      count(*) filter (where q.subject = 'Chemistry' and q.question_type = 'single_correct'),
      count(*) filter (where q.subject = 'Chemistry' and q.question_type = 'numerical'),
      count(*) filter (where q.subject = 'Mathematics' and q.question_type = 'single_correct'),
      count(*) filter (where q.subject = 'Mathematics' and q.question_type = 'numerical')
    into v_total, v_physics_mcq, v_physics_num, v_chemistry_mcq, v_chemistry_num, v_math_mcq, v_math_num
    from public.jee_pyq_questions q
    join private.jee_pyq_answer_keys k on k.question_id = q.id
    where q.is_published and q.review_status = 'approved' and q.year = p_year and q.session = p_session;

    if v_total <> 75 or v_physics_mcq <> 20 or v_physics_num <> 5
      or v_chemistry_mcq <> 20 or v_chemistry_num <> 5
      or v_math_mcq <> 20 or v_math_num <> 5 then
      raise exception 'This shift is not a verified 75-question paper with 20 MCQs and 5 numerical questions per subject' using errcode = 'P0002';
    end if;

    select array_agg(s.id order by s.subject, case s.question_type when 'single_correct' then 1 else 2 end, s.created_at),
      jsonb_agg(jsonb_build_object(
        'id', s.id, 'source_id', s.source_id, 'title', s.title, 'exam', s.exam,
        'year', s.year, 'session', s.session, 'subject', s.subject, 'chapter', s.chapter,
        'statement', s.statement, 'statement_image_path', s.statement_image_path,
        'options', s.options, 'asset_paths', s.asset_paths, 'question_type', s.question_type,
        'marks_correct', s.marks_correct, 'marks_wrong', s.marks_wrong
      ) order by s.subject, case s.question_type when 'single_correct' then 1 else 2 end, s.created_at)
    into v_question_ids, v_questions
    from public.jee_pyq_questions s
    join private.jee_pyq_answer_keys k on k.question_id = s.id
    where s.is_published and s.review_status = 'approved' and s.year = p_year and s.session = p_session;
  else
    select array_agg(s.id), jsonb_agg(jsonb_build_object(
      'id', s.id, 'source_id', s.source_id, 'title', s.title, 'exam', s.exam,
      'year', s.year, 'session', s.session, 'subject', s.subject, 'chapter', s.chapter,
      'statement', s.statement, 'statement_image_path', s.statement_image_path,
      'options', s.options, 'asset_paths', s.asset_paths, 'question_type', s.question_type,
      'marks_correct', s.marks_correct, 'marks_wrong', s.marks_wrong
    ))
    into v_question_ids, v_questions
    from (
      select q.* from public.jee_pyq_questions q
      join private.jee_pyq_answer_keys k on k.question_id = q.id
      where q.is_published and q.review_status = 'approved'
        and (p_mode <> 'shift' or (q.year = p_year and q.session = p_session))
        and (p_subject is null or q.subject = p_subject)
        and (nullif(btrim(p_chapter), '') is null or q.chapter = p_chapter)
      order by random()
      limit p_question_count
    ) s;
  end if;

  if coalesce(cardinality(v_question_ids), 0) < p_question_count then
    raise exception 'Not enough reviewed questions with verified answer keys for this test' using errcode = 'P0002';
  end if;

  insert into public.mock_test_attempts (user_id, mode, exam_year, session, subject, chapter, duration_seconds, question_ids, total_questions)
  values (v_user, p_mode, p_year, p_session, p_subject, nullif(btrim(p_chapter), ''), p_duration_seconds, v_question_ids, cardinality(v_question_ids))
  returning id into v_attempt_id;

  return jsonb_build_object('attempt_id', v_attempt_id, 'started_at', now(), 'duration_seconds', p_duration_seconds,
    'total_questions', cardinality(v_question_ids), 'questions', coalesce(v_questions, '[]'::jsonb));
end;
$function$;

create or replace function public.get_mock_test_result(p_attempt_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_result jsonb;
begin
  if v_user is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  select jsonb_build_object(
    'attempt_id', a.id, 'status', a.status, 'started_at', a.started_at, 'submitted_at', a.submitted_at,
    'duration_seconds', a.duration_seconds, 'total_questions', a.total_questions, 'attempted_count', a.attempted_count,
    'correct_count', a.correct_count, 'wrong_count', a.wrong_count, 'score', a.score, 'max_score', a.max_score,
    'questions', coalesce(jsonb_agg(jsonb_build_object(
      'id', q.id, 'title', q.title, 'subject', q.subject, 'chapter', q.chapter, 'question_type', q.question_type,
      'statement', q.statement, 'statement_image_path', q.statement_image_path, 'options', q.options,
      'selected_answer', r.selected_answer, 'is_correct', r.is_correct, 'marks_awarded', r.marks_awarded,
      'correct_answer', k.correct_answer, 'solution', k.solution
    ) order by array_position(a.question_ids, q.id)) filter (where q.id is not null), '[]'::jsonb)
  ) into v_result
  from public.mock_test_attempts a
  left join unnest(a.question_ids) as assigned(question_id) on true
  left join public.jee_pyq_questions q on q.id = assigned.question_id
  left join private.mock_test_responses r on r.attempt_id = a.id and r.question_id = q.id
  left join private.jee_pyq_answer_keys k on k.question_id = q.id
  where a.id = p_attempt_id and a.user_id = v_user and a.status = 'submitted'
  group by a.id;
  if v_result is null then raise exception 'Submitted test not found for this user' using errcode = 'P0002'; end if;
  return v_result;
end;
$function$;

create or replace function public.submit_mock_test(p_attempt_id uuid, p_answers jsonb)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_attempt public.mock_test_attempts%rowtype;
begin
  if v_user is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'array' then raise exception 'Answers must be a JSON array' using errcode = '22023'; end if;

  select * into v_attempt from public.mock_test_attempts a
  where a.id = p_attempt_id and a.user_id = v_user for update;
  if not found then raise exception 'Mock test not found for this user' using errcode = 'P0002'; end if;
  if v_attempt.status = 'submitted' then return public.get_mock_test_result(p_attempt_id); end if;
  if v_attempt.duration_seconds > 0 and now() > v_attempt.started_at + make_interval(secs => v_attempt.duration_seconds) + interval '60 seconds' then
    raise exception 'Mock test time limit has passed' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_answers) as e(item)
    where nullif(e.item ->> 'question_id', '') is null
      or not ((e.item ->> 'question_id')::uuid = any(v_attempt.question_ids))
  ) then raise exception 'Answer contains a question outside this attempt' using errcode = '22023'; end if;
  if (select count(*) from jsonb_array_elements(p_answers)) <>
     (select count(distinct (item ->> 'question_id')) from jsonb_array_elements(p_answers) as a(item)) then
    raise exception 'Duplicate answer for a question' using errcode = '22023';
  end if;

  insert into private.mock_test_responses (attempt_id, question_id, selected_answer, is_correct, marks_awarded)
  select v_attempt.id, assigned.question_id, answers.answer,
    coalesce(upper(btrim(answers.answer)) = upper(btrim(k.correct_answer)), false),
    case when nullif(btrim(answers.answer), '') is null then 0
      when upper(btrim(answers.answer)) = upper(btrim(k.correct_answer)) then q.marks_correct
      else q.marks_wrong end
  from unnest(v_attempt.question_ids) as assigned(question_id)
  join public.jee_pyq_questions q on q.id = assigned.question_id
  join private.jee_pyq_answer_keys k on k.question_id = q.id
  left join lateral (
    select nullif(btrim(e.item ->> 'answer'), '') as answer
    from jsonb_array_elements(p_answers) as e(item)
    where (e.item ->> 'question_id')::uuid = assigned.question_id
    limit 1
  ) answers on true;

  update public.mock_test_attempts a
  set status = 'submitted', submitted_at = now(),
      attempted_count = (select count(*) from private.mock_test_responses r where r.attempt_id = a.id and r.selected_answer is not null),
      correct_count = (select count(*) from private.mock_test_responses r where r.attempt_id = a.id and r.is_correct),
      wrong_count = (select count(*) from private.mock_test_responses r where r.attempt_id = a.id and r.selected_answer is not null and not r.is_correct),
      score = (select coalesce(sum(r.marks_awarded), 0) from private.mock_test_responses r where r.attempt_id = a.id),
      max_score = (select coalesce(sum(q.marks_correct), 0) from unnest(a.question_ids) as assigned(question_id) join public.jee_pyq_questions q on q.id = assigned.question_id)
  where a.id = v_attempt.id;

  return public.get_mock_test_result(p_attempt_id);
end;
$function$;

revoke all on function public.start_mock_test(text,integer,text,text,text,integer,integer) from public, anon, authenticated;
revoke all on function public.submit_mock_test(uuid,jsonb) from public, anon, authenticated;
revoke all on function public.get_mock_test_result(uuid) from public, anon, authenticated;
grant execute on function public.start_mock_test(text,integer,text,text,text,integer,integer) to authenticated;
grant execute on function public.submit_mock_test(uuid,jsonb) to authenticated;
grant execute on function public.get_mock_test_result(uuid) to authenticated;
