import type { Metadata } from "next";
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
  const search = (params.q ?? "").replace(/[^\p{L}\p{N}\s.,()+\-]/gu, "").trim().slice(0, 80);
  const supabase = await createSupabaseServerClient();

  let query = supabase
    .from("jee_pyq_questions")
    .select("id, source_id, title, exam, year, subject, chapter, difficulty, statement, statement_image_path, options, tags, asset_paths")
    .eq("is_published", true)
    .eq("review_status", "approved")
    .order("year", { ascending: false })
    .range(0, 19);

  if (subject) query = query.eq("subject", subject);
  if (search) query = query.ilike("statement", `%${search}%`);

  const { data, error } = await query;
  const rows = (data ?? []) as unknown as Row[];

  return (
    <main className="mx-auto min-h-screen max-w-6xl px-5 py-6 sm:px-8 lg:py-12">
      <header className="mb-8 flex items-center justify-between border-b border-[var(--border)] pb-5">
        <a href="/" className="flex items-center gap-3"><span className="grid size-9 place-items-center rounded-lg bg-[var(--accent)] text-xs font-black text-[var(--accent-foreground)]">BJ</span><span className="text-sm font-bold tracking-[0.18em]">BLACK-JEE</span></a>
        <nav className="flex gap-4 text-sm text-[var(--muted)]"><a href="/challenge">Daily challenge</a><a href="/profile">Profile</a></nav>
      </header>
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--muted)]">Practice library</p>
      <h1 className="mt-2 text-4xl font-semibold tracking-tight sm:text-5xl">Previous-year questions</h1>
      <p className="mt-3 max-w-2xl text-sm leading-6 text-[var(--muted)]">Browse approved and published JEE questions. Answer keys and worked solutions are served separately by the protected grading workflow.</p>

      <form method="get" className="mt-7 grid gap-3 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4 sm:grid-cols-[1fr_220px_auto] sm:items-end">
        <label className="block text-sm font-medium"><span className="mb-2 block">Search question text</span><input name="q" defaultValue={search} maxLength={80} placeholder="Search a concept or phrase" className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3 outline-none focus:border-[var(--accent)]" /></label>
        <label className="block text-sm font-medium"><span className="mb-2 block">Subject</span><select name="subject" defaultValue={subject ?? ""} className="w-full rounded-xl border border-[var(--border)] bg-[#11131a] px-3 py-3 outline-none focus:border-[var(--accent)]"><option value="">All subjects</option>{subjects.map((item) => <option key={item} value={item}>{item}</option>)}</select></label>
        <button type="submit" className="rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)]">Search</button>
      </form>

      {error ? <p role="alert" className="mt-6 rounded-xl border border-red-400/30 bg-red-400/10 p-4 text-sm text-red-200">The question bank could not be loaded. Please try again shortly.</p> : null}
      {!error && rows.length === 0 ? <section className="mt-6 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-6"><p className="font-semibold">No published questions found</p><p className="mt-2 text-sm leading-6 text-[var(--muted)]">The new question bank is empty until reviewed content is imported and approved. Drafts remain private.</p></section> : null}
      <PyqQuestionList rows={rows} />
      {!error && rows.length === 20 ? <p className="mt-6 text-center text-xs text-[var(--muted)]">Showing the first 20 matching questions. Pagination will be expanded with the full PYQ module.</p> : null}
    </main>
  );
}
