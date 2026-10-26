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

  -- Exact effective table-level privilege matrix for all four public tables.
  -- PYQ and challenge schedule reads intentionally use column grants, not a
  -- table-level SELECT grant. Attempt rows are readable only to authenticated
  -- users, with RLS still constraining reads to the owning user.
  FOR r IN
    SELECT * FROM (VALUES
      ('anon', 'daily_challenge_attempts', false, false, false, false, false, false, false),
      ('anon', 'daily_challenges', false, false, false, false, false, false, false),
      ('anon', 'jee_pyq_questions', false, false, false, false, false, false, false),
      ('anon', 'mock_test_attempts', false, false, false, false, false, false, false),
      ('authenticated', 'daily_challenge_attempts', true, false, false, false, false, false, false),
      ('authenticated', 'daily_challenges', false, true, true, true, false, false, false),
      ('authenticated', 'jee_pyq_questions', false, true, true, true, false, false, false),
      ('authenticated', 'mock_test_attempts', true, false, false, false, false, false, false),
      ('service_role', 'daily_challenge_attempts', true, true, true, true, true, true, true),
      ('service_role', 'daily_challenges', true, true, true, true, true, true, true),
      ('service_role', 'jee_pyq_questions', true, true, true, true, true, true, true),
      ('service_role', 'mock_test_attempts', true, true, true, true, true, true, true)
    ) AS expected(role_name, table_name, sel, ins, upd, del, trunc, refs, trig)
  LOOP
    IF (has_table_privilege(r.role_name, format('public.%I', r.table_name), 'SELECT'),
        has_table_privilege(r.role_name, format('public.%I', r.table_name), 'INSERT'),
        has_table_privilege(r.role_name, format('public.%I', r.table_name), 'UPDATE'),
        has_table_privilege(r.role_name, format('public.%I', r.table_name), 'DELETE'),
        has_table_privilege(r.role_name, format('public.%I', r.table_name), 'TRUNCATE'),
        has_table_privilege(r.role_name, format('public.%I', r.table_name), 'REFERENCES'),
        has_table_privilege(r.role_name, format('public.%I', r.table_name), 'TRIGGER'))
       IS DISTINCT FROM
       (r.sel, r.ins, r.upd, r.del, r.trunc, r.refs, r.trig) THEN
      RAISE EXCEPTION 'Table-level privilege matrix changed for role %, table %',
        r.role_name, r.table_name;
    END IF;
  END LOOP;

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

  -- Exact schema-level access for browser and service roles.
  IF NOT has_schema_privilege('anon', 'public', 'USAGE')
     OR NOT has_schema_privilege('authenticated', 'public', 'USAGE')
     OR NOT has_schema_privilege('service_role', 'public', 'USAGE')
     OR has_schema_privilege('anon', 'public', 'CREATE')
     OR has_schema_privilege('authenticated', 'public', 'CREATE')
     OR has_schema_privilege('service_role', 'public', 'CREATE')
     OR has_schema_privilege('anon', 'private', 'USAGE')
     OR has_schema_privilege('authenticated', 'private', 'USAGE')
     OR has_schema_privilege('service_role', 'private', 'USAGE')
     OR has_schema_privilege('anon', 'private', 'CREATE')
     OR has_schema_privilege('authenticated', 'private', 'CREATE')
     OR has_schema_privilege('service_role', 'private', 'CREATE') THEN
    RAISE EXCEPTION 'Schema usage/create privilege boundary changed';
  END IF;

  -- Private tables remain inaccessible directly to all browser/service roles;
  -- privileged access is intentionally mediated by reviewed SECURITY DEFINER RPCs.
  FOR r IN
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'private' AND table_type = 'BASE TABLE'
  LOOP
    IF has_table_privilege('anon', format('private.%I', r.table_name), 'SELECT')
       OR has_table_privilege('anon', format('private.%I', r.table_name), 'INSERT')
       OR has_table_privilege('anon', format('private.%I', r.table_name), 'UPDATE')
       OR has_table_privilege('anon', format('private.%I', r.table_name), 'DELETE')
       OR has_table_privilege('authenticated', format('private.%I', r.table_name), 'SELECT')
       OR has_table_privilege('authenticated', format('private.%I', r.table_name), 'INSERT')
       OR has_table_privilege('authenticated', format('private.%I', r.table_name), 'UPDATE')
       OR has_table_privilege('authenticated', format('private.%I', r.table_name), 'DELETE')
       OR has_table_privilege('service_role', format('private.%I', r.table_name), 'SELECT')
       OR has_table_privilege('service_role', format('private.%I', r.table_name), 'INSERT')
       OR has_table_privilege('service_role', format('private.%I', r.table_name), 'UPDATE')
       OR has_table_privilege('service_role', format('private.%I', r.table_name), 'DELETE') THEN
      RAISE EXCEPTION 'Unexpected direct privilege on private table %', r.table_name;
    END IF;
  END LOOP;
END;
$test$;

SELECT 'PASS: public browser-role column reads and table-level writes match the captured grant contract' AS public_grant_contract;
