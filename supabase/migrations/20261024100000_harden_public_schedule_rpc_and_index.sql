-- Hardening pass for the public challenge schedule RPC.
-- The RPC returns only schedule metadata. Keep that public contract, but run as invoker
-- and grant anon only the columns it needs; RLS continues to restrict rows to live challenges.
create or replace function public.get_current_daily_challenge()
returns jsonb
language sql
stable
security invoker
set search_path to ''
as $function$
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

revoke all on function public.get_current_daily_challenge() from public;
grant execute on function public.get_current_daily_challenge() to anon, authenticated, service_role;

grant select (id, challenge_date, title, subject, starts_at, ends_at, solution_release_at, is_live)
  on public.daily_challenges to anon;

create index if not exists daily_challenge_sessions_user_id_idx
  on private.daily_challenge_sessions (user_id);
