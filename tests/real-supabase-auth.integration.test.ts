import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/**
 * Optional real-Supabase-Auth integration suite.
 *
 * It is skipped unless every required environment variable points to an
 * isolated disposable Supabase project with pre-seeded synthetic fixtures.
 * Never point these variables at the production project.
 */
const env = {
  url: process.env.BLACKJEE_AUTH_TEST_URL,
  key: process.env.BLACKJEE_AUTH_TEST_PUBLISHABLE_KEY,
  studentAEmail: process.env.BLACKJEE_AUTH_TEST_STUDENT_A_EMAIL,
  studentAPassword: process.env.BLACKJEE_AUTH_TEST_STUDENT_A_PASSWORD,
  studentBEmail: process.env.BLACKJEE_AUTH_TEST_STUDENT_B_EMAIL,
  studentBPassword: process.env.BLACKJEE_AUTH_TEST_STUDENT_B_PASSWORD,
  adminEmail: process.env.BLACKJEE_AUTH_TEST_ADMIN_EMAIL,
  adminPassword: process.env.BLACKJEE_AUTH_TEST_ADMIN_PASSWORD,
  bInProgressAttemptId: process.env.BLACKJEE_AUTH_TEST_B_IN_PROGRESS_ATTEMPT_ID,
  bSubmittedAttemptId: process.env.BLACKJEE_AUTH_TEST_B_SUBMITTED_ATTEMPT_ID,
  unreleasedChallengeId: process.env.BLACKJEE_AUTH_TEST_UNRELEASED_CHALLENGE_ID,
};

const enabled = Object.values(env).every((value) => Boolean(value?.trim()));

function makeClient(): SupabaseClient {
  if (!env.url || !env.key) {
    throw new Error("Real Supabase Auth integration environment is incomplete.");
  }

  return createClient(env.url, env.key, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });
}

describe.skipIf(!enabled)("real Supabase Auth authorization integration", () => {
  let anonymous: SupabaseClient | undefined;
  let studentA: SupabaseClient | undefined;
  let studentB: SupabaseClient | undefined;
  let admin: SupabaseClient | undefined;

  beforeAll(async () => {
    anonymous = makeClient();
    studentA = makeClient();
    studentB = makeClient();
    admin = makeClient();

    const signIns = await Promise.all([
      studentA.auth.signInWithPassword({
        email: env.studentAEmail!,
        password: env.studentAPassword!,
      }),
      studentB.auth.signInWithPassword({
        email: env.studentBEmail!,
        password: env.studentBPassword!,
      }),
      admin.auth.signInWithPassword({
        email: env.adminEmail!,
        password: env.adminPassword!,
      }),
    ]);

    for (const result of signIns) {
      expect(result.error, "Synthetic test user must sign in through Supabase Auth").toBeNull();
      expect(result.data.session?.access_token).toBeTruthy();
    }

    const adminUser = await admin!.auth.getUser();
    expect(adminUser.error).toBeNull();
    expect(adminUser.data.user?.app_metadata?.role).toBe("admin");
  });

  afterAll(async () => {
    await Promise.all([
      studentA?.auth.signOut(),
      studentB?.auth.signOut(),
      admin?.auth.signOut(),
    ]);
  });

  it("denies anonymous calls to protected mock-test RPCs", async () => {
    const calls = await Promise.all([
      anonymous!.rpc("resume_mock_test", {
        p_attempt_id: env.bInProgressAttemptId!,
      }),
      anonymous.rpc("get_mock_test_result", {
        p_attempt_id: env.bSubmittedAttemptId!,
      }),
    ]);

    expect(calls.every((result) => result.error !== null)).toBe(true);
    expect(calls.every((result) => result.data === null)).toBe(true);
  });

  it("prevents student A from resuming student B's in-progress attempt", async () => {
    const result = await studentA!.rpc("resume_mock_test", {
      p_attempt_id: env.bInProgressAttemptId!,
    });

    expect(result.error).not.toBeNull();
    expect(result.data).toBeNull();
  });

  it("prevents student A from submitting to student B's attempt", async () => {
    const result = await studentA.rpc("submit_mock_test", {
      p_attempt_id: env.bInProgressAttemptId!,
      p_answers: [],
    });

    expect(result.error).not.toBeNull();
    expect(result.data).toBeNull();
  });

  it("prevents student A from reading student B's submitted result", async () => {
    const result = await studentA.rpc("get_mock_test_result", {
      p_attempt_id: env.bSubmittedAttemptId!,
    });

    expect(result.error).not.toBeNull();
    expect(result.data).toBeNull();
  });

  it("rejects admin authoring by an ordinary authenticated student", async () => {
    const result = await studentA.rpc("admin_save_daily_challenge", {
      p_challenge_id: null,
      p_challenge_date: null,
      p_title: null,
      p_subject: null,
      p_statement: null,
      p_statement_image_path: null,
      p_options: null,
      p_starts_at: null,
      p_ends_at: null,
      p_solution_release_at: null,
      p_correct_answer: null,
      p_solution: null,
      p_is_live: false,
    });

    expect(result.error).not.toBeNull();
    expect(result.data).toBeNull();
  });

  it("does not reveal an unreleased daily-challenge answer or solution", async () => {
    const result = await studentA.rpc("get_daily_challenge_result", {
      p_challenge_id: env.unreleasedChallengeId!,
    });

    expect(result.error).toBeNull();
    expect(result.data).toMatchObject({ solution_released: false });
    expect(result.data).not.toHaveProperty("correct_answer");
    expect(result.data).not.toHaveProperty("solution");
  });

  it("does not grant direct browser access to the private answer-key schema", async () => {
    const result = await studentA!
      .schema("private")
      .from("jee_pyq_answer_keys")
      .select("correct_answer")
      .limit(1);

    expect(result.error).not.toBeNull();
    expect(result.data).toBeNull();
  });
});
