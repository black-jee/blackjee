revoke execute on function public.start_daily_challenge(uuid) from anon, public;
grant execute on function public.start_daily_challenge(uuid) to authenticated;
revoke execute on function public.submit_daily_challenge(uuid,text) from anon, public;
grant execute on function public.submit_daily_challenge(uuid,text) to authenticated;
revoke execute on function public.get_daily_challenge_result(uuid) from anon, public;
grant execute on function public.get_daily_challenge_result(uuid) to authenticated;
