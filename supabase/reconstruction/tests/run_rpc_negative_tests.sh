#!/usr/bin/env bash
set -euo pipefail

# Real negative authorization checks against the disposable PostgreSQL replay.
# Fixtures contain only synthetic user IDs and an empty mock-attempt shell;
# no JEE question, answer, solution, or student data is inserted.

expect_denial() {
  local label="$1"
  local expected="$2"
  local sql="$3"
  local output
  if output="$(psql -X -v ON_ERROR_STOP=1 -qAt -c "$sql" 2>&1)"; then
    echo "FAIL: $label unexpectedly succeeded"
    exit 1
  fi
  if [[ "$output" != *"$expected"* ]]; then
    echo "FAIL: $label failed for an unexpected reason"
    printf '%s\n' "$output"
    exit 1
  fi
  echo "PASS: $label"
}

user_a="aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
user_b="bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
attempt_id="cccccccc-cccc-4ccc-8ccc-cccccccccccc"

psql -X -v ON_ERROR_STOP=1 -qAt -c "INSERT INTO auth.users(id) VALUES ('$user_a'), ('$user_b') ON CONFLICT (id) DO NOTHING;"
psql -X -v ON_ERROR_STOP=1 -qAt -c "INSERT INTO public.mock_test_attempts(id,user_id,mode,duration_seconds,question_ids,total_questions) VALUES ('$attempt_id','$user_a','focused',1800,ARRAY[]::uuid[],1) ON CONFLICT (id) DO NOTHING;"

expect_denial \
  "anonymous cannot execute admin review RPC" \
  "permission denied for function admin_review_jee_pyq_question" \
  "SET ROLE anon; SELECT public.admin_review_jee_pyq_question(NULL::uuid, false, false, NULL::text[]);"

nonadmin_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"app_metadata\":{\"role\":\"student\"}}'; SELECT public.admin_save_daily_challenge(NULL::uuid, NULL::date, NULL::text, NULL::text, NULL::text, NULL::text, NULL::jsonb, NULL::timestamptz, NULL::timestamptz, NULL::timestamptz, NULL::text, NULL::text, NULL::boolean);"
expect_denial \
  "ordinary authenticated user cannot author a challenge" \
  "Administrator access required" \
  "$nonadmin_sql"

# Client-controlled user_metadata must not grant administrative access.
spoofed_admin_challenge_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"user_metadata\":{\"role\":\"admin\"},\"app_metadata\":{\"role\":\"student\"}}'; SELECT public.admin_save_daily_challenge(NULL::uuid, NULL::date, NULL::text, NULL::text, NULL::text, NULL::text, NULL::jsonb, NULL::timestamptz, NULL::timestamptz, NULL::timestamptz, NULL::text, NULL::text, NULL::boolean);"
expect_denial \
  "user_metadata admin claim cannot author a challenge" \
  "Administrator access required" \
  "$spoofed_admin_challenge_sql"

spoofed_admin_pyq_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"user_metadata\":{\"role\":\"admin\"},\"app_metadata\":{\"role\":\"student\"}}'; SELECT public.admin_review_jee_pyq_question(NULL::uuid, false, false, NULL::text[]);"
expect_denial \
  "user_metadata admin claim cannot review PYQs" \
  "Administrator access required" \
  "$spoofed_admin_pyq_sql"

spoofed_admin_pyq_save_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"user_metadata\":{\"role\":\"admin\"},\"app_metadata\":{\"role\":\"student\"}}'; SELECT public.admin_save_jee_pyq_question(NULL::uuid, NULL::text, NULL::text, NULL::text, NULL::integer, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text, NULL::jsonb, NULL::text, NULL::integer, NULL::integer, NULL::text, NULL::text, NULL::text, NULL::integer, NULL::text[], NULL::text[], NULL::text[]);"
expect_denial \
  "user_metadata admin claim cannot author PYQs" \
  "Administrator access required" \
  "$spoofed_admin_pyq_save_sql"

# Even a real admin must not publish a live challenge without a worked solution.
blank_live_solution_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"app_metadata\":{\"role\":\"admin\"}}'; SELECT public.admin_save_daily_challenge(NULL::uuid, CURRENT_DATE, 'Synthetic replay fixture', 'Physics', 'Synthetic test statement', NULL::text, '[]'::jsonb, now(), now() + interval '1 hour', now() + interval '2 hours', 'A', '   ', true);"
expect_denial \
  "live daily challenge cannot be saved without a worked solution" \
  "A live challenge must include a worked solution" \
  "$blank_live_solution_sql"

