-- BLACK-JEE security regression assertions — READ ONLY.
-- Designed for a disposable reconstruction replay; also safe for live catalog audit.
-- Catalog-only assertions; no schema or application data is changed.
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

  -- Fingerprint reconstructed definitions that still match the captured live catalog.
  -- admin_save_daily_challenge intentionally includes reconstruction-only hardening;
  -- validate its new rules semantically below rather than comparing it to the live hash.
  SELECT string_agg(e.name, ', ' ORDER BY e.name)
  INTO v_missing
  FROM (VALUES
    ('admin_review_jee_pyq_question', 'c60ab9ab4141edcb615f475919cbf620'),
    ('admin_save_jee_pyq_question', '9de6669f0727df14fd0851895ee37466'),
    ('get_current_daily_challenge', 'ff76bf83a39b595544fe15f3475cd70b'),
    ('get_daily_challenge_result', 'ccb0c62728a64f6382ffdf9a8f2f63d8'),
    ('get_mock_test_result', '3be309fd8edd50c20e814a5a99fb5f51'),
    ('grade_jee_pyq', 'ffa56082434a79de6d37607fb225b145'),
    ('resume_mock_test', 'c14e3486e41e53f9aee6207093b380df'),
    ('start_daily_challenge', '6184a711c54ac02ef621064bb99fa8b4'),
    ('start_mock_test', '721ed05ba1d51a63a1af126da78f669f'),
    ('submit_daily_challenge', '9976c9390ebb5140757cc27e6afb02ec'),
    ('submit_mock_test', '33b381c7bb94b3b772ca5f90db196c5d')
  ) e(name, expected_md5)
  LEFT JOIN pg_proc p
    ON p.pronamespace = 'public'::regnamespace
   AND p.proname = e.name
  WHERE p.oid IS NULL OR md5(pg_get_functiondef(p.oid)) <> e.expected_md5;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'Reconstructed RPC definition fingerprints differ from the live catalog: %', v_missing;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proname = 'admin_save_daily_challenge'
      AND pg_get_functiondef(p.oid) LIKE '%A live challenge must include a worked solution%'
      AND pg_get_functiondef(p.oid) LIKE '%Daily challenge option labels must be unique%'
      AND pg_get_functiondef(p.oid) LIKE '%Correct answer must match one of the option labels%'
      AND pg_get_functiondef(p.oid) LIKE '%jsonb_array_length(p_options) > 12%'
  ) THEN
    RAISE EXCEPTION 'Reconstructed daily-challenge RPC is missing solution/options integrity guards';
  END IF;

  -- The anonymous schedule RPC must remain invoker-rights and metadata-only.
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proname = 'get_current_daily_challenge'
      AND NOT p.prosecdef
      AND has_function_privilege('anon', p.oid, 'EXECUTE')
      AND pg_get_functiondef(p.oid) NOT LIKE '%statement%'
      AND pg_get_functiondef(p.oid) NOT LIKE '%options%'
      AND pg_get_functiondef(p.oid) NOT LIKE '%statement_image_path%'
  ) THEN
    RAISE EXCEPTION 'Anonymous daily-challenge schedule RPC is missing or exposes question content';
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

  -- Check all observed policy names, tables, commands, and role sets, not only
  -- the three highest-impact read/ownership predicates checked below.
  SELECT string_agg(e.tablename || '.' || e.policyname, ', ' ORDER BY e.policyname)
  INTO v_missing
  FROM (VALUES
    ('daily_challenge_attempts', 'Users read their own challenge attempts', 'SELECT', ARRAY['authenticated']::name[]),
    ('daily_challenges', 'Admins delete challenges', 'DELETE', ARRAY['authenticated']::name[]),
    ('daily_challenges', 'Admins insert challenges', 'INSERT', ARRAY['authenticated']::name[]),
    ('daily_challenges', 'Admins update challenges', 'UPDATE', ARRAY['authenticated']::name[]),
    ('daily_challenges', 'Live challenge schedule is readable', 'SELECT', ARRAY['anon','authenticated']::name[]),
    ('jee_pyq_questions', 'Admins delete PYQs', 'DELETE', ARRAY['authenticated']::name[]),
    ('jee_pyq_questions', 'Admins insert PYQs', 'INSERT', ARRAY['authenticated']::name[]),
    ('jee_pyq_questions', 'Admins update PYQs', 'UPDATE', ARRAY['authenticated']::name[]),
    ('jee_pyq_questions', 'Published PYQs and admin review queue are readable', 'SELECT', ARRAY['anon','authenticated']::name[]),
    ('mock_test_attempts', 'Users can read own mock test attempts', 'SELECT', ARRAY['authenticated']::name[])
  ) AS e(tablename, policyname, cmd, expected_roles)
  LEFT JOIN pg_policies p
    ON p.schemaname = 'public'
   AND p.tablename = e.tablename
   AND p.policyname = e.policyname
  WHERE p.policyname IS NULL
     OR p.cmd <> e.cmd
     OR cardinality(p.roles) <> cardinality(e.expected_roles)
     OR NOT (p.roles @> e.expected_roles);

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'RLS policy name/table/command/role mismatch: %', v_missing;
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

  IF has_column_privilege('anon', 'public.daily_challenges', 'statement_image_path', 'SELECT')
     OR NOT has_column_privilege('authenticated', 'public.daily_challenges', 'statement_image_path', 'SELECT') THEN
    RAISE EXCEPTION 'Daily-challenge image path must be hidden from anon and available only to authenticated flow';
  END IF;

  -- Private tables currently have no policies because browser roles have no
  -- schema access. Any policy change requires an explicit model review.
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'private') THEN
    RAISE EXCEPTION 'Private-schema RLS policy inventory changed; review security model';
  END IF;
END;
$security$;

SELECT 'PASS: privileged RPC attributes, schedule RPC, admin guards, private-schema isolation, and column grants' AS security_regression_assertions;
