-- Database-level option-label validation must protect writes beyond the UI schema.
DO $$
DECLARE
  v_message text;
  v_id uuid;
BEGIN
  BEGIN
    INSERT INTO public.jee_pyq_questions
      (source_id, title, statement, subject, question_type, options)
    VALUES
      ('BJ-CI-DUPLICATE-' || gen_random_uuid()::text, 'Synthetic validation fixture',
       'Synthetic validation fixture only', 'Physics', 'single_correct',
       '[{"label":"A","text":"first"},{"label":"a","text":"duplicate"}]'::jsonb);
    RAISE EXCEPTION 'Duplicate option labels unexpectedly succeeded';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
    IF v_message <> 'Single-correct option labels must be unique' THEN
      RAISE EXCEPTION 'Unexpected duplicate-label error: %', v_message;
    END IF;
  END;

  BEGIN
    INSERT INTO public.jee_pyq_questions
      (source_id, title, statement, subject, question_type, options)
    VALUES
      ('BJ-CI-BLANK-LABEL-' || gen_random_uuid()::text, 'Synthetic validation fixture',
       'Synthetic validation fixture only', 'Physics', 'single_correct',
       '[{"label":" ","text":"blank"},{"label":"B","text":"second"}]'::jsonb);
    RAISE EXCEPTION 'Blank option label unexpectedly succeeded';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
    IF v_message <> 'Single-correct options need non-empty labels' THEN
      RAISE EXCEPTION 'Unexpected blank-label error: %', v_message;
    END IF;
  END;

  INSERT INTO public.jee_pyq_questions
    (source_id, title, statement, subject, question_type, options)
  VALUES
    ('BJ-CI-VALID-LABELS-' || gen_random_uuid()::text, 'Synthetic validation fixture',
     'Synthetic validation fixture only', 'Physics', 'single_correct',
     '[{"label":"A","text":"first"},{"label":"B","text":"second"}]'::jsonb)
  RETURNING id INTO v_id;

  DELETE FROM public.jee_pyq_questions WHERE id = v_id;
END;
$$;
