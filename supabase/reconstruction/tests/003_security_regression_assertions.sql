-- BLACK-JEE security regression assertions — READ ONLY.
-- Intended for a disposable reconstruction replay. Catalog-only assertions;
-- no application data is inserted, updated, or deleted.
-- This does not replace authenticated-user negative tests against RPC calls.

DO $security$
DECLARE
  v_count integer;
  v_missing text;
BEGIN
  -- Require the known privileged RPC set, safe search_path, and no anon/PUBLIC
  -- EXECUTE grants. Authenticated EXECUTE is intentional only because each
  -- RPC must enforce authorization inside its own body.
  WITH expected(name) AS (
    VALUES
      ('admin_review_jee_pyq_question'),
      ('admin_save_daily_challenge'),
      ('admin_save_jee_pyq_question'),
      ('get_daily_challenge_result'),
      ('get_mock_test_result'),
      ('grade_jee_pyq'),
      ('resume_mock_test'),
      ('start_daily_challenge'),
      ('start_mock_test'),
      ('submit_daily_challenge'),
      ('submit_mock_test')
  ),
  observed AS (
    SELECT e.name, p.oid, p.prosecdef, p.proconfig,
           EXISTS (
             SELECT 1 FROM aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
             WHERE a.grantee = 0 AND a.privilege_type = 'EXECUTE'
           ) AS public_execute,
           has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_execute
    FROM expected e
    LEFT JOIN pg_proc p ON p.pronamespace = 'public'::regnamespace
                       AND p.proname = e.name
  )
  SELECT count(*) FILTER (WHERE oid IS NOT NULL),
         string_agg(name, ', ' ORDER BY name) FILTER (
           WHERE oid IS NULL OR NOT prosecdef
              OR NOT coalesce(proconfig @> ARRAY['search_path=""'], false)
              OR public_execute OR anon_execute
              OR pg_get_functiondef(oid) NOT LIKE '%auth.uid()%'
         )
  INTO v_count, v_missing
  FROM observed;

  IF v_count <> 11 THEN
    RAISE EXCEPTION 'Expected 11 privileged RPCs; found %', v_count;
  END IF;
  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'Privileged RPC attributes/ACL mismatch: %', v_missing;
  END IF;

  -- Admin authoring/review RPCs must keep a server-managed role check.
  SELECT string_agg(e.name, ', ' ORDER BY e.name)
  INTO v_missing
  FROM (VALUES
    ('admin_review_jee_pyq_question'),
    ('admin_save_daily_challenge'),
    ('admin_save_jee_pyq_question')
  ) e(name)
  WHERE NOT EXISTS (
    SELECT 1 FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proname = e.name
      AND pg_get_functiondef(p.oid) LIKE '%auth.uid()%'
      AND pg_get_functiondef(p.oid) LIKE '%app_metadata%'
      AND pg_get_functiondef(p.oid) LIKE '%admin%'
  );
  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'Admin RPC authorization guard missing from: %', v_missing;
  END IF;

  -- Browser roles must not enter the private schema or read its tables/columns
  -- directly; privileged functions are the intended controlled access path.
  IF has_schema_privilege('anon', 'private', 'USAGE')
     OR has_schema_privilege('authenticated', 'private', 'USAGE') THEN
    RAISE EXCEPTION 'Browser roles must not have USAGE on private schema';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.role_table_grants g
    WHERE g.table_schema = 'private' AND g.grantee IN ('anon', 'authenticated')
  ) OR EXISTS (
    SELECT 1 FROM information_schema.column_privileges g
    WHERE g.table_schema = 'private' AND g.grantee IN ('anon', 'authenticated')
  ) THEN
    RAISE EXCEPTION 'Browser roles have direct privileges on private tables/columns';
  END IF;

  -- Public RLS policy count and key authorization predicates must not drift.
  SELECT count(*) INTO v_count FROM pg_policies WHERE schemaname = 'public';
  IF v_count <> 10 THEN
    RAISE EXCEPTION 'Expected exactly 10 public RLS policies; found %', v_count;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'jee_pyq_questions'
      AND policyname = 'Published PYQs and admin review queue are readable'
      AND roles @> ARRAY['anon','authenticated']::name[]
      AND qual LIKE '%is_published%'
      AND qual LIKE '%approved%'
      AND qual LIKE '%app_metadata%'
  ) THEN
    RAISE EXCEPTION 'Published-PYQ read policy is missing or its access predicate drifted';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'daily_challenges'
      AND policyname = 'Live challenge schedule is readable'
      AND roles @> ARRAY['anon','authenticated']::name[]
      AND qual LIKE '%is_live%'
      AND qual LIKE '%app_metadata%'
  ) THEN
    RAISE EXCEPTION 'Daily-challenge schedule policy is missing or its access predicate drifted';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'mock_test_attempts'
      AND policyname = 'Users can read own mock test attempts'
      AND qual LIKE '%auth.uid()%'
      AND qual LIKE '%user_id%'
  ) THEN
    RAISE EXCEPTION 'Mock-test attempt ownership policy is missing or drifted';
  END IF;

  -- Column-level grants are intentional: PYQ content is directly queryable,
  -- while daily-challenge question text/options must stay behind the session RPC.
  IF NOT has_column_privilege('anon', 'public.jee_pyq_questions', 'statement', 'SELECT')
     OR NOT has_column_privilege('authenticated', 'public.jee_pyq_questions', 'statement', 'SELECT') THEN
    RAISE EXCEPTION 'Expected anon/authenticated column SELECT on public PYQ statement';
  END IF;

  IF has_column_privilege('anon', 'public.daily_challenges', 'statement', 'SELECT')
     OR has_column_privilege('anon', 'public.daily_challenges', 'options', 'SELECT')
     OR has_column_privilege('authenticated', 'public.daily_challenges', 'statement', 'SELECT')
     OR has_column_privilege('authenticated', 'public.daily_challenges', 'options', 'SELECT') THEN
    RAISE EXCEPTION 'Daily-challenge statement/options must not be directly readable by browser roles';
  END IF;

  -- Private tables currently have no policies because browser roles have no
  -- schema access. Any policy change requires an explicit model review.
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'private') THEN
    RAISE EXCEPTION 'Private-schema RLS policy inventory changed; review security model';
  END IF;
END;
$security$;

SELECT 'PASS: privileged RPC attributes, admin guards, private-schema isolation, and column grants' AS security_regression_assertions;
