-- Exact effective execute-access contract captured from the live public routine ACLs on 2026-10-25.
-- Run only against the disposable reconstruction replay after reconstructed RPC definitions.
DO $test$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[])', false, true, true),
      ('public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)', false, true, true),
      ('public.admin_save_jee_pyq_question(uuid,text,text,text,integer,text,text,text,text,text,jsonb,text,integer,integer,text,text,text,integer,text[],text[],text[])', false, true, true),
      ('public.get_current_daily_challenge()', true, true, true),
      ('public.get_daily_challenge_result(uuid)', false, true, true),
      ('public.get_mock_test_result(uuid)', false, true, true),
      ('public.grade_jee_pyq(uuid,text)', false, true, true),
      ('public.resume_mock_test(uuid)', false, true, true),
      ('public.start_daily_challenge(uuid)', false, true, true),
      ('public.start_mock_test(text,integer,text,text,text,integer,integer)', false, true, true),
      ('public.submit_daily_challenge(uuid,text)', false, true, true),
      ('public.submit_mock_test(uuid,jsonb)', false, true, true)
    ) AS expected(signature, anon_exec, authenticated_exec, service_role_exec)
  LOOP
    IF to_regprocedure(r.signature) IS NULL THEN
      RAISE EXCEPTION 'Expected public RPC is missing: %', r.signature;
    END IF;

    IF (has_function_privilege('anon', to_regprocedure(r.signature), 'EXECUTE'),
        has_function_privilege('authenticated', to_regprocedure(r.signature), 'EXECUTE'),
        has_function_privilege('service_role', to_regprocedure(r.signature), 'EXECUTE'))
       IS DISTINCT FROM
       (r.anon_exec, r.authenticated_exec, r.service_role_exec) THEN
      RAISE EXCEPTION 'Effective EXECUTE privilege matrix changed for %', r.signature;
    END IF;

    -- Check explicit/default ACL entries too: PUBLIC must not receive EXECUTE.
    IF EXISTS (
      SELECT 1
      FROM pg_proc p
      CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) acl
      WHERE p.oid = to_regprocedure(r.signature)
        AND acl.grantee = 0
        AND acl.privilege_type = 'EXECUTE'
    ) THEN
      RAISE EXCEPTION 'PUBLIC must not have EXECUTE on %', r.signature;
    END IF;
  END LOOP;
END;
$test$;

SELECT 'PASS: all 12 public RPC execute privileges match the captured role matrix; PUBLIC has no EXECUTE grant' AS routine_execute_acl_contract;
