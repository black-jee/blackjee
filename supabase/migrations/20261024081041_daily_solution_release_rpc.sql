create or replace function public.get_daily_challenge_result(p_challenge_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $function$
declare v_challenge public.daily_challenges%rowtype; v_key text; v_solution text;
begin
 select * into v_challenge from public.daily_challenges c where c.id=p_challenge_id and c.is_live;
 if not found then raise exception 'Challenge not found' using errcode='P0002'; end if;
 if now() < v_challenge.solution_release_at then
   return jsonb_build_object('solution_released',false,'solution_release_at',v_challenge.solution_release_at,'message','The worked solution is not released yet.');
 end if;
 select k.correct_answer,k.solution into v_key,v_solution from private.daily_challenge_answer_keys k where k.challenge_id=p_challenge_id;
 if not found then raise exception 'Challenge answer key is not configured'; end if;
 return jsonb_build_object('solution_released',true,'correct_answer',v_key,'solution',coalesce(v_solution,''));
end;
$function$;
revoke execute on function public.get_daily_challenge_result(uuid) from public, anon;
grant execute on function public.get_daily_challenge_result(uuid) to authenticated;
