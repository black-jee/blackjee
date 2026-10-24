-- Reject NULL required inputs explicitly; SQL NULL comparisons do not evaluate TRUE.
-- Forward-only hardening: do not rewrite historical migration files.
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
  if p_mode is null or p_mode not in ('shift','focused') then raise exception 'Invalid mock test mode' using errcode = '22023'; end if;
  if p_question_count is null or p_duration_seconds is null
     or p_question_count < 1 or p_question_count > 75
     or p_duration_seconds < 0 or p_duration_seconds > 10800 then
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
