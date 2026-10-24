"use client";

import { useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";

export function ResetPasswordForm() {
  const [email, setEmail] = useState("");
  const [busy, setBusy] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    setSent(false);
    try {
      const supabase = createSupabaseBrowserClient();
      const redirectTo = new URL("/auth/update-password", window.location.origin).toString();
      const { error: requestError } = await supabase.auth.resetPasswordForEmail(email.trim(), { redirectTo });
      if (requestError) throw requestError;
      setSent(true);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Could not request a password reset.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="space-y-4">
      <label className="block space-y-2 text-sm font-medium">
        <span>Email address</span>
        <input type="email" autoComplete="email" required value={email} onChange={(event) => setEmail(event.target.value)} className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3 outline-none focus:border-[var(--accent)]" />
      </label>
      {sent ? <p role="status" className="rounded-lg border border-[var(--accent)]/30 bg-[var(--accent)]/5 px-3 py-2 text-sm">If the account is eligible, a reset link will be sent to this address.</p> : null}
      {error ? <p role="alert" className="rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-sm text-red-200">{error}</p> : null}
      <button type="submit" disabled={busy} className="w-full rounded-xl bg-[var(--accent)] px-4 py-3 text-sm font-bold text-[var(--accent-foreground)] disabled:opacity-60">{busy ? "Sending…" : "Send reset link"}</button>
    </form>
  );
}
