-- BLACK-JEE reconstructed-schema smoke tests.
-- Run ONLY against a disposable database after applying the labelled
-- reconstruction draft. Read-only assertions; inserts no application data.
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
end
$test$;

select 'PASS: nine expected tables, RLS flags, selected constraints, and observed secondary indexes exist' as reconstruction_smoke_test;
