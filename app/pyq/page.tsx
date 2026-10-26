import type { Metadata } from "next";
import Link from "next/link";
import { PyqQuestionList } from "@/components/pyq/pyq-question-list";
import type { PyqRow } from "@/lib/questions/pyq-adapter";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Previous-year questions" };
export const dynamic = "force-dynamic";

type SearchParams = Promise<{ q?: string; subject?: string }>;
type Row = PyqRow;
const subjects = ["Physics", "Chemistry", "Mathematics"] as const;

export default async function PyqPage({ searchParams }: { searchParams: SearchParams }) {
  const params = await searchParams;
  const subject = subjects.find((value) => value === params.subject);
  const search = (params.q ?? "")
    .replace(/[^\p{L}\p{N}\s.,()+\-]/gu, "")
    .trim()
    .slice(0, 80);
  const hasFilters = Boolean(subject || search);
  const supabase = await createSupabaseServerClient();

  let query = supabase
    .from("jee_pyq_questions")
    .select(
      "id, source_id, title, exam, year, subject, chapter, difficulty, statement, statement_image_path, options, tags, asset_paths",
    )
    .eq("is_published", true)
    .eq("review_status", "approved")
    .order("year", { ascending: false })
    .range(0, 19);

  if (subject) query = query.eq("subject", subject);
  if (search) query = query.ilike("statement", `%${search}%`);

  const { data, error } = await query;
  const rows = (data ?? []) as unknown as Row[];

  return (
    <main className="mx-auto min-h-screen max-w-6xl px-4 pb-16 pt-4 sm:px-8 sm:pt-7 lg:pt-10">
      <header className="mb-10 flex flex-wrap items-center justify-between gap-4 border-b border-[var(--border)] pb-5">
        <Link href="/" className="group flex min-h-11 items-center gap-3 rounded-lg">
          <span className="grid size-10 place-items-center rounded-xl bg-[var(--accent)] text-xs font-black text-[var(--accent-foreground)] shadow-[0_0_24px_rgb(215_255_100_/_12%)] transition-transform group-hover:scale-105">
            BJ
          </span>
          <span className="text-sm font-bold tracking-[0.18em]">BLACK-JEE</span>
        </Link>
        <nav aria-label="Main navigation" className="flex flex-wrap items-center gap-2 text-sm">
          <Link
            href="/challenge"
            className="rounded-full px-3 py-2 text-[var(--muted)] transition-colors hover:bg-white/5 hover:text-[var(--text)]"
          >
            Daily challenge
          </Link>
          <Link
            href="/profile"
            className="rounded-full border border-[var(--border)] px-3 py-2 text-[var(--text)] transition-colors hover:border-[var(--accent)]"
          >
            Profile
          </Link>
        </nav>
      </header>

      <section aria-labelledby="pyq-title" className="relative">
        <div className="pointer-events-none absolute -left-12 -top-10 -z-10 size-56 rounded-full bg-[var(--accent)] opacity-[0.045] blur-3xl" />
        <p className="inline-flex items-center gap-2 rounded-full border border-[var(--accent)]/25 bg-[var(--accent)]/[0.07] px-3 py-1.5 text-[11px] font-bold uppercase tracking-[0.18em] text-[var(--accent)]">
          <span aria-hidden="true" className="size-1.5 rounded-full bg-[var(--accent)]" />
          Practice library
        </p>
        <div className="mt-4 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
          <div className="max-w-3xl">
            <h1 id="pyq-title" className="text-3xl font-semibold tracking-tight sm:text-5xl">
              Previous-year questions<span className="text-[var(--accent)]">.</span>
            </h1>
            <p className="mt-4 max-w-2xl text-sm leading-7 text-[var(--muted)] sm:text-base">
              Build exam confidence one question at a time. Practice approved JEE questions, check
              your answers, and work through solutions when they unlock.
            </p>
          </div>
          <p className="shrink-0 text-xs text-[var(--muted)]">
            <span className="font-semibold text-[var(--text)]">JEE Main</span>
            <span aria-hidden="true"> · </span>
            Physics, Chemistry &amp; Mathematics
          </p>
        </div>
      </section>

      <section
        aria-label="Search and filter questions"
        className="mt-7 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4 shadow-[0_16px_48px_rgb(0_0_0_/_12%)] sm:mt-9 sm:p-5"
      >
        <form method="get" className="grid gap-4 sm:grid-cols-[minmax(0,1fr)_220px_auto] sm:items-end">
          <label className="block min-w-0 text-sm font-medium">
            <span className="mb-2 block text-[var(--text)]">Find a question</span>
            <input
              name="q"
              type="search"
              defaultValue={search}
              maxLength={80}
              placeholder="Try a topic, formula, or phrase"
              aria-label="Search question text"
              className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-black/20 px-4 py-3 text-base text-[var(--text)] outline-none transition-colors placeholder:text-[var(--muted)]/70 hover:border-[var(--muted)]/60 focus:border-[var(--accent)]"
            />
          </label>
          <label className="block text-sm font-medium">
            <span className="mb-2 block text-[var(--text)]">Subject</span>
            <select
              name="subject"
              defaultValue={subject ?? ""}
              aria-label="Filter by subject"
              className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-[#11131a] px-4 py-3 text-base text-[var(--text)] outline-none transition-colors hover:border-[var(--muted)]/60 focus:border-[var(--accent)]"
            >
              <option value="">All subjects</option>
              {subjects.map((item) => (
                <option key={item} value={item}>
                  {item}
                </option>
              ))}
            </select>
          </label>
          <button
            type="submit"
            className="min-h-12 rounded-xl bg-[var(--accent)] px-6 py-3 text-sm font-bold text-[var(--accent-foreground)] transition-transform hover:-translate-y-0.5 hover:shadow-[0_8px_24px_rgb(215_255_100_/_12%)] active:translate-y-0 sm:min-w-28"
          >
            Search
          </button>
        </form>
        {hasFilters ? (
          <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-[var(--border)] pt-4 text-xs">
            <span className="text-[var(--muted)]">Active filters:</span>
            {subject ? (
              <span className="rounded-full border border-[var(--border)] bg-white/[0.03] px-3 py-1.5 text-[var(--text)]">
                {subject}
              </span>
            ) : null}
            {search ? (
              <span className="max-w-full truncate rounded-full border border-[var(--border)] bg-white/[0.03] px-3 py-1.5 text-[var(--text)]">
                “{search}”
              </span>
            ) : null}
            <Link
              href="/pyq"
              className="ml-auto rounded-lg px-2 py-1.5 font-semibold text-[var(--accent)] underline-offset-4 hover:underline"
            >
              Clear filters
            </Link>
          </div>
        ) : null}
      </section>

      {error ? (
        <section
          role="alert"
          className="mt-7 rounded-2xl border border-red-400/30 bg-red-400/[0.07] p-5 sm:p-6"
        >
          <p className="font-semibold text-red-200">Questions could not be loaded</p>
          <p className="mt-2 text-sm leading-6 text-[var(--muted)]">
            Your filters are still here. Please try your search again in a moment.
          </p>
          <Link
            href={hasFilters ? `/pyq${subject ? `?subject=${encodeURIComponent(subject)}` : ""}` : "/pyq"}
            className="mt-4 inline-flex min-h-10 items-center rounded-lg border border-[var(--border)] px-4 py-2 text-sm font-semibold transition-colors hover:border-[var(--accent)]"
          >
            Try again
          </Link>
        </section>
      ) : (
        <section aria-labelledby="results-heading" className="mt-8 sm:mt-10">
          <div className="flex flex-wrap items-end justify-between gap-3 border-b border-[var(--border)] pb-4">
            <div>
              <h2 id="results-heading" className="text-lg font-semibold tracking-tight sm:text-xl">
                {hasFilters ? "Matching questions" : "Ready to practice?"}
              </h2>
              <p className="mt-1 text-sm text-[var(--muted)]">
                {rows.length > 0
                  ? `Showing ${rows.length} ${rows.length === 1 ? "question" : "questions"}${rows.length === 20 ? " · first page" : ""}`
                  : "Only reviewed and approved questions appear here."}
              </p>
            </div>
            <span className="rounded-full border border-[var(--border)] px-3 py-1.5 text-xs text-[var(--muted)]">
              {subject ?? "All subjects"}
            </span>
          </div>

          {!rows.length ? (
            <div className="mt-5 rounded-2xl border border-dashed border-[var(--border)] bg-[var(--surface)]/60 px-5 py-10 text-center sm:px-8">
              <span aria-hidden="true" className="mx-auto grid size-12 place-items-center rounded-2xl border border-[var(--border)] bg-white/[0.03] text-xl">
                ?
              </span>
              <h3 className="mt-4 text-base font-semibold">
                {hasFilters ? "No questions match these filters" : "Your practice library is growing"}
              </h3>
              <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-[var(--muted)]">
                {hasFilters
                  ? "Try a different phrase or choose another subject. Unpublished drafts are kept out of student results."
                  : "New questions will appear here after their content and answers have been reviewed and approved."}
              </p>
              {hasFilters ? (
                <Link
                  href="/pyq"
                  className="mt-5 inline-flex min-h-11 items-center justify-center rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)] transition-transform hover:-translate-y-0.5"
                >
                  Clear search and filters
                </Link>
              ) : null}
            </div>
          ) : (
            <PyqQuestionList rows={rows} />
          )}
          {!error && rows.length === 20 ? (
            <p className="mt-6 rounded-xl border border-[var(--border)] bg-[var(--surface)] px-4 py-3 text-center text-xs leading-5 text-[var(--muted)]">
              You’re viewing the first 20 matching questions. More results can be added when
              pagination is implemented.
            </p>
          ) : null}
        </section>
      )}
    </main>
  );
}
