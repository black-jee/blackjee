import type { Metadata } from "next";
import Link from "next/link";
import { PyqAuthoringForm } from "@/components/admin/pyq-authoring-form";
import { PyqReviewActions } from "@/components/admin/pyq-review-actions";
import { requireAdmin } from "@/lib/auth/require-admin";

export const metadata: Metadata = { title: "PYQ authoring · Admin" };
export const dynamic = "force-dynamic";

type QuestionRow = {
  id: string;
  source_id: string;
  title: string;
  subject: string;
  year: number | null;
  session: string | null;
  chapter: string | null;
  statement: string;
  options: unknown;
  solution: string | null;
  source_pdf: string | null;
  source_page: number | null;
  source_status: string;
  review_status: string;
  is_published: boolean;
  updated_at: string;
};

export default async function AdminPyqPage() {
  const { supabase } = await requireAdmin("/admin/pyq");
  const { data, error } = await supabase
    .from("jee_pyq_questions")
    .select(
      "id,source_id,title,subject,year,session,chapter,statement,options,solution,source_pdf,source_page,source_status,review_status,is_published,updated_at",
    )
    .order("updated_at", { ascending: false })
    .limit(100);
  const questions = (data ?? []) as QuestionRow[];

  return (
    <main className="mx-auto min-h-screen max-w-6xl px-5 py-6 sm:px-8 lg:py-12">
      <header className="mb-8 flex flex-wrap items-center justify-between gap-4 border-b border-[var(--border)] pb-5">
        <Link href="/admin" className="flex items-center gap-3">
          <span className="grid size-9 place-items-center rounded-lg bg-[var(--accent)] text-xs font-black text-[var(--accent-foreground)]">
            BJ
          </span>
          <span className="text-sm font-bold tracking-[0.18em]">BLACK-JEE ADMIN</span>
        </Link>
        <nav className="flex gap-4 text-sm text-[var(--muted)]">
          <Link href="/admin">Daily challenges</Link>
          <Link href="/pyq">Student PYQs</Link>
        </nav>
      </header>
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--accent)]">
        Content workbench
      </p>
      <h1 className="mt-2 text-4xl font-semibold tracking-tight sm:text-5xl">
        PYQ authoring & review
      </h1>
      <p className="mt-3 max-w-3xl text-sm leading-6 text-[var(--muted)]">
        Create source-tracked questions, keep answer keys private, review drafts, and publish only
        after the source, solution and assets have been checked. Saving a question never publishes
        it.
      </p>

      <section className="mt-8 rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-7">
        <h2 className="mb-5 text-2xl font-semibold tracking-tight">Create question draft</h2>
        <PyqAuthoringForm />
      </section>

      <section className="mt-10">
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h2 className="text-2xl font-semibold tracking-tight">Recent question drafts</h2>
            <p className="mt-1 text-sm text-[var(--muted)]">
              Latest 100 records; answer keys are not included in this query.
            </p>
          </div>
          <span className="text-xs text-[var(--muted)]">{questions.length} loaded</span>
        </div>
        {error ? (
          <p
            role="alert"
            className="mt-4 rounded-xl border border-red-400/30 bg-red-400/10 p-4 text-sm text-red-200"
          >
            The question list could not be loaded. Check the administrator database policy.
          </p>
        ) : null}
        {!error && questions.length === 0 ? (
          <p className="mt-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5 text-sm text-[var(--muted)]">
            No question records yet. Add a draft above or import verified source content.
          </p>
        ) : null}
        <div className="mt-4 space-y-4">
          {questions.map((question) => {
            const options = Array.isArray(question.options)
              ? (question.options as { label?: string; text?: string }[])
              : [];
            return (
              <article
                key={question.id}
                className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4 sm:p-5"
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <p className="font-semibold">{question.title}</p>
                    <p className="mt-1 text-xs text-[var(--muted)]">
                      {question.source_id} · {question.subject}
                      {question.chapter ? ` · ${question.chapter}` : ""}
                      {question.year ? ` · ${question.year}` : ""}
                      {question.session ? ` · ${question.session}` : ""}
                    </p>
                  </div>
                  <div className="flex flex-wrap gap-2 text-[10px] font-bold uppercase tracking-wider">
                    <span className="rounded-full border border-[var(--border)] px-2 py-1">
                      {question.review_status}
                    </span>
                    <span className="rounded-full border border-[var(--border)] px-2 py-1">
                      {question.is_published ? "Published" : "Unpublished"}
                    </span>
                    <span className="rounded-full border border-[var(--border)] px-2 py-1">
                      {question.source_status}
                    </span>
                  </div>
                </div>
                <p className="mt-3 whitespace-pre-wrap text-sm leading-6">
                  {question.statement.slice(0, 500)}
                  {question.statement.length > 500 ? "…" : ""}
                </p>
                {options.length ? (
                  <ul className="mt-3 grid gap-1 text-xs text-[var(--muted)] sm:grid-cols-2">
                    {options.map((option, index) => (
                      <li key={option.label ?? index}>
                        {option.label ?? String(index + 1)}.{" "}
                        {option.text ?? "[image / formatted option]"}
                      </li>
                    ))}
                  </ul>
                ) : null}
                <details className="mt-4 rounded-xl border border-[var(--border)] bg-[var(--surface-raised)]">
                  <summary className="cursor-pointer px-4 py-3 text-sm font-semibold">
                    View worked solution {question.solution ? "" : "· not entered"}
                  </summary>
                  <div className="border-t border-[var(--border)] px-4 py-4">
                    {question.solution ? (
                      <p className="whitespace-pre-wrap text-sm leading-6">{question.solution}</p>
                    ) : (
                      <p className="text-sm text-[var(--muted)]">No solution has been entered for this draft yet.</p>
                    )}
                  </div>
                </details>
                <div className="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-[var(--border)] pt-4">
                  <p className="text-xs text-[var(--muted)]">
                    {question.source_pdf
                      ? `${question.source_pdf}${question.source_page ? ` · page ${question.source_page}` : ""}`
                      : "Source reference not recorded"}
                  </p>
                  <PyqReviewActions
                    id={question.id}
                    isPublished={question.is_published}
                    reviewStatus={question.review_status}
                  />
                </div>
              </article>
            );
          })}
        </div>
      </section>
    </main>
  );
}
