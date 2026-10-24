-- Add a safe relative image asset reference to daily challenge question content.
alter table public.daily_challenges
  add column if not exists statement_image_path text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'daily_challenges_statement_image_path_safe'
      and conrelid = 'public.daily_challenges'::regclass
  ) then
    alter table public.daily_challenges
      add constraint daily_challenges_statement_image_path_safe
      check (
        statement_image_path is null
        or statement_image_path !~ '(^/|//|(^|/)[.][.](/|$)|[^A-Za-z0-9._/-])'
      );
  end if;
end;
$$;

create or replace function public.start_daily_challenge(p_challenge_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
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
