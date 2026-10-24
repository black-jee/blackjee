-- Resume only the caller's own in-progress mock test; never return answer keys before submission.
create or replace function public.resume_mock_test(p_attempt_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_result jsonb;
begin
  if v_user is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'attempt_id', a.id, 'mode', a.mode, 'exam_year', a.exam_year, 'session', a.session,
    'subject', a.subject, 'chapter', a.chapter, 'started_at', a.started_at,
    'duration_seconds', a.duration_seconds, 'total_questions', a.total_questions,
    'questions', coalesce(jsonb_agg(jsonb_build_object(
      'id', q.id, 'source_id', q.source_id, 'title', q.title, 'exam', q.exam, 'year', q.year,
      'session', q.session, 'subject', q.subject, 'chapter', q.chapter, 'statement', q.statement,
      'statement_image_path', q.statement_image_path, 'options', q.options, 'asset_paths', q.asset_paths,
      'question_type', q.question_type, 'marks_correct', q.marks_correct, 'marks_wrong', q.marks_wrong
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

revoke all on function public.resume_mock_test(uuid) from public, anon, authenticated;
grant execute on function public.resume_mock_test(uuid) to authenticated;
