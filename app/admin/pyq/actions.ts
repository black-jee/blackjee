"use server";

import { z } from "zod";
import { isSafeAssetPath } from "@/lib/questions/schema";
import { createSupabaseServerClient } from "@/lib/supabase/server";

const optionSchema = z
  .array(
    z.object({
      id: z.string().trim().min(1).max(20),
      label: z.string().trim().min(1).max(12),
      text: z.string().max(4000).default(""),
      imagePath: z.string().trim().max(500).optional(),
    }),
  )
  .min(2)
  .max(12);

const questionSchema = z.object({
  questionId: z.string().uuid().nullable(),
  sourceId: z.string().trim().max(160),
  title: z.string().trim().min(3).max(240),
  exam: z.string().trim().max(80),
  year: z.number().int().min(2000).max(2100).nullable(),
  session: z.string().trim().max(120),
  subject: z.enum(["Physics", "Chemistry", "Mathematics"]),
  chapter: z.string().trim().max(160),
  statement: z.string().trim().min(1).max(100000),
  statementImagePath: z.string().trim().max(500),
  options: optionSchema,
  questionType: z.enum(["single_correct", "numerical"]),
  marksCorrect: z.number().int().min(1).max(20),
  marksWrong: z.number().int().min(-20).max(0),
  correctAnswer: z.string().trim().min(1).max(100),
  solution: z.string().max(100000),
  sourcePdf: z.string().trim().max(500),
  sourcePage: z.number().int().min(1).max(10000).nullable(),
  tags: z.array(z.string().trim().min(1).max(80)).max(30),
  assetPaths: z.array(z.string().trim().min(1).max(500)).max(100),
  reviewNotes: z.array(z.string().trim().min(1).max(1000)).max(30).optional(),
});

export type PyqActionResult = { ok: true; id?: string } | { ok: false; error: string };

async function getAdminClient() {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user || data.user.app_metadata?.role !== "admin") {
    return { supabase, authorized: false };
  }
  return { supabase, authorized: true };
}

export async function savePyqQuestion(input: unknown): Promise<PyqActionResult> {
  const parsed = questionSchema.safeParse(input);
  if (!parsed.success)
    return { ok: false, error: parsed.error.issues[0]?.message ?? "Check the question fields." };
  const q = parsed.data;
  if (q.statementImagePath && !isSafeAssetPath(q.statementImagePath))
    return { ok: false, error: "Question image path must be a safe relative path." };
  if (q.assetPaths.some((path) => !isSafeAssetPath(path)))
    return { ok: false, error: "An asset path is unsafe." };
  if (q.options.some((option) => option.imagePath && !isSafeAssetPath(option.imagePath)))
    return { ok: false, error: "An option image path is unsafe." };
  if (
    q.questionType === "single_correct" &&
    !q.options.some((option) => option.label.toUpperCase() === q.correctAnswer.toUpperCase())
  ) {
    return { ok: false, error: "The answer key must match an option label." };
  }

  const { supabase, authorized } = await getAdminClient();
  if (!authorized) return { ok: false, error: "Administrator access is required." };
  const { data, error } = await supabase.rpc("admin_save_jee_pyq_question", {
    p_question_id: q.questionId,
    p_source_id: q.sourceId || null,
    p_title: q.title,
    p_exam: q.exam || "JEE Main",
    p_year: q.year,
    p_session: q.session || null,
    p_subject: q.subject,
    p_chapter: q.chapter || null,
    p_statement: q.statement,
    p_statement_image_path: q.statementImagePath || null,
    p_options: q.options,
    p_question_type: q.questionType,
    p_marks_correct: q.marksCorrect,
    p_marks_wrong: q.marksWrong,
    p_correct_answer: q.correctAnswer,
    p_solution: q.solution,
    p_source_pdf: q.sourcePdf || null,
    p_source_page: q.sourcePage,
    p_tags: q.tags,
    p_asset_paths: q.assetPaths,
    p_review_notes: q.reviewNotes,
  });
  if (error || typeof data !== "string")
    return {
      ok: false,
      error: "Question was not saved. Confirm the source ID is unique and all fields are valid.",
    };
  return { ok: true, id: data };
}

export async function reviewPyqQuestion(input: unknown): Promise<PyqActionResult> {
  const parsed = z
    .object({
      questionId: z.string().uuid(),
      approve: z.boolean(),
      publish: z.boolean(),
      reviewNotes: z.array(z.string().trim().min(1).max(1000)).max(30),
    })
    .safeParse(input);
  if (!parsed.success) return { ok: false, error: "Invalid review request." };
  if (parsed.data.publish && !parsed.data.approve)
    return { ok: false, error: "Approve the question before publishing." };

  const { supabase, authorized } = await getAdminClient();
  if (!authorized) return { ok: false, error: "Administrator access is required." };
  const { data, error } = await supabase.rpc("admin_review_jee_pyq_question", {
    p_question_id: parsed.data.questionId,
    p_approve: parsed.data.approve,
    p_publish: parsed.data.publish,
    p_review_notes: parsed.data.reviewNotes?.length ? parsed.data.reviewNotes : null,
  });
  if (error || !data || typeof data !== "object")
    return {
      ok: false,
      error:
        "Review action failed. The database requires a valid private answer key before publication.",
    };
  return { ok: true, id: parsed.data.questionId };
}
