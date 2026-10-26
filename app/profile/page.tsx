import type { Metadata } from "next";
import Link from "next/link";
import { SiteHeader } from "@/components/site-header";
import { SignOutButton } from "@/components/auth/sign-out-button";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Your profile" };
export const dynamic = "force-dynamic";

type Attempt = {
  id: string;
  selected_answer: string;
  is_correct: boolean;
  elapsed_seconds: number;
  submitted_at: string;
  daily_challenges?: { title?: string; challenge_date?: string; subject?: string } | null;
};

export default async function ProfilePage() {
  const supabase = await createSupabaseServerClient();
  const { data: auth } = await supabase.auth.getUser();
  const user = auth.user;

  if (!user) {
    return (
      <main className="mx-auto flex min-h-screen max-w-3xl flex-col justify-center px-5 py-12">
        <Link href="/" className="mb-8 text-sm font-bold tracking-[0.18em]">
          BLACK-JEE
        </Link>
        <section className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-7">
          <h1 className="text-3xl font-semibold tracking-tight">Your profile</h1>
          <p className="mt-3 text-sm leading-6 text-[var(--muted)]">
            Sign in to see your challenge history and account details.
          </p>
          <a
            href="/login?next=%2Fprofile"
            className="mt-5 inline-flex rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)]"
          >
            Sign in
          </a>
        </section>
      </main>
    );
  }

  const { data, error } = await supabase
    .from("daily_challenge_attempts")
    .select(
      "id, selected_answer, is_correct, elapsed_seconds, submitted_at, daily_challenges(title, challenge_date, subject)",
    )
    .eq("user_id", user.id)
    .order("submitted_at", { ascending: false })
    .limit(30);

  const attempts = (data ?? []) as unknown as Attempt[];

  return (
    <main className="mx-auto min-h-screen max-w-4xl px-5 py-6 sm:px-8 lg:py-12">
      <SiteHeader />
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--muted)]">
        Student account
      </p>
      <h1 className="mt-2 text-4xl font-semibold tracking-tight">Your profile</h1>
      <section className="mt-7 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5">
        <p className="text-xs uppercase tracking-widest text-[var(--muted)]">Signed-in email</p>
        <p className="mt-2 break-all font-medium">{user.email ?? "Email not available"}</p>
        <p className="mt-2 text-xs text-[var(--muted)]">
          Your private attempt history is loaded under your authenticated user identity and database
          row-level security.
        </p>
      </section>
      <section className="mt-8">
        <div className="flex items-end justify-between gap-4">
          <h2 className="text-2xl font-semibold tracking-tight">Challenge history</h2>
          <span className="text-xs text-[var(--muted)]">Latest 30</span>
        </div>
        {error ? (
          <p
            role="alert"
            className="mt-4 rounded-xl border border-red-400/30 bg-red-400/10 p-4 text-sm text-red-200"
          >
            Your history could not be loaded right now.
          </p>
        ) : null}
        {!error && attempts.length === 0 ? (
          <p className="mt-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5 text-sm text-[var(--muted)]">
            No challenge attempts yet. Your completed attempts will appear here.
          </p>
        ) : null}
        <div className="mt-4 space-y-3">
          {attempts.map((attempt) => (
            <article
              key={attempt.id}
              className="flex flex-col gap-3 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4 sm:flex-row sm:items-center sm:justify-between"
            >
              <div>
                <p className="font-semibold">
                  {attempt.daily_challenges?.title ?? "Daily challenge"}
                </p>
                <p className="mt-1 text-xs text-[var(--muted)]">
                  {attempt.daily_challenges?.subject ?? "Mixed"} ·{" "}
                  {attempt.daily_challenges?.challenge_date ??
                    new Date(attempt.submitted_at).toLocaleDateString()}
                </p>
              </div>
              <div className="flex items-center gap-4 text-sm">
                <span
                  className={attempt.is_correct ? "text-[var(--accent)]" : "text-[var(--muted)]"}
                >
                  {attempt.is_correct ? "Correct" : "Incorrect"}
                </span>
                <span className="font-mono tabular-nums">
                  {Math.floor(attempt.elapsed_seconds / 60)}m {attempt.elapsed_seconds % 60}s
                </span>
              </div>
            </article>
          ))}
        </div>
      </section>
      <a
        href="/challenge"
        className="mt-8 inline-flex rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)]"
      >
        Go to daily challenge
      </a>
    </main>
  );
}
