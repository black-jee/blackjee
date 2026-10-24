-- Save or update a daily challenge and its private answer key atomically.
-- Authorization is enforced by the database using server-managed app_metadata.
create or replace function public.admin_save_daily_challenge(
  p_challenge_id uuid,
  p_challenge_date date,
  p_title text,
  p_subject text,
  p_statement text,
  p_statement_image_path text,
  p_options jsonb,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_solution_release_at timestamptz,
  p_correct_answer text,
  p_solution text,
  p_is_live boolean
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
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

  if p_starts_at >= p_ends_at or p_ends_at > p_solution_release_at then
    raise exception 'Challenge schedule times are invalid' using errcode = '22023';
  end if;

  if p_options is null or jsonb_typeof(p_options) <> 'array' then
    raise exception 'Options must be a JSON array' using errcode = '22023';
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

revoke all on function public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean) from public, anon, authenticated;
grant execute on function public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean) to authenticated;
