-- Regression assertions for the PYQ admin review/publish gate.
-- Use exceptions rather than a result set so CI/psql test runners fail closed.
do $$
declare
  routine regprocedure := 'public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[])'::regprocedure;
  definition text;
begin
  definition := pg_get_functiondef(routine);

  if has_function_privilege('anon', routine, 'EXECUTE') then
    raise exception 'anon must not execute the PYQ admin review RPC';
  end if;

  if not has_function_privilege('authenticated', routine, 'EXECUTE') then
    raise exception 'authenticated must be able to call the guarded PYQ review RPC';
  end if;

  if not (select prosecdef from pg_proc where oid = routine) then
    raise exception 'PYQ admin review RPC must use SECURITY DEFINER';
  end if;

  if position('app_metadata' in definition) = 0 then
    raise exception 'PYQ admin review RPC must check the server-managed admin role';
  end if;

  if position('private.jee_pyq_answer_keys' in definition) = 0 then
    raise exception 'PYQ admin review RPC must check the private answer key';
  end if;

  if position('source_page' in definition) = 0
     or position('Cannot publish without a source document and page number' in definition) = 0 then
    raise exception 'PYQ publishing must require source document and page provenance';
  end if;

  if position('Cannot publish without a worked solution' in definition) = 0 then
    raise exception 'PYQ publishing must require a worked solution';
  end if;

  if position('Cannot publish without a private answer key' in definition) = 0 then
    raise exception 'PYQ publishing must require a private answer key';
  end if;
end;
$$;
