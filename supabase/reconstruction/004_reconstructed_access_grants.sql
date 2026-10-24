-- BLACK-JEE reconstructed access grants — current live catalog snapshot.
-- Generated from read-only information_schema privilege inspection on 2026-10-24.
-- This captures observed browser/service-role access, NOT historical migration SQL.
-- Apply only in a disposable database after reconstructed tables/policies/RPCs.
-- Review the frontend contract and every column before any production use.
BEGIN;

-- Keep the private schema unreachable to browser roles and the service role's
-- direct SQL surface consistent with the live project. SECURITY DEFINER RPCs
-- execute as their owner and are the intended controlled access path.
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON ALL TABLES IN SCHEMA private FROM PUBLIC, anon, authenticated, service_role;

-- Public schema is usable but not creatable by application roles.
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
REVOKE CREATE ON SCHEMA public FROM PUBLIC, anon, authenticated, service_role;

-- Service role has full table privileges on the four public application tables.
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO service_role;

-- Authenticated students can read their own attempts through RLS. Writes to
-- challenge/PYQ authoring tables are separately gated by admin-only RLS policies.
GRANT SELECT ON TABLE public.daily_challenge_attempts TO authenticated;
GRANT SELECT ON TABLE public.mock_test_attempts TO authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.daily_challenges TO authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.jee_pyq_questions TO authenticated;

-- Public PYQ browse contract: only these columns are directly selectable.
GRANT SELECT (
  id, source_id, title, exam, year, subject, chapter, difficulty, statement,
  options, tags, asset_paths, review_status, is_published, created_at, updated_at,
  statement_image_path, session, question_type, marks_correct, marks_wrong,
  source_page, source_pdf, source_reference, source_status
) ON TABLE public.jee_pyq_questions TO anon, authenticated;

-- Anonymous users can inspect challenge schedule metadata only. Authenticated
-- users additionally receive the image path needed by the challenge session flow.
-- Neither browser role can directly read challenge statement/options.
GRANT SELECT (
  id, challenge_date, title, subject, starts_at, ends_at, solution_release_at, is_live
) ON TABLE public.daily_challenges TO anon;

GRANT SELECT (
  id, challenge_date, title, subject, starts_at, ends_at, is_live, statement_image_path
) ON TABLE public.daily_challenges TO authenticated;

COMMIT;
