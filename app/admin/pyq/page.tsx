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

const SUBJECTS = ["Physics", "Chemistry", "Mathematics"] as const;

function paperSlot(question: QuestionRow) {
  const match = question.source_id.match(/SLOT-(\d{1,3})$/i);
  return match ? Number(match[1]) : null;
}

function subjectQuestionNumber(question: QuestionRow, fallback: number) {
  const slot = paperSlot(question);
  if (slot !== null && slot >= 1 && slot <= 25 && question.subject === "Physics") return slot;
  if (slot !== null && slot >= 26 && slot <= 50 && question.subject === "Chemistry") return slot - 25;
  if (slot !== null && slot >= 51 && slot <= 75 && question.subject === "Mathematics") return slot - 50;
  return fallback;
}

function statusClass(status: string) {
  const value = status.toLowerCase();
  if (value === "approved" || value === "published" || value === "verified") {
    return "border-emerald-400/30 bg-emerald-400/10 text-emerald-200";
  }
  if (value === "rejected" || value === "blocked") {
    return "border-red-400/30 bg-red-400/10 text-red-200";
  }
  return "border-[var(--border)] bg-[var(--surface-raised)] text-[var(--muted)]";
}

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
  const grouped = SUBJECTS.map((subject) => ({
    subject,
    rows: questions
      .filter((question) => question.subject === subject)
      .sort((a, b) => {
        const aSlot = paperSlot(a);
        const bSlot = paperSlot(b);
        if (aSlot !== null && bSlot !== null) return aSlot - bSlot;
        if (aSlot !== null) return -1;
        if (bSlot !== null) return 1;
        return b.updated_at.localeCompare(a.updated_at);
      }),
  }));
  const otherQuestions = questions.filter(
    (question) => !SUBJECTS.includes(question.subject as (typeof SUBJECTS)[number]),
  );
  const publishedCount = questions.filter((question) => question.is_published).length;
  const draftCount = questions.length - publishedCount;
  const slotCount = questions.filter((question) => paperSlot(question) !== null).length;

  return (
    <main className="mx-auto min-h-screen w-full max-w-7xl px-3 py-4 sm:px-6 sm:py-8 lg:px-8 lg:py-10">
      <header className="mb-7 flex flex-wrap items-center justify-between gap-3 border-b border-[var(--border)] pb-5">
        <Link href="/admin" className="flex min-w-0 items-center gap-3">
          <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-[var(--accent)] text-xs font-black text-[var(--accent-foreground)]">BJ</span>
          <span className="text-xs font-bold tracking-[0.16em] sm:text-sm">BLACK-JEE ADMIN</span>
        </Link>
        <nav className="flex flex-wrap gap-x-4 gap-y-2 text-xs text-[var(--muted)] sm:text-sm">
          <Link href="/admin" className="hover:text-[var(--text)]">Daily challenges</Link>
          <Link href="/pyq" className="hover:text-[var(--text)]">Student PYQs</Link>
        </nav>
      </header>

      <section className="space-y-3">
        <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--accent)]">Content workbench</p>
        <div className="flex flex-col justify-between gap-4 lg:flex-row lg:items-end">
          <div className="min-w-0">
            <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl lg:text-5xl">PYQ authoring &amp; review</h1>
            <p className="mt-3 max-w-3xl text-sm leading-6 text-[var(--muted)]">
              Create, format and review questions. Physics, Chemistry and Mathematics are grouped separately;
              source slots retain the full-paper numbering from 001 to 075.
            </p>
          </div>
          <a href="#create-question" className="inline-flex w-fit items-center justify-center rounded-xl bg-[var(--accent)] px-4 py-3 text-sm font-bold text-[var(--accent-foreground)]">+ Add question</a>
        </div>
      </section>

      <section aria-label="Question overview" className="mt-6 grid grid-cols-2 gap-3 lg:grid-cols-4">
        {[
          { label: "Loaded records", value: questions.length, note: "Latest 100 max" },
          { label: "Paper slots", value: slotCount, note: "Numbered source slots" },
          { label: "Draft / unpublished", value: draftCount, note: "Not visible to students" },
          { label: "Published", value: publishedCount, note: "Live student content" },
        ].map((item) => (
          <div key={item.label} className="min-w-0 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-3 sm:p-4">
            <p className="text-xs leading-5 text-[var(--muted)]">{item.label}</p>
            <p className="mt-1 text-2xl font-semibold tabular-nums sm:text-3xl">{item.value}</p>
            <p className="mt-1 text-[11px] leading-4 text-[var(--muted)]">{item.note}</p>
          </div>
        ))}
      </section>

      <section id="create-question" className="mt-8 scroll-mt-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-3 sm:rounded-3xl sm:p-6 lg:p-7">
        <div className="mb-5 flex flex-wrap items-start justify-between gap-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--accent)]">Manual entry</p>
            <h2 className="mt-1 text-xl font-semibold tracking-tight sm:text-2xl">Create question draft</h2>
            <p className="mt-1 max-w-2xl text-sm leading-5 text-[var(--muted)]">Fill in the metadata, question, options, answer key and worked solution. Save keeps it unpublished for review.</p>
          </div>
          <span className="rounded-full border border-[var(--border)] px-3 py-1.5 text-xs text-[var(--muted)]">Draft only · safe by default</span>
        </div>
        <PyqAuthoringForm />
      </section>

      <section className="mt-10">
        <div className="mb-5 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--accent)]">Question library</p>
            <h2 className="mt-1 text-2xl font-semibold tracking-tight sm:text-3xl">Browse by subject</h2>
            <p className="mt-1 text-sm leading-5 text-[var(--muted)]">Paper slots use full-paper numbering. Each PCM subject also has its own question number (1–25).</p>
          </div>
          <span className="w-fit rounded-full border border-[var(--border)] px-3 py-1.5 text-xs text-[var(--muted)]">{questions.length} records loaded</span>
        </div>

        {error ? (
          <p role="alert" className="rounded-xl border border-red-400/30 bg-red-400/10 p-4 text-sm text-red-200">
            The question list could not be loaded. Check the administrator database policy.
          </p>
        ) : null}
        {!error && questions.length === 0 ? (
          <p className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5 text-sm text-[var(--muted)]">No question records yet. Add a draft above or import verified source content.</p>
        ) : null}

        <div className="space-y-7">
          {grouped.map(({ subject, rows }) => (
            <section key={subject} className="overflow-hidden rounded-2xl border border-[var(--border)] bg-[var(--surface)] sm:rounded-3xl">
              <header className="flex flex-wrap items-center justify-between gap-3 border-b border-[var(--border)] bg-[var(--surface-raised)] px-4 py-4 sm:px-5">
                <div>
                  <h3 className="text-lg font-semibold sm:text-xl">{subject}</h3>
                  <p className="mt-0.5 text-xs text-[var(--muted)]">
                    {subject === "Physics" ? "Paper slots 001–025" : subject === "Chemistry" ? "Paper slots 026–050" : "Paper slots 051–075"}
                  </p>
                </div>
                <span className="rounded-full border border-[var(--border)] px-3 py-1 text-xs tabular-nums">{rows.length} questions</span>
              </header>
              {rows.length === 0 ? (
                <p className="p-4 text-sm text-[var(--muted)]">No {subject.toLowerCase()} records loaded.</p>
              ) : (
                <div className="divide-y divide-[var(--border)]">
                  {rows.map((question, index) => {
                    const slot = paperSlot(question);
                    const qNumber = subjectQuestionNumber(question, index + 1);
                    const options = Array.isArray(question.options)
                      ? (question.options as { label?: string; text?: string; imagePath?: string }[])
                      : [];
                    return (
                      <article key={question.id} className="min-w-0 p-3 sm:p-5">
                        <div className="flex min-w-0 items-start gap-3">
                          <div className="grid size-11 shrink-0 place-items-center rounded-xl border border-[var(--border)] bg-[var(--surface-raised)] text-xs font-bold tabular-nums sm:size-12">
                            {slot !== null ? String(slot).padStart(3, "0") : "Q" + qNumber}
                          </div>
                          <div className="min-w-0 flex-1">
                            <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                              <div className="min-w-0">
                                <h4 className="break-words text-sm font-semibold leading-6 sm:text-base">{question.title}</h4>
                                <p className="mt-1 break-all text-[11px] leading-5 text-[var(--muted)] sm:text-xs">{question.source_id}</p>
                              </div>
                              <div className="flex flex-wrap gap-1.5">
                                <span className={"rounded-full border px-2 py-1 text-[10px] font-bold uppercase tracking-wide " + statusClass(question.review_status)}>{question.review_status}</span>
                                <span className={"rounded-full border px-2 py-1 text-[10px] font-bold uppercase tracking-wide " + statusClass(question.is_published ? "published" : "unpublished")}>{question.is_published ? "Published" : "Unpublished"}</span>
                                <span className={"rounded-full border px-2 py-1 text-[10px] font-bold uppercase tracking-wide " + statusClass(question.source_status)}>{question.source_status}</span>
                              </div>
                            </div>
                            <div className="mt-3 rounded-xl border border-[var(--border)] bg-[var(--surface-raised)] p-3 sm:p-4">
                              <p className="mb-1 text-[10px] font-bold uppercase tracking-wider text-[var(--muted)]">
                                Paper slot {slot !== null ? String(slot).padStart(3, "0") : "not assigned"} · {subject} Q{qNumber}
                              </p>
                              <p className="whitespace-pre-wrap break-words text-sm leading-6">{question.statement || "Question statement not entered."}</p>
                            </div>
                            {options.length > 0 ? (
                              <div className="mt-3 grid min-w-0 gap-2 sm:grid-cols-2">
                                {options.map((option, optionIndex) => (
                                  <div key={(option.label ?? String(optionIndex)) + "-" + optionIndex} className="flex min-w-0 items-start gap-2.5 rounded-xl border border-[var(--border)] p-3">
                                    <span className="grid size-7 shrink-0 place-items-center rounded-lg border border-[var(--border)] bg-[var(--surface-raised)] text-xs font-bold">{option.label ?? String.fromCharCode(65 + optionIndex)}</span>
                                    <span className="min-w-0 whitespace-pre-wrap break-words text-sm leading-5">{option.text || (option.imagePath ? "Image: " + option.imagePath : "Option text empty")}</span>
                                  </div>
                                ))}
                              </div>
                            ) : (
                              <p className="mt-3 text-xs text-[var(--muted)]">No options saved yet.</p>
                            )}
                            <details className="mt-3 rounded-xl border border-[var(--border)] bg-[var(--surface-raised)]">
                              <summary className="cursor-pointer px-3 py-3 text-sm font-semibold sm:px-4">
                                View worked solution {question.solution ? "" : "· not entered"}
                              </summary>
                              <div className="border-t border-[var(--border)] px-3 py-4 sm:px-4">
                                {question.solution ? (
                                  <p className="whitespace-pre-wrap break-words text-sm leading-7">{question.solution}</p>
                                ) : (
                                  <p className="text-sm text-[var(--muted)]">No solution has been entered for this draft yet.</p>
                                )}
                              </div>
                            </details>
                            <div className="mt-4 flex flex-col gap-3 border-t border-[var(--border)] pt-3 sm:flex-row sm:items-center sm:justify-between">
                              <p className="break-words text-xs leading-5 text-[var(--muted)]">
                                {question.source_pdf ? question.source_pdf + (question.source_page ? " · page " + question.source_page : "") : "Source reference not recorded"}
                              </p>
                              <PyqReviewActions id={question.id} isPublished={question.is_published} reviewStatus={question.review_status} />
                            </div>
                          </div>
                        </div>
                      </article>
                    );
                  })}
                </div>
              )}
            </section>
          ))}
          {otherQuestions.length > 0 ? (
            <section className="overflow-hidden rounded-2xl border border-[var(--border)] bg-[var(--surface)] sm:rounded-3xl">
              <header className="border-b border-[var(--border)] bg-[var(--surface-raised)] px-4 py-4 sm:px-5">
                <h3 className="text-lg font-semibold">Other / legacy records</h3>
                <p className="mt-1 text-xs text-[var(--muted)]">Kept separate from the three subject sections.</p>
              </header>
              <div className="divide-y divide-[var(--border)]">
                {otherQuestions.map((question) => (
                  <article key={question.id} className="p-4">
                    <p className="text-sm font-semibold">{question.title}</p>
                    <p className="mt-1 break-all text-xs text-[var(--muted)]">{question.source_id} · {question.subject || "No subject"}</p>
                    <p className="mt-2 whitespace-pre-wrap break-words text-sm leading-6">{question.statement}</p>
                    <div className="mt-3"><PyqReviewActions id={question.id} isPublished={question.is_published} reviewStatus={question.review_status} /></div>
                  </article>
                ))}
              </div>
            </section>
          ) : null}
        </div>
        <p className="mt-4 text-xs leading-5 text-[var(--muted)]">This screen loads the latest 100 records. Slot numbers come from stable source IDs; other records stay separate and are not renumbered as paper slots.</p>
      </section>
    </main>
  );
}
