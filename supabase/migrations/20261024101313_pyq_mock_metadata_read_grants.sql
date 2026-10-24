-- Expose non-sensitive paper metadata required for shift selection and marking display.
grant select (session, question_type, marks_correct, marks_wrong)
  on public.jee_pyq_questions to anon, authenticated;
