-- BLACK-JEE reconstructed RPC definitions — current live catalog snapshot.
-- Generated from read-only pg_get_functiondef output on 2026-10-24.
-- These are current definitions, NOT recovered historical migration bodies.
-- Apply only after 001_reconstructed_table_shapes.sql in a disposable database.
-- Review every function body and ACL before using in any deployment.
-- Live definition MD5 values are included to preserve the snapshot provenance.
BEGIN;

-- Live definition fingerprint: c60ab9ab4141edcb615f475919cbf620
CREATE OR REPLACE FUNCTION public.admin_review_jee_pyq_question(p_question_id uuid, p_approve boolean, p_publish boolean, p_review_notes text[] DEFAULT NULL::text[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := auth.uid();
  v_question public.jee_pyq_questions%rowtype;
  v_answer text;
  v_solution text;
begin
  if v_user is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  if p_publish and not p_approve then
    raise exception 'A question must be approved before publishing' using errcode = '22023';
  end if;

  select * into v_question
  from public.jee_pyq_questions q
  where q.id = p_question_id
  for update;
  if not found then
    raise exception 'Question not found' using errcode = 'P0002';
  end if;

  if p_publish then
    if nullif(btrim(v_question.source_pdf), '') is null or coalesce(v_question.source_page, 0) < 1 then
      raise exception 'Cannot publish without a source document and page number' using errcode = '22023';
    end if;
    if nullif(btrim(v_question.statement), '') is null then
      raise exception 'Cannot publish an empty question' using errcode = '22023';
    end if;

    select k.correct_answer, k.solution
      into v_answer, v_solution
    from private.jee_pyq_answer_keys k
    where k.question_id = p_question_id;

    if not found or nullif(btrim(v_answer), '') is null then
      raise exception 'Cannot publish without a private answer key' using errcode = '22023';
    end if;
    if nullif(btrim(v_solution), '') is null then
      raise exception 'Cannot publish without a worked solution' using errcode = '22023';
    end if;
    if v_question.question_type = 'single_correct' and not exists (
      select 1
      from jsonb_array_elements(v_question.options) as o(item)
      where upper(coalesce(o.item->>'label', o.item->>'letter', '')) = upper(btrim(v_answer))
    ) then
      raise exception 'Private answer key does not match any option label' using errcode = '22023';
    end if;
  end if;

  update public.jee_pyq_questions
  set review_status = case when p_approve then 'approved' else 'draft' end,
      is_published = p_publish,
      reviewed_by = case when p_approve then v_user else null end,
      reviewed_at = case when p_approve then now() else null end,
      source_status = case when p_publish then 'approved_for_publish' when p_approve then 'verified_draft' else source_status end,
      publication_block_reason = case when p_publish then null when p_approve then 'Approved as a draft; not published.' else 'Returned to draft for additional review.' end,
      review_notes = coalesce(p_review_notes, review_notes),
      updated_at = now()
  where id = p_question_id;

  return jsonb_build_object(
    'id', p_question_id,
    'review_status', case when p_approve then 'approved' else 'draft' end,
    'is_published', p_publish
  );
end;
$function$;

-- Original live definition fingerprint before reconstruction-only hardening: ebdff78aa677719515c9e500fc576562
CREATE OR REPLACE FUNCTION public.admin_save_daily_challenge(p_challenge_id uuid, p_challenge_date date, p_title text, p_subject text, p_statement text, p_statement_image_path text, p_options jsonb, p_starts_at timestamp with time zone, p_ends_at timestamp with time zone, p_solution_release_at timestamp with time zone, p_correct_answer text, p_solution text, p_is_live boolean)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := auth.uid();
  v_challenge_id uuid;
begin
  if v_user is null or coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') <> 'admin' then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  if nullif(btrim(p_title), '') is null
     or nullif(btrim(p_statement), '') is null
     or nullif(btrim(p_correct_answer), '') is null then
    raise exception 'Title, statement and correct answer are required' using errcode = '22023';
  end if;

  -- Reconstructed hardening: enforce publication completeness at the RPC boundary,
  -- not only in the web form, because administrators can call this RPC directly.
  if coalesce(p_is_live, false) and nullif(btrim(p_solution), '') is null then
    raise exception 'A live challenge must include a worked solution' using errcode = '22023';
  end if;

  if p_starts_at >= p_ends_at or p_ends_at > p_solution_release_at then
    raise exception 'Challenge schedule times are invalid' using errcode = '22023';
  end if;

  if p_options is null or jsonb_typeof(p_options) <> 'array' then
    raise exception 'Options must be a JSON array' using errcode = '22023';
  end if;
  if jsonb_array_length(p_options) > 12 then
    raise exception 'A daily challenge can have at most 12 options' using errcode = '22023';
  end if;
  if jsonb_array_length(p_options) > 0 and exists (
    select 1
    from jsonb_array_elements(p_options) as o(item)
    where nullif(btrim(o.item->>'label'), '') is null
  ) then
    raise exception 'Daily challenge options need non-empty labels' using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_options) as o(item)
    group by upper(btrim(o.item->>'label'))
    having count(*) > 1
  ) then
    raise exception 'Daily challenge option labels must be unique' using errcode = '22023';
  end if;
  if jsonb_array_length(p_options) > 0 and not exists (
    select 1
    from jsonb_array_elements(p_options) as o(item)
    where upper(btrim(o.item->>'label')) = upper(btrim(p_correct_answer))
  ) then
    raise exception 'Correct answer must match one of the option labels' using errcode = '22023';
  end if;

  if p_challenge_id is null then
    insert into public.daily_challenges (
      challenge_date, title, subject, statement, statement_image_path, options,
      starts_at, ends_at, solution_release_at, is_live, created_by
    ) values (
      p_challenge_date, btrim(p_title), p_subject, p_statement, p_statement_image_path, p_options,
      p_starts_at, p_ends_at, p_solution_release_at, coalesce(p_is_live, false), v_user
    )
    returning id into v_challenge_id;
  else
    update public.daily_challenges
    set challenge_date = p_challenge_date,
        title = btrim(p_title),
        subject = p_subject,
        statement = p_statement,
        statement_image_path = p_statement_image_path,
        options = p_options,
        starts_at = p_starts_at,
        ends_at = p_ends_at,
        solution_release_at = p_solution_release_at,
        is_live = coalesce(p_is_live, false)
    where id = p_challenge_id
    returning id into v_challenge_id;

    if v_challenge_id is null then
      raise exception 'Challenge not found' using errcode = 'P0002';
    end if;
  end if;

  insert into private.daily_challenge_answer_keys (challenge_id, correct_answer, solution)
  values (v_challenge_id, upper(btrim(p_correct_answer)), coalesce(p_solution, ''))
  on conflict (challenge_id) do update
    set correct_answer = excluded.correct_answer,
        solution = excluded.solution;

  return v_challenge_id;
