-- Regression contract for exposed SECURITY DEFINER RPCs.
-- Run against a disposable database or as a read-only catalog assertion.
-- This checks the security boundary, not every business-rule branch.

DO $$
DECLARE
  v_signature text;
  v_routine regprocedure;
  v_definition text;
  v_config text[];
  v_is_definer boolean;
  v_student_signatures text[] := ARRAY[
    'public.get_daily_challenge_result(uuid)',
    'public.get_mock_test_result(uuid)',
    'public.grade_jee_pyq(uuid,text)',
    'public.resume_mock_test(uuid)',
    'public.start_daily_challenge(uuid)',
    'public.start_mock_test(text,integer,text,text,text,integer,integer)',
    'public.submit_daily_challenge(uuid,text)',
    'public.submit_mock_test(uuid,jsonb)'
  ];
  v_admin_signatures text[] := ARRAY[
    'public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[])',
    'public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)',
    'public.admin_save_jee_pyq_question(uuid,text,text,text,integer,text,text,text,text,text,jsonb,text,integer,integer,text,text,text,integer,text[],text[],text[])'
  ];
BEGIN
  FOREACH v_signature IN ARRAY v_student_signatures || v_admin_signatures LOOP
    v_routine := to_regprocedure(v_signature);
    IF v_routine IS NULL THEN
      RAISE EXCEPTION 'Expected RPC is missing: %', v_signature;
    END IF;

    SELECT p.prosecdef, p.proconfig, pg_get_functiondef(p.oid)
      INTO v_is_definer, v_config, v_definition
    FROM pg_proc p
    WHERE p.oid = v_routine::oid;

    IF NOT v_is_definer THEN
      RAISE EXCEPTION 'Expected SECURITY DEFINER RPC: %', v_signature;
    END IF;
    IF array_position(v_config, 'search_path=""') IS NULL THEN
      RAISE EXCEPTION 'RPC must pin an empty search_path: %', v_signature;
    END IF;
    IF has_function_privilege('anon', v_routine::oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'Anonymous role must not execute RPC: %', v_signature;
    END IF;
    IF NOT has_function_privilege('authenticated', v_routine::oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'Authenticated role must be able to call guarded RPC: %', v_signature;
    END IF;
    IF position('auth.uid()' IN v_definition) = 0 THEN
      RAISE EXCEPTION 'RPC must bind authorization to auth.uid(): %', v_signature;
    END IF;

    IF v_signature = ANY(v_admin_signatures) THEN
      IF position('app_metadata' IN v_definition) = 0
         OR position('admin' IN lower(v_definition)) = 0 THEN
        RAISE EXCEPTION 'Admin RPC must check server-managed admin metadata: %', v_signature;
      END IF;
    END IF;
  END LOOP;
END;
$$;
