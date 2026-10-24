-- Negative-permission regression checks for the target project's private answer/session tables.
do $$
declare
  table_name text;
  table_oid regclass;
begin
  foreach table_name in array array[
    'private.daily_challenge_answer_keys',
    'private.daily_challenge_sessions',
    'private.jee_pyq_answer_attempts',
    'private.jee_pyq_answer_keys'
  ] loop
    table_oid := to_regclass(table_name);
    if table_oid is null then
      raise exception 'Expected private table % is missing', table_name;
    end if;
    if has_table_privilege('anon', table_oid, 'SELECT')
       or has_table_privilege('authenticated', table_oid, 'SELECT')
       or has_table_privilege('anon', table_oid, 'INSERT')
       or has_table_privilege('authenticated', table_oid, 'INSERT')
       or has_table_privilege('anon', table_oid, 'UPDATE')
       or has_table_privilege('authenticated', table_oid, 'UPDATE')
       or has_table_privilege('anon', table_oid, 'DELETE')
       or has_table_privilege('authenticated', table_oid, 'DELETE') then
      raise exception 'Browser role has direct table privileges on %', table_name;
    end if;
  end loop;

  if not (select relrowsecurity from pg_class where oid = 'private.daily_challenge_answer_keys'::regclass) then
    raise exception 'RLS must remain enabled on private answer keys';
  end if;

  if not (select prosecdef from pg_proc where oid = 'public.start_daily_challenge(uuid)'::regprocedure) then
    raise exception 'Challenge start must remain a trusted server-side RPC';
  end if;

  if position('auth.uid()' in pg_get_functiondef('public.start_daily_challenge(uuid)'::regprocedure)) = 0 then
    raise exception 'Challenge start must bind the session to auth.uid()';
  end if;

  if position('auth.uid()' in pg_get_functiondef('public.submit_daily_challenge(uuid,text)'::regprocedure)) = 0 then
    raise exception 'Challenge submit must bind the submission to auth.uid()';
  end if;

  if position('auth.uid()' in pg_get_functiondef('public.grade_jee_pyq(uuid,text)'::regprocedure)) = 0 then
    raise exception 'PYQ grading must bind attempts to auth.uid()';
  end if;
end;
$$;
