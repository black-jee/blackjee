-- Regression assertions for optional daily-challenge diagrams.
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'daily_challenges'
      and column_name = 'statement_image_path'
  ) then
    raise exception 'daily_challenges.statement_image_path is missing';
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'daily_challenges_statement_image_path_safe'
      and conrelid = 'public.daily_challenges'::regclass
  ) then
    raise exception 'safe relative asset path constraint is missing';
  end if;

  if position('statement_image_path' in pg_get_functiondef('public.start_daily_challenge(uuid)'::regprocedure)) = 0 then
    raise exception 'start_daily_challenge must return the question image path';
  end if;
end;
$$;
