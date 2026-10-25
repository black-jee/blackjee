create table if not exists private.daily_challenge_sessions (
 challenge_id uuid not null references public.daily_challenges(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 started_at timestamptz not null default now(),
 submitted_at timestamptz,
 primary key(challenge_id,user_id)
);
alter table private.daily_challenge_sessions enable row level security;
revoke all on table private.daily_challenge_sessions from public,anon,authenticated;

create or replace function public.get_current_daily_challenge()
returns jsonb language sql stable security definer set search_path='' as $function$
 select jsonb_build_object('id',c.id,'challenge_date',c.challenge_date,'title',c.title,'subject',c.subject,
   'starts_at',c.starts_at,'ends_at',c.ends_at,'solution_release_at',c.solution_release_at)
 from public.daily_challenges c where c.is_live and now()>=c.starts_at and now()<c.ends_at order by c.starts_at desc limit 1;
$function$;
revoke execute on function public.get_current_daily_challenge() from public;
grant execute on function public.get_current_daily_challenge() to anon,authenticated;

create or replace function public.start_daily_challenge(p_challenge_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $function$
declare v_user uuid:=auth.uid(); v_challenge public.daily_challenges%rowtype; v_started timestamptz;
begin
 if v_user is null then raise exception 'Sign in required' using errcode='42501'; end if;
 select * into v_challenge from public.daily_challenges c where c.id=p_challenge_id and c.is_live and now()>=c.starts_at and now()<c.ends_at;
 if not found then raise exception 'Challenge is not currently open' using errcode='P0002'; end if;
 if exists(select 1 from public.daily_challenge_attempts a where a.challenge_id=p_challenge_id and a.user_id=v_user) then
   raise exception 'You have already submitted an attempt for this challenge' using errcode='23505';
 end if;
 insert into private.daily_challenge_sessions(challenge_id,user_id) values(p_challenge_id,v_user) on conflict(challenge_id,user_id) do nothing;
 select s.started_at into v_started from private.daily_challenge_sessions s where s.challenge_id=p_challenge_id and s.user_id=v_user and s.submitted_at is null;
 if v_started is null then raise exception 'This challenge attempt is already submitted' using errcode='23505'; end if;
 return jsonb_build_object('id',v_challenge.id,'challenge_date',v_challenge.challenge_date,'title',v_challenge.title,'subject',v_challenge.subject,
   'statement',v_challenge.statement,'options',v_challenge.options,'starts_at',v_challenge.starts_at,'ends_at',v_challenge.ends_at,
   'solution_release_at',v_challenge.solution_release_at,'started_at',v_started);
end;
$function$;
revoke execute on function public.start_daily_challenge(uuid) from public, anon;
grant execute on function public.start_daily_challenge(uuid) to authenticated;

drop function if exists public.submit_daily_challenge(uuid,text,integer);
create or replace function public.submit_daily_challenge(p_challenge_id uuid,p_answer text)
returns jsonb language plpgsql security definer set search_path='' as $function$
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
revoke execute on function public.submit_daily_challenge(uuid,text) from public, anon;
grant execute on function public.submit_daily_challenge(uuid,text) to authenticated;
