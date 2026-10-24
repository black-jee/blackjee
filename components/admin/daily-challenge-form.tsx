"use client";

import { useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { saveDailyChallenge } from "@/app/admin/actions";

export function DailyChallengeForm() {
  const formRef = useRef<HTMLFormElement>(null);
  const router = useRouter();
  const [busy, startTransition] = useTransition();
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = event.currentTarget;
    const data = new FormData(form);
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await saveDailyChallenge(data);
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setMessage(`Challenge saved successfully. ID: ${result.id}`);
      formRef.current?.reset();
      router.refresh();
    });
  }

  return (
    <form ref={formRef} onSubmit={submit} className="space-y-5">
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block space-y-2 text-sm font-medium"><span>Results date</span><input type="date" name="challengeDate" required className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3" /></label>
        <label className="block space-y-2 text-sm font-medium"><span>Subject</span><select name="subject" required defaultValue="Physics" className="w-full rounded-xl border border-[var(--border)] bg-[#11131a] px-3 py-3"><option>Physics</option><option>Chemistry</option><option>Mathematics</option><option>Mixed</option></select></label>
      </div>
      <label className="block space-y-2 text-sm font-medium"><span>Challenge title</span><input name="title" minLength={3} maxLength={160} required placeholder="e.g. Daily challenge — Mechanics" className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3" /></label>
      <label className="block space-y-2 text-sm font-medium"><span>Question statement</span><textarea name="statement" required rows={5} maxLength={100000} placeholder="Use $...$ or \\( ... \\) around inline formulas." className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3 leading-6" /></label>
      <label className="block space-y-2 text-sm font-medium"><span>Question image path (optional)</span><input name="statementImagePath" maxLength={500} placeholder="assets/questions/example-diagram.png" className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3" /><span className="block text-xs font-normal text-[var(--muted)]">Use a relative path to a reviewed asset already present in the new application.</span></label>
      <label className="block space-y-2 text-sm font-medium"><span>Answer options (one per line)</span><textarea name="optionsText" rows={4} maxLength={20000} placeholder={"Option A\nOption B\nOption C\nOption D"} className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3 leading-6" /></label>
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block space-y-2 text-sm font-medium"><span>Correct answer</span><input name="correctAnswer" required placeholder="A, B, C, D or a numeric answer" className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3" /></label>
        <label className="block space-y-2 text-sm font-medium"><span>Official solution</span><textarea name="solution" rows={3} maxLength={100000} placeholder="Worked solution (kept private until release time)" className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3 leading-6" /></label>
      </div>
      <div className="rounded-2xl border border-[var(--border)] p-4">
        <p className="mb-3 text-sm font-semibold">Schedule — Indian Standard Time (IST)</p>
        <div className="grid gap-4 sm:grid-cols-3">
          <label className="block space-y-2 text-xs font-medium"><span>Starts at</span><input type="datetime-local" name="startsAt" required className="w-full min-w-0 rounded-xl border border-[var(--border)] bg-black/20 px-2 py-3" /></label>
          <label className="block space-y-2 text-xs font-medium"><span>Ends at</span><input type="datetime-local" name="endsAt" required className="w-full min-w-0 rounded-xl border border-[var(--border)] bg-black/20 px-2 py-3" /></label>
          <label className="block space-y-2 text-xs font-medium"><span>Solution releases</span><input type="datetime-local" name="solutionReleaseAt" required className="w-full min-w-0 rounded-xl border border-[var(--border)] bg-black/20 px-2 py-3" /></label>
        </div>
      </div>
      <label className="flex items-start gap-3 text-sm"><input type="checkbox" name="isLive" className="mt-1 accent-[var(--accent)]" /><span><strong>Publish as live</strong><span className="mt-1 block text-xs leading-5 text-[var(--muted)]">Only enable after verifying the question, options, answer, solution, schedule and image assets.</span></span></label>
      {error ? <p role="alert" className="rounded-xl border border-red-400/30 bg-red-400/10 p-3 text-sm text-red-200">{error}</p> : null}
      {message ? <p role="status" className="rounded-xl border border-[var(--accent)]/30 bg-[var(--accent)]/5 p-3 text-sm text-[var(--accent)]">{message}</p> : null}
      <button type="submit" disabled={busy} className="rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)] disabled:opacity-60">{busy ? "Saving…" : "Save challenge"}</button>
    </form>
  );
}
