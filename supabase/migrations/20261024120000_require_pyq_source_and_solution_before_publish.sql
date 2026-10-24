-- Require source provenance and a worked solution before publishing a JEE PYQ.
-- The private answer key is checked only inside this administrator-only RPC.
CREATE OR REPLACE FUNCTION public.admin_review_jee_pyq_question(
  p_question_id uuid,
  p_approve boolean,
  p_publish boolean,
  p_review_notes text[] DEFAULT NULL::text[]
)
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
    if nullif(btrim(v_question.source_pdf), '') is null then
      raise exception 'Cannot publish without a source reference' using errcode = '22023';
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

REVOKE ALL ON FUNCTION public.admin_review_jee_pyq_question(uuid, boolean, boolean, text[]) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_review_jee_pyq_question(uuid, boolean, boolean, text[]) TO authenticated;
