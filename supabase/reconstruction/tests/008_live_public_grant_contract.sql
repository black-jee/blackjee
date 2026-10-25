-- Exact browser-role public column-access snapshot captured through read-only privilege inspection on 2026-10-25.
-- Run only against the disposable reconstruction replay after reconstructed access grants.
-- This checks effective column SELECT boundaries and table-level attempt/authoring privileges.
DO $test$
DECLARE
  r record;
  c record;
  allowed boolean;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('anon', 'daily_challenges', ARRAY['id','challenge_date','title','subject','starts_at','ends_at','solution_release_at','is_live']::text[]),
      ('authenticated', 'daily_challenges', ARRAY['id','challenge_date','title','subject','starts_at','ends_at','is_live','statement_image_path']::text[]),
      ('anon', 'jee_pyq_questions', ARRAY['asset_paths','chapter','created_at','difficulty','exam','id','is_published','marks_correct','marks_wrong','options','question_type','review_status','session','source_id','source_page','source_pdf','source_reference','source_status','statement','statement_image_path','subject','tags','title','updated_at','year']::text[]),
      ('authenticated', 'jee_pyq_questions', ARRAY['asset_paths','chapter','created_at','difficulty','exam','id','is_published','marks_correct','marks_wrong','options','question_type','review_status','session','source_id','source_page','source_pdf','source_reference','source_status','statement','statement_image_path','subject','tags','title','updated_at','year']::text[])
    ) AS expected(role_name, table_name, allowed_columns)
  LOOP
    FOR c IN
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = r.table_name
    LOOP
      allowed := c.column_name = ANY(r.allowed_columns);
      IF has_column_privilege(r.role_name, format('public.%I', r.table_name), c.column_name, 'SELECT')
         IS DISTINCT FROM allowed THEN
        RAISE EXCEPTION 'Unexpected SELECT privilege: role %, table %, column %, expected allowed %',
          r.role_name, r.table_name, c.column_name, allowed;
      END IF;
    END LOOP;
  END LOOP;

  -- Attempt rows are table-readable only to authenticated users; RLS must still
  -- constrain those reads to the owning user.
  IF NOT has_table_privilege('authenticated', 'public.daily_challenge_attempts', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.mock_test_attempts', 'SELECT')
     OR has_table_privilege('anon', 'public.daily_challenge_attempts', 'SELECT')
     OR has_table_privilege('anon', 'public.mock_test_attempts', 'SELECT') THEN
    RAISE EXCEPTION 'Attempt table SELECT privilege boundary changed';
  END IF;

  -- Authenticated authoring writes remain granted at the table level and gated
  -- by the reviewed admin-only RLS policies. Anonymous writes are never allowed.
  IF NOT has_table_privilege('authenticated', 'public.daily_challenges', 'INSERT')
     OR NOT has_table_privilege('authenticated', 'public.daily_challenges', 'UPDATE')
     OR NOT has_table_privilege('authenticated', 'public.daily_challenges', 'DELETE')
     OR NOT has_table_privilege('authenticated', 'public.jee_pyq_questions', 'INSERT')
     OR NOT has_table_privilege('authenticated', 'public.jee_pyq_questions', 'UPDATE')
     OR NOT has_table_privilege('authenticated', 'public.jee_pyq_questions', 'DELETE') THEN
    RAISE EXCEPTION 'Authenticated authoring table-level write grants are missing';
  END IF;

  IF has_table_privilege('anon', 'public.daily_challenges', 'INSERT')
     OR has_table_privilege('anon', 'public.daily_challenges', 'UPDATE')
     OR has_table_privilege('anon', 'public.daily_challenges', 'DELETE')
     OR has_table_privilege('anon', 'public.jee_pyq_questions', 'INSERT')
     OR has_table_privilege('anon', 'public.jee_pyq_questions', 'UPDATE')
     OR has_table_privilege('anon', 'public.jee_pyq_questions', 'DELETE')
     OR has_table_privilege('authenticated', 'public.daily_challenge_attempts', 'INSERT')
     OR has_table_privilege('authenticated', 'public.daily_challenge_attempts', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.daily_challenge_attempts', 'DELETE')
     OR has_table_privilege('authenticated', 'public.mock_test_attempts', 'INSERT')
     OR has_table_privilege('authenticated', 'public.mock_test_attempts', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.mock_test_attempts', 'DELETE') THEN
    RAISE EXCEPTION 'Unexpected browser-role write privilege on a public table';
  END IF;

  IF NOT has_schema_privilege('anon', 'public', 'USAGE')
     OR NOT has_schema_privilege('authenticated', 'public', 'USAGE')
     OR has_schema_privilege('anon', 'public', 'CREATE')
     OR has_schema_privilege('authenticated', 'public', 'CREATE') THEN
    RAISE EXCEPTION 'Public schema usage/create privilege boundary changed';
  END IF;
END;
$test$;

SELECT 'PASS: public browser-role column reads and table-level writes match the captured grant contract' AS public_grant_contract;
