import type { Metadata } from "next";
import Link from "next/link";
import { MockTestRunner } from "@/components/mock-tests/mock-test-runner";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Mock tests" };
export const dynamic = "force-dynamic";

type ShiftRow = { year: number | null; session: string | null };
type ActiveAttempt = {
  id: string;
  mode: string;
  exam_year: number | null;
  session: string | null;
  total_questions: number;
  started_at: string;
  duration_seconds: number;
};

export default async function MockTestsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: auth } = await supabase.auth.getUser();
  const { data: shiftRows, error: bankError } = await supabase
    .from("jee_pyq_questions")
    .select("year, session")
    .eq("is_published", true)
    .eq("review_status", "approved")
    .not("year", "is", null)
    .not("session", "is", null)
    .limit(1000);

  const shiftMap = new Map<string, { year: number; session: string }>();
  for (const row of (shiftRows ?? []) as ShiftRow[]) {
    if (typeof row.year !== "number" || !row.session?.trim()) continue;
    shiftMap.set(`${row.year}||${row.session}`, { year: row.year, session: row.session });
  }
  const shifts = [...shiftMap.values()].sort(
    (a, b) => b.year - a.year || a.session.localeCompare(b.session),
  );

  let activeAttempts: ActiveAttempt[] = [];
  if (auth.user) {
    const { data } = await supabase
      .from("mock_test_attempts")
      .select("id, mode, exam_year, session, total_questions, started_at, duration_seconds")
      .eq("user_id", auth.user.id)
      .eq("status", "in_progress")
      .order("started_at", { ascending: false })
      .limit(5);
    activeAttempts = (data ?? []) as ActiveAttempt[];
  }

  return (
    <main className="mx-auto min-h-screen max-w-6xl px-5 py-6 sm:px-8 lg:py-12">
      <header className="mb-8 flex items-center justify-between border-b border-[var(--border)] pb-5">
        <Link href="/" className="flex items-center gap-3">
          <span className="grid size-9 place-items-center rounded-lg bg-[var(--accent)] text-xs font-black text-[var(--accent-foreground)]">
            BJ
          </span>
          <span className="text-sm font-bold tracking-[0.18em]">BLACK-JEE</span>
        </Link>
        <nav className="flex gap-4 text-sm text-[var(--muted)]">
          <a href="/chapterwise">Chapters</a>
          <a href="/pyq">PYQs</a>
          <a href="/profile">Profile</a>
        </nav>
      </header>
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--muted)]">
        Exam simulation
      </p>
      <h1 className="mt-2 text-4xl font-semibold tracking-tight sm:text-5xl">Mock tests</h1>
      <p className="mt-3 max-w-2xl text-sm leading-6 text-[var(--muted)]">
        Timed CBT practice with question navigation, review flags, local progress recovery,
        server-validated final submission, and per-question marking.
      </p>
      {bankError ? (
        <p
          role="alert"
          className="mt-5 rounded-xl border border-red-400/30 bg-red-400/10 p-4 text-sm text-red-200"
        >
          The published question bank could not be loaded.
        </p>
      ) : null}
      {!bankError && shifts.length === 0 ? (
        <p className="mt-5 rounded-xl border border-[var(--border)] bg-[var(--surface)] p-4 text-sm leading-6 text-[var(--muted)]">
          No published exam shifts are available yet. The source archive contains a partial April 4,
          2026 Shift 1 package, but unresolved questions must be reviewed before import and
          publication.
        </p>
      ) : null}
      <div className="mt-7">
        <MockTestRunner shifts={shifts} activeAttempts={activeAttempts} />
      </div>
    </main>
  );
}
