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

  -- Private tables currently have no policies because browser roles have no
  -- schema access. Any policy change requires an explicit model review.
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'private') THEN
    RAISE EXCEPTION 'Private-schema RLS policy inventory changed; review security model';
  END IF;
END;
$security$;

SELECT 'PASS: privileged RPC attributes, admin guards, and private-schema browser isolation' AS security_regression_assertions;
