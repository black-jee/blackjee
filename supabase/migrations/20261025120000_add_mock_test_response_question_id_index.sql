-- Add a supporting index for the mock-test response -> PYQ foreign key.
-- Forward-only migration. This file is not applied to the production database by this task.
CREATE INDEX IF NOT EXISTS mock_test_responses_question_id_idx
  ON private.mock_test_responses (question_id);
