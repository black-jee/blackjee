-- Verify the question_id foreign key has a supporting leading-column index.
DO $$
DECLARE
  v_index_definition text;
BEGIN
  SELECT indexdef
  INTO v_index_definition
  FROM pg_indexes
  WHERE schemaname = 'private'
    AND tablename = 'mock_test_responses'
    AND indexname = 'mock_test_responses_question_id_idx';

  IF v_index_definition IS NULL THEN
    RAISE EXCEPTION 'Missing index private.mock_test_responses_question_id_idx';
  END IF;

  IF v_index_definition !~* '\\(question_id\\)' THEN
    RAISE EXCEPTION 'Question FK index must lead with question_id; got: %', v_index_definition;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'private'
      AND t.relname = 'mock_test_responses'
      AND c.conname = 'mock_test_responses_question_id_fkey'
      AND c.contype = 'f'
  ) THEN
    RAISE EXCEPTION 'Expected mock_test_responses_question_id_fkey to exist';
  END IF;
END;
$$;

SELECT 'PASS: mock_test_responses.question_id has a supporting index' AS fk_index_regression;
