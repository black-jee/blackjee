"use server";

import { z } from "zod";
import { isSafeAssetPath } from "@/lib/questions/schema";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { isValidIstLocalDateTime, istLocalDateTimeToIso } from "@/lib/time/ist-local-date-time";

const localDateTime = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/, "Use a valid date and time.")
  .refine(isValidIstLocalDateTime, "Use a real calendar date and time.");

const challengeFormSchema = z.object({
  challengeDate: z.string().date(),
  title: z.string().trim().min(3).max(160),
  subject: z.enum(["Physics", "Chemistry", "Mathematics", "Mixed"]),
  statement: z.string().trim().min(1).max(100_000),
  statementImagePath: z.string().trim().max(500),
  optionsText: z.string().max(20_000),
  correctAnswer: z.string().trim().min(1).max(100),
  solution: z.string().max(100_000),
  startsAt: localDateTime,
  endsAt: localDateTime,
  solutionReleaseAt: localDateTime,
  isLive: z.boolean(),
});

function istIso(value: string): string {
  return new Date(`${value}:00+05:30`).toISOString();
}

export type SaveChallengeResult = { ok: true; id: string } | { ok: false; error: string };

export async function saveDailyChallenge(formData: FormData): Promise<SaveChallengeResult> {
  const raw = {
    challengeDate: String(formData.get("challengeDate") ?? ""),
    title: String(formData.get("title") ?? ""),
    subject: String(formData.get("subject") ?? ""),
    statement: String(formData.get("statement") ?? ""),
    statementImagePath: String(formData.get("statementImagePath") ?? ""),
    optionsText: String(formData.get("optionsText") ?? ""),
    correctAnswer: String(formData.get("correctAnswer") ?? ""),
    solution: String(formData.get("solution") ?? ""),
    startsAt: String(formData.get("startsAt") ?? ""),
    endsAt: String(formData.get("endsAt") ?? ""),
    solutionReleaseAt: String(formData.get("solutionReleaseAt") ?? ""),
    isLive: formData.get("isLive") === "on",
  };

  const parsed = challengeFormSchema.safeParse(raw);
  if (!parsed.success)
    return { ok: false, error: parsed.error.issues[0]?.message ?? "Check the form values." };

  const values = parsed.data;
  if (values.statementImagePath && !isSafeAssetPath(values.statementImagePath)) {
    return { ok: false, error: "The question image path must be a safe relative path." };
  }

  const startsAt = istLocalDateTimeToIso(values.startsAt);
  const endsAt = istLocalDateTimeToIso(values.endsAt);
  const solutionReleaseAt = istLocalDateTimeToIso(values.solutionReleaseAt);
  if (!(
    Date.parse(startsAt) < Date.parse(endsAt) && Date.parse(endsAt) <= Date.parse(solutionReleaseAt)
  )) {
    return {
      ok: false,
      error:
        "Schedule must start before it ends, and the solution release must be at or after the end.",
    };
  }

  const optionLines = values.optionsText
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);
  if (optionLines.length > 12) {
    return { ok: false, error: "A daily challenge can have at most 12 options." };
  }

  const options = optionLines.map((text, index) => ({
    id: String.fromCharCode(97 + index),
    label: String.fromCharCode(65 + index),
    text,
  }));
  const correctAnswer = values.correctAnswer.trim().toUpperCase();
  if (options.length > 0 && !options.some((option) => option.label === correctAnswer)) {
    return { ok: false, error: "Correct answer must match one of the option labels (A, B, C…)."};
  }

  const supabase = await createSupabaseServerClient();
  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user || auth.user.app_metadata?.role !== "admin") {
    return { ok: false, error: "Administrator access is required." };
  }

  const { data, error } = await supabase.rpc("admin_save_daily_challenge", {
    p_challenge_id: null,
    p_challenge_date: values.challengeDate,
    p_title: values.title,
    p_subject: values.subject,
    p_statement: values.statement,
    p_statement_image_path: values.statementImagePath || null,
    p_options: options,
    p_starts_at: startsAt,
    p_ends_at: endsAt,
    p_solution_release_at: solutionReleaseAt,
    p_correct_answer: correctAnswer,
    p_solution: values.solution,
    p_is_live: values.isLive,
  });

  if (error || typeof data !== "string")
    return {
      ok: false,
      error: "Challenge could not be saved. Check the date, schedule, and administrator role.",
    };
  return { ok: true, id: data };
}
