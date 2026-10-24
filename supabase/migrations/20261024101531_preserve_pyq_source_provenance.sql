-- Preserve original source provenance and QA state for migrated question content.
alter table public.jee_pyq_questions
  add column if not exists source_page integer,
  add column if not exists source_pdf text,
  add column if not exists source_reference jsonb not null default '{}'::jsonb,
  add column if not exists quality_checks jsonb not null default '{}'::jsonb,
  add column if not exists review_notes text[] not null default '{}'::text[],
  add column if not exists source_status text not null default 'not_verified',
  add column if not exists publication_block_reason text;

do $$
begin
  if not exists (select 1 from pg_constraint where conname='jee_pyq_source_status_check' and conrelid='public.jee_pyq_questions'::regclass) then
    alter table public.jee_pyq_questions
      add constraint jee_pyq_source_status_check
      check (source_status in ('awaiting_source','content_added','needs_review','verified_draft','approved_for_publish','not_verified'));
  end if;
end;
$$;

grant select (source_page, source_pdf, source_reference, source_status)
  on public.jee_pyq_questions to anon, authenticated;
