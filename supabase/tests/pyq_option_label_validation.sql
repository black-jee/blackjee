-- Database-level option-label validation must protect writes beyond the UI schema.
DO $$
DECLARE
  v_message text;
  v_id uuid;
  v_numerical_id uuid;
BEGIN
  BEGIN
    INSERT INTO public.jee_pyq_questions
      (source_id, title, statement, subject, question_type, options)
    VALUES
      ('BJ-CI-NON-ARRAY-' || gen_random_uuid()::text, 'Synthetic validation fixture',
       'Synthetic validation fixture only', 'Physics', 'single_correct',
       '{"label":"A"}'::jsonb);
    RAISE EXCEPTION 'Non-array options unexpectedly succeeded';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
    IF v_message <> 'Single-correct questions need an options array' THEN
      RAISE EXCEPTION 'Unexpected non-array options error: %', v_message;
    END IF;
  END;

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

  BEGIN
    INSERT INTO public.jee_pyq_questions
      (source_id, title, statement, subject, question_type, options)
    VALUES
      ('BJ-CI-ONE-OPTION-' || gen_random_uuid()::text, 'Synthetic validation fixture',
       'Synthetic validation fixture only', 'Physics', 'single_correct',
       '[{"label":"A","text":"only option"}]'::jsonb);
    RAISE EXCEPTION 'Single option unexpectedly succeeded';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
    IF v_message <> 'Single-correct questions need at least two options' THEN
      RAISE EXCEPTION 'Unexpected one-option error: %', v_message;
    END IF;
  END;

  INSERT INTO public.jee_pyq_questions
    (source_id, title, statement, subject, question_type, options)
  VALUES
    ('BJ-CI-VALID-LABELS-' || gen_random_uuid()::text, 'Synthetic validation fixture',
     'Synthetic validation fixture only', 'Physics', 'single_correct',
     '[{"label":"A","text":"first"},{"label":"B","text":"second"}]'::jsonb)
  RETURNING id INTO v_id;

  -- The trigger must also protect updates, not just initial inserts.
  BEGIN
    UPDATE public.jee_pyq_questions
    SET options = '[{"label":"C","text":"first"},{"label":"c","text":"duplicate"}]'::jsonb
    WHERE id = v_id;
    RAISE EXCEPTION 'Duplicate labels on update unexpectedly succeeded';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_message = MESSAGE_TEXT;
    IF v_message <> 'Single-correct option labels must be unique' THEN
      RAISE EXCEPTION 'Unexpected duplicate-label update error: %', v_message;
    END IF;
  END;

  DELETE FROM public.jee_pyq_questions WHERE id = v_id;

  -- Numerical questions intentionally have no multiple-choice options.
  INSERT INTO public.jee_pyq_questions
    (source_id, title, statement, subject, question_type, options)
  VALUES
    ('BJ-CI-NUMERICAL-' || gen_random_uuid()::text, 'Synthetic validation fixture',
     'Synthetic validation fixture only', 'Mathematics', 'numerical', '[]'::jsonb)
  RETURNING id INTO v_numerical_id;

  DELETE FROM public.jee_pyq_questions WHERE id = v_numerical_id;
END;
$$;
