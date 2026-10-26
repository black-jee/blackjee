import "server-only";

import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

/**
 * Enforces administrator access on the server. UI visibility is never the security boundary.
 * Authorization is read from server-managed app_metadata, not user-editable user_metadata.
 */
export async function requireAdmin(nextPath = "/admin") {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.auth.getUser();

  if (error || !data.user) redirect(`/login?next=${encodeURIComponent(nextPath)}`);

  if (data.user.app_metadata?.role !== "admin") {
    redirect("/?access=denied");
  }

  return { supabase, user: data.user };
}
