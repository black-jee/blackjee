-- Store a semantic image path for PYQ question-level diagrams.
-- Option-level images remain attached to the matching option in the options JSON.
alter table public.jee_pyq_questions
  add column if not exists statement_image_path text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'jee_pyq_questions_statement_image_path_safe'
      and conrelid = 'public.jee_pyq_questions'::regclass
  ) then
    alter table public.jee_pyq_questions
      add constraint jee_pyq_questions_statement_image_path_safe
      check (
        statement_image_path is null
        or statement_image_path !~ '(^/|//|(^|/)[.][.](/|$)|[^A-Za-z0-9._/-])'
      );
  end if;
end;
$$;
