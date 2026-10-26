"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";
import { safeInternalRedirectPath } from "@/lib/auth/safe-next-path";

export function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const requestedNext = searchParams.get("next");
  const safeNext = safeInternalRedirectPath(requestedNext);

  async function signIn(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      });
      if (signInError) throw signInError;
      router.replace(safeNext);
      router.refresh();
    } catch {
      setError("Unable to sign in. Check your credentials and try again.");
    } finally {
      setBusy(false);
    }
  }

  async function signInWithGoogle() {
    setBusy(true);
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const redirectTo = new URL("/auth/callback", window.location.origin);
      redirectTo.searchParams.set("next", safeNext);
      const { error: oauthError } = await supabase.auth.signInWithOAuth({
        provider: "google",
        options: { redirectTo: redirectTo.toString() },
      });
      if (oauthError) throw oauthError;
    } catch (cause) {
      setError("Google sign-in is unavailable. Please try again.");
      setBusy(false);
    }
  }

  return (
    <div className="space-y-5">
      <button
        type="button"
        onClick={signInWithGoogle}
        disabled={busy}
        className="w-full rounded-xl border border-[var(--border)] px-4 py-3 text-sm font-semibold hover:bg-white/5 disabled:opacity-60"
      >
        Continue with Google
      </button>
      <div className="flex items-center gap-3 text-xs text-[var(--muted)]">
        <span className="h-px flex-1 bg-[var(--border)]" />
        <span>or use email</span>
        <span className="h-px flex-1 bg-[var(--border)]" />
      </div>
      <form onSubmit={signIn} className="space-y-4">
        <label className="block space-y-2 text-sm font-medium">
          <span>Email address</span>
          <input
            type="email"
            autoComplete="email"
            required
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3 outline-none focus:border-[var(--accent)]"
          />
        </label>
        <label className="block space-y-2 text-sm font-medium">
          <span>Password</span>
          <input
            type="password"
            autoComplete="current-password"
            required
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3 outline-none focus:border-[var(--accent)]"
          />
        </label>
        {error ? (
          <p
            role="alert"
            className="rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-sm text-red-200"
          >
            {error}
          </p>
        ) : null}
        <button
          type="submit"
          disabled={busy}
          className="w-full rounded-xl bg-[var(--accent)] px-4 py-3 text-sm font-bold text-[var(--accent-foreground)] disabled:opacity-60"
        >
          {busy ? "Please wait…" : "Sign in"}
        </button>
      </form>
      <a
        href="/auth/reset-password"
        className="block text-center text-sm text-[var(--muted)] underline underline-offset-4 hover:text-[var(--text)]"
      >
        Forgot password?
      </a>
    </div>
  );
}
