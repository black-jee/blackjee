import type { Metadata } from "next";
import { SiteHeader } from "@/components/site-header";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Chapter-wise practice" };
export const dynamic = "force-dynamic";

type ChapterRow = { subject: "Physics" | "Chemistry" | "Mathematics"; chapter: string | null };

export default async function ChapterwisePage() {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from("jee_pyq_questions")
    .select("subject, chapter")
    .eq("is_published", true)
    .eq("review_status", "approved")
    .not("chapter", "is", null)
    .limit(1000);

  const unique = new Map<
    string,
    { subject: ChapterRow["subject"]; chapter: string; count: number }
  >();
  for (const row of (data ?? []) as ChapterRow[]) {
    if (!row.chapter?.trim()) continue;
    const key = `${row.subject}::${row.chapter}`;
    const item = unique.get(key);
    if (item) item.count += 1;
    else unique.set(key, { subject: row.subject, chapter: row.chapter, count: 1 });
  }
  const groups = ["Physics", "Chemistry", "Mathematics"].map((subject) => ({
    subject,
    chapters: [...unique.values()]
      .filter((item) => item.subject === subject)
      .sort((a, b) => a.chapter.localeCompare(b.chapter)),
  }));

  return (
    <main className="mx-auto min-h-screen max-w-6xl px-5 py-6 sm:px-8 lg:py-12">
      <SiteHeader />
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--muted)]">
        Study by topic
      </p>
      <h1 className="mt-2 text-4xl font-semibold tracking-tight sm:text-5xl">
        Chapter-wise practice
      </h1>
      <p className="mt-3 max-w-2xl text-sm leading-6 text-[var(--muted)]">
        Choose a subject and chapter to practice reviewed questions. Only published questions appear
        in this index.
      </p>
      {error ? (
        <p
          role="alert"
          className="mt-6 rounded-xl border border-red-400/30 bg-red-400/10 p-4 text-sm text-red-200"
        >
          Chapter data could not be loaded. Please try again.
        </p>
      ) : null}
      {!error && unique.size === 0 ? (
        <section className="mt-7 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-6">
          <h2 className="font-semibold">Chapter library is being prepared</h2>
          <p className="mt-2 text-sm leading-6 text-[var(--muted)]">
            Reviewed questions with chapter metadata will populate this page after content import.
          </p>
          <a href="/pyq" className="mt-4 inline-flex text-sm underline underline-offset-4">
            Browse all PYQs
          </a>
        </section>
      ) : null}
      <div className="mt-7 grid gap-5 lg:grid-cols-3">
        {groups.map((group) => (
          <section
            key={group.subject}
            className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5"
          >
            <h2 className="text-xl font-semibold">{group.subject}</h2>
            <p className="mt-1 text-xs text-[var(--muted)]">
              {group.chapters.length} chapters indexed
            </p>
            <div className="mt-4 space-y-2">
              {group.chapters.map((chapter) => (
                <a
                  key={chapter.chapter}
                  href={`/chapter-practice?subject=${encodeURIComponent(group.subject)}&chapter=${encodeURIComponent(chapter.chapter)}`}
                  className="flex items-center justify-between gap-3 rounded-xl border border-[var(--border)] px-3 py-3 text-sm hover:bg-white/5"
                >
                  <span>{chapter.chapter}</span>
                  <span className="shrink-0 text-xs text-[var(--muted)]">{chapter.count} Qs ↗</span>
                </a>
              ))}
              {!group.chapters.length ? (
                <p className="rounded-xl border border-dashed border-[var(--border)] p-3 text-xs text-[var(--muted)]">
                  No reviewed chapters yet.
                </p>
              ) : null}
            </div>
          </section>
        ))}
      </div>
    </main>
  );
}
