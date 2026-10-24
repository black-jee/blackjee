-- BLACK-JEE security catalog inventory — READ ONLY.
-- Run against a disposable replay or inspect output from the live catalog.
-- This is an inventory query, not a migration and not a complete security test.
-- Never apply GRANT/REVOKE changes based on this report without reviewing
-- the actual frontend access contract and SECURITY DEFINER function bodies.

-- 1. Schema privileges for browser/service roles.
select
  n.nspname as schema_name,
  r.rolname as grantee,
  has_schema_privilege(r.rolname, n.oid, 'USAGE') as can_use_schema,
  has_schema_privilege(r.rolname, n.oid, 'CREATE') as can_create_in_schema
from pg_namespace n
cross join pg_roles r
where n.nspname in ('public', 'private')
  and r.rolname in ('anon', 'authenticated', 'service_role')
order by n.nspname, r.rolname;

-- 2. Table-level privileges. Column-level grants are reported separately below.
select
  table_schema,
  table_name,
  grantee,
  privilege_type,
  is_grantable
from information_schema.role_table_grants
where table_schema in ('public', 'private')
  and grantee in ('anon', 'authenticated', 'service_role')
order by table_schema, table_name, grantee, privilege_type;

-- 3. Column-level privileges (important for published PYQ and challenge tables).
select
  table_schema,
  table_name,
  column_name,
  grantee,
  privilege_type,
  is_grantable
from information_schema.column_privileges
where table_schema in ('public', 'private')
  and grantee in ('anon', 'authenticated', 'service_role')
order by table_schema, table_name, column_name, grantee, privilege_type;

-- 4. Function execute ACLs and security attributes. This includes every
-- function in public/private; inspect each SECURITY DEFINER body separately.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as identity_arguments,
  p.prosecdef as security_definer,
  p.proconfig as function_settings,
  coalesce(array_to_string(array(
    select case
      when x.grantee = 0 then 'PUBLIC'
      else pg_get_userbyid(x.grantee)
    end || ':' || x.privilege_type
    from aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) x
    where x.privilege_type = 'EXECUTE'
    order by 1
  ), ', '), '') as execute_acl
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname in ('public', 'private')
order by n.nspname, p.proname, pg_get_function_identity_arguments(p.oid);

-- 5. RLS policy inventory. Compare policy role, command, USING, and WITH CHECK.
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual as using_expression,
  with_check
from pg_policies
where schemaname in ('public', 'private')
order by schemaname, tablename, policyname;

-- 6. Triggers (exclude internal FK/constraint triggers).
select
  n.nspname as schema_name,
  c.relname as table_name,
  t.tgname as trigger_name,
  pg_get_triggerdef(t.oid, true) as trigger_definition
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where not t.tgisinternal
  and n.nspname in ('public', 'private')
order by n.nspname, c.relname, t.tgname;
