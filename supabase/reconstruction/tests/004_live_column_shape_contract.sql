-- Exact live column-shape snapshot captured with read-only catalog queries on 2026-10-25.
-- Run only against the disposable reconstruction replay. This asserts columns,
-- order, type, nullability, defaults, identity, and generated attributes; it
-- does not mutate schema/data and does not prove constraints, grants, or routine parity.
DO $test$
DECLARE
  mismatches text;
BEGIN
  WITH expected(schema_name, table_name, ordinal_position, column_name, data_type, not_null, default_expr, identity_kind, generated_kind) AS (
    VALUES
    ('private', 'daily_challenge_answer_keys', 1, 'challenge_id', 'uuid', true, NULL, '', ''),
    ('private', 'daily_challenge_answer_keys', 2, 'correct_answer', 'text', true, NULL, '', ''),
    ('private', 'daily_challenge_answer_keys', 3, 'solution', 'text', false, NULL, '', ''),
    ('private', 'daily_challenge_sessions', 1, 'challenge_id', 'uuid', true, NULL, '', ''),
    ('private', 'daily_challenge_sessions', 2, 'user_id', 'uuid', true, NULL, '', ''),
    ('private', 'daily_challenge_sessions', 3, 'started_at', 'timestamp with time zone', true, 'now()', '', ''),
    ('private', 'daily_challenge_sessions', 4, 'submitted_at', 'timestamp with time zone', false, NULL, '', ''),
    ('private', 'jee_pyq_answer_attempts', 1, 'user_id', 'uuid', true, NULL, '', ''),
    ('private', 'jee_pyq_answer_attempts', 2, 'question_id', 'uuid', true, NULL, '', ''),
    ('private', 'jee_pyq_answer_attempts', 3, 'wrong_attempts', 'integer', true, '0', '', ''),
    ('private', 'jee_pyq_answer_attempts', 4, 'first_attempt_at', 'timestamp with time zone', true, 'now()', '', ''),
    ('private', 'jee_pyq_answer_attempts', 5, 'last_attempt_at', 'timestamp with time zone', true, 'now()', '', ''),
    ('private', 'jee_pyq_answer_attempts', 6, 'solution_unlocked_at', 'timestamp with time zone', false, NULL, '', ''),
    ('private', 'jee_pyq_answer_keys', 1, 'question_id', 'uuid', true, NULL, '', ''),
    ('private', 'jee_pyq_answer_keys', 2, 'correct_answer', 'text', true, NULL, '', ''),
    ('private', 'jee_pyq_answer_keys', 3, 'solution', 'text', false, NULL, '', ''),
    ('private', 'jee_pyq_answer_keys', 4, 'updated_at', 'timestamp with time zone', true, 'now()', '', ''),
    ('private', 'mock_test_responses', 1, 'attempt_id', 'uuid', true, NULL, '', ''),
    ('private', 'mock_test_responses', 2, 'question_id', 'uuid', true, NULL, '', ''),
    ('private', 'mock_test_responses', 3, 'selected_answer', 'text', false, NULL, '', ''),
    ('private', 'mock_test_responses', 4, 'is_correct', 'boolean', true, 'false', '', ''),
    ('private', 'mock_test_responses', 5, 'marks_awarded', 'integer', true, '0', '', ''),
    ('private', 'mock_test_responses', 6, 'answered_at', 'timestamp with time zone', true, 'now()', '', ''),
    ('public', 'daily_challenge_attempts', 1, 'id', 'uuid', true, 'gen_random_uuid()', '', ''),
    ('public', 'daily_challenge_attempts', 2, 'challenge_id', 'uuid', true, NULL, '', ''),
    ('public', 'daily_challenge_attempts', 3, 'user_id', 'uuid', true, NULL, '', ''),
    ('public', 'daily_challenge_attempts', 4, 'selected_answer', 'text', true, NULL, '', ''),
    ('public', 'daily_challenge_attempts', 5, 'is_correct', 'boolean', true, NULL, '', ''),
    ('public', 'daily_challenge_attempts', 6, 'elapsed_seconds', 'integer', true, NULL, '', ''),
    ('public', 'daily_challenge_attempts', 7, 'submitted_at', 'timestamp with time zone', true, 'now()', '', ''),
    ('public', 'daily_challenges', 1, 'id', 'uuid', true, 'gen_random_uuid()', '', ''),
    ('public', 'daily_challenges', 2, 'challenge_date', 'date', true, NULL, '', ''),
    ('public', 'daily_challenges', 3, 'title', 'text', true, NULL, '', ''),
    ('public', 'daily_challenges', 4, 'subject', 'text', true, NULL, '', ''),
    ('public', 'daily_challenges', 5, 'statement', 'text', true, NULL, '', ''),
    ('public', 'daily_challenges', 6, 'options', 'jsonb', true, '''[]''::jsonb', '', ''),
    ('public', 'daily_challenges', 7, 'starts_at', 'timestamp with time zone', true, NULL, '', ''),
    ('public', 'daily_challenges', 8, 'ends_at', 'timestamp with time zone', true, NULL, '', ''),
    ('public', 'daily_challenges', 9, 'solution_release_at', 'timestamp with time zone', true, NULL, '', ''),
    ('public', 'daily_challenges', 10, 'is_live', 'boolean', true, 'false', '', ''),
    ('public', 'daily_challenges', 11, 'created_by', 'uuid', false, NULL, '', ''),
    ('public', 'daily_challenges', 12, 'created_at', 'timestamp with time zone', true, 'now()', '', ''),
    ('public', 'daily_challenges', 13, 'statement_image_path', 'text', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 1, 'id', 'uuid', true, 'gen_random_uuid()', '', ''),
    ('public', 'jee_pyq_questions', 2, 'source_id', 'text', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 3, 'title', 'text', true, NULL, '', ''),
    ('public', 'jee_pyq_questions', 4, 'exam', 'text', true, '''JEE Main''::text', '', ''),
    ('public', 'jee_pyq_questions', 5, 'year', 'integer', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 6, 'subject', 'text', true, NULL, '', ''),
    ('public', 'jee_pyq_questions', 7, 'chapter', 'text', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 8, 'difficulty', 'text', true, '''Main''::text', '', ''),
    ('public', 'jee_pyq_questions', 9, 'statement', 'text', true, NULL, '', ''),
    ('public', 'jee_pyq_questions', 10, 'options', 'jsonb', true, '''[]''::jsonb', '', ''),
    ('public', 'jee_pyq_questions', 11, 'tags', 'text[]', true, '''{}''::text[]', '', ''),
    ('public', 'jee_pyq_questions', 12, 'asset_paths', 'text[]', true, '''{}''::text[]', '', ''),
    ('public', 'jee_pyq_questions', 13, 'review_status', 'text', true, '''draft''::text', '', ''),
    ('public', 'jee_pyq_questions', 14, 'is_published', 'boolean', true, 'false', '', ''),
    ('public', 'jee_pyq_questions', 15, 'created_by', 'uuid', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 16, 'reviewed_by', 'uuid', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 17, 'reviewed_at', 'timestamp with time zone', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 18, 'created_at', 'timestamp with time zone', true, 'now()', '', ''),
    ('public', 'jee_pyq_questions', 19, 'updated_at', 'timestamp with time zone', true, 'now()', '', ''),
    ('public', 'jee_pyq_questions', 20, 'statement_image_path', 'text', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 21, 'session', 'text', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 22, 'question_type', 'text', true, '''single_correct''::text', '', ''),
    ('public', 'jee_pyq_questions', 23, 'marks_correct', 'integer', true, '4', '', ''),
    ('public', 'jee_pyq_questions', 24, 'marks_wrong', 'integer', true, '''-1''::integer', '', ''),
    ('public', 'jee_pyq_questions', 25, 'source_page', 'integer', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 26, 'source_pdf', 'text', false, NULL, '', ''),
    ('public', 'jee_pyq_questions', 27, 'source_reference', 'jsonb', true, '''{}''::jsonb', '', ''),
    ('public', 'jee_pyq_questions', 28, 'quality_checks', 'jsonb', true, '''{}''::jsonb', '', ''),
    ('public', 'jee_pyq_questions', 29, 'review_notes', 'text[]', true, '''{}''::text[]', '', ''),
    ('public', 'jee_pyq_questions', 30, 'source_status', 'text', true, '''not_verified''::text', '', ''),
    ('public', 'jee_pyq_questions', 31, 'publication_block_reason', 'text', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 1, 'id', 'uuid', true, 'gen_random_uuid()', '', ''),
    ('public', 'mock_test_attempts', 2, 'user_id', 'uuid', true, NULL, '', ''),
    ('public', 'mock_test_attempts', 3, 'mode', 'text', true, NULL, '', ''),
    ('public', 'mock_test_attempts', 4, 'exam_year', 'integer', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 5, 'session', 'text', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 6, 'subject', 'text', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 7, 'chapter', 'text', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 8, 'duration_seconds', 'integer', true, NULL, '', ''),
    ('public', 'mock_test_attempts', 9, 'question_ids', 'uuid[]', true, NULL, '', ''),
    ('public', 'mock_test_attempts', 10, 'total_questions', 'integer', true, NULL, '', ''),
    ('public', 'mock_test_attempts', 11, 'status', 'text', true, '''in_progress''::text', '', ''),
    ('public', 'mock_test_attempts', 12, 'started_at', 'timestamp with time zone', true, 'now()', '', ''),
    ('public', 'mock_test_attempts', 13, 'submitted_at', 'timestamp with time zone', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 14, 'attempted_count', 'integer', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 15, 'correct_count', 'integer', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 16, 'wrong_count', 'integer', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 17, 'score', 'integer', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 18, 'max_score', 'integer', false, NULL, '', ''),
    ('public', 'mock_test_attempts', 19, 'created_at', 'timestamp with time zone', true, 'now()', '', '')
  ), actual AS (
    SELECT n.nspname AS schema_name, c.relname AS table_name, a.attnum AS ordinal_position,
           a.attname AS column_name, pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
           a.attnotnull AS not_null, pg_catalog.pg_get_expr(d.adbin, d.adrelid) AS default_expr,
           a.attidentity AS identity_kind, a.attgenerated AS generated_kind
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_catalog.pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
    WHERE n.nspname IN ('public', 'private')
      AND c.relkind IN ('r', 'p')
      AND a.attnum > 0 AND NOT a.attisdropped
  ), differences AS (
    (SELECT 'missing_or_different: ' || e.schema_name || '.' || e.table_name || '.' || e.column_name AS detail
     FROM expected e LEFT JOIN actual a USING (schema_name, table_name, ordinal_position, column_name)
     WHERE a.column_name IS NULL OR (e.data_type, e.not_null, e.default_expr, e.identity_kind, e.generated_kind)
       IS DISTINCT FROM (a.data_type, a.not_null, a.default_expr, a.identity_kind, a.generated_kind))
    UNION ALL
    (SELECT 'unexpected_column: ' || a.schema_name || '.' || a.table_name || '.' || a.column_name AS detail
     FROM actual a LEFT JOIN expected e USING (schema_name, table_name, ordinal_position, column_name)
     WHERE e.column_name IS NULL)
  )
  SELECT string_agg(detail, E'\\n' ORDER BY detail) INTO mismatches FROM differences;
  IF mismatches IS NOT NULL THEN
    RAISE EXCEPTION 'Live column-shape snapshot mismatch:%', E'\\n' || mismatches;
  END IF;
END;
$test$;

SELECT 'PASS: all 93 live column definitions match the captured reconstruction snapshot' AS column_shape_contract;
