-- Assert the reconstructed RPC baseline matches the exact read-only live definition
-- captured from pg_get_functiondef before branch-only hardening is applied.
DO $test$
DECLARE
  v_definition text;
  v_actual_md5 text;
  v_expected_md5 constant text := 'ebdff78aa677719515c9e500fc576562';
BEGIN
  SELECT pg_get_functiondef(
    'public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)'::regprocedure
  )
  INTO v_definition;

  v_actual_md5 := md5(v_definition);
  IF v_actual_md5 <> v_expected_md5 THEN
    RAISE EXCEPTION 'Live baseline fingerprint mismatch: expected %, got %', v_expected_md5, v_actual_md5;
  END IF;
END;
$test$;

SELECT 'PASS: admin_save_daily_challenge matches the captured live baseline fingerprint' AS baseline_fingerprint_test;
