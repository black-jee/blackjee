-- Reconstruct the applied PYQ authoring/review migration in version control.
-- This migration is idempotent so a fresh project can replay it safely.
alter table public.jee_pyq_questions
  add column if not exists reviewed_by uuid references auth.users(id) on delete set null,
  add column if not exists reviewed_at timestamptz;

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
begin
  if v_user is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  if p_publish and not p_approve then
    raise exception 'A question must be approved before publishing' using errcode = '22023';
  end if;

  select * into v_question
  from public.jee_pyq_questions q
  where q.id=p_question_id
  for update;
  if not found then raise exception 'Question not found' using errcode = 'P0002'; end if;

  if p_publish then
    select k.correct_answer into v_answer
    from private.jee_pyq_answer_keys k
    where k.question_id=p_question_id;
    if not found or nullif(btrim(v_answer),'') is null then
      raise exception 'Cannot publish without a private answer key' using errcode = '22023';
    end if;
    if v_question.question_type='single_correct' and not exists (
      select 1 from jsonb_array_elements(v_question.options) as o(item)
      where upper(coalesce(o.item->>'label',o.item->>'letter',''))=upper(btrim(v_answer))
    ) then
      raise exception 'Private answer key does not match any option label' using errcode = '22023';
    end if;
    if nullif(btrim(v_question.statement),'') is null then
      raise exception 'Cannot publish an empty question' using errcode = '22023';
    end if;
  end if;

  update public.jee_pyq_questions
  set review_status=case when p_approve then 'approved' else 'draft' end,
      is_published=p_publish,
      reviewed_by=case when p_approve then v_user else null end,
      reviewed_at=case when p_approve then now() else null end,
      source_status=case when p_publish then 'approved_for_publish' when p_approve then 'verified_draft' else source_status end,
      publication_block_reason=case when p_publish then null when p_approve then 'Approved as a draft; not published.' else 'Returned to draft for additional review.' end,
      review_notes=coalesce(p_review_notes,review_notes),
      updated_at=now()
  where id=p_question_id;

  return jsonb_build_object('id',p_question_id,'review_status',case when p_approve then 'approved' else 'draft' end,'is_published',p_publish);
end;
$function$
;

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
$function$
;

revoke all on function public.admin_save_jee_pyq_question(uuid,text,text,text,integer,text,text,text,text,text,jsonb,text,integer,integer,text,text,text,integer,text[],text[],text[]) from public, anon, authenticated;
grant execute on function public.admin_save_jee_pyq_question(uuid,text,text,text,integer,text,text,text,text,text,jsonb,text,integer,integer,text,text,text,integer,text[],text[],text[]) to authenticated;
revoke all on function public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[]) from public, anon, authenticated;
grant execute on function public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[]) to authenticated;
