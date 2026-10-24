-- Regression checks for the database-enforced admin-only challenge save RPC.
select
  not has_function_privilege(
    'anon',
    'public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)',
    'EXECUTE'
  ) as anon_denied,
  has_function_privilege(
    'authenticated',
    'public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)',
    'EXECUTE'
  ) as authenticated_can_call_guarded_rpc,
  (select prosecdef from pg_proc where oid = 'public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)'::regprocedure) as trusted_function,
  position('app_metadata' in pg_get_functiondef('public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)'::regprocedure)) > 0 as checks_server_managed_role,
  position('private.daily_challenge_answer_keys' in pg_get_functiondef('public.admin_save_daily_challenge(uuid,date,text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text,text,boolean)'::regprocedure)) > 0 as stores_private_answer_key;
