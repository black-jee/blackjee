-- Regression assertions for the public schedule RPC hardening migration.
do $$
begin
  if (select prosecdef from pg_proc where oid = 'public.get_current_daily_challenge()'::regprocedure) then
    raise exception 'get_current_daily_challenge must not run as SECURITY DEFINER';
  end if;

  if not has_function_privilege('anon', 'public.get_current_daily_challenge()', 'EXECUTE') then
    raise exception 'anon must retain execute access to the public schedule RPC';
  end if;

  if has_column_privilege('anon', 'public.daily_challenges', 'statement', 'SELECT') then
    raise exception 'anon must not be able to select question statements';
  end if;

  if not has_column_privilege('anon', 'public.daily_challenges', 'title', 'SELECT') then
    raise exception 'anon should be able to select public schedule titles';
  end if;

  if to_regclass('private.daily_challenge_sessions_user_id_idx') is null then
    raise exception 'daily challenge session user foreign key index is missing';
  end if;
end;
$$;
