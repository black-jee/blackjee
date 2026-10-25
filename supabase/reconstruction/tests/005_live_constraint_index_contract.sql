-- Read-only live catalog snapshot captured on 2026-10-25. Run only in the
-- disposable reconstruction replay before branch-only hardening migrations.
-- This checks all 49 constraints and 23 indexes, including definitions and flags.
DO $test$
DECLARE
  mismatches text;
BEGIN
  WITH expected(schema_name, table_name, constraint_name, constraint_type, definition, is_deferrable, is_deferred, is_validated) AS (
    VALUES
    ('private', 'daily_challenge_answer_keys', 'daily_challenge_answer_keys_challenge_id_fkey', 'f', 'FOREIGN KEY (challenge_id) REFERENCES daily_challenges(id) ON DELETE CASCADE', false, false, true),
    ('private', 'daily_challenge_answer_keys', 'daily_challenge_answer_keys_correct_answer_nonempty', 'c', 'CHECK (length(TRIM(BOTH FROM correct_answer)) > 0)', false, false, true),
    ('private', 'daily_challenge_answer_keys', 'daily_challenge_answer_keys_pkey', 'p', 'PRIMARY KEY (challenge_id)', false, false, true),
    ('private', 'daily_challenge_sessions', 'daily_challenge_sessions_challenge_id_fkey', 'f', 'FOREIGN KEY (challenge_id) REFERENCES daily_challenges(id) ON DELETE CASCADE', false, false, true),
    ('private', 'daily_challenge_sessions', 'daily_challenge_sessions_pkey', 'p', 'PRIMARY KEY (challenge_id, user_id)', false, false, true),
    ('private', 'daily_challenge_sessions', 'daily_challenge_sessions_user_id_fkey', 'f', 'FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE', false, false, true),
    ('private', 'jee_pyq_answer_attempts', 'jee_pyq_answer_attempts_pkey', 'p', 'PRIMARY KEY (user_id, question_id)', false, false, true),
    ('private', 'jee_pyq_answer_attempts', 'jee_pyq_answer_attempts_question_id_fkey', 'f', 'FOREIGN KEY (question_id) REFERENCES jee_pyq_questions(id) ON DELETE CASCADE', false, false, true),
    ('private', 'jee_pyq_answer_attempts', 'jee_pyq_answer_attempts_user_id_fkey', 'f', 'FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE', false, false, true),
    ('private', 'jee_pyq_answer_attempts', 'jee_pyq_answer_attempts_wrong_attempts_check', 'c', 'CHECK (wrong_attempts >= 0 AND wrong_attempts <= 2)', false, false, true),
    ('private', 'jee_pyq_answer_keys', 'jee_pyq_answer_keys_correct_answer_nonempty', 'c', 'CHECK (length(TRIM(BOTH FROM correct_answer)) > 0)', false, false, true),
    ('private', 'jee_pyq_answer_keys', 'jee_pyq_answer_keys_pkey', 'p', 'PRIMARY KEY (question_id)', false, false, true),
    ('private', 'jee_pyq_answer_keys', 'jee_pyq_answer_keys_question_id_fkey', 'f', 'FOREIGN KEY (question_id) REFERENCES jee_pyq_questions(id) ON DELETE CASCADE', false, false, true),
    ('private', 'mock_test_responses', 'mock_test_responses_attempt_id_fkey', 'f', 'FOREIGN KEY (attempt_id) REFERENCES mock_test_attempts(id) ON DELETE CASCADE', false, false, true),
    ('private', 'mock_test_responses', 'mock_test_responses_pkey', 'p', 'PRIMARY KEY (attempt_id, question_id)', false, false, true),
    ('private', 'mock_test_responses', 'mock_test_responses_question_id_fkey', 'f', 'FOREIGN KEY (question_id) REFERENCES jee_pyq_questions(id) ON DELETE RESTRICT', false, false, true),
    ('public', 'daily_challenge_attempts', 'daily_challenge_attempts_challenge_id_fkey', 'f', 'FOREIGN KEY (challenge_id) REFERENCES daily_challenges(id) ON DELETE CASCADE', false, false, true),
    ('public', 'daily_challenge_attempts', 'daily_challenge_attempts_challenge_id_user_id_key', 'u', 'UNIQUE (challenge_id, user_id)', false, false, true),
    ('public', 'daily_challenge_attempts', 'daily_challenge_attempts_elapsed_seconds_check', 'c', 'CHECK (elapsed_seconds >= 0 AND elapsed_seconds <= 86400)', false, false, true),
    ('public', 'daily_challenge_attempts', 'daily_challenge_attempts_pkey', 'p', 'PRIMARY KEY (id)', false, false, true),
    ('public', 'daily_challenge_attempts', 'daily_challenge_attempts_user_id_fkey', 'f', 'FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE', false, false, true),
    ('public', 'daily_challenges', 'daily_challenges_challenge_date_key', 'u', 'UNIQUE (challenge_date)', false, false, true),
    ('public', 'daily_challenges', 'daily_challenges_check', 'c', 'CHECK (starts_at < ends_at AND ends_at <= solution_release_at)', false, false, true),
    ('public', 'daily_challenges', 'daily_challenges_created_by_fkey', 'f', 'FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL', false, false, true),
    ('public', 'daily_challenges', 'daily_challenges_options_check', 'c', 'CHECK (jsonb_typeof(options) = ''array''::text)', false, false, true),
    ('public', 'daily_challenges', 'daily_challenges_pkey', 'p', 'PRIMARY KEY (id)', false, false, true),
    ('public', 'daily_challenges', 'daily_challenges_statement_image_path_safe', 'c', 'CHECK (statement_image_path IS NULL OR statement_image_path !~ ''(^/|//|(^|/)[.][.](/|$)|[^A-Za-z0-9._/-])''::text)', false, false, true),
    ('public', 'daily_challenges', 'daily_challenges_subject_check', 'c', 'CHECK (subject = ANY (ARRAY[''Physics''::text, ''Chemistry''::text, ''Mathematics''::text, ''Mixed''::text]))', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_marks_check', 'c', 'CHECK (marks_correct > 0 AND marks_wrong <= 0)', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_question_type_check', 'c', 'CHECK (question_type = ANY (ARRAY[''single_correct''::text, ''numerical''::text]))', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_questions_created_by_fkey', 'f', 'FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_questions_difficulty_check', 'c', 'CHECK (difficulty = ANY (ARRAY[''Main''::text, ''Advanced''::text, ''Mixed''::text]))', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_questions_options_check', 'c', 'CHECK (jsonb_typeof(options) = ''array''::text)', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_questions_pkey', 'p', 'PRIMARY KEY (id)', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_questions_review_status_check', 'c', 'CHECK (review_status = ANY (ARRAY[''draft''::text, ''in_review''::text, ''approved''::text, ''rejected''::text]))', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_questions_reviewed_by_fkey', 'f', 'FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_questions_source_id_key', 'u', 'UNIQUE (source_id)', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_questions_statement_image_path_safe', 'c', 'CHECK (statement_image_path IS NULL OR statement_image_path !~ ''(^/|//|(^|/)[.][.](/|$)|[^A-Za-z0-9._/-])''::text)', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_questions_subject_check', 'c', 'CHECK (subject = ANY (ARRAY[''Physics''::text, ''Chemistry''::text, ''Mathematics''::text]))', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_questions_year_check', 'c', 'CHECK (year >= 2002 AND year <= 2100)', false, false, true),
    ('public', 'jee_pyq_questions', 'jee_pyq_source_status_check', 'c', 'CHECK (source_status = ANY (ARRAY[''awaiting_source''::text, ''content_added''::text, ''needs_review''::text, ''verified_draft''::text, ''approved_for_publish''::text, ''not_verified''::text]))', false, false, true),
    ('public', 'jee_pyq_questions', 'published_questions_must_be_approved', 'c', 'CHECK (NOT is_published OR review_status = ''approved''::text)', false, false, true),
    ('public', 'mock_test_attempts', 'mock_test_attempts_check', 'c', 'CHECK (status = ''in_progress''::text AND submitted_at IS NULL OR status = ''submitted''::text AND submitted_at IS NOT NULL)', false, false, true),
    ('public', 'mock_test_attempts', 'mock_test_attempts_duration_seconds_check', 'c', 'CHECK (duration_seconds >= 0 AND duration_seconds <= 10800)', false, false, true),
    ('public', 'mock_test_attempts', 'mock_test_attempts_mode_check', 'c', 'CHECK (mode = ANY (ARRAY[''shift''::text, ''focused''::text]))', false, false, true),
    ('public', 'mock_test_attempts', 'mock_test_attempts_pkey', 'p', 'PRIMARY KEY (id)', false, false, true),
    ('public', 'mock_test_attempts', 'mock_test_attempts_status_check', 'c', 'CHECK (status = ANY (ARRAY[''in_progress''::text, ''submitted''::text]))', false, false, true),
    ('public', 'mock_test_attempts', 'mock_test_attempts_total_questions_check', 'c', 'CHECK (total_questions >= 1 AND total_questions <= 75)', false, false, true),
    ('public', 'mock_test_attempts', 'mock_test_attempts_user_id_fkey', 'f', 'FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE', false, false, true)
  ), actual AS (
    SELECT n.nspname AS schema_name, c.relname AS table_name, con.conname AS constraint_name,
           con.contype AS constraint_type, pg_catalog.pg_get_constraintdef(con.oid, true) AS definition,
           con.condeferrable AS is_deferrable, con.condeferred AS is_deferred, con.convalidated AS is_validated
    FROM pg_catalog.pg_constraint con
    JOIN pg_catalog.pg_class c ON c.oid = con.conrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'private')
  ), differences AS (
    (SELECT 'missing_or_different_constraint: ' || e.schema_name || '.' || e.table_name || '.' || e.constraint_name AS detail
     FROM expected e LEFT JOIN actual a USING (schema_name, table_name, constraint_name)
     WHERE a.constraint_name IS NULL OR (e.constraint_type, e.definition, e.is_deferrable, e.is_deferred, e.is_validated)
       IS DISTINCT FROM (a.constraint_type, a.definition, a.is_deferrable, a.is_deferred, a.is_validated))
    UNION ALL
    (SELECT 'unexpected_constraint: ' || a.schema_name || '.' || a.table_name || '.' || a.constraint_name AS detail
     FROM actual a LEFT JOIN expected e USING (schema_name, table_name, constraint_name)
     WHERE e.constraint_name IS NULL)
  )
  SELECT string_agg(detail, E'\\n' ORDER BY detail) INTO mismatches FROM differences;
  IF mismatches IS NOT NULL THEN
    RAISE EXCEPTION 'Live constraint snapshot mismatch:%', E'\\n' || mismatches;
  END IF;
