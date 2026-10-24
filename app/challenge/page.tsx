import type { Metadata } from "next";
import Link from "next/link";
import { ChallengeAttempt } from "@/components/challenge/challenge-attempt";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Daily challenge" };
export const dynamic = "force-dynamic";

type Schedule = {
  id: string;
  challenge_date: string;
  title: string;
  subject: string;
  starts_at: string;
  ends_at: string;
  solution_release_at: string;
};

export default async function ChallengePage() {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc("get_current_daily_challenge");
  const schedule =
    data && typeof data === "object" && !Array.isArray(data) ? (data as Schedule) : null;

  return (
    <main className="mx-auto min-h-screen w-full max-w-4xl px-5 py-6 sm:px-8 lg:py-12">
      <header className="mb-8 flex items-center justify-between border-b border-[var(--border)] pb-5">
        <Link href="/" className="flex items-center gap-3">
          <span className="grid size-9 place-items-center rounded-lg bg-[var(--accent)] text-xs font-black text-[var(--accent-foreground)]">
            BJ
          </span>
          <span className="text-sm font-bold tracking-[0.18em]">BLACK-JEE</span>
        </Link>
        <a href="/profile" className="text-sm text-[var(--muted)] underline underline-offset-4">
          Profile
        </a>
      </header>
      <p className="mb-2 text-xs font-bold uppercase tracking-[0.2em] text-[var(--muted)]">
        Train with intent
      </p>
      <h1 className="mb-7 text-4xl font-semibold tracking-tight sm:text-5xl">Daily challenge</h1>
      {error ? (
        <div
          role="alert"
          className="rounded-xl border border-red-400/30 bg-red-400/10 p-4 text-sm text-red-200"
        >
          Could not load the challenge schedule. Please retry shortly.
        </div>
      ) : null}
      {!error && !schedule ? (
        <section className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-7">
          <p className="text-lg font-semibold">No active challenge right now</p>
          <p className="mt-2 text-sm leading-6 text-[var(--muted)]">
            The next scheduled challenge will appear here when its attempt window opens.
          </p>
          <Link
            href="/"
            className="mt-5 inline-flex rounded-xl border border-[var(--border)] px-4 py-2.5 text-sm font-semibold"
          >
            Back to dashboard
          </Link>
        </section>
      ) : null}
      {schedule ? <ChallengeAttempt schedule={schedule} /> : null}
      <p className="mt-6 text-xs leading-5 text-[var(--muted)]">
        This flow uses the new BLACK-JEE Supabase project. The original production website remains
        unchanged.
      </p>
    </main>
  );
}
