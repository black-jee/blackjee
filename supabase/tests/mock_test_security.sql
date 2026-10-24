-- Regression assertions for mock-test ownership, privileges and answer-key separation.
do $$
begin
  if has_function_privilege('anon','public.start_mock_test(text,integer,text,text,text,integer,integer)','EXECUTE') then
    raise exception 'anon must not start mock tests';
  end if;
  if not has_function_privilege('authenticated','public.start_mock_test(text,integer,text,text,text,integer,integer)','EXECUTE') then
    raise exception 'authenticated users must be able to start mock tests';
  end if;
  if has_function_privilege('anon','public.submit_mock_test(uuid,jsonb)','EXECUTE') then
    raise exception 'anon must not submit mock tests';
  end if;
  if has_table_privilege('authenticated','public.mock_test_attempts','INSERT')
     or has_table_privilege('authenticated','public.mock_test_attempts','UPDATE')
     or has_table_privilege('authenticated','public.mock_test_attempts','DELETE') then
    raise exception 'Students must not mutate mock-test attempts directly';
  end if;
  if has_table_privilege('authenticated','private.mock_test_responses','SELECT')
     or has_table_privilege('authenticated','private.mock_test_responses','INSERT')
     or has_table_privilege('authenticated','private.mock_test_responses','UPDATE')
     or has_table_privilege('authenticated','private.mock_test_responses','DELETE') then
    raise exception 'Students must not access private mock-test responses directly';
  end if;
  if not (select relrowsecurity from pg_class where oid='public.mock_test_attempts'::regclass) then
    raise exception 'RLS must be enabled on mock-test attempts';
  end if;
  if not (select relrowsecurity from pg_class where oid='private.mock_test_responses'::regclass) then
    raise exception 'RLS must be enabled on private mock-test responses';
  end if;
  if position('auth.uid()' in pg_get_functiondef('public.start_mock_test(text,integer,text,text,text,integer,integer)'::regprocedure)) = 0
     or position('auth.uid()' in pg_get_functiondef('public.resume_mock_test(uuid)'::regprocedure)) = 0
     or position('auth.uid()' in pg_get_functiondef('public.submit_mock_test(uuid,jsonb)'::regprocedure)) = 0
     or position('auth.uid()' in pg_get_functiondef('public.get_mock_test_result(uuid)'::regprocedure)) = 0 then
    raise exception 'Every mock-test RPC must bind attempts to auth.uid()';
  end if;
end;
$$;