END;
$test$;

DO $test$
DECLARE
  mismatches text;
BEGIN
  WITH expected(schema_name, table_name, index_schema, index_name, definition, predicate, is_unique, is_primary, is_valid, is_ready, key_attributes, total_attributes) AS (
    VALUES
    ('private', 'daily_challenge_answer_keys', 'private', 'daily_challenge_answer_keys_pkey', 'CREATE UNIQUE INDEX daily_challenge_answer_keys_pkey ON private.daily_challenge_answer_keys USING btree (challenge_id)', NULL, true, true, true, true, 1, 1),
    ('private', 'daily_challenge_sessions', 'private', 'daily_challenge_sessions_pkey', 'CREATE UNIQUE INDEX daily_challenge_sessions_pkey ON private.daily_challenge_sessions USING btree (challenge_id, user_id)', NULL, true, true, true, true, 2, 2),
    ('private', 'daily_challenge_sessions', 'private', 'daily_challenge_sessions_user_id_idx', 'CREATE INDEX daily_challenge_sessions_user_id_idx ON private.daily_challenge_sessions USING btree (user_id)', NULL, false, false, true, true, 1, 1),
    ('private', 'jee_pyq_answer_attempts', 'private', 'jee_pyq_answer_attempts_pkey', 'CREATE UNIQUE INDEX jee_pyq_answer_attempts_pkey ON private.jee_pyq_answer_attempts USING btree (user_id, question_id)', NULL, true, true, true, true, 2, 2),
    ('private', 'jee_pyq_answer_attempts', 'private', 'jee_pyq_answer_attempts_question_idx', 'CREATE INDEX jee_pyq_answer_attempts_question_idx ON private.jee_pyq_answer_attempts USING btree (question_id)', NULL, false, false, true, true, 1, 1),
    ('private', 'jee_pyq_answer_keys', 'private', 'jee_pyq_answer_keys_pkey', 'CREATE UNIQUE INDEX jee_pyq_answer_keys_pkey ON private.jee_pyq_answer_keys USING btree (question_id)', NULL, true, true, true, true, 1, 1),
    ('private', 'mock_test_responses', 'private', 'mock_test_responses_pkey', 'CREATE UNIQUE INDEX mock_test_responses_pkey ON private.mock_test_responses USING btree (attempt_id, question_id)', NULL, true, true, true, true, 2, 2),
    ('public', 'daily_challenge_attempts', 'public', 'daily_attempt_user_idx', 'CREATE INDEX daily_attempt_user_idx ON public.daily_challenge_attempts USING btree (user_id, submitted_at DESC)', NULL, false, false, true, true, 2, 2),
    ('public', 'daily_challenge_attempts', 'public', 'daily_challenge_attempts_challenge_id_user_id_key', 'CREATE UNIQUE INDEX daily_challenge_attempts_challenge_id_user_id_key ON public.daily_challenge_attempts USING btree (challenge_id, user_id)', NULL, true, false, true, true, 2, 2),
    ('public', 'daily_challenge_attempts', 'public', 'daily_challenge_attempts_pkey', 'CREATE UNIQUE INDEX daily_challenge_attempts_pkey ON public.daily_challenge_attempts USING btree (id)', NULL, true, true, true, true, 1, 1),
    ('public', 'daily_challenges', 'public', 'daily_challenges_challenge_date_key', 'CREATE UNIQUE INDEX daily_challenges_challenge_date_key ON public.daily_challenges USING btree (challenge_date)', NULL, true, false, true, true, 1, 1),
    ('public', 'daily_challenges', 'public', 'daily_challenges_created_by_idx', 'CREATE INDEX daily_challenges_created_by_idx ON public.daily_challenges USING btree (created_by)', NULL, false, false, true, true, 1, 1),
    ('public', 'daily_challenges', 'public', 'daily_challenges_live_idx', 'CREATE INDEX daily_challenges_live_idx ON public.daily_challenges USING btree (is_live, starts_at, ends_at)', NULL, false, false, true, true, 3, 3),
    ('public', 'daily_challenges', 'public', 'daily_challenges_pkey', 'CREATE UNIQUE INDEX daily_challenges_pkey ON public.daily_challenges USING btree (id)', NULL, true, true, true, true, 1, 1),
    ('public', 'jee_pyq_questions', 'public', 'jee_pyq_created_by_idx', 'CREATE INDEX jee_pyq_created_by_idx ON public.jee_pyq_questions USING btree (created_by)', NULL, false, false, true, true, 1, 1),
    ('public', 'jee_pyq_questions', 'public', 'jee_pyq_paper_lookup_idx', 'CREATE INDEX jee_pyq_paper_lookup_idx ON public.jee_pyq_questions USING btree (year, session, subject, question_type) WHERE ((is_published = true) AND (review_status = ''approved''::text))', '((is_published = true) AND (review_status = ''approved''::text))', false, false, true, true, 4, 4),
    ('public', 'jee_pyq_questions', 'public', 'jee_pyq_questions_pkey', 'CREATE UNIQUE INDEX jee_pyq_questions_pkey ON public.jee_pyq_questions USING btree (id)', NULL, true, true, true, true, 1, 1),
    ('public', 'jee_pyq_questions', 'public', 'jee_pyq_questions_source_id_key', 'CREATE UNIQUE INDEX jee_pyq_questions_source_id_key ON public.jee_pyq_questions USING btree (source_id)', NULL, true, false, true, true, 1, 1),
    ('public', 'jee_pyq_questions', 'public', 'jee_pyq_review_queue_idx', 'CREATE INDEX jee_pyq_review_queue_idx ON public.jee_pyq_questions USING btree (review_status, created_at DESC)', NULL, false, false, true, true, 2, 2),
    ('public', 'jee_pyq_questions', 'public', 'jee_pyq_reviewed_by_idx', 'CREATE INDEX jee_pyq_reviewed_by_idx ON public.jee_pyq_questions USING btree (reviewed_by)', NULL, false, false, true, true, 1, 1),
    ('public', 'jee_pyq_questions', 'public', 'jee_pyq_subject_year_idx', 'CREATE INDEX jee_pyq_subject_year_idx ON public.jee_pyq_questions USING btree (subject, year DESC) WHERE is_published', 'is_published', false, false, true, true, 2, 2),
    ('public', 'mock_test_attempts', 'public', 'mock_test_attempts_pkey', 'CREATE UNIQUE INDEX mock_test_attempts_pkey ON public.mock_test_attempts USING btree (id)', NULL, true, true, true, true, 1, 1),
    ('public', 'mock_test_attempts', 'public', 'mock_test_attempts_user_created_idx', 'CREATE INDEX mock_test_attempts_user_created_idx ON public.mock_test_attempts USING btree (user_id, created_at DESC)', NULL, false, false, true, true, 2, 2)
  ), actual AS (
    SELECT nt.nspname AS schema_name, t.relname AS table_name, ni.nspname AS index_schema, i.relname AS index_name,
           pg_catalog.pg_get_indexdef(i.oid) AS definition, pg_catalog.pg_get_expr(x.indpred, x.indrelid) AS predicate,
           x.indisunique AS is_unique, x.indisprimary AS is_primary, x.indisvalid AS is_valid, x.indisready AS is_ready,
           x.indnkeyatts AS key_attributes, x.indnatts AS total_attributes
    FROM pg_catalog.pg_index x
    JOIN pg_catalog.pg_class t ON t.oid = x.indrelid
    JOIN pg_catalog.pg_namespace nt ON nt.oid = t.relnamespace
    JOIN pg_catalog.pg_class i ON i.oid = x.indexrelid
    JOIN pg_catalog.pg_namespace ni ON ni.oid = i.relnamespace
    WHERE nt.nspname IN ('public', 'private')
  ), differences AS (
    (SELECT 'missing_or_different_index: ' || e.index_schema || '.' || e.index_name AS detail
     FROM expected e LEFT JOIN actual a USING (schema_name, table_name, index_schema, index_name)
     WHERE a.index_name IS NULL OR (e.definition, e.predicate, e.is_unique, e.is_primary, e.is_valid, e.is_ready, e.key_attributes, e.total_attributes)
       IS DISTINCT FROM (a.definition, a.predicate, a.is_unique, a.is_primary, a.is_valid, a.is_ready, a.key_attributes, a.total_attributes))
    UNION ALL
    (SELECT 'unexpected_index: ' || a.index_schema || '.' || a.index_name AS detail
     FROM actual a LEFT JOIN expected e USING (schema_name, table_name, index_schema, index_name)
     WHERE e.index_name IS NULL)
  )
  SELECT string_agg(detail, E'\\n' ORDER BY detail) INTO mismatches FROM differences;
  IF mismatches IS NOT NULL THEN
    RAISE EXCEPTION 'Live index snapshot mismatch:%', E'\\n' || mismatches;
  END IF;
END;
$test$;

SELECT 'PASS: all 49 constraint definitions and 23 index definitions match the live snapshot' AS structural_definition_contract;
