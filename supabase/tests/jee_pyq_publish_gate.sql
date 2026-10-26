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


-- Runtime negative tests with synthetic fixtures. CI runs this file only against
-- the disposable PostgreSQL reconstruction; never execute it against production.
begin;
do $test$
declare
  v_admin uuid := 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  q_no_source uuid;
  q_no_page uuid;
  q_no_key uuid;
  q_no_solution uuid;
  q_bad_answer uuid;
  test_case record;
  actual_error text;
begin
  insert into auth.users(id) values (v_admin) on conflict (id) do nothing;

  insert into public.jee_pyq_questions
    (title, subject, statement, options, source_pdf, source_page)
  values
    ('Synthetic publish gate: no source', 'Physics', 'Synthetic test statement',
     '[{"label":"A","text":"Synthetic option A"},{"label":"B","text":"Synthetic option B"}]'::jsonb, null, 1)
  returning id into q_no_source;

  insert into public.jee_pyq_questions
    (title, subject, statement, options, source_pdf, source_page)
  values
    ('Synthetic publish gate: no page', 'Physics', 'Synthetic test statement',
     '[{"label":"A","text":"Synthetic option A"},{"label":"B","text":"Synthetic option B"}]'::jsonb, 'synthetic-source.pdf', null)
  returning id into q_no_page;

  insert into public.jee_pyq_questions
    (title, subject, statement, options, source_pdf, source_page)
  values
    ('Synthetic publish gate: no key', 'Physics', 'Synthetic test statement',
     '[{"label":"A","text":"Synthetic option A"},{"label":"B","text":"Synthetic option B"}]'::jsonb, 'synthetic-source.pdf', 1)
  returning id into q_no_key;

  insert into public.jee_pyq_questions
    (title, subject, statement, options, source_pdf, source_page)
  values
    ('Synthetic publish gate: no solution', 'Physics', 'Synthetic test statement',
     '[{"label":"A","text":"Synthetic option A"},{"label":"B","text":"Synthetic option B"}]'::jsonb, 'synthetic-source.pdf', 1)
  returning id into q_no_solution;

  insert into public.jee_pyq_questions
    (title, subject, statement, options, source_pdf, source_page)
  values
    ('Synthetic publish gate: bad answer label', 'Physics', 'Synthetic test statement',
     '[{"label":"A","text":"Synthetic option A"},{"label":"B","text":"Synthetic option B"}]'::jsonb, 'synthetic-source.pdf', 1)
  returning id into q_bad_answer;

  insert into private.jee_pyq_answer_keys(question_id, correct_answer, solution)
  values
    (q_no_source, 'A', 'Synthetic worked solution'),
    (q_no_page, 'A', 'Synthetic worked solution'),
    (q_no_solution, 'A', '   '),
    (q_bad_answer, 'Z', 'Synthetic worked solution');

  perform set_config('request.jwt.claim.sub', v_admin::text, true);
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', v_admin::text,
      'app_metadata', jsonb_build_object('role', 'admin')
    )::text,
    true
  );

  for test_case in
    select * from (values
      (q_no_source, 'missing source document', 'Cannot publish without a source document and page number'),
      (q_no_page, 'missing source page', 'Cannot publish without a source document and page number'),
      (q_no_key, 'missing private answer key', 'Cannot publish without a private answer key'),
      (q_no_solution, 'blank worked solution', 'Cannot publish without a worked solution'),
      (q_bad_answer, 'answer label absent from options', 'Private answer key does not match any option label')
    ) as cases(question_id, label, expected_error)
  loop
    begin
      perform public.admin_review_jee_pyq_question(
        test_case.question_id, true, true, null::text[]
      );
      raise exception 'TEST_UNEXPECTED_SUCCESS: %', test_case.label;
    exception when others then
      get stacked diagnostics actual_error = message_text;
      if actual_error like 'TEST_UNEXPECTED_SUCCESS:%' then
        raise exception 'PYQ publish gate failed to reject %', test_case.label;
      end if;
      if position(test_case.expected_error in actual_error) = 0 then
        raise exception 'PYQ publish gate % failed for unexpected reason: %',
          test_case.label, actual_error;
      end if;
      raise notice 'PASS: PYQ publish gate rejects %', test_case.label;
    end;
  end loop;
end;
$test$;
rollback;
