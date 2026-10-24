-- Catalog-level contract for daily-challenge authoring integrity.
DO $$
DECLARE
  v_definition text;
  v_routine regprocedure := 'public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)'::regprocedure;
BEGIN
  SELECT pg_get_functiondef(v_routine) INTO v_definition;
  IF position('A live challenge must include a worked solution' IN v_definition) = 0 THEN
    RAISE EXCEPTION 'Daily challenge RPC must reject live challenges without a worked solution';
  END IF;
  IF position('A daily challenge can have at most 12 options' IN v_definition) = 0
     OR position('Daily challenge options need non-empty labels' IN v_definition) = 0
     OR position('Daily challenge option labels must be unique' IN v_definition) = 0
     OR position('Correct answer must match one of the option labels' IN v_definition) = 0 THEN
    RAISE EXCEPTION 'Daily challenge RPC is missing option-integrity validation';
  END IF;
  IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = v_routine) THEN
    RAISE EXCEPTION 'Daily challenge authoring RPC must remain SECURITY DEFINER';
  END IF;
  IF has_function_privilege('anon', v_routine, 'EXECUTE')
     OR NOT has_function_privilege('authenticated', v_routine, 'EXECUTE') THEN
    RAISE EXCEPTION 'Daily challenge authoring RPC execute grants are incorrect';
  END IF;
END;
$$;
