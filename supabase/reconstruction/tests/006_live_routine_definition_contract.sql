-- Exact current live routine snapshot captured through read-only catalog queries on 2026-10-25.
-- Run only against the disposable reconstruction replay, after RPC definitions are replayed.
-- This fingerprints function bodies and checks identity signature, language, security mode,
-- and pinned configuration. ACLs are covered by the separate access/security contracts.
DO $test$
DECLARE
  mismatches text;
BEGIN
  WITH expected(schema_name, function_name, identity_arguments, definition_md5, language, security_definer, function_config) AS (
    VALUES
    ('public', 'admin_review_jee_pyq_question', 'p_question_id uuid, p_approve boolean, p_publish boolean, p_review_notes text[]', 'c60ab9ab4141edcb615f475919cbf620', 'plpgsql', true, 'search_path=""'),
    ('public', 'admin_save_daily_challenge', 'p_challenge_id uuid, p_challenge_date date, p_title text, p_subject text, p_statement text, p_statement_image_path text, p_options jsonb, p_starts_at timestamp with time zone, p_ends_at timestamp with time zone, p_solution_release_at timestamp with time zone, p_correct_answer text, p_solution text, p_is_live boolean', 'ebdff78aa677719515c9e500fc576562', 'plpgsql', true, 'search_path=""'),
    ('public', 'admin_save_jee_pyq_question', 'p_question_id uuid, p_source_id text, p_title text, p_exam text, p_year integer, p_session text, p_subject text, p_chapter text, p_statement text, p_statement_image_path text, p_options jsonb, p_question_type text, p_marks_correct integer, p_marks_wrong integer, p_correct_answer text, p_solution text, p_source_pdf text, p_source_page integer, p_tags text[], p_asset_paths text[], p_review_notes text[]', '9de6669f0727df14fd0851895ee37466', 'plpgsql', true, 'search_path=""'),
    ('public', 'get_current_daily_challenge', '', 'ff76bf83a39b595544fe15f3475cd70b', 'sql', false, 'search_path=""'),
    ('public', 'get_daily_challenge_result', 'p_challenge_id uuid', 'ccb0c62728a64f6382ffdf9a8f2f63d8', 'plpgsql', true, 'search_path=""'),
    ('public', 'get_mock_test_result', 'p_attempt_id uuid', '3be309fd8edd50c20e814a5a99fb5f51', 'plpgsql', true, 'search_path=""'),
    ('public', 'grade_jee_pyq', 'p_question_id uuid, p_answer text', 'ffa56082434a79de6d37607fb225b145', 'plpgsql', true, 'search_path=""'),
    ('public', 'resume_mock_test', 'p_attempt_id uuid', 'c14e3486e41e53f9aee6207093b380df', 'plpgsql', true, 'search_path=""'),
    ('public', 'start_daily_challenge', 'p_challenge_id uuid', '6184a711c54ac02ef621064bb99fa8b4', 'plpgsql', true, 'search_path=""'),
    ('public', 'start_mock_test', 'p_mode text, p_year integer, p_session text, p_subject text, p_chapter text, p_question_count integer, p_duration_seconds integer', '721ed05ba1d51a63a1af126da78f669f', 'plpgsql', true, 'search_path=""'),
    ('public', 'submit_daily_challenge', 'p_challenge_id uuid, p_answer text', '9976c9390ebb5140757cc27e6afb02ec', 'plpgsql', true, 'search_path=""'),
    ('public', 'submit_mock_test', 'p_attempt_id uuid, p_answers jsonb', '33b381c7bb94b3b772ca5f90db196c5d', 'plpgsql', true, 'search_path=""')
  ), actual AS (
    SELECT n.nspname AS schema_name, p.proname AS function_name,
           pg_catalog.pg_get_function_identity_arguments(p.oid) AS identity_arguments,
           md5(pg_catalog.pg_get_functiondef(p.oid)) AS definition_md5,
           l.lanname AS language, p.prosecdef AS security_definer,
           coalesce(array_to_string(p.proconfig, ','), '') AS function_config
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    JOIN pg_catalog.pg_language l ON l.oid = p.prolang
    WHERE n.nspname IN ('public', 'private') AND p.prokind = 'f'
  ), differences AS (
    (SELECT 'missing_or_different_routine: ' || e.schema_name || '.' || e.function_name || '(' || e.identity_arguments || ')' AS detail
     FROM expected e LEFT JOIN actual a USING (schema_name, function_name, identity_arguments)
     WHERE a.function_name IS NULL OR (e.definition_md5, e.language, e.security_definer, e.function_config)
       IS DISTINCT FROM (a.definition_md5, a.language, a.security_definer, a.function_config))
    UNION ALL
    (SELECT 'unexpected_routine: ' || a.schema_name || '.' || a.function_name || '(' || a.identity_arguments || ')' AS detail
     FROM actual a LEFT JOIN expected e USING (schema_name, function_name, identity_arguments)
     WHERE e.function_name IS NULL)
  )
  SELECT string_agg(detail, E'\\n' ORDER BY detail) INTO mismatches FROM differences;
  IF mismatches IS NOT NULL THEN
    RAISE EXCEPTION 'Live routine snapshot mismatch:%', E'\\n' || mismatches;
  END IF;
END;
$test$;

SELECT 'PASS: all 12 live routine fingerprints and security attributes match the captured snapshot' AS routine_definition_contract;
