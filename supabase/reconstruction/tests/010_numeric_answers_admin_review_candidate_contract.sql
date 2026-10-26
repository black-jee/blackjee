\set ON_ERROR_STOP on
-- This contract runs only in the disposable CI PostgreSQL database after the
-- labelled migration candidate has been replayed. It does not prove historical
-- provenance or equivalence to the missing applied migration body.
do $$
declare
  c record;
  p record;
begin
  for c in
    select conname, pg_get_constraintdef(oid) as definition
    from pg_constraint
    where conrelid = 'private.jee_pyq_answer_keys'::regclass
      and conname = 'jee_pyq_answer_keys_correct_answer_nonempty'
      and contype = 'c'
  loop
    if position('length' in lower(c.definition)) = 0
       or position('correct_answer' in lower(c.definition)) = 0 then
      raise exception 'Unexpected PYQ answer-key constraint definition: %', c.definition;
    end if;
  end loop;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'private.jee_pyq_answer_keys'::regclass
      and conname = 'jee_pyq_answer_keys_correct_answer_nonempty'
      and contype = 'c'
  ) then
    raise exception 'Missing nonempty PYQ answer-key constraint';
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'private.daily_challenge_answer_keys'::regclass
      and conname = 'daily_challenge_answer_keys_correct_answer_nonempty'
      and contype = 'c'
      and position('correct_answer' in lower(pg_get_constraintdef(oid))) > 0
  ) then
    raise exception 'Missing nonempty daily-challenge answer-key constraint';
  end if;

  select * into p
  from pg_policies
  where schemaname = 'public'
    and tablename = 'jee_pyq_questions'
    and policyname = 'Published PYQs and admin review queue are readable';

  if not found then
    raise exception 'Missing candidate PYQ read policy';
  end if;
  if p.cmd <> 'SELECT'
     or not ('anon' = any(p.roles) and 'authenticated' = any(p.roles))
     or position('is_published' in lower(coalesce(p.qual, ''))) = 0
     or position('review_status' in lower(coalesce(p.qual, ''))) = 0
     or position('admin' in lower(coalesce(p.qual, ''))) = 0 then
    raise exception 'Unexpected candidate PYQ policy contract: %', row_to_json(p);
  end if;
end $$;
