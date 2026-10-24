import type { Metadata } from "next";
import { DailyChallengeForm } from "@/components/admin/daily-challenge-form";
import { requireAdmin } from "@/lib/auth/require-admin";

export const metadata: Metadata = { title: "Admin dashboard" };
export const dynamic = "force-dynamic";

type ChallengeRow = {
  id: string;
  challenge_date: string;
  title: string;
  subject: string;
  starts_at: string;
  ends_at: string;
  solution_release_at: string;
  is_live: boolean;
};

export default async function AdminPage() {
  const { supabase, user } = await requireAdmin();
  const { data, error } = await supabase
    .from("daily_challenges")
    .select("id, challenge_date, title, subject, starts_at, ends_at, solution_release_at, is_live")
    .order("challenge_date", { ascending: false })
    .limit(30);

  const challenges = (data ?? []) as ChallengeRow[];

  return (
    <main className="mx-auto min-h-screen max-w-6xl px-5 py-6 sm:px-8 lg:py-12">
      <header className="mb-8 flex items-center justify-between border-b border-[var(--border)] pb-5">
        <a href="/" className="flex items-center gap-3"><span className="grid size-9 place-items-center rounded-lg bg-[var(--accent)] text-xs font-black text-[var(--accent-foreground)]">BJ</span><span className="text-sm font-bold tracking-[0.18em]">BLACK-JEE ADMIN</span></a>
        <a href="/profile" className="text-sm text-[var(--muted)] underline underline-offset-4">Account</a>
      </header>
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--accent)]">Restricted workspace</p>
      <h1 className="mt-2 text-4xl font-semibold tracking-tight sm:text-5xl">Admin dashboard</h1>
      <p className="mt-3 text-sm text-[var(--muted)]">Signed in as {user.email ?? "administrator"}. Every write is checked by the server and the database.</p>

      <section className="mt-8 rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-7">
        <h2 className="mb-5 text-2xl font-semibold tracking-tight">Create daily challenge</h2>
        <DailyChallengeForm />
      </section>

      <section className="mt-10">
        <div className="flex items-end justify-between gap-4"><h2 className="text-2xl font-semibold tracking-tight">Scheduled challenges</h2><span className="text-xs text-[var(--muted)]">Latest 30</span></div>
        {error ? <p role="alert" className="mt-4 rounded-xl border border-red-400/30 bg-red-400/10 p-4 text-sm text-red-200">The challenge list could not be loaded.</p> : null}
        {!error && challenges.length === 0 ? <p className="mt-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5 text-sm text-[var(--muted)]">No challenges are configured in the new database yet.</p> : null}
        <div className="mt-4 space-y-3">
          {challenges.map((challenge) => (
            <article key={challenge.id} className="flex flex-col gap-3 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4 sm:flex-row sm:items-center sm:justify-between">
              <div><p className="font-semibold">{challenge.title}</p><p className="mt-1 text-xs text-[var(--muted)]">{challenge.challenge_date} · {challenge.subject}</p></div>
              <div className="flex flex-wrap items-center gap-3 text-xs"><span className={challenge.is_live ? "text-[var(--accent)]" : "text-[var(--muted)]"}>{challenge.is_live ? "Live" : "Draft / hidden"}</span><span className="text-[var(--muted)]">{new Date(challenge.starts_at).toLocaleString("en-IN", { timeZone: "Asia/Kolkata" })} – {new Date(challenge.ends_at).toLocaleString("en-IN", { timeZone: "Asia/Kolkata" })} IST</span></div>
            </article>
          ))}
        </div>
      </section>
      <p className="mt-8 text-xs leading-5 text-[var(--muted)]">Publishing is a high-impact action. Review content and timing before enabling live status. Bulk deletion and photo cleanup will be implemented only with explicit confirmation and verified storage behavior.</p>
    </main>
  );
}
