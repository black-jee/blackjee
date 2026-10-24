-- Regression checks for the database-enforced admin-only challenge save RPC.
-- A failed assertion raises an exception so CI fails closed.
do $$
declare
  routine regprocedure := 'public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)'::regprocedure;
  definition text;
begin
  definition := pg_get_functiondef(routine);

  if has_function_privilege('anon', routine, 'EXECUTE') then
    raise exception 'anon must not execute the admin challenge save RPC';
  end if;
  if not has_function_privilege('authenticated', routine, 'EXECUTE') then
    raise exception 'authenticated must be able to call the guarded admin RPC';
  end if;
  if not (select prosecdef from pg_proc where oid = routine) then
    raise exception 'Admin challenge save RPC must use SECURITY DEFINER';
  end if;
  if position('app_metadata' in definition) = 0 then
    raise exception 'Admin challenge save RPC must check the server-managed role';
  end if;
  if position('private.daily_challenge_answer_keys' in definition) = 0 then
    raise exception 'Admin challenge save RPC must keep the answer key private';
  end if;
end;
$$;
