import type { Metadata } from "next";
import Link from "next/link";
import { MathPreview, PyqAuthoringForm } from "@/components/admin/pyq-authoring-form";
import { PyqReviewActions } from "@/components/admin/pyq-review-actions";
import { requireAdmin } from "@/lib/auth/require-admin";

export const metadata: Metadata = { title: "PYQ shifts · Admin" };
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
  source_pdf: string | null;
  source_page: number | null;
  source_status: string;
  review_status: string;
  is_published: boolean;
  updated_at: string;
};

const SUBJECTS = ["Physics", "Chemistry", "Mathematics"] as const;

function paperSlot(question: QuestionRow) {
  const match = question.source_id?.match(/SLOT-(\d{1,3})$/i);
  const slot = match ? Number(match[1]) : null;
  return slot !== null && slot >= 1 && slot <= 75 ? slot : null;
}

function subjectForSlot(slot: number) {
  if (slot <= 25) return "Physics";
  if (slot <= 50) return "Chemistry";
  return "Mathematics";
}

function subjectForQuestion(question: QuestionRow) {
  const slot = paperSlot(question);
  return slot === null ? question.subject : subjectForSlot(slot);
}

function subjectQuestionNumber(question: QuestionRow, fallback: number) {
  const slot = paperSlot(question);
  if (slot !== null) return ((slot - 1) % 25) + 1;
  const legacy = question.source_id?.match(/-(?:PHY|PHYSICS|CHEM|CHEMISTRY|MAT|MATH|MATHEMATICS)-(\d{1,3})$/i);
  return legacy ? Number(legacy[1]) : fallback;
}

function shiftInfo(question: QuestionRow) {
  const match = question.source_id?.match(/(?:^|-)JM-(\d{8})-S(\d+)(?:-|$)/i);
  if (match) {
    const raw = match[1];
    const date = new Date(Date.UTC(Number(raw.slice(0, 4)), Number(raw.slice(4, 6)) - 1, Number(raw.slice(6, 8))));
    const dateLabel = new Intl.DateTimeFormat("en-IN", {
      day: "numeric",
      month: "long",
      year: "numeric",
      timeZone: "UTC",
    }).format(date);
    return {
      key: "jee-main-" + raw + "-shift-" + match[2],
      title: "JEE Main · " + dateLabel + " · Shift " + match[2],
      date: dateLabel,
      shift: Number(match[2]),
    };
  }
  const session = question.session?.trim() || "Shift not specified";
  const year = question.year ? String(question.year) : "";
  return {
    key: "JEE Main-" + year + "-" + session,
    title: ["JEE Main", year, session].filter(Boolean).join(" · "),
    date: session,
    shift: 999,
  };
}

function statusClass(status: string) {
  const value = (status || "draft").toLowerCase();
  if (value === "approved" || value === "published" || value === "verified" || value === "verified_draft") {
    return "border-emerald-400/30 bg-emerald-400/10 text-emerald-200";
  }
  if (value === "rejected" || value === "blocked") {
    return "border-red-400/30 bg-red-400/10 text-red-200";
  }
  return "border-[var(--border)] bg-[var(--surface-raised)] text-[var(--muted)]";
}

function safeOptions(value: unknown) {
  return Array.isArray(value)
    ? (value as { label?: string; text?: string; imagePath?: string }[])
    : [];
}

