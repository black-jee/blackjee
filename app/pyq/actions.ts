"use server";

import { z } from "zod";
import { createSupabaseServerClient } from "@/lib/supabase/server";

const gradeSchema = z.object({
  questionId: z.string().uuid(),
  answer: z.string().trim().min(1).max(100),
});

export type GradePyqResult =
  { ok: true; data: Record<string, unknown> } | { ok: false; error: string; code?: string };

export async function gradePyqQuestion(
  questionId: string,
  answer: string,
): Promise<GradePyqResult> {
  const parsed = gradeSchema.safeParse({ questionId, answer });
  if (!parsed.success) return { ok: false, error: "Choose an answer first." };

  const supabase = await createSupabaseServerClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user)
    return { ok: false, error: "Sign in to submit a practice answer.", code: "AUTH_REQUIRED" };

  const { data, error } = await supabase.rpc("grade_jee_pyq", {
    p_question_id: parsed.data.questionId,
    p_answer: parsed.data.answer,
  });
  if (error) return { ok: false, error: "The answer could not be graded. Please retry." };
  if (!data || typeof data !== "object" || Array.isArray(data))
    return { ok: false, error: "The grading response was invalid." };

  return { ok: true, data: data as Record<string, unknown> };
}