end;
$function$;

-- Live definition fingerprint: 9de6669f0727df14fd0851895ee37466
CREATE OR REPLACE FUNCTION public.admin_save_jee_pyq_question(p_question_id uuid, p_source_id text, p_title text, p_exam text, p_year integer, p_session text, p_subject text, p_chapter text, p_statement text, p_statement_image_path text, p_options jsonb, p_question_type text, p_marks_correct integer, p_marks_wrong integer, p_correct_answer text, p_solution text, p_source_pdf text, p_source_page integer, p_tags text[], p_asset_paths text[], p_review_notes text[])
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := auth.uid();
  v_id uuid;
  v_source_id text;
  v_correct_answer text;
begin
  if v_user is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  if nullif(btrim(p_title),'') is null or length(p_title) > 240
     or nullif(btrim(p_statement),'') is null or length(p_statement) > 100000 then
    raise exception 'Question title and statement are required and must be within limits' using errcode = '22023';
  end if;
  if p_subject not in ('Physics','Chemistry','Mathematics') then
    raise exception 'Invalid subject' using errcode = '22023';
  end if;
  if p_question_type not in ('single_correct','numerical') then
    raise exception 'Invalid question type' using errcode = '22023';
  end if;
  if coalesce(p_marks_correct,0) <= 0 or coalesce(p_marks_wrong,1) > 0 then
    raise exception 'Marking values must use positive marks for correct and zero/negative marks for incorrect' using errcode = '22023';
  end if;
  if p_options is null or jsonb_typeof(p_options) <> 'array' or jsonb_array_length(p_options) > 12 then
    raise exception 'Options must be a JSON array with at most 12 items' using errcode = '22023';
  end if;
  if p_question_type = 'single_correct' and jsonb_array_length(p_options) < 2 then
    raise exception 'Single-correct questions need at least two options' using errcode = '22023';
  end if;
  if p_question_type = 'single_correct' and not exists (
    select 1 from jsonb_array_elements(p_options) as o(item)
    where upper(coalesce(o.item->>'label',o.item->>'letter','')) = upper(btrim(p_correct_answer))
  ) then
    raise exception 'Correct answer must match an option label' using errcode = '22023';
  end if;
  if p_statement_image_path is not null and (
    p_statement_image_path !~ '^[A-Za-z0-9._/-]+$'
    or p_statement_image_path ~ '^/'
    or p_statement_image_path ~ '//'
    or p_statement_image_path ~ '(^|/)\.\.(/|$)'
  ) then
    raise exception 'Unsafe statement image path' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_options) as o(item)
    where nullif(o.item->>'imagePath','') is not null
      and ((o.item->>'imagePath') !~ '^[A-Za-z0-9._/-]+$'
        or (o.item->>'imagePath') ~ '^/'
        or (o.item->>'imagePath') ~ '//'
        or (o.item->>'imagePath') ~ '(^|/)\.\.(/|$)')
  ) then
    raise exception 'Unsafe option image path' using errcode = '22023';
  end if;
  if exists (
    select 1 from unnest(coalesce(p_asset_paths,array[]::text[])) as asset(path)
    where asset.path !~ '^[A-Za-z0-9._/-]+$'
      or asset.path ~ '^/'
      or asset.path ~ '//'
      or asset.path ~ '(^|/)\.\.(/|$)'
  ) then
    raise exception 'Unsafe asset path' using errcode = '22023';
  end if;

  v_source_id := coalesce(nullif(btrim(p_source_id),''),'BJ-ADMIN-' || gen_random_uuid()::text);
  if length(v_source_id) > 160 then
    raise exception 'Source identifier is too long' using errcode = '22023';
  end if;
  v_correct_answer := case when p_question_type = 'single_correct' then upper(btrim(p_correct_answer)) else btrim(p_correct_answer) end;

  if p_question_id is null then
    insert into public.jee_pyq_questions (
      source_id,title,exam,year,session,subject,chapter,difficulty,statement,statement_image_path,
      options,question_type,marks_correct,marks_wrong,source_pdf,source_page,tags,asset_paths,
      review_notes,source_status,publication_block_reason,review_status,is_published,created_by
    ) values (
      v_source_id,btrim(p_title),coalesce(nullif(btrim(p_exam),''),'JEE Main'),p_year,nullif(btrim(p_session),''),
      p_subject,nullif(btrim(p_chapter),''),'Main',btrim(p_statement),nullif(btrim(p_statement_image_path),''),
      p_options,p_question_type,p_marks_correct,p_marks_wrong,nullif(btrim(p_source_pdf),''),p_source_page,
      coalesce(p_tags,array[]::text[]),coalesce(p_asset_paths,array[]::text[]),
      coalesce(p_review_notes,array[]::text[]),'not_verified',
      'Draft only: source, answer key, solution, and image references require review.',
      'draft',false,v_user
    ) returning id into v_id;
  else
    update public.jee_pyq_questions
    set source_id=v_source_id,title=btrim(p_title),exam=coalesce(nullif(btrim(p_exam),''),'JEE Main'),
        year=p_year,session=nullif(btrim(p_session),''),subject=p_subject,chapter=nullif(btrim(p_chapter),''),
        statement=btrim(p_statement),statement_image_path=nullif(btrim(p_statement_image_path),''),
        options=p_options,question_type=p_question_type,marks_correct=p_marks_correct,marks_wrong=p_marks_wrong,
        source_pdf=nullif(btrim(p_source_pdf),''),source_page=p_source_page,
        tags=coalesce(p_tags,array[]::text[]),asset_paths=coalesce(p_asset_paths,array[]::text[]),
        review_notes=coalesce(p_review_notes,review_notes),source_status='not_verified',
        publication_block_reason='Edited question returned to draft; source and answer must be reviewed again.',
        review_status='draft',is_published=false,reviewed_by=null,reviewed_at=null,updated_at=now()
    where id=p_question_id
    returning id into v_id;
    if v_id is null then
      raise exception 'Question not found' using errcode = 'P0002';
    end if;
  end if;

  insert into private.jee_pyq_answer_keys(question_id,correct_answer,solution)
  values (v_id,v_correct_answer,nullif(p_solution,''))
  on conflict (question_id) do update
    set correct_answer=excluded.correct_answer,solution=excluded.solution,updated_at=now();

  return v_id;