export default async function AdminPyqPage() {
  const { supabase } = await requireAdmin("/admin/pyq");
  const { data, error } = await supabase
    .from("jee_pyq_questions")
    .select(
      "id,source_id,title,subject,year,session,chapter,statement,options,source_pdf,source_page,source_status,review_status,is_published,updated_at",
    )
    .order("updated_at", { ascending: false })
    .limit(500);

  if (error) {
    // Keep database details in server logs only; never expose internal policy/schema errors in the admin UI.
    console.error("[admin/pyq] Could not load shift library:", error.message);
  }

  const questions = (data ?? []) as QuestionRow[];
  const shiftMap = new Map<string, { info: ReturnType<typeof shiftInfo>; rows: QuestionRow[] }>();
  for (const question of questions) {
    const info = shiftInfo(question);
    const current = shiftMap.get(info.key);
    if (current) current.rows.push(question);
    else shiftMap.set(info.key, { info, rows: [question] });
  }
  const shifts = Array.from(shiftMap.values()).sort((a, b) => {
    const aSlot = a.rows.map(paperSlot).find((slot) => slot !== null) ?? 0;
    const bSlot = b.rows.map(paperSlot).find((slot) => slot !== null) ?? 0;
    if (aSlot && bSlot) return aSlot - bSlot;
    return b.info.title.localeCompare(a.info.title);
  });
  const publishedCount = questions.filter((question) => question.is_published).length;
  const paperSlotCount = questions.filter((question) => paperSlot(question) !== null).length;
  const draftCount = questions.length - publishedCount;

  return (
    <main className="mx-auto min-h-screen w-full max-w-7xl px-3 py-4 sm:px-6 sm:py-8 lg:px-8 lg:py-10">
      <header className="mb-8 flex flex-wrap items-center justify-between gap-3 border-b border-[var(--border)] pb-5">
        <Link href="/admin" className="flex min-w-0 items-center gap-3">
          <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-[var(--accent)] text-xs font-black text-[var(--accent-foreground)]">BJ</span>
          <span className="text-xs font-bold tracking-[0.16em] sm:text-sm">BLACK-JEE ADMIN</span>
        </Link>
        <nav className="flex flex-wrap gap-x-4 gap-y-2 text-xs text-[var(--muted)] sm:text-sm">
          <Link href="/admin" className="hover:text-[var(--text)]">Dashboard</Link>
          <Link href="/pyq" className="hover:text-[var(--text)]">Student PYQs</Link>
        </nav>
      </header>

      <section className="mb-7">
        <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--accent)]">Question library</p>
        <div className="mt-2 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
          <div className="min-w-0">
            <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl lg:text-5xl">Previous year shifts</h1>
            <p className="mt-3 max-w-2xl text-sm leading-6 text-[var(--muted)]">
              Start with the exam date and shift. Open a shift to browse Physics, Chemistry and Mathematics with clean numbering, readable options and formatted equations.
            </p>
          </div>
          <details id="add-question" className="group w-full shrink-0 sm:w-auto">
            <summary className="flex min-h-12 cursor-pointer list-none items-center justify-center gap-2 rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)] shadow-sm transition hover:opacity-90 [&::-webkit-details-marker]:hidden">
              <span className="text-lg leading-none">+</span> Add question
            </summary>
            <div className="mt-4 w-full rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-3 sm:w-[min(720px,calc(100vw-2rem))] sm:p-6 lg:p-7">
              <div className="mb-5">
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--accent)]">Manual entry</p>
                <h2 className="mt-1 text-xl font-semibold sm:text-2xl">Create question draft</h2>
                <p className="mt-1 text-sm leading-5 text-[var(--muted)]">Add the question, each option, answer key and solution. New entries remain unpublished until reviewed.</p>
              </div>
              <PyqAuthoringForm />
            </div>
          </details>
        </div>
      </section>

      <section aria-label="Question library summary" className="mb-8 grid grid-cols-3 gap-2 sm:gap-3">
        {[
          { label: "Shifts", value: shifts.length },
          { label: "Paper slots", value: paperSlotCount },
          { label: "Drafts", value: draftCount },
        ].map((item) => (
          <div key={item.label} className="min-w-0 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-3 sm:p-4">
            <p className="text-xs text-[var(--muted)]">{item.label}</p>
            <p className="mt-1 text-2xl font-semibold tabular-nums sm:text-3xl">{item.value}</p>
          </div>
        ))}
      </section>

      <section aria-label="Exam shifts" className="space-y-4">
        {error ? (
          <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-7">
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--muted)]">Shift library</p>
            <h2 className="mt-2 text-lg font-semibold">Your shifts will appear here</h2>
            <p className="mt-1 max-w-xl text-sm leading-6 text-[var(--muted)]">The library is temporarily unavailable. Refresh this page to try again.</p>
          </div>
        ) : shifts.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-[var(--border)] bg-[var(--surface)] px-5 py-10 text-center sm:py-14">
            <span className="mx-auto grid size-12 place-items-center rounded-2xl border border-[var(--border)] bg-[var(--surface-raised)] text-xl">▤</span>
            <h2 className="mt-4 text-lg font-semibold">No shifts added yet</h2>
            <p className="mx-auto mt-1 max-w-md text-sm leading-6 text-[var(--muted)]">When question records are added, each exam date and shift will appear here as a separate card.</p>
          </div>
        ) : (
          shifts.map(({ info, rows }) => {
            const paperRows = rows.filter((question) => paperSlot(question) !== null);
            const legacyRows = rows.filter((question) => paperSlot(question) === null);
            const subjectRows = SUBJECTS.map((subject) => ({
              subject,
              rows: paperRows
                .filter((question) => subjectForQuestion(question) === subject)
                .sort((a, b) => (paperSlot(a) ?? 999) - (paperSlot(b) ?? 999)),
            }));
            return (
              <details key={info.key} className="group overflow-hidden rounded-2xl border border-[var(--border)] bg-[var(--surface)] shadow-sm transition open:border-[var(--accent)]/40 sm:rounded-3xl">
                <summary className="flex cursor-pointer list-none items-center gap-3 p-4 sm:gap-4 sm:p-5 lg:p-6 [&::-webkit-details-marker]:hidden">
                  <span className="grid size-12 shrink-0 place-items-center rounded-xl border border-[var(--border)] bg-[var(--surface-raised)] text-lg sm:size-14">
                    <span aria-hidden="true">▤</span>
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block break-words text-base font-semibold leading-6 sm:text-lg">{info.title}</span>
                    <span className="mt-1 block text-xs leading-5 text-[var(--muted)]">{paperRows.length} numbered slots · {legacyRows.length} legacy records · {rows.filter((q) => q.is_published).length} published</span>
                  </span>
                  <span className="hidden rounded-full border border-[var(--border)] px-3 py-1.5 text-xs font-semibold sm:inline-flex">Open shift</span>
                  <span aria-hidden="true" className="shrink-0 text-xl text-[var(--muted)] transition-transform group-open:rotate-180">⌄</span>
                </summary>

                <div className="border-t border-[var(--border)] bg-black/[0.03] p-3 sm:p-5 lg:p-6">
                  <div className="mb-5 flex flex-wrap gap-2">
                    <span className="rounded-full border border-[var(--border)] bg-[var(--surface)] px-3 py-1.5 text-xs">Physics · 001–025</span>
                    <span className="rounded-full border border-[var(--border)] bg-[var(--surface)] px-3 py-1.5 text-xs">Chemistry · 026–050</span>
                    <span className="rounded-full border border-[var(--border)] bg-[var(--surface)] px-3 py-1.5 text-xs">Mathematics · 051–075</span>
                  </div>

                  <div className="space-y-6">
                    {subjectRows.map(({ subject, rows: subjectQuestions }) => (
                      <section key={subject} className="overflow-hidden rounded-2xl border border-[var(--border)] bg-[var(--surface)]">
                        <header className="flex flex-wrap items-center justify-between gap-2 border-b border-[var(--border)] bg-[var(--surface-raised)] px-4 py-3 sm:px-5">
                          <div>
                            <h3 className="text-base font-semibold sm:text-lg">{subject}</h3>
                            <p className="mt-0.5 text-xs text-[var(--muted)]">
                              {subject === "Physics" ? "Paper slots 001–025 · Questions 1–25" : subject === "Chemistry" ? "Paper slots 026–050 · Questions 1–25" : "Paper slots 051–075 · Questions 1–25"}
                            </p>
                          </div>
                          <span className="rounded-full border border-[var(--border)] px-3 py-1 text-xs tabular-nums">{subjectQuestions.length}/25 slots</span>
                        </header>
                        {subjectQuestions.length === 0 ? (
                          <p className="p-4 text-sm text-[var(--muted)]">No numbered slots available for this subject.</p>
                        ) : (
                          <div className="divide-y divide-[var(--border)]">
                            {subjectQuestions.map((question, index) => {
                              const slot = paperSlot(question) ?? index + 1;
                              const qNumber = subjectQuestionNumber(question, index + 1);
                              const options = safeOptions(question.options);
                              const placeholder = !question.statement || question.statement.toLowerCase().includes("content not yet added");
                              return (
                                <article key={question.id} className="min-w-0 p-3 sm:p-4">
                                  <div className="flex min-w-0 items-start gap-3">
                                    <span className="grid size-10 shrink-0 place-items-center rounded-xl border border-[var(--border)] bg-[var(--surface-raised)] text-xs font-bold tabular-nums sm:size-11">{String(slot).padStart(3, "0")}</span>
                                    <div className="min-w-0 flex-1">
                                      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                                        <div className="min-w-0">
                                          <h4 className="break-words text-sm font-semibold leading-6 sm:text-base">Question {qNumber}</h4>
                                          <p className="mt-0.5 break-all text-[10px] leading-5 text-[var(--muted)] sm:text-xs">{question.source_id}</p>
                                        </div>
                                        <div className="flex flex-wrap gap-1.5">
                                          <span className={"rounded-full border px-2 py-1 text-[10px] font-bold uppercase tracking-wide " + statusClass(question.review_status)}>{question.review_status}</span>
                                          <span className={"rounded-full border px-2 py-1 text-[10px] font-bold uppercase tracking-wide " + statusClass(question.is_published ? "published" : "unpublished")}>{question.is_published ? "Published" : "Draft"}</span>
                                        </div>
                                      </div>
                                      <div className="mt-3 rounded-xl border border-[var(--border)] bg-[var(--surface-raised)] p-3 sm:p-4">
                                        <div className="mb-2 flex flex-wrap items-center justify-between gap-2">
                                          <p className="text-[10px] font-bold uppercase tracking-[0.14em] text-[var(--muted)]">Question statement</p>
                                          {placeholder ? <span className="rounded-full border border-amber-400/30 bg-amber-400/10 px-2 py-1 text-[10px] font-semibold text-amber-200">Content pending</span> : null}
                                        </div>
                                        <MathPreview text={question.statement || "Question statement not entered."} />
                                      </div>
                                      {options.length > 0 ? (
                                        <div className="mt-3 grid min-w-0 gap-2 sm:grid-cols-2">
                                          {options.map((option, optionIndex) => (
                                            <div key={(option.label ?? String(optionIndex)) + "-" + optionIndex} className="flex min-w-0 items-start gap-2.5 rounded-xl border border-[var(--border)] bg-[var(--surface)] p-3">
                                              <span className="grid size-7 shrink-0 place-items-center rounded-lg border border-[var(--border)] bg-[var(--surface-raised)] text-xs font-bold">{option.label ?? String.fromCharCode(65 + optionIndex)}</span>
                                              <span className="min-w-0 flex-1">{option.text ? <MathPreview text={option.text} /> : option.imagePath ? <span className="break-words text-sm text-[var(--muted)]">Image: {option.imagePath}</span> : <span className="text-sm text-[var(--muted)]">Option text not entered</span>}</span>
                                            </div>
                                          ))}
                                        </div>
                                      ) : (
                                        <p className="mt-3 text-xs text-[var(--muted)]">Options have not been entered for this record yet.</p>
                                      )}
                                      <div className="mt-3 flex flex-col gap-3 border-t border-[var(--border)] pt-3 sm:flex-row sm:items-center sm:justify-between">
                                        <p className="break-words text-xs leading-5 text-[var(--muted)]">{question.source_pdf ? question.source_pdf + (question.source_page ? " · page " + question.source_page : "") : "Source reference not recorded"}</p>
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
                  </div>

                  {legacyRows.length > 0 ? (
                    <details className="mt-5 rounded-2xl border border-[var(--border)] bg-[var(--surface)]">
                      <summary className="cursor-pointer px-4 py-3 text-sm font-semibold">Legacy records ({legacyRows.length}) · outside the 75 numbered slots</summary>
                      <div className="divide-y divide-[var(--border)] border-t border-[var(--border)]">
                        {legacyRows.map((question) => (
                          <article key={question.id} className="p-4">
                            <div className="flex flex-wrap items-center justify-between gap-2">
                              <h4 className="text-sm font-semibold">{question.title}</h4>
                              <span className="rounded-full border border-[var(--border)] px-2 py-1 text-[10px]">{question.subject}</span>
                            </div>
                            <p className="mt-1 break-all text-[11px] text-[var(--muted)]">{question.source_id}</p>
                            <div className="mt-3"><MathPreview text={question.statement || "Question statement not entered."} /></div>
                            <div className="mt-3"><PyqReviewActions id={question.id} isPublished={question.is_published} reviewStatus={question.review_status} /></div>
                          </article>
                        ))}
                      </div>
                    </details>
                  ) : null}
                </div>
              </details>
            );
          })
        )}
      </section>

      <p className="mt-8 text-center text-xs leading-5 text-[var(--muted)]">Only open a shift when you want to work on its questions. The form stays closed until you select “Add question”. New questions are saved as drafts.</p>
    </main>
  );
}