# Even an administrator must supply a complete challenge date and schedule.
# These exercise the function at runtime, not just a catalog-text assertion.
null_challenge_date_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"app_metadata\":{\"role\":\"admin\"}}'; SELECT public.admin_save_daily_challenge(NULL::uuid, NULL::date, 'Synthetic replay fixture', 'Physics', 'Synthetic test statement', NULL::text, '[]'::jsonb, now(), now() + interval '1 hour', now() + interval '2 hours', 'A', 'Worked synthetic solution', false);"
expect_denial \\
  "daily challenge RPC rejects NULL challenge date" \\
  "Challenge date and schedule times are required" \\
  "$null_challenge_date_sql"

null_starts_at_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"app_metadata\":{\"role\":\"admin\"}}'; SELECT public.admin_save_daily_challenge(NULL::uuid, CURRENT_DATE, 'Synthetic replay fixture', 'Physics', 'Synthetic test statement', NULL::text, '[]'::jsonb, NULL::timestamptz, now() + interval '1 hour', now() + interval '2 hours', 'A', 'Worked synthetic solution', false);"
expect_denial \\
  "daily challenge RPC rejects NULL start time" \\
  "Challenge date and schedule times are required" \\
  "$null_starts_at_sql"

null_ends_at_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"app_metadata\":{\"role\":\"admin\"}}'; SELECT public.admin_save_daily_challenge(NULL::uuid, CURRENT_DATE, 'Synthetic replay fixture', 'Physics', 'Synthetic test statement', NULL::text, '[]'::jsonb, now(), NULL::timestamptz, now() + interval '2 hours', 'A', 'Worked synthetic solution', false);"
expect_denial \\
  "daily challenge RPC rejects NULL end time" \\
  "Challenge date and schedule times are required" \\
  "$null_ends_at_sql"

null_solution_release_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"app_metadata\":{\"role\":\"admin\"}}'; SELECT public.admin_save_daily_challenge(NULL::uuid, CURRENT_DATE, 'Synthetic replay fixture', 'Physics', 'Synthetic test statement', NULL::text, '[]'::jsonb, now(), now() + interval '1 hour', NULL::timestamptz, 'A', 'Worked synthetic solution', false);"
expect_denial \\
  "daily challenge RPC rejects NULL solution release time" \\
  "Challenge date and schedule times are required" \\
  "$null_solution_release_sql"

# Database RPC must reject option labels that are duplicated or inconsistent with the answer.
invalid_options_prefix="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"app_metadata\":{\"role\":\"admin\"}}'; SELECT public.admin_save_daily_challenge(NULL::uuid, CURRENT_DATE, 'Synthetic replay fixture', 'Physics', 'Synthetic test statement', NULL::text, "
invalid_options_suffix=", now(), now() + interval '1 hour', now() + interval '2 hours', 'A', 'Worked synthetic solution', false);"
expect_denial \
  "daily challenge RPC rejects duplicate option labels" \
  "Daily challenge option labels must be unique" \
  "${invalid_options_prefix}jsonb_build_array(jsonb_build_object('label','A','text','one'),jsonb_build_object('label','a','text','two'))${invalid_options_suffix}"
invalid_answer_suffix=", now(), now() + interval '1 hour', now() + interval '2 hours', 'C', 'Worked synthetic solution', false);" 
expect_denial \
  "daily challenge RPC rejects answer not present in options" \
  "Correct answer must match one of the option labels" \
  "${invalid_options_prefix}jsonb_build_array(jsonb_build_object('label','A','text','one'),jsonb_build_object('label','B','text','two'))${invalid_answer_suffix}"

expect_denial \
  "daily challenge RPC rejects blank option labels" \
  "Daily challenge options need non-empty labels" \
  "${invalid_options_prefix}jsonb_build_array(jsonb_build_object('label',' ','text','one'))${invalid_options_suffix}"

expect_denial \
  "daily challenge RPC rejects more than 12 options" \
  "A daily challenge can have at most 12 options" \
  "${invalid_options_prefix}(SELECT jsonb_agg(jsonb_build_object('label', chr(64 + n), 'text', 'option') ORDER BY n) FROM generate_series(1,13) AS g(n))${invalid_options_suffix}"

