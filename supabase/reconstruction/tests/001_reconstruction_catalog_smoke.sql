-- BLACK-JEE reconstructed-schema smoke tests.
-- Run ONLY against a disposable database after applying reconstruction files
-- 001 and 002. Read-only assertions; inserts no application data.
-- This validates selected catalog invariants, not full production parity.

do $test$
declare
  missing text;
begin
  if to_regclass('public.jee_pyq_questions') is null
     or to_regclass('public.daily_challenges') is null
     or to_regclass('public.daily_challenge_attempts') is null
     or to_regclass('public.mock_test_attempts') is null
     or to_regclass('private.jee_pyq_answer_keys') is null
     or to_regclass('private.jee_pyq_answer_attempts') is null
     or to_regclass('private.daily_challenge_answer_keys') is null
     or to_regclass('private.daily_challenge_sessions') is null
     or to_regclass('private.mock_test_responses') is null then
    raise exception 'Reconstruction smoke test failed: one or more of the nine expected tables are missing';
  end if;

  -- Check every column represented in the reconstructed table draft.
  select string_agg(format('%I.%I.%I', expected.schema_name, expected.table_name, expected.column_name), ', ')
    into missing
  from (values
    ('public','jee_pyq_questions',array['id','source_id','title','exam','year','subject','chapter','difficulty','statement','options','tags','asset_paths','review_status','is_published','created_by','reviewed_by','reviewed_at','created_at','updated_at','statement_image_path','session','question_type','marks_correct','marks_wrong','source_page','source_pdf','source_reference','quality_checks','review_notes','source_status','publication_block_reason']::text[]),
    ('public','daily_challenges',array['id','challenge_date','title','subject','statement','options','starts_at','ends_at','solution_release_at','is_live','created_by','created_at','statement_image_path']::text[]),
    ('public','daily_challenge_attempts',array['id','challenge_id','user_id','selected_answer','is_correct','elapsed_seconds','submitted_at']::text[]),
    ('public','mock_test_attempts',array['id','user_id','mode','exam_year','session','subject','chapter','duration_seconds','question_ids','total_questions','status','started_at','submitted_at','attempted_count','correct_count','wrong_count','score','max_score','created_at']::text[]),
    ('private','jee_pyq_answer_keys',array['question_id','correct_answer','solution','updated_at']::text[]),
    ('private','jee_pyq_answer_attempts',array['user_id','question_id','wrong_attempts','first_attempt_at','last_attempt_at','solution_unlocked_at']::text[]),
    ('private','daily_challenge_answer_keys',array['challenge_id','correct_answer','solution']::text[]),
    ('private','daily_challenge_sessions',array['challenge_id','user_id','started_at','submitted_at']::text[]),
    ('private','mock_test_responses',array['attempt_id','question_id','selected_answer','is_correct','marks_awarded','answered_at']::text[])
  ) expected(schema_name, table_name, column_names)
  cross join lateral unnest(expected.column_names) as cols(column_name)
  where not exists (
    select 1 from information_schema.columns col
    where col.table_schema = expected.schema_name
      and col.table_name = expected.table_name
      and col.column_name = cols.column_name
  );
  if missing is not null then
    raise exception 'Missing reconstructed table columns: %', missing;
  end if;

  select string_agg(format('%I.%I', n.nspname, c.relname), ', ')
    into missing
  from (values
    ('public','jee_pyq_questions'),
    ('public','daily_challenges'),
    ('public','daily_challenge_attempts'),
    ('public','mock_test_attempts'),
    ('private','jee_pyq_answer_keys'),
    ('private','jee_pyq_answer_attempts'),
    ('private','daily_challenge_answer_keys'),
    ('private','daily_challenge_sessions'),
    ('private','mock_test_responses')
  ) expected(schema_name, table_name)
  join pg_namespace n on n.nspname = expected.schema_name
  join pg_class c on c.relnamespace = n.oid and c.relname = expected.table_name
  where not c.relrowsecurity;
  if missing is not null then
    raise exception 'RLS is not enabled on expected tables: %', missing;
  end if;

  select string_agg(expected.policy_name, ', ')
    into missing
  from (values
    ('public','daily_challenge_attempts','Users read their own challenge attempts'),
    ('public','daily_challenges','Admins delete challenges'),
    ('public','daily_challenges','Admins insert challenges'),
    ('public','daily_challenges','Admins update challenges'),
    ('public','daily_challenges','Live challenge schedule is readable'),
    ('public','jee_pyq_questions','Admins delete PYQs'),
    ('public','jee_pyq_questions','Admins insert PYQs'),
    ('public','jee_pyq_questions','Admins update PYQs'),
    ('public','jee_pyq_questions','Published PYQs and admin review queue are readable'),
    ('public','mock_test_attempts','Users can read own mock test attempts')
  ) expected(schema_name, table_name, policy_name)
  where not exists (
    select 1 from pg_policies p
    where p.schemaname = expected.schema_name
      and p.tablename = expected.table_name
      and p.policyname = expected.policy_name
  );
  if missing is not null then
    raise exception 'Missing reconstructed RLS policies: %', missing;
  end if;

  select string_agg(expected.constraint_name, ', ')
    into missing
  from (values
    ('public','jee_pyq_questions','jee_pyq_questions_created_by_fkey'),
    ('public','jee_pyq_questions','jee_pyq_questions_reviewed_by_fkey'),
    ('public','daily_challenges','daily_challenges_created_by_fkey'),
    ('public','daily_challenge_attempts','daily_challenge_attempts_challenge_id_fkey'),
    ('public','daily_challenge_attempts','daily_challenge_attempts_user_id_fkey'),
    ('public','mock_test_attempts','mock_test_attempts_user_id_fkey'),
    ('private','jee_pyq_answer_keys','jee_pyq_answer_keys_question_id_fkey'),
    ('private','jee_pyq_answer_attempts','jee_pyq_answer_attempts_user_id_fkey'),
    ('private','jee_pyq_answer_attempts','jee_pyq_answer_attempts_question_id_fkey'),
    ('private','daily_challenge_answer_keys','daily_challenge_answer_keys_challenge_id_fkey'),
    ('private','daily_challenge_sessions','daily_challenge_sessions_challenge_id_fkey'),
    ('private','daily_challenge_sessions','daily_challenge_sessions_user_id_fkey'),
    ('private','mock_test_responses','mock_test_responses_attempt_id_fkey'),
    ('private','mock_test_responses','mock_test_responses_question_id_fkey')
  ) expected(schema_name, table_name, constraint_name)
  where not exists (
    select 1 from pg_constraint con
    join pg_class c on c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = expected.schema_name
      and c.relname = expected.table_name
      and con.conname = expected.constraint_name
      and con.contype = 'f'
  );
  if missing is not null then
    raise exception 'Missing catalog-confirmed foreign keys: %', missing;
  end if;

  select string_agg(expected.constraint_name, ', ')
    into missing
  from (values
    ('public','jee_pyq_questions','jee_pyq_marks_check'),
    ('public','jee_pyq_questions','published_questions_must_be_approved'),
    ('public','daily_challenges','daily_challenges_check'),
    ('public','daily_challenge_attempts','daily_challenge_attempts_challenge_id_user_id_key'),
    ('public','mock_test_attempts','mock_test_attempts_check')
  ) expected(schema_name, table_name, constraint_name)
  where not exists (
    select 1 from pg_constraint con
    join pg_class c on c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = expected.schema_name
      and c.relname = expected.table_name
      and con.conname = expected.constraint_name
  );
  if missing is not null then
    raise exception 'Missing catalog-confirmed constraints: %', missing;
  end if;

  select string_agg(expected.index_name, ', ')
    into missing
  from (values
    ('public','daily_challenge_attempts','daily_attempt_user_idx'),
    ('public','daily_challenges','daily_challenges_created_by_idx'),
    ('public','daily_challenges','daily_challenges_live_idx'),
    ('public','jee_pyq_questions','jee_pyq_created_by_idx'),
    ('public','jee_pyq_questions','jee_pyq_paper_lookup_idx'),
    ('public','jee_pyq_questions','jee_pyq_review_queue_idx'),
    ('public','jee_pyq_questions','jee_pyq_reviewed_by_idx'),
    ('public','jee_pyq_questions','jee_pyq_subject_year_idx'),
    ('private','daily_challenge_sessions','daily_challenge_sessions_user_id_idx'),
    ('private','jee_pyq_answer_attempts','jee_pyq_answer_attempts_question_idx')
  ) expected(schema_name, table_name, index_name)
  where not exists (
    select 1 from pg_indexes i
    where i.schemaname = expected.schema_name
      and i.tablename = expected.table_name
      and i.indexname = expected.index_name
  );
  if missing is not null then
    raise exception 'Missing catalog-confirmed secondary indexes: %', missing;
  end if;

  -- Assert every observed constraint name and kind, not only a selected subset.
  select string_agg(expected.constraint_name, ', ')
    into missing
  from (values
    ('private','daily_challenge_answer_keys','daily_challenge_answer_keys_correct_answer_nonempty','c'),
    ('private','daily_challenge_answer_keys','daily_challenge_answer_keys_challenge_id_fkey','f'),
    ('private','daily_challenge_answer_keys','daily_challenge_answer_keys_pkey','p'),
    ('private','daily_challenge_sessions','daily_challenge_sessions_challenge_id_fkey','f'),
    ('private','daily_challenge_sessions','daily_challenge_sessions_user_id_fkey','f'),
    ('private','daily_challenge_sessions','daily_challenge_sessions_pkey','p'),
    ('private','jee_pyq_answer_attempts','jee_pyq_answer_attempts_wrong_attempts_check','c'),
    ('private','jee_pyq_answer_attempts','jee_pyq_answer_attempts_question_id_fkey','f'),
    ('private','jee_pyq_answer_attempts','jee_pyq_answer_attempts_user_id_fkey','f'),
    ('private','jee_pyq_answer_attempts','jee_pyq_answer_attempts_pkey','p'),
    ('private','jee_pyq_answer_keys','jee_pyq_answer_keys_correct_answer_nonempty','c'),
    ('private','jee_pyq_answer_keys','jee_pyq_answer_keys_question_id_fkey','f'),
    ('private','jee_pyq_answer_keys','jee_pyq_answer_keys_pkey','p'),
    ('private','mock_test_responses','mock_test_responses_attempt_id_fkey','f'),
    ('private','mock_test_responses','mock_test_responses_question_id_fkey','f'),
    ('private','mock_test_responses','mock_test_responses_pkey','p'),
    ('public','daily_challenge_attempts','daily_challenge_attempts_elapsed_seconds_check','c'),
    ('public','daily_challenge_attempts','daily_challenge_attempts_challenge_id_fkey','f'),
    ('public','daily_challenge_attempts','daily_challenge_attempts_user_id_fkey','f'),
    ('public','daily_challenge_attempts','daily_challenge_attempts_pkey','p'),
    ('public','daily_challenge_attempts','daily_challenge_attempts_challenge_id_user_id_key','u'),
    ('public','daily_challenges','daily_challenges_check','c'),
    ('public','daily_challenges','daily_challenges_options_check','c'),
    ('public','daily_challenges','daily_challenges_statement_image_path_safe','c'),
    ('public','daily_challenges','daily_challenges_subject_check','c'),
    ('public','daily_challenges','daily_challenges_created_by_fkey','f'),
    ('public','daily_challenges','daily_challenges_pkey','p'),
    ('public','daily_challenges','daily_challenges_challenge_date_key','u'),
    ('public','jee_pyq_questions','jee_pyq_marks_check','c'),
    ('public','jee_pyq_questions','jee_pyq_question_type_check','c'),
    ('public','jee_pyq_questions','jee_pyq_questions_difficulty_check','c'),
    ('public','jee_pyq_questions','jee_pyq_questions_options_check','c'),
    ('public','jee_pyq_questions','jee_pyq_questions_review_status_check','c'),
    ('public','jee_pyq_questions','jee_pyq_questions_statement_image_path_safe','c'),
    ('public','jee_pyq_questions','jee_pyq_questions_subject_check','c'),
    ('public','jee_pyq_questions','jee_pyq_questions_year_check','c'),
    ('public','jee_pyq_questions','jee_pyq_source_status_check','c'),
    ('public','jee_pyq_questions','published_questions_must_be_approved','c'),
    ('public','jee_pyq_questions','jee_pyq_questions_created_by_fkey','f'),
    ('public','jee_pyq_questions','jee_pyq_questions_reviewed_by_fkey','f'),
    ('public','jee_pyq_questions','jee_pyq_questions_pkey','p'),
    ('public','jee_pyq_questions','jee_pyq_questions_source_id_key','u'),
    ('public','mock_test_attempts','mock_test_attempts_check','c'),
    ('public','mock_test_attempts','mock_test_attempts_duration_seconds_check','c'),
    ('public','mock_test_attempts','mock_test_attempts_mode_check','c'),
    ('public','mock_test_attempts','mock_test_attempts_status_check','c'),
    ('public','mock_test_attempts','mock_test_attempts_total_questions_check','c'),
    ('public','mock_test_attempts','mock_test_attempts_user_id_fkey','f'),
    ('public','mock_test_attempts','mock_test_attempts_pkey','p')
  ) expected(schema_name, table_name, constraint_name, constraint_type)
  where not exists (
    select 1 from pg_constraint con
    join pg_class c on c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = expected.schema_name
      and c.relname = expected.table_name
      and con.conname = expected.constraint_name
      and con.contype::text = expected.constraint_type
  );
  if missing is not null then
    raise exception 'Missing catalog-confirmed constraints or wrong constraint kinds: %', missing;
  end if;

end
$test$;

select 'PASS: nine tables, reconstructed columns, RLS flags, 10 policies, 14 foreign keys, all 49 observed constraints, and observed secondary indexes exist' as reconstruction_smoke_test;
