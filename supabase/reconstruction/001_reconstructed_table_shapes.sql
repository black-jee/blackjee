-- RECONSTRUCTION DRAFT — generated from read-only catalog column metadata on 2026-10-24.
-- NOT original historical SQL. NOT a production migration. NOT a complete baseline:
-- grants, policies, indexes, functions, owners, storage, and exact constraint actions
-- must be captured and compared before replay. Apply only in a disposable database.
begin;

create schema if not exists private;

create table public.jee_pyq_questions (
  id uuid primary key default gen_random_uuid(),
  source_id text unique,
  title text not null,
  exam text not null default 'JEE Main',
  year integer check (year >= 2002 and year <= 2100),
  subject text not null check (subject in ('Physics','Chemistry','Mathematics')),
  chapter text,
  difficulty text not null default 'Main' check (difficulty in ('Main','Advanced','Mixed')),
  statement text not null,
  options jsonb not null default '[]'::jsonb check (jsonb_typeof(options) = 'array'),
  tags text[] not null default '{}'::text[],
  asset_paths text[] not null default '{}'::text[],
  review_status text not null default 'draft' check (review_status in ('draft','in_review','approved','rejected')),
  is_published boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  statement_image_path text check (statement_image_path is null or statement_image_path !~ '(^/|//|(^|/)[.][.](/|$)|[^A-Za-z0-9._/-])'),
  session text,
  question_type text not null default 'single_correct' check (question_type in ('single_correct','numerical')),
  marks_correct integer not null default 4,
  marks_wrong integer not null default -1,
  source_page integer,
  source_pdf text,
  source_reference jsonb not null default '{}'::jsonb,
  quality_checks jsonb not null default '{}'::jsonb,
  review_notes text[] not null default '{}'::text[],
  source_status text not null default 'not_verified' check (source_status in ('awaiting_source','content_added','needs_review','verified_draft','approved_for_publish','not_verified')),
  publication_block_reason text
);

create table public.daily_challenges (
  id uuid primary key default gen_random_uuid(),
  challenge_date date not null unique,
  title text not null,
  subject text not null check (subject in ('Physics','Chemistry','Mathematics','Mixed')),
  statement text not null,
  options jsonb not null default '[]'::jsonb check (jsonb_typeof(options) = 'array'),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  solution_release_at timestamptz not null,
  is_live boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  statement_image_path text check (statement_image_path is null or statement_image_path !~ '(^/|//|(^|/)[.][.](/|$)|[^A-Za-z0-9._/-])')
);

create table public.daily_challenge_attempts (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.daily_challenges(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  selected_answer text not null,
  is_correct boolean not null,
  elapsed_seconds integer not null check (elapsed_seconds >= 0 and elapsed_seconds <= 86400),
  submitted_at timestamptz not null default now()
);

create table public.mock_test_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mode text not null check (mode in ('shift','focused')),
  exam_year integer,
  session text,
  subject text,
  chapter text,
  duration_seconds integer not null check (duration_seconds >= 0 and duration_seconds <= 10800),
  question_ids uuid[] not null,
  total_questions integer not null check (total_questions >= 1 and total_questions <= 75),
  status text not null default 'in_progress' check (status in ('in_progress','submitted')),
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  attempted_count integer,
  correct_count integer,
  wrong_count integer,
  score integer,
  max_score integer,
  created_at timestamptz not null default now()
);

create table private.jee_pyq_answer_keys (
  question_id uuid primary key references public.jee_pyq_questions(id) on delete cascade,
  correct_answer text not null check (length(trim(correct_answer)) > 0),
  solution text,
  updated_at timestamptz not null default now()
);

create table private.jee_pyq_answer_attempts (
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.jee_pyq_questions(id) on delete cascade,
  wrong_attempts integer not null default 0 check (wrong_attempts >= 0 and wrong_attempts <= 2),
  first_attempt_at timestamptz not null default now(),
  last_attempt_at timestamptz not null default now(),
  solution_unlocked_at timestamptz,
  primary key (user_id, question_id)
);

create table private.daily_challenge_answer_keys (
  challenge_id uuid primary key references public.daily_challenges(id) on delete cascade,
  correct_answer text not null check (length(trim(correct_answer)) > 0),
  solution text
);

create table private.daily_challenge_sessions (
  challenge_id uuid not null references public.daily_challenges(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  primary key (challenge_id, user_id)
);

create table private.mock_test_responses (
  attempt_id uuid not null references public.mock_test_attempts(id) on delete cascade,
  question_id uuid not null references public.jee_pyq_questions(id) on delete restrict,
  selected_answer text,
  is_correct boolean not null default false,
  marks_awarded integer not null default 0,
  answered_at timestamptz not null default now(),
  primary key (attempt_id, question_id)
);

alter table public.jee_pyq_questions enable row level security;
alter table public.daily_challenges enable row level security;
alter table public.daily_challenge_attempts enable row level security;
alter table public.mock_test_attempts enable row level security;
alter table private.jee_pyq_answer_keys enable row level security;
alter table private.jee_pyq_answer_attempts enable row level security;
alter table private.daily_challenge_answer_keys enable row level security;
alter table private.daily_challenge_sessions enable row level security;
alter table private.mock_test_responses enable row level security;

commit;

-- IMPORTANT REVIEW GATES:
-- 1. Foreign-key delete actions have been updated from a read-only catalog query;
--    re-check them during replay comparison and capture any ON UPDATE behavior too.
-- 2. Column nullability/defaults were cross-checked against information_schema;
--    CHECK/UNIQUE/FK definitions still require full catalog comparison.
-- 3. No RLS policies, table/column grants, sequence grants, indexes beyond primary/
--    unique constraints, function definitions/ACLs, storage config, or seed data
--    are included. This is a structural draft only, not a secure runnable app.
