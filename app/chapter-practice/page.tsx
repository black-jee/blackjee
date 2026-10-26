import type { Metadata } from "next";
import { SiteHeader } from "@/components/site-header";
import { PyqQuestionList } from "@/components/pyq/pyq-question-list";
import type { PyqRow } from "@/lib/questions/pyq-adapter";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Chapter practice" };
export const dynamic = "force-dynamic";

type SearchParams = Promise<{ q?: string; subject?: string; chapter?: string }>;
const subjects = ["Physics", "Chemistry", "Mathematics"] as const;

export default async function ChapterPracticePage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const subject = subjects.find((value) => value === params.subject);
  const chapter = (params.chapter ?? "").trim().slice(0, 160);
  const search = (params.q ?? "")
    .replace(/[^\p{L}\p{N}\s.,()+\-]/gu, "")
    .trim()
    .slice(0, 80);
  const supabase = await createSupabaseServerClient();

  let query = supabase
    .from("jee_pyq_questions")
    .select(
      "id, source_id, title, exam, year, subject, chapter, difficulty, statement, statement_image_path, options, tags, asset_paths",
    )
    .eq("is_published", true)
    .eq("review_status", "approved")
    .order("year", { ascending: false })
    .range(0, 49);

  if (subject) query = query.eq("subject", subject);
  if (chapter) query = query.eq("chapter", chapter);
  if (search) query = query.ilike("statement", `%${search}%`);

  const { data, error } = await query;
  const rows = (data ?? []) as unknown as PyqRow[];

  return (
    <main className="mx-auto min-h-screen max-w-6xl px-5 py-6 sm:px-8 lg:py-12">
      <SiteHeader />
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--muted)]">
        {subject ?? "Subject"} · Practice
      </p>
      <h1 className="mt-2 text-4xl font-semibold tracking-tight sm:text-5xl">
        {chapter || "Chapter practice"}
      </h1>
      <p className="mt-3 max-w-2xl text-sm leading-6 text-[var(--muted)]">
        Answer checking is handled by the database. Worked solutions remain gated by the configured
        attempt policy.
      </p>
      <form
        method="get"
        className="mt-7 grid gap-3 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4 sm:grid-cols-[220px_1fr_auto] sm:items-end"
      >
        {subject ? <input type="hidden" name="subject" value={subject} /> : null}
        {chapter ? <input type="hidden" name="chapter" value={chapter} /> : null}
        <label className="block text-sm font-medium">
          <span className="mb-2 block">Find within chapter</span>
          <input
            name="q"
            defaultValue={search}
            maxLength={80}
            placeholder="Search question text"
            className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3"
          />
        </label>
        <div className="text-xs leading-5 text-[var(--muted)]">
          Published questions only. Drafts and answer keys are not included in this query.
        </div>
        <button
          type="submit"
          className="rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)]"
        >
          Search
        </button>
      </form>
      {error ? (
        <p
          role="alert"
          className="mt-6 rounded-xl border border-red-400/30 bg-red-400/10 p-4 text-sm text-red-200"
        >
          Questions could not be loaded.
        </p>
      ) : null}
      {!error && rows.length === 0 ? (
        <section className="mt-6 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-6">
          <p className="font-semibold">No reviewed questions in this selection yet</p>
          <p className="mt-2 text-sm text-[var(--muted)]">
            The new database is empty until source questions are imported, reviewed and published.
          </p>
          <a href="/pyq" className="mt-4 inline-flex text-sm underline underline-offset-4">
            Browse PYQs
          </a>
        </section>
      ) : null}
      <PyqQuestionList rows={rows} />
      {!error && rows.length === 50 ? (
        <p className="mt-6 text-center text-xs text-[var(--muted)]">
          Showing the first 50 matching questions.
        </p>
      ) : null}
    </main>
  );
}
