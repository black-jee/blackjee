"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";

export function UpdatePasswordForm() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage(null);
    setError(null);
    if (password.length < 12) return setError("Choose a password with at least 12 characters.");
    if (password !== confirm) return setError("The passwords do not match.");

    setBusy(true);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: updateError } = await supabase.auth.updateUser({ password });
      if (updateError) throw updateError;
      setMessage("Password updated. You can continue to BLACK-JEE.");
      setPassword("");
      setConfirm("");
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Could not update the password.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="space-y-4">
      <label className="block space-y-2 text-sm font-medium"><span>New password</span><input type="password" autoComplete="new-password" minLength={12} required value={password} onChange={(event) => setPassword(event.target.value)} className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3 outline-none focus:border-[var(--accent)]" /></label>
      <label className="block space-y-2 text-sm font-medium"><span>Confirm password</span><input type="password" autoComplete="new-password" minLength={12} required value={confirm} onChange={(event) => setConfirm(event.target.value)} className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3 outline-none focus:border-[var(--accent)]" /></label>
      {message ? <p role="status" className="text-sm text-[var(--accent)]">{message}</p> : null}
      {error ? <p role="alert" className="text-sm text-red-200">{error}</p> : null}
      <button type="submit" disabled={busy} className="w-full rounded-xl bg-[var(--accent)] px-4 py-3 text-sm font-bold text-[var(--accent-foreground)] disabled:opacity-60">{busy ? "Updating…" : "Update password"}</button>
      {message ? <button type="button" onClick={() => router.replace("/login")} className="w-full rounded-xl border border-[var(--border)] px-4 py-3 text-sm">Return to sign in</button> : null}
    </form>
  );
}
