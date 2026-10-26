"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";

type Subject = "Physics" | "Chemistry" | "Mathematics";
type ChapterRow = { subject: Subject; chapter: string | null };
type Chapter = { subject: Subject; chapter: string; count: number };

export default function ChapterwiseContent() {
  const [chapters, setChapters] = useState<Chapter[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    let active = true;
    async function loadChapters() {
      try {
        const supabase = createSupabaseBrowserClient();
        const { data, error: queryError } = await supabase
          .from("jee_pyq_questions")
          .select("subject, chapter")
          .eq("is_published", true)
          .eq("review_status", "approved")
          .not("chapter", "is", null)
          .limit(1000);
        if (queryError) throw queryError;
        const unique = new Map<string, Chapter>();
        for (const row of (data ?? []) as ChapterRow[]) {
          if (!row.chapter?.trim()) continue;
          const key = `${row.subject}::${row.chapter}`;
          const existing = unique.get(key);
          if (existing) existing.count += 1;
          else unique.set(key, { subject: row.subject, chapter: row.chapter, count: 1 });
        }
        if (active) setChapters([...unique.values()]);
      } catch {
        if (active) setError(true);
      } finally {
        if (active) setLoading(false);
      }
    }
    void loadChapters();
    return () => { active = false; };
  }, []);

  const groups = (["Physics", "Chemistry", "Mathematics"] as const).map((subject) => ({
    subject,
    chapters: chapters
      .filter((chapter) => chapter.subject === subject)
      .sort((a, b) => a.chapter.localeCompare(b.chapter)),
  }));

  return (
    <main className="mx-auto min-h-screen max-w-6xl px-5 py-6 sm:px-8 lg:py-12">
      <header className="mb-8 flex items-center justify-between border-b border-[var(--border)] pb-5">
        <Link href="/" className="flex items-center gap-3">
          <span className="grid size-9 place-items-center rounded-lg bg-[var(--accent)] text-xs font-black text-[var(--accent-foreground)]">BJ</span>
          <span className="text-sm font-bold tracking-[0.18em]">BLACK-JEE</span>
        </Link>
        <nav className="flex gap-4 text-sm text-[var(--muted)]">
          <a href="/pyq">PYQs</a>
          <a href="/mock-tests">Mock tests</a>
        </nav>
      </header>
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--muted)]">Study by topic</p>
      <h1 className="mt-2 text-4xl font-semibold tracking-tight sm:text-5xl">Chapter-wise practice</h1>
      <p className="mt-3 max-w-2xl text-sm leading-6 text-[var(--muted)]">Choose a subject and chapter to practice reviewed questions. Only published questions appear in this index.</p>
      {loading ? <p role="status" className="mt-6 text-sm text-[var(--muted)]">Loading reviewed chapters…</p> : null}
      {error ? <p role="alert" className="mt-6 rounded-xl border border-red-400/30 bg-red-400/10 p-4 text-sm text-red-200">Chapter data could not be loaded. Please try again.</p> : null}
      {!loading && !error && chapters.length === 0 ? (
        <section className="mt-7 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-6">
          <h2 className="font-semibold">Chapter library is being prepared</h2>
          <p className="mt-2 text-sm leading-6 text-[var(--muted)]">Reviewed questions with chapter metadata will populate this page after content import.</p>
          <a href="/pyq" className="mt-4 inline-flex text-sm underline underline-offset-4">Browse all PYQs</a>
        </section>
      ) : null}
      <div className="mt-7 grid gap-5 lg:grid-cols-3">
        {groups.map((group) => (
          <section key={group.subject} className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5">
            <h2 className="text-xl font-semibold">{group.subject}</h2>
            <p className="mt-1 text-xs text-[var(--muted)]">{group.chapters.length} chapters indexed</p>
            <div className="mt-4 space-y-2">
              {group.chapters.map((chapter) => (
                <a key={chapter.chapter} href={`/chapter-practice?subject=${encodeURIComponent(group.subject)}&chapter=${encodeURIComponent(chapter.chapter)}`} className="flex items-center justify-between gap-3 rounded-xl border border-[var(--border)] px-3 py-3 text-sm hover:bg-white/5">
                  <span>{chapter.chapter}</span>
                  <span className="shrink-0 text-xs text-[var(--muted)]">{chapter.count} Qs ↗</span>
                </a>
              ))}
              {!group.chapters.length ? <p className="rounded-xl border border-dashed border-[var(--border)] p-3 text-xs text-[var(--muted)]">No reviewed chapters yet.</p> : null}
            </div>
          </section>
        ))}
      </div>
    </main>
  );
}
