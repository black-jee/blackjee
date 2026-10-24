-- Required start_mock_test parameters must reject NULL with stable validation errors.
DO $$
DECLARE
  v_message text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);

  BEGIN
    PERFORM public.start_mock_test(NULL::text, NULL::integer, NULL::text, NULL::text, NULL::text, 20, 1800);
    RAISE EXCEPTION 'NULL mode unexpectedly succeeded';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
    IF v_message <> 'Invalid mock test mode' THEN RAISE EXCEPTION 'Unexpected NULL mode error: %', v_message; END IF;
  END;

  BEGIN
    PERFORM public.start_mock_test('focused', NULL, NULL, NULL, NULL, NULL, 1800);
    RAISE EXCEPTION 'NULL question count unexpectedly succeeded';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
    IF v_message <> 'Question count or time limit is outside supported bounds' THEN RAISE EXCEPTION 'Unexpected NULL question count error: %', v_message; END IF;
  END;

  BEGIN
    PERFORM public.start_mock_test('focused', NULL, NULL, NULL, NULL, 20, NULL);
    RAISE EXCEPTION 'NULL duration unexpectedly succeeded';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
    IF v_message <> 'Question count or time limit is outside supported bounds' THEN RAISE EXCEPTION 'Unexpected NULL duration error: %', v_message; END IF;
  END;
END;
$$;
