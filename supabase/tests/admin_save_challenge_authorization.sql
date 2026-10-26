-- Regression checks for the database-enforced admin-only challenge save RPC.
-- A failed assertion raises an exception so CI fails closed.
do $$
declare
  routine regprocedure := 'public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)'::regprocedure;
  definition text;
  pyq_routine regprocedure := 'public.admin_save_jee_pyq_question(uuid,text,text,text,integer,text,text,text,text,text,jsonb,text,integer,integer,text,text,text,integer,text[],text[],text[])'::regprocedure;
  pyq_definition text;
begin
  definition := pg_get_functiondef(routine);
  pyq_definition := pg_get_functiondef(pyq_routine);

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

  if has_function_privilege('anon', pyq_routine, 'EXECUTE') then
    raise exception 'anon must not execute the admin PYQ save RPC';
  end if;
  if not has_function_privilege('authenticated', pyq_routine, 'EXECUTE') then
    raise exception 'authenticated must be able to call the guarded admin PYQ save RPC';
  end if;
  if not (select prosecdef from pg_proc where oid = pyq_routine) then
    raise exception 'Admin PYQ save RPC must use SECURITY DEFINER';
  end if;
  if position('app_metadata' in pyq_definition) = 0
     or position('Administrator access required' in pyq_definition) = 0 then
    raise exception 'Admin PYQ save RPC must check the server-managed admin role';
  end if;
  if position('private.jee_pyq_answer_keys' in pyq_definition) = 0 then
    raise exception 'Admin PYQ save RPC must keep answer keys private';
  end if;
end;
$$;
