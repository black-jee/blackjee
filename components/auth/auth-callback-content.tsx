"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";

export default function AuthCallbackContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [message, setMessage] = useState("Completing sign-in…");

  useEffect(() => {
    let active = true;
    async function completeAuth() {
      const requestedNext = searchParams.get("next");
      const safeNext = requestedNext?.startsWith("/") && !requestedNext.startsWith("//") ? requestedNext : "/";
      const code = searchParams.get("code");
      const authError = searchParams.get("error_description") ?? searchParams.get("error");
      if (authError || !code) {
        if (active) { setMessage("Sign-in could not be completed. Please try again."); router.replace("/login?error=oauth_callback"); }
        return;
      }
      try {
        const supabase = createSupabaseBrowserClient();
        const { error } = await supabase.auth.exchangeCodeForSession(code);
        if (error) throw error;
        if (active) router.replace(safeNext);
      } catch {
        if (active) { setMessage("Sign-in could not be completed. Please try again."); router.replace("/login?error=oauth_exchange"); }
      }
    }
    void completeAuth();
    return () => { active = false; };
  }, [router, searchParams]);

  return <main className="mx-auto flex min-h-screen max-w-lg flex-col justify-center px-5 py-12"><section className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-7"><p role="status" className="text-sm text-[var(--muted)]">{message}</p></section></main>;
}
