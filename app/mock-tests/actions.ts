"use server";

import { z } from "zod";
import { createSupabaseServerClient } from "@/lib/supabase/server";

const startSchema = z.object({
  mode: z.enum(["shift", "focused"]),
  year: z.number().int().min(2000).max(2100).nullable(),
  session: z.string().trim().max(120).nullable(),
  subject: z.enum(["Physics", "Chemistry", "Mathematics"]).nullable(),
  chapter: z.string().trim().max(160).nullable(),
  questionCount: z.union([z.literal(10), z.literal(20), z.literal(30), z.literal(75)]),
  durationSeconds: z.number().int().min(0).max(10800),
});

const answerSchema = z
  .array(
    z.object({
      question_id: z.string().uuid(),
      answer: z.string().max(100),
    }),
  )
  .max(75);

export type MockTestActionResult =
  { ok: true; data: Record<string, unknown> } | { ok: false; error: string; code?: string };

async function getAuthenticatedClient() {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) return { supabase, userId: null };
  return { supabase, userId: data.user.id };
}

export async function startMockTest(input: unknown): Promise<MockTestActionResult> {
  const parsed = startSchema.safeParse(input);
  if (!parsed.success) return { ok: false, error: "Check the test settings and try again." };
  if (parsed.data.mode === "shift" && (!parsed.data.year || !parsed.data.session)) {
    return { ok: false, error: "Choose a year and shift first." };
  }

  const { supabase, userId } = await getAuthenticatedClient();
  if (!userId) return { ok: false, error: "Sign in to start a mock test.", code: "AUTH_REQUIRED" };

  const { data, error } = await supabase.rpc("start_mock_test", {
    p_mode: parsed.data.mode,
    p_year: parsed.data.mode === "shift" ? parsed.data.year : null,
    p_session: parsed.data.mode === "shift" ? parsed.data.session : null,
    p_subject: parsed.data.subject,
    p_chapter: parsed.data.chapter || null,
    p_question_count: parsed.data.questionCount,
    p_duration_seconds: parsed.data.durationSeconds,
  });
  if (error)
    return {
      ok: false,
      error: error.message.includes("verified 75-question")
        ? error.message
        : "A test could not be started. The selected bank may not have enough reviewed questions with verified answer keys.",
      code: error.code,
    };
  if (!data || typeof data !== "object" || Array.isArray(data))
    return { ok: false, error: "The test response was invalid." };
  return { ok: true, data: data as Record<string, unknown> };
}

export async function resumeMockTest(attemptId: string): Promise<MockTestActionResult> {
  const parsedId = z.string().uuid().safeParse(attemptId);
  if (!parsedId.success) return { ok: false, error: "Invalid mock test identifier." };
  const { supabase, userId } = await getAuthenticatedClient();
  if (!userId) return { ok: false, error: "Sign in to resume this test.", code: "AUTH_REQUIRED" };
  const { data, error } = await supabase.rpc("resume_mock_test", { p_attempt_id: parsedId.data });
  if (error) return { ok: false, error: "This mock test is no longer available to resume." };
  if (!data || typeof data !== "object" || Array.isArray(data))
    return { ok: false, error: "The resume response was invalid." };
  return { ok: true, data: data as Record<string, unknown> };
}

export async function submitMockTest(
  attemptId: string,
  answers: unknown,
): Promise<MockTestActionResult> {
  const parsedId = z.string().uuid().safeParse(attemptId);
  const parsedAnswers = answerSchema.safeParse(answers);
  if (!parsedId.success || !parsedAnswers.success)
    return { ok: false, error: "The submitted answers were invalid." };

  const { supabase, userId } = await getAuthenticatedClient();
  if (!userId) return { ok: false, error: "Sign in to submit this test.", code: "AUTH_REQUIRED" };

  const { data, error } = await supabase.rpc("submit_mock_test", {
    p_attempt_id: parsedId.data,
    p_answers: parsedAnswers.data,
  });
  if (error)
    return {
      ok: false,
      error: "The test could not be submitted. Its server-side time limit may have passed.",
    };
  if (!data || typeof data !== "object" || Array.isArray(data))
    return { ok: false, error: "The results response was invalid." };
  return { ok: true, data: data as Record<string, unknown> };
}
