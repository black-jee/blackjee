"use server";

import { z } from "zod";
import { createSupabaseServerClient } from "@/lib/supabase/server";

const challengeIdSchema = z.string().uuid();
const answerSchema = z.object({
  challengeId: z.string().uuid(),
  answer: z.string().trim().min(1).max(500),
});

export type ChallengeActionResult =
  | { ok: true; data: Record<string, unknown> }
  | { ok: false; error: string; code?: string };

async function requireUser() {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) return { supabase, error: "Sign in is required." };
  return { supabase, error: null };
}

export async function startChallenge(challengeId: string): Promise<ChallengeActionResult> {
  const parsed = challengeIdSchema.safeParse(challengeId);
  if (!parsed.success) return { ok: false, error: "Invalid challenge identifier." };

  const { supabase, error: authError } = await requireUser();
  if (authError) return { ok: false, error: authError, code: "AUTH_REQUIRED" };

  const { data, error } = await supabase.rpc("start_daily_challenge", { p_challenge_id: parsed.data });
  if (error) return { ok: false, error: "Could not start this challenge.", code: error.code };
  if (!data || typeof data !== "object" || Array.isArray(data)) return { ok: false, error: "The challenge response was invalid." };
  return { ok: true, data: data as Record<string, unknown> };
}

export async function submitChallenge(challengeId: string, answer: string): Promise<ChallengeActionResult> {
  const parsed = answerSchema.safeParse({ challengeId, answer });
  if (!parsed.success) return { ok: false, error: "Choose a valid answer before submitting." };

  const { supabase, error: authError } = await requireUser();
  if (authError) return { ok: false, error: authError, code: "AUTH_REQUIRED" };

  const { data, error } = await supabase.rpc("submit_daily_challenge", {
    p_challenge_id: parsed.data.challengeId,
    p_answer: parsed.data.answer,
  });
  if (error) return { ok: false, error: "Could not submit this answer. Check whether the attempt is still open.", code: error.code };
  if (!data || typeof data !== "object" || Array.isArray(data)) return { ok: false, error: "The submission response was invalid." };
  return { ok: true, data: data as Record<string, unknown> };
}

export async function getChallengeResult(challengeId: string): Promise<ChallengeActionResult> {
  const parsed = challengeIdSchema.safeParse(challengeId);
  if (!parsed.success) return { ok: false, error: "Invalid challenge identifier." };

  const { supabase, error: authError } = await requireUser();
  if (authError) return { ok: false, error: authError, code: "AUTH_REQUIRED" };

  const { data, error } = await supabase.rpc("get_daily_challenge_result", { p_challenge_id: parsed.data });
  if (error) return { ok: false, error: "Could not load the official solution yet.", code: error.code };
  if (!data || typeof data !== "object" || Array.isArray(data)) return { ok: false, error: "The result response was invalid." };
  return { ok: true, data: data as Record<string, unknown> };
}
