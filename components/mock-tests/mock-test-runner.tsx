"use client";

/* eslint @next/next/no-img-element: off -- exam diagrams need their original aspect ratio. */
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { resumeMockTest, startMockTest, submitMockTest } from "@/app/mock-tests/actions";
import { QuestionContent } from "@/components/questions/question-content";
import { renderQuestionText } from "@/lib/questions/render";
import { isSafeAssetPath } from "@/lib/questions/schema";
import { toPyqOptions } from "@/lib/questions/pyq-adapter";

type Shift = { year: number; session: string };
type ActiveAttempt = { id: string; mode: string; exam_year: number | null; session: string | null; total_questions: number; started_at: string; duration_seconds: number };
type MockQuestion = {
  id: string;
  source_id?: string;
  title?: string;
  exam?: string;
  year?: number | null;
  session?: string | null;
  subject: "Physics" | "Chemistry" | "Mathematics";
  chapter?: string | null;
  statement: string;
  statement_image_path?: string | null;
  options: unknown;
  asset_paths?: string[];
  question_type: "single_correct" | "numerical";
  marks_correct: number;
  marks_wrong: number;
};
type Attempt = {
  attempt_id: string;
  mode: "shift" | "focused";
  exam_year?: number | null;
  session?: string | null;
  subject?: string | null;
  chapter?: string | null;
  started_at: string;
  duration_seconds: number;
  total_questions: number;
  questions: MockQuestion[];
};

function asAttempt(value: Record<string, unknown>): Attempt | null {
  if (typeof value.attempt_id !== "string" || typeof value.started_at !== "string" || !Array.isArray(value.questions)) return null;
  return value as unknown as Attempt;
}

function formatTime(seconds: number): string {
  const safe = Math.max(0, Math.floor(seconds));
  return [Math.floor(safe / 3600), Math.floor((safe % 3600) / 60), safe % 60].map((part) => String(part).padStart(2, "0")).join(":");
}

function answerStorageKey(attemptId: string) {
  return `blackjee-mock-answers:${attemptId}`;
}

