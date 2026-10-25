-- Exact current live public RLS policy snapshot captured through read-only pg_policies inspection on 2026-10-25.
-- Run only against the disposable reconstruction replay after reconstructed policies are applied.
-- This checks policy command, mode, role set, USING expression, and WITH CHECK expression.
DO $test$
DECLARE
  mismatches text;
BEGIN
  WITH expected(schema_name, table_name, policy_name, permissive, roles, command, using_expression, check_expression) AS (
    VALUES
      ('public', 'daily_challenge_attempts', 'Users read their own challenge attempts', 'PERMISSIVE', ARRAY['authenticated']::name[], 'SELECT',
       $$((user_id = ( SELECT auth.uid() AS uid)) OR (((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text))$$, NULL::text),
      ('public', 'daily_challenges', 'Admins delete challenges', 'PERMISSIVE', ARRAY['authenticated']::name[], 'DELETE',
       $$(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text)$$, NULL::text),
      ('public', 'daily_challenges', 'Admins insert challenges', 'PERMISSIVE', ARRAY['authenticated']::name[], 'INSERT',
       NULL::text, $$(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text)$$),
      ('public', 'daily_challenges', 'Admins update challenges', 'PERMISSIVE', ARRAY['authenticated']::name[], 'UPDATE',
       $$(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text)$$,
       $$(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text)$$),
      ('public', 'daily_challenges', 'Live challenge schedule is readable', 'PERMISSIVE', ARRAY['anon','authenticated']::name[], 'SELECT',
       $$((is_live = true) OR (((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text))$$, NULL::text),
      ('public', 'jee_pyq_questions', 'Admins delete PYQs', 'PERMISSIVE', ARRAY['authenticated']::name[], 'DELETE',
       $$(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text)$$, NULL::text),
      ('public', 'jee_pyq_questions', 'Admins insert PYQs', 'PERMISSIVE', ARRAY['authenticated']::name[], 'INSERT',
       NULL::text, $$(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text)$$),
      ('public', 'jee_pyq_questions', 'Admins update PYQs', 'PERMISSIVE', ARRAY['authenticated']::name[], 'UPDATE',
       $$(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text)$$,
       $$(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text)$$),
      ('public', 'jee_pyq_questions', 'Published PYQs and admin review queue are readable', 'PERMISSIVE', ARRAY['anon','authenticated']::name[], 'SELECT',
       $$((is_published AND (review_status = 'approved'::text)) OR (((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text) = 'admin'::text))$$, NULL::text),
      ('public', 'mock_test_attempts', 'Users can read own mock test attempts', 'PERMISSIVE', ARRAY['authenticated']::name[], 'SELECT',
       $$(user_id = ( SELECT auth.uid() AS uid))$$, NULL::text)
  ), actual AS (
    SELECT schemaname AS schema_name, tablename AS table_name, policyname AS policy_name,
           permissive, roles, cmd AS command, qual AS using_expression, with_check AS check_expression
    FROM pg_policies
    WHERE schemaname = 'public'
  ), differences AS (
    (SELECT 'missing_or_different_policy: ' || e.table_name || '.' || e.policy_name AS detail
     FROM expected e LEFT JOIN actual a USING (schema_name, table_name, policy_name)
     WHERE a.policy_name IS NULL
        OR (e.permissive, e.roles, e.command, e.using_expression, e.check_expression)
           IS DISTINCT FROM
           (a.permissive, a.roles, a.command, a.using_expression, a.check_expression))
    UNION ALL
    (SELECT 'unexpected_policy: ' || a.table_name || '.' || a.policy_name AS detail
     FROM actual a LEFT JOIN expected e USING (schema_name, table_name, policy_name)
     WHERE e.policy_name IS NULL)
  )
  SELECT string_agg(detail, E'\n' ORDER BY detail) INTO mismatches FROM differences;

  IF mismatches IS NOT NULL THEN
    RAISE EXCEPTION 'Live RLS policy snapshot mismatch:%', E'\n' || mismatches;
  END IF;
END;
$test$;

SELECT 'PASS: all 10 public RLS policy definitions match the captured live snapshot' AS rls_policy_definition_contract;
