-- Regression checks for the PYQ admin review/publish gate.
with function_definition as (
  select pg_get_functiondef(
    'public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[])'::regprocedure
  ) as def
)
select
  not has_function_privilege(
    'anon',
    'public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[])',
    'EXECUTE'
  ) as anon_denied,
  has_function_privilege(
    'authenticated',
    'public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[])',
    'EXECUTE'
  ) as authenticated_can_call_guarded_rpc,
  (select prosecdef from pg_proc
   where oid = 'public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[])'::regprocedure
  ) as trusted_function,
  position('app_metadata' in def) > 0 as checks_server_managed_role,
  position('private.jee_pyq_answer_keys' in def) > 0 as reads_private_answer_key,
  position('source_page' in def) > 0 as requires_source_page,
  position('Cannot publish without a source document and page number' in def) > 0 as requires_source_document_and_page,
  position('Cannot publish without a worked solution' in def) > 0 as requires_worked_solution,
  position('Cannot publish without a private answer key' in def) > 0 as requires_private_answer_key
from function_definition;