export function MockTestRunner({ shifts, activeAttempts }: { shifts: Shift[]; activeAttempts: ActiveAttempt[] }) {
  const router = useRouter();
  const [mode, setMode] = useState<"shift" | "focused">("shift");
  const [shiftKey, setShiftKey] = useState(shifts.length ? `${shifts[0].year}||${shifts[0].session}` : "");
  const [subject, setSubject] = useState("");
  const [chapter, setChapter] = useState("");
  const [questionCount, setQuestionCount] = useState(20);
  const [durationMinutes, setDurationMinutes] = useState(180);
  const [attempt, setAttempt] = useState<Attempt | null>(null);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [reviewIds, setReviewIds] = useState<string[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [remaining, setRemaining] = useState(0);
  const [result, setResult] = useState<Record<string, unknown> | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const submitLock = useRef(false);

  const questions = useMemo(() => attempt?.questions ?? [], [attempt]);
  const current = questions[currentIndex];
  const options = useMemo(() => toPyqOptions(current?.options), [current]);
  const attemptedCount = questions.filter((question) => Boolean(answers[question.id]?.trim())).length;
  const shiftParts = shiftKey.split("||");
  const selectedYear = shiftParts[0] ? Number(shiftParts[0]) : null;
  const selectedSession = shiftParts[1] || null;

  function storeAnswers(next: Record<string, string>, attemptId = attempt?.attempt_id) {
    setAnswers(next);
    if (!attemptId) return;
    try {
      localStorage.setItem(answerStorageKey(attemptId), JSON.stringify(next));
    } catch {
      setError("Progress could not be saved on this device. Keep this tab open until you submit.");
    }
  }

  async function start() {
    setBusy(true);
    setError(null);
    const response = await startMockTest({
      mode,
      year: mode === "shift" ? selectedYear : null,
      session: mode === "shift" ? selectedSession : null,
      subject: subject || null,
      chapter: chapter.trim() || null,
      questionCount,
      durationSeconds: durationMinutes * 60,
    });
    setBusy(false);
    if (!response.ok) {
      if (response.code === "AUTH_REQUIRED") router.push(`/login?next=${encodeURIComponent("/mock-tests")}`);
      else setError(response.error);
      return;
    }
    const next = asAttempt(response.data);
    if (!next) {
      setError("The mock test could not be prepared from the question bank.");
      return;
    }
    submitLock.current = false;
    setAttempt(next);
    setAnswers({});
    setReviewIds([]);
    setCurrentIndex(0);
    setResult(null);
    setRemaining(next.duration_seconds);
    try {
      localStorage.setItem(answerStorageKey(next.attempt_id), "{}");
    } catch {
      // The server still owns the question list and final grading.
    }
  }

  async function resume(attemptId: string) {
    setBusy(true);
    setError(null);
    const response = await resumeMockTest(attemptId);
    setBusy(false);
    if (!response.ok) {
      if (response.code === "AUTH_REQUIRED") router.push(`/login?next=${encodeURIComponent("/mock-tests")}`);
      else setError(response.error);
      return;
    }
    const next = asAttempt(response.data);
    if (!next) {
      setError("This mock test could not be resumed.");
      return;
    }
    let saved: Record<string, string> = {};
    try {
      const raw = localStorage.getItem(answerStorageKey(attemptId));
      const parsed: unknown = raw ? JSON.parse(raw) : {};
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
        for (const question of next.questions) {
          const value = (parsed as Record<string, unknown>)[question.id];
          if (typeof value === "string" && value.length <= 100) saved[question.id] = value;
        }
      }
    } catch {
      saved = {};
    }
    submitLock.current = false;
    setAttempt(next);
    setAnswers(saved);
    setReviewIds([]);
    setCurrentIndex(0);
    setResult(null);
    setRemaining(next.duration_seconds);
  }

  const finish = useCallback(async (automatic = false) => {
    if (!attempt || result || submitLock.current) return;
    if (!automatic && !window.confirm("Submit this mock test now? You cannot change answers after submission.")) return;
    submitLock.current = true;
    setBusy(true);
    setError(null);
    const payload = questions.map((question) => ({ question_id: question.id, answer: answers[question.id] ?? "" }));
    const response = await submitMockTest(attempt.attempt_id, payload);
    setBusy(false);
    if (!response.ok) {
      submitLock.current = false;
      setError(response.error);
      return;
    }
    setResult(response.data);
    try {
      localStorage.removeItem(answerStorageKey(attempt.attempt_id));
    } catch {
      // Result is stored in Supabase; local cleanup is best-effort.
    }
  }, [attempt, result, questions, answers]);

  useEffect(() => {
    if (!attempt || result || attempt.duration_seconds === 0) return;
    const started = Date.parse(attempt.started_at);
    const interval = window.setInterval(() => {
      const left = Math.max(0, Math.ceil((started + attempt.duration_seconds * 1000 - Date.now()) / 1000));
      setRemaining(left);
      if (left === 0) void finish(true);
    }, 1000);
    return () => window.clearInterval(interval);
  }, [attempt, result, finish]);

  function chooseAnswer(value: string) {
    if (!current || result || busy) return;
    storeAnswers({ ...answers, [current.id]: value });
  }

  function toggleReview() {
    if (!current) return;
    setReviewIds((previous) => previous.includes(current.id) ? previous.filter((id) => id !== current.id) : [...previous, current.id]);
  }

  if (result) {
    const rows = Array.isArray(result.questions) ? result.questions as Record<string, unknown>[] : [];
    return (
      <section className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-8">
        <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--accent)]">Mock test submitted</p>
        <h2 className="mt-2 text-3xl font-semibold tracking-tight">Your results</h2>
        <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
          {[
            ["Score", `${String(result.score ?? 0)} / ${String(result.max_score ?? 0)}`],
            ["Correct", String(result.correct_count ?? 0)],
            ["Incorrect", String(result.wrong_count ?? 0)],
            ["Attempted", `${String(result.attempted_count ?? 0)} / ${String(result.total_questions ?? rows.length)}`],
          ].map(([label, value]) => <div key={label} className="rounded-xl border border-[var(--border)] p-4"><p className="text-xl font-semibold tabular-nums">{value}</p><p className="mt-1 text-xs text-[var(--muted)]">{label}</p></div>)}
        </div>
        <div className="mt-7 space-y-4">
          {rows.map((row, index) => (
            <article key={String(row.id)} className="rounded-xl border border-[var(--border)] p-4">
              <div className="flex items-center justify-between gap-3"><p className="font-semibold">Question {index + 1} · {String(row.subject ?? "")}</p><span className={row.is_correct === true ? "text-sm text-[var(--accent)]" : "text-sm text-[var(--muted)]"}>{row.is_correct === true ? "Correct" : row.selected_answer ? "Incorrect" : "Unattempted"}</span></div>
              <div className="mt-3 text-sm leading-7" dangerouslySetInnerHTML={{ __html: renderQuestionText(String(row.statement ?? "")) }} />
              <p className="mt-3 text-sm">Your answer: {String(row.selected_answer ?? "—")} · Correct answer: {String(row.correct_answer ?? "—")} · Marks: {String(row.marks_awarded ?? 0)}</p>
              {typeof row.solution === "string" && row.solution ? <div className="mt-3 border-t border-[var(--border)] pt-3"><p className="text-xs font-bold uppercase tracking-widest text-[var(--accent)]">Solution</p><div className="mt-2 whitespace-pre-wrap text-sm leading-7" dangerouslySetInnerHTML={{ __html: renderQuestionText(row.solution) }} /></div> : null}
            </article>
          ))}
        </div>
        <button type="button" onClick={() => { setAttempt(null); setResult(null); setAnswers({}); setReviewIds([]); setCurrentIndex(0); router.refresh(); }} className="mt-7 rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)]">Back to test setup</button>
      </section>
    );
  }

  if (attempt && current) {
    return (
      <section className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-4 sm:p-7">
        <div className="flex flex-wrap items-start justify-between gap-4 border-b border-[var(--border)] pb-5">
          <div><p className="text-xs font-bold uppercase tracking-[0.18em] text-[var(--accent)]">{current.subject} · {current.question_type === "numerical" ? "Numerical" : "Single correct"}</p><h2 className="mt-2 text-xl font-semibold">Question {currentIndex + 1} of {questions.length}</h2><p className="mt-1 text-xs text-[var(--muted)]">{current.chapter ?? "JEE practice"} · +{current.marks_correct} / {current.marks_wrong} marks</p></div>
          <div className="rounded-xl border border-[var(--border)] px-3 py-2 text-right"><p className="text-[10px] uppercase tracking-widest text-[var(--muted)]">{attempt.duration_seconds ? "Time left" : "Timer"}</p><p className="font-mono text-lg tabular-nums">{attempt.duration_seconds ? formatTime(remaining) : "No limit"}</p></div>
        </div>
        <div className="mt-6"><QuestionContent question={{ sourceId: current.source_id ?? current.id, statement: current.statement, statementImagePath: current.statement_image_path ?? undefined, options: [], subject: current.subject, chapter: current.chapter ?? undefined, assetPaths: current.asset_paths ?? [] }} /></div>
        {current.question_type === "numerical" || options.length === 0 ? (
          <label className="mt-6 block text-sm font-medium">Enter your answer
            <input inputMode="decimal" value={answers[current.id] ?? ""} onChange={(event) => chooseAnswer(event.target.value)} disabled={busy} className="mt-2 w-full max-w-sm rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3" />
          </label>
        ) : (
          <fieldset disabled={busy} className="mt-6 grid gap-3">
            <legend className="mb-2 text-sm font-semibold">Select one option</legend>
            {options.map((option) => (
              <label key={option.id} className={`flex cursor-pointer items-start gap-3 rounded-xl border p-3 ${answers[current.id] === option.label ? "border-[var(--accent)] bg-[var(--accent)]/5" : "border-[var(--border)] hover:bg-white/5"}`}>
                <input type="radio" name={`mock-${current.id}`} checked={answers[current.id] === option.label} onChange={() => chooseAnswer(option.label)} className="mt-1 accent-[var(--accent)]" />
                <span className="grid size-6 shrink-0 place-items-center rounded-full border border-[var(--border)] text-xs font-semibold">{option.label}</span>
                <span className="min-w-0 flex-1">{option.text ? <span dangerouslySetInnerHTML={{ __html: renderQuestionText(option.text) }} /> : null}{option.imagePath && isSafeAssetPath(option.imagePath) ? <img src={`/${option.imagePath}`} alt={`Option ${option.label}`} loading="lazy" decoding="async" className="mt-3 h-auto max-h-64 max-w-full rounded-lg border border-[var(--border)] object-contain" /> : null}</span>
              </label>
            ))}
          </fieldset>
        )}
        <div className="mt-6 flex flex-wrap gap-2 border-t border-[var(--border)] pt-5">
          <button type="button" disabled={currentIndex === 0 || busy} onClick={() => setCurrentIndex((index) => index - 1)} className="rounded-xl border border-[var(--border)] px-4 py-2.5 text-sm disabled:opacity-40">← Previous</button>
          <button type="button" disabled={busy} onClick={() => storeAnswers({ ...answers, [current.id]: "" })} className="rounded-xl border border-[var(--border)] px-4 py-2.5 text-sm">Clear response</button>
          <button type="button" disabled={busy} onClick={toggleReview} className={`rounded-xl border px-4 py-2.5 text-sm ${reviewIds.includes(current.id) ? "border-[var(--accent)] text-[var(--accent)]" : "border-[var(--border)]"}`}>{reviewIds.includes(current.id) ? "Marked for review" : "Mark for review"}</button>
          <button type="button" disabled={currentIndex === questions.length - 1 || busy} onClick={() => setCurrentIndex((index) => index + 1)} className="ml-auto rounded-xl border border-[var(--border)] px-4 py-2.5 text-sm disabled:opacity-40">Next →</button>
          <button type="button" disabled={busy} onClick={() => void finish(false)} className="rounded-xl bg-[var(--accent)] px-4 py-2.5 text-sm font-bold text-[var(--accent-foreground)] disabled:opacity-50">{busy ? "Submitting…" : "Submit test"}</button>
        </div>
        <div className="mt-5 border-t border-[var(--border)] pt-5"><div className="mb-3 flex items-center justify-between"><p className="text-sm font-semibold">Question palette</p><p className="text-xs text-[var(--muted)]">{attemptedCount} attempted · {reviewIds.length} for review</p></div><div className="grid grid-cols-5 gap-2 sm:grid-cols-10">{questions.map((question, index) => <button key={question.id} type="button" onClick={() => setCurrentIndex(index)} className={`relative rounded-lg border px-2 py-2 text-xs font-semibold ${currentIndex === index ? "border-[var(--accent)] bg-[var(--accent)]/10 text-[var(--accent)]" : answers[question.id]?.trim() ? "border-[var(--accent)]/50" : "border-[var(--border)] text-[var(--muted)]"}`}>{index + 1}{reviewIds.includes(question.id) ? <span className="absolute -right-1 -top-1 size-2 rounded-full bg-amber-400" aria-label="Marked for review" /> : null}</button>)}</div></div>
        {error ? <p role="alert" className="mt-4 rounded-xl border border-red-400/30 bg-red-400/10 p-3 text-sm text-red-200">{error}</p> : null}
        <p className="mt-5 text-xs leading-5 text-[var(--muted)]">Your attempt and question assignment are stored in Supabase. The browser saves answer progress on this device; the server validates ownership, assignment, marks and final submission time.</p>
      </section>
    );
  }

  return (
    <section className="space-y-6">
      {activeAttempts.length ? <div className="rounded-2xl border border-[var(--accent)]/30 bg-[var(--surface)] p-5"><h2 className="font-semibold">Resume an unfinished test</h2><div className="mt-3 flex flex-wrap gap-2">{activeAttempts.map((item) => <button key={item.id} type="button" disabled={busy} onClick={() => void resume(item.id)} className="rounded-xl border border-[var(--border)] px-4 py-2.5 text-sm">Resume {item.mode === "shift" ? `${item.exam_year} ${item.session ?? "shift"}` : "focused test"} · {item.total_questions} questions</button>)}</div></div> : null}
      <form onSubmit={(event) => { event.preventDefault(); void start(); }} className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-7">
        <p className="text-xs font-bold uppercase tracking-[0.18em] text-[var(--accent)]">Exam simulation</p><h2 className="mt-2 text-2xl font-semibold tracking-tight">Configure your mock test</h2>
        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <label className="block space-y-2 text-sm font-medium"><span>Test mode</span><select value={mode} onChange={(event) => setMode(event.target.value as "shift" | "focused")} className="w-full rounded-xl border border-[var(--border)] bg-[#11131a] px-3 py-3"><option value="shift">Published year / shift</option><option value="focused">Focused practice test</option></select></label>
          {mode === "shift" ? <label className="block space-y-2 text-sm font-medium"><span>Year and shift</span><select value={shiftKey} onChange={(event) => setShiftKey(event.target.value)} disabled={!shifts.length} className="w-full rounded-xl border border-[var(--border)] bg-[#11131a] px-3 py-3"><option value="">Choose a published shift</option>{shifts.map((shift) => <option key={`${shift.year}||${shift.session}`} value={`${shift.year}||${shift.session}`}>{shift.year} · {shift.session}</option>)}</select></label> : <label className="block space-y-2 text-sm font-medium"><span>Subject</span><select value={subject} onChange={(event) => setSubject(event.target.value)} className="w-full rounded-xl border border-[var(--border)] bg-[#11131a] px-3 py-3"><option value="">All subjects</option><option>Physics</option><option>Chemistry</option><option>Mathematics</option></select></label>}
          {mode === "focused" ? <label className="block space-y-2 text-sm font-medium"><span>Chapter (optional)</span><input value={chapter} onChange={(event) => setChapter(event.target.value)} maxLength={160} placeholder="e.g. Electrostatics" className="w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3" /></label> : null}
          <label className="block space-y-2 text-sm font-medium"><span>Question count</span><select value={questionCount} onChange={(event) => setQuestionCount(Number(event.target.value))} className="w-full rounded-xl border border-[var(--border)] bg-[#11131a] px-3 py-3"><option value={10}>10 questions</option><option value={20}>20 questions</option><option value={30}>30 questions</option><option value={75}>75 questions · full paper</option></select></label>
          <label className="block space-y-2 text-sm font-medium"><span>Time limit</span><select value={durationMinutes} onChange={(event) => setDurationMinutes(Number(event.target.value))} className="w-full rounded-xl border border-[var(--border)] bg-[#11131a] px-3 py-3"><option value={180}>180 minutes</option><option value={120}>120 minutes</option><option value={60}>60 minutes</option><option value={45}>45 minutes</option><option value={30}>30 minutes</option><option value={15}>15 minutes</option><option value={0}>No timer</option></select></label>
        </div>
        <p className="mt-5 text-xs leading-5 text-[var(--muted)]">JEE marking is question-specific (+4/−1 by default). A full paper is enabled only when a shift has exactly 20 MCQs and 5 numerical questions per subject, all reviewed, published and answer-key verified.</p>
        <button type="submit" disabled={busy || (mode === "shift" && !shifts.length)} className="mt-5 rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)] disabled:opacity-50">{busy ? "Preparing test…" : "Start mock test"}</button>
        {error ? <p role="alert" className="mt-4 rounded-xl border border-red-400/30 bg-red-400/10 p-3 text-sm text-red-200">{error}</p> : null}
      </form>
    </section>
  );
}