end;
$function$;

-- Live definition fingerprint: ff76bf83a39b595544fe15f3475cd70b
CREATE OR REPLACE FUNCTION public.get_current_daily_challenge()
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'id', c.id,
    'challenge_date', c.challenge_date,
    'title', c.title,
    'subject', c.subject,
    'starts_at', c.starts_at,
    'ends_at', c.ends_at,
    'solution_release_at', c.solution_release_at
  )
  from public.daily_challenges c
  where c.is_live
    and now() >= c.starts_at
    and now() < c.ends_at
  order by c.starts_at desc
  limit 1;
$function$;

-- Live definition fingerprint: ccb0c62728a64f6382ffdf9a8f2f63d8
CREATE OR REPLACE FUNCTION public.get_daily_challenge_result(p_challenge_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := auth.uid();
  v_challenge public.daily_challenges%rowtype;
  v_key text;
  v_solution text;
begin
  if v_user is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select * into v_challenge
  from public.daily_challenges c
  where c.id = p_challenge_id and c.is_live;
  if not found then
    raise exception 'Challenge not found' using errcode = 'P0002';
  end if;

  if now() < v_challenge.solution_release_at then
    return jsonb_build_object(
      'solution_released', false,
      'solution_release_at', v_challenge.solution_release_at,
      'message', 'The worked solution is not released yet.'
    );
  end if;

  select k.correct_answer, k.solution
  into v_key, v_solution
  from private.daily_challenge_answer_keys k
  where k.challenge_id = p_challenge_id;
  if not found then
    raise exception 'Challenge answer key is not configured';
  end if;

  return jsonb_build_object(
    'solution_released', true,
    'correct_answer', v_key,
    'solution', coalesce(v_solution, '')
  );
end;
$function$;

-- Live definition fingerprint: 3be309fd8edd50c20e814a5a99fb5f51
CREATE OR REPLACE FUNCTION public.get_mock_test_result(p_attempt_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := auth.uid();
  v_result jsonb;
begin
  if v_user is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'attempt_id', a.id,
    'status', a.status,
    'started_at', a.started_at,
    'submitted_at', a.submitted_at,
    'duration_seconds', a.duration_seconds,
    'total_questions', a.total_questions,
    'attempted_count', a.attempted_count,
    'correct_count', a.correct_count,
    'wrong_count', a.wrong_count,
    'score', a.score,
    'max_score', a.max_score,
    'questions', coalesce(jsonb_agg(jsonb_build_object(
      'id', q.id,
      'title', q.title,
      'subject', q.subject,
      'chapter', q.chapter,
      'question_type', q.question_type,
      'statement', q.statement,
      'statement_image_path', q.statement_image_path,
      'options', q.options,
      'selected_answer', r.selected_answer,
      'is_correct', r.is_correct,
      'marks_awarded', r.marks_awarded,
      'correct_answer', k.correct_answer,
      'solution', k.solution
    ) order by array_position(a.question_ids, q.id)) filter (where q.id is not null), '[]'::jsonb)
  ) into v_result
  from public.mock_test_attempts a
  left join unnest(a.question_ids) as assigned(question_id) on true
  left join public.jee_pyq_questions q on q.id = assigned.question_id
  left join private.mock_test_responses r on r.attempt_id = a.id and r.question_id = q.id
  left join private.jee_pyq_answer_keys k on k.question_id = q.id
  where a.id = p_attempt_id and a.user_id = v_user and a.status = 'submitted'
  group by a.id;

  if v_result is null then
    raise exception 'Submitted test not found for this user' using errcode = 'P0002';
  end if;
  return v_result;
end;
$function$;

-- Live definition fingerprint: ffa56082434a79de6d37607fb225b145
CREATE OR REPLACE FUNCTION public.grade_jee_pyq(p_question_id uuid, p_answer text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_key text; v_solution text; v_wrong integer:=0; v_unlocked_at timestamptz; v_correct boolean;
begin
 if v_user is null then raise exception 'Sign in required' using errcode='42501'; end if;
 if not exists(select 1 from public.jee_pyq_questions q where q.id=p_question_id and q.is_published and q.review_status='approved') then raise exception 'Question is not available for grading' using errcode='P0002'; end if;
 select k.correct_answer,k.solution into v_key,v_solution from private.jee_pyq_answer_keys k where k.question_id=p_question_id;
 if not found then raise exception 'Answer key is not available' using errcode='P0002'; end if;
 v_correct:=upper(trim(coalesce(p_answer,'')))=upper(trim(v_key));
 insert into private.jee_pyq_answer_attempts as existing(user_id,question_id,wrong_attempts,first_attempt_at,last_attempt_at)
 values(v_user,p_question_id,case when v_correct then 0 else 1 end,now(),now())
 on conflict(user_id,question_id) do update set
 wrong_attempts=case when existing.solution_unlocked_at is not null or v_correct then existing.wrong_attempts else least(existing.wrong_attempts+1,2) end,
 last_attempt_at=now(),
 solution_unlocked_at=coalesce(existing.solution_unlocked_at,case when not v_correct and existing.wrong_attempts+1>=2 then now() else null end)
 returning wrong_attempts,solution_unlocked_at into v_wrong,v_unlocked_at;
 return jsonb_build_object('is_correct',v_correct,'solution_unlocked',v_unlocked_at is not null,'wrong_attempts',v_wrong,'attempts_until_solution',greatest(0,2-v_wrong),
 'correct_answer',case when v_unlocked_at is not null then v_key else null end,'solution',case when v_unlocked_at is not null then coalesce(v_solution,'') else null end,
 'message',case when v_correct then 'Correct answer.' when v_unlocked_at is not null then 'Incorrect. The worked solution is now unlocked.' else 'Incorrect answer. The worked solution unlocks after two incorrect attempts.' end);
end;
$function$;

-- Live definition fingerprint: c14e3486e41e53f9aee6207093b380df
CREATE OR REPLACE FUNCTION public.resume_mock_test(p_attempt_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := auth.uid();
  v_result jsonb;
begin
  if v_user is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'attempt_id', a.id,
    'mode', a.mode,
    'exam_year', a.exam_year,
    'session', a.session,
    'subject', a.subject,
    'chapter', a.chapter,
    'started_at', a.started_at,
    'duration_seconds', a.duration_seconds,
    'total_questions', a.total_questions,
    'questions', coalesce(jsonb_agg(jsonb_build_object(
      'id', q.id,
      'source_id', q.source_id,
      'title', q.title,
      'exam', q.exam,
      'year', q.year,
      'session', q.session,
      'subject', q.subject,
      'chapter', q.chapter,
      'statement', q.statement,
      'statement_image_path', q.statement_image_path,
      'options', q.options,
      'asset_paths', q.asset_paths,
      'question_type', q.question_type,
      'marks_correct', q.marks_correct,
      'marks_wrong', q.marks_wrong
    ) order by array_position(a.question_ids, q.id)) filter (where q.id is not null), '[]'::jsonb)
  ) into v_result
  from public.mock_test_attempts a
  left join unnest(a.question_ids) as assigned(question_id) on true
  left join public.jee_pyq_questions q on q.id = assigned.question_id
  where a.id = p_attempt_id and a.user_id = v_user and a.status = 'in_progress'
  group by a.id;

  if v_result is null then
    raise exception 'Active mock test not found for this user' using errcode = 'P0002';
  end if;
  return v_result;
end;
$function$;

-- Live definition fingerprint: 6184a711c54ac02ef621064bb99fa8b4
CREATE OR REPLACE FUNCTION public.start_daily_challenge(p_challenge_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := auth.uid();
  v_challenge public.daily_challenges%rowtype;
  v_started timestamptz;
begin
  if v_user is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select * into v_challenge
  from public.daily_challenges c
  where c.id = p_challenge_id
    and c.is_live
    and now() >= c.starts_at
    and now() < c.ends_at;

  if not found then
    raise exception 'Challenge is not currently open' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.daily_challenge_attempts a
    where a.challenge_id = p_challenge_id and a.user_id = v_user
  ) then
    raise exception 'You have already submitted an attempt for this challenge' using errcode = '23505';
  end if;

  insert into private.daily_challenge_sessions(challenge_id, user_id)
  values (p_challenge_id, v_user)
  on conflict (challenge_id, user_id) do nothing;

  select s.started_at into v_started
  from private.daily_challenge_sessions s
  where s.challenge_id = p_challenge_id
    and s.user_id = v_user
    and s.submitted_at is null;

  if v_started is null then
    raise exception 'This challenge attempt is already submitted' using errcode = '23505';
  end if;

  return jsonb_build_object(
    'id', v_challenge.id,
    'challenge_date', v_challenge.challenge_date,
    'title', v_challenge.title,
    'subject', v_challenge.subject,
    'statement', v_challenge.statement,
    'statement_image_path', v_challenge.statement_image_path,
    'options', v_challenge.options,
    'starts_at', v_challenge.starts_at,
    'ends_at', v_challenge.ends_at,
    'solution_release_at', v_challenge.solution_release_at,
    'started_at', v_started
  );
end;
$function$;

-- Live definition fingerprint: 721ed05ba1d51a63a1af126da78f669f
CREATE OR REPLACE FUNCTION public.start_mock_test(p_mode text, p_year integer DEFAULT NULL::integer, p_session text DEFAULT NULL::text, p_subject text DEFAULT NULL::text, p_chapter text DEFAULT NULL::text, p_question_count integer DEFAULT 20, p_duration_seconds integer DEFAULT 1800)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
    select array_agg(s.id order by s.selection_order),
      jsonb_agg(jsonb_build_object(
        'id', s.id, 'source_id', s.source_id, 'title', s.title, 'exam', s.exam,
        'year', s.year, 'session', s.session, 'subject', s.subject, 'chapter', s.chapter,
        'statement', s.statement, 'statement_image_path', s.statement_image_path,
        'options', s.options, 'asset_paths', s.asset_paths, 'question_type', s.question_type,
        'marks_correct', s.marks_correct, 'marks_wrong', s.marks_wrong
      ) order by s.selection_order)
    into v_question_ids, v_questions
    from (
      select q.*, row_number() over (order by random()) as selection_order
      from public.jee_pyq_questions q
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

-- Live definition fingerprint: 9976c9390ebb5140757cc27e6afb02ec
CREATE OR REPLACE FUNCTION public.submit_daily_challenge(p_challenge_id uuid, p_answer text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_key text; v_correct boolean; v_challenge public.daily_challenges%rowtype; v_started timestamptz; v_elapsed integer;
begin
 if v_user is null then raise exception 'Sign in required' using errcode='42501'; end if;
 select * into v_challenge from public.daily_challenges c where c.id=p_challenge_id and c.is_live and now()>=c.starts_at and now()<c.ends_at;
 if not found then raise exception 'Challenge is not currently open' using errcode='P0002'; end if;
 select s.started_at into v_started from private.daily_challenge_sessions s where s.challenge_id=p_challenge_id and s.user_id=v_user and s.submitted_at is null for update;
 if not found then raise exception 'Start the challenge before submitting' using errcode='42501'; end if;
 select k.correct_answer into v_key from private.daily_challenge_answer_keys k where k.challenge_id=p_challenge_id;
 if not found then raise exception 'Challenge answer key is not configured'; end if;
 v_correct:=upper(trim(coalesce(p_answer,'')))=upper(trim(v_key));
 v_elapsed:=greatest(0,least(86400,floor(extract(epoch from (now()-v_started)))::integer));
 insert into public.daily_challenge_attempts(challenge_id,user_id,selected_answer,is_correct,elapsed_seconds) values(p_challenge_id,v_user,upper(trim(p_answer)),v_correct,v_elapsed);
 update private.daily_challenge_sessions set submitted_at=now() where challenge_id=p_challenge_id and user_id=v_user;
 return jsonb_build_object('submitted',true,'is_correct',v_correct,'elapsed_seconds',v_elapsed,'solution_released',now()>=v_challenge.solution_release_at,
   'message',case when v_correct then 'Answer submitted. Good work.' else 'Answer submitted. Review the solution when it is released.' end);
exception when unique_violation then raise exception 'You have already submitted an attempt for this challenge' using errcode='23505';
end;
$function$;

-- Live definition fingerprint: 33b381c7bb94b3b772ca5f90db196c5d
CREATE OR REPLACE FUNCTION public.submit_mock_test(p_attempt_id uuid, p_answers jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := auth.uid();
  v_attempt public.mock_test_attempts%rowtype;
begin
  if v_user is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'array' then
    raise exception 'Answers must be a JSON array' using errcode = '22023';
  end if;

  select * into v_attempt
  from public.mock_test_attempts a
  where a.id = p_attempt_id and a.user_id = v_user
  for update;

  if not found then
    raise exception 'Mock test not found for this user' using errcode = 'P0002';
  end if;
  if v_attempt.status = 'submitted' then
    return public.get_mock_test_result(p_attempt_id);
  end if;
  if v_attempt.duration_seconds > 0 and now() > v_attempt.started_at + make_interval(secs => v_attempt.duration_seconds) + interval '60 seconds' then
    raise exception 'Mock test time limit has passed' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_answers) as e(item)
    where nullif(e.item ->> 'question_id', '') is null
       or not ((e.item ->> 'question_id')::uuid = any(v_attempt.question_ids))
  ) then
    raise exception 'Answer contains a question outside this attempt' using errcode = '22023';
  end if;
  if (select count(*) from jsonb_array_elements(p_answers)) <>
     (select count(distinct (item ->> 'question_id')) from jsonb_array_elements(p_answers) as a(item)) then
    raise exception 'Duplicate answer for a question' using errcode = '22023';
  end if;

  insert into private.mock_test_responses (attempt_id, question_id, selected_answer, is_correct, marks_awarded)
  select
    v_attempt.id,
    assigned.question_id,
    answers.answer,
    coalesce(upper(btrim(answers.answer)) = upper(btrim(k.correct_answer)), false),
    case
      when nullif(btrim(answers.answer), '') is null then 0
      when upper(btrim(answers.answer)) = upper(btrim(k.correct_answer)) then q.marks_correct
      else q.marks_wrong
    end
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
  set status = 'submitted',
      submitted_at = now(),
      attempted_count = (select count(*) from private.mock_test_responses r where r.attempt_id = a.id and r.selected_answer is not null),
      correct_count = (select count(*) from private.mock_test_responses r where r.attempt_id = a.id and r.is_correct),
      wrong_count = (select count(*) from private.mock_test_responses r where r.attempt_id = a.id and r.selected_answer is not null and not r.is_correct),
      score = (select coalesce(sum(r.marks_awarded), 0) from private.mock_test_responses r where r.attempt_id = a.id),
      max_score = (select coalesce(sum(q.marks_correct), 0) from unnest(a.question_ids) as assigned(question_id) join public.jee_pyq_questions q on q.id = assigned.question_id)
  where a.id = v_attempt.id;

  return public.get_mock_test_result(p_attempt_id);
end;
$function$;

-- Privileged RPCs require authenticated invocation and enforce identity/role
-- checks inside their function bodies. Never grant these to anon or PUBLIC.
REVOKE ALL ON FUNCTION public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[]) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamp with time zone,timestamp with time zone,timestamp with time zone,text,text,boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamp with time zone,timestamp with time zone,timestamp with time zone,text,text,boolean) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.admin_save_jee_pyq_question(uuid,text,text,text,integer,text,text,text,text,text,jsonb,text,integer,integer,text,text,text,integer,text[],text[],text[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_save_jee_pyq_question(uuid,text,text,text,integer,text,text,text,text,text,jsonb,text,integer,integer,text,text,text,integer,text[],text[],text[]) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.get_current_daily_challenge() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_current_daily_challenge() TO anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.get_daily_challenge_result(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_daily_challenge_result(uuid) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.get_mock_test_result(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_mock_test_result(uuid) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.grade_jee_pyq(uuid,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.grade_jee_pyq(uuid,text) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.resume_mock_test(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resume_mock_test(uuid) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.start_daily_challenge(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.start_daily_challenge(uuid) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.start_mock_test(text,integer,text,text,text,integer,integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.start_mock_test(text,integer,text,text,text,integer,integer) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.submit_daily_challenge(uuid,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_daily_challenge(uuid,text) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.submit_mock_test(uuid,jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_mock_test(uuid,jsonb) TO authenticated, service_role;

COMMIT;