cross_user_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"app_metadata\":{\"role\":\"student\"}}'; SELECT public.resume_mock_test('$attempt_id'::uuid);"
expect_denial \
  "user cannot resume another user's mock attempt" \
  "Active mock test not found for this user" \
  "$cross_user_sql"

cross_user_submit_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"app_metadata\":{\"role\":\"student\"}}'; SELECT public.submit_mock_test('$attempt_id'::uuid, '[]'::jsonb);"
expect_denial \
  "user cannot submit another user's mock attempt" \
  "Mock test not found for this user" \
  "$cross_user_submit_sql"

cross_user_result_sql="SET ROLE authenticated; SET request.jwt.claim.sub = '$user_b'; SET request.jwt.claims = '{\"sub\":\"$user_b\",\"app_metadata\":{\"role\":\"student\"}}'; SELECT public.get_mock_test_result('$attempt_id'::uuid);"
expect_denial \
  "user cannot retrieve another user's mock-test result" \
  "Submitted test not found for this user" \
  "$cross_user_result_sql"

expect_denial \
  "authenticated user cannot query private answer-key schema directly" \
  "permission denied for schema private" \
  "SET ROLE authenticated; SELECT correct_answer FROM private.jee_pyq_answer_keys LIMIT 1;"

# Exercise successful admin authoring using only a synthetic challenge.
# Create/update runs as authenticated admin; privileged test harness verifies and cleans up.
psql -X -v ON_ERROR_STOP=1 -qAt <<'SQL'
SET ROLE authenticated;
SET request.jwt.claim.sub = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
SET request.jwt.claims = '{"sub":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb","app_metadata":{"role":"admin"}}';
DO $$
DECLARE
  v_id uuid;
  v_updated_id uuid;
  v_options jsonb := jsonb_build_array(
    jsonb_build_object('label', 'A', 'text', 'synthetic option one'),
    jsonb_build_object('label', 'B', 'text', 'synthetic option two')
  );
BEGIN
  v_id := public.admin_save_daily_challenge(
    NULL, CURRENT_DATE, 'Synthetic authoring create', 'Physics',
    'Synthetic authoring test statement', NULL, v_options,
    now(), now() + interval '1 hour', now() + interval '2 hours',
    'A', 'Synthetic worked solution', false
  );

  v_updated_id := public.admin_save_daily_challenge(
    v_id, CURRENT_DATE, 'Synthetic authoring update', 'Physics',
    'Synthetic authoring updated statement', NULL, v_options,
    now(), now() + interval '1 hour', now() + interval '2 hours',
    'B', 'Synthetic updated worked solution', false
  );

  IF v_updated_id IS DISTINCT FROM v_id THEN
    RAISE EXCEPTION 'Daily challenge authoring update returned a different ID';
  END IF;

  PERFORM set_config('blackjee.test_daily_challenge_id', v_id::text, false);
END;
$$;
RESET ROLE;
DO $$
DECLARE
  v_id uuid := current_setting('blackjee.test_daily_challenge_id')::uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.daily_challenges
    WHERE id = v_id
      AND title = 'Synthetic authoring update'
      AND statement = 'Synthetic authoring updated statement'
  ) THEN
    RAISE EXCEPTION 'Daily challenge authoring update did not persist';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM private.daily_challenge_answer_keys
    WHERE challenge_id = v_id
      AND correct_answer = 'B'
      AND solution = 'Synthetic updated worked solution'
  ) THEN
    RAISE EXCEPTION 'Daily challenge answer-key update did not persist';
  END IF;

  DELETE FROM public.daily_challenges WHERE id = v_id;

  IF EXISTS (SELECT 1 FROM public.daily_challenges WHERE id = v_id)
     OR EXISTS (SELECT 1 FROM private.daily_challenge_answer_keys WHERE challenge_id = v_id) THEN
    RAISE EXCEPTION 'Synthetic daily challenge fixture cleanup failed';
  END IF;
END;
$$;
SQL
echo "PASS: synthetic daily-challenge create/update/read-back/cleanup"

psql -X -v ON_ERROR_STOP=1 -qAt -c "DELETE FROM public.mock_test_attempts WHERE id = '$attempt_id'; DELETE FROM auth.users WHERE id IN ('$user_a', '$user_b');"
echo "PASS: disposable RPC negative authorization suite"
