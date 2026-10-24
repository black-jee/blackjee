-- Expose only the image path metadata needed for rendering approved PYQs.
-- Daily challenge diagram paths stay hidden from anon until the authenticated start RPC returns content.
grant select (statement_image_path) on public.jee_pyq_questions to anon, authenticated;
grant select (statement_image_path) on public.daily_challenges to authenticated;
