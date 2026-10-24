-- Enforce daily-challenge authoring integrity at the database boundary.
-- Forward-only hardening: do not edit historical migration files.
CREATE OR REPLACE FUNCTION public.admin_save_daily_challenge(
  p_challenge_id uuid,
  p_challenge_date date,
  p_title text,
  p_subject text,
  p_statement text,
  p_statement_image_path text,
  p_options jsonb,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_solution_release_at timestamptz,
  p_correct_answer text,
  p_solution text,
  p_is_live boolean
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_challenge_id uuid;
BEGIN
  IF v_user IS NULL OR coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') <> 'admin' THEN
    RAISE EXCEPTION 'Administrator access required' USING errcode = '42501';
  END IF;

  IF nullif(btrim(p_title), '') IS NULL
     OR nullif(btrim(p_statement), '') IS NULL
     OR nullif(btrim(p_correct_answer), '') IS NULL THEN
    RAISE EXCEPTION 'Title, statement and correct answer are required' USING errcode = '22023';
  END IF;

  IF coalesce(p_is_live, false) AND nullif(btrim(p_solution), '') IS NULL THEN
    RAISE EXCEPTION 'A live challenge must include a worked solution' USING errcode = '22023';
  END IF;

  IF p_starts_at >= p_ends_at OR p_ends_at > p_solution_release_at THEN
    RAISE EXCEPTION 'Challenge schedule times are invalid' USING errcode = '22023';
  END IF;

  IF p_options IS NULL OR jsonb_typeof(p_options) <> 'array' THEN
    RAISE EXCEPTION 'Options must be a JSON array' USING errcode = '22023';
  END IF;
  IF jsonb_array_length(p_options) > 12 THEN
    RAISE EXCEPTION 'A daily challenge can have at most 12 options' USING errcode = '22023';
  END IF;
  IF jsonb_array_length(p_options) > 0 AND EXISTS (
    SELECT 1
    FROM jsonb_array_elements(p_options) AS o(item)
    WHERE nullif(btrim(o.item->>'label'), '') IS NULL
  ) THEN
    RAISE EXCEPTION 'Daily challenge options need non-empty labels' USING errcode = '22023';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM jsonb_array_elements(p_options) AS o(item)
    GROUP BY upper(btrim(o.item->>'label'))
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'Daily challenge option labels must be unique' USING errcode = '22023';
  END IF;
  IF jsonb_array_length(p_options) > 0 AND NOT EXISTS (
    SELECT 1
    FROM jsonb_array_elements(p_options) AS o(item)
    WHERE upper(btrim(o.item->>'label')) = upper(btrim(p_correct_answer))
  ) THEN
    RAISE EXCEPTION 'Correct answer must match one of the option labels' USING errcode = '22023';
  END IF;

  IF p_challenge_id IS NULL THEN
    INSERT INTO public.daily_challenges (
      challenge_date, title, subject, statement, statement_image_path, options,
      starts_at, ends_at, solution_release_at, is_live, created_by
    ) VALUES (
      p_challenge_date, btrim(p_title), p_subject, p_statement, p_statement_image_path, p_options,
      p_starts_at, p_ends_at, p_solution_release_at, coalesce(p_is_live, false), v_user
    )
    RETURNING id INTO v_challenge_id;
  ELSE
    UPDATE public.daily_challenges
    SET challenge_date = p_challenge_date,
        title = btrim(p_title),
        subject = p_subject,
        statement = p_statement,
        statement_image_path = p_statement_image_path,
        options = p_options,
        starts_at = p_starts_at,
        ends_at = p_ends_at,
        solution_release_at = p_solution_release_at,
        is_live = coalesce(p_is_live, false)
    WHERE id = p_challenge_id
    RETURNING id INTO v_challenge_id;

    IF v_challenge_id IS NULL THEN
      RAISE EXCEPTION 'Challenge not found' USING errcode = 'P0002';
    END IF;
  END IF;

  INSERT INTO private.daily_challenge_answer_keys (challenge_id, correct_answer, solution)
  VALUES (v_challenge_id, upper(btrim(p_correct_answer)), coalesce(p_solution, ''))
  ON CONFLICT (challenge_id) DO UPDATE
    SET correct_answer = excluded.correct_answer,
        solution = excluded.solution;

  RETURN v_challenge_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean) TO authenticated;
