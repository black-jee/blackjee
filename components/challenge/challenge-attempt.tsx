"use client";

import { useEffect, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { getChallengeResult, startChallenge, submitChallenge } from "@/app/challenge/actions";
import { renderQuestionText } from "@/lib/questions/render";
import { isSafeAssetPath } from "@/lib/questions/schema";

type Schedule = { id: string; title: string; subject: string; starts_at: string; ends_at: string; solution_release_at: string };
type Option = { id: string; label: string; text: string; imagePath?: string };

function normalizeOptions(raw: unknown): Option[] {
  if (!Array.isArray(raw)) return [];
  return raw.slice(0, 12).map((item, index) => {
    const fallbackLabel = String.fromCharCode(65 + index);
    if (typeof item === "string") return { id: String(index), label: fallbackLabel, text: item };
    if (item && typeof item === "object") {
      const value = item as Record<string, unknown>;
      return {
        id: typeof value.id === "string" ? value.id : String(index),
        label: typeof value.label === "string" ? value.label : fallbackLabel,
        text: typeof value.text === "string" ? value.text : typeof value.value === "string" ? value.value : "",
        imagePath: typeof value.imagePath === "string" ? value.imagePath : typeof value.image_path === "string" ? value.image_path : undefined,
      };
    }
    return { id: String(index), label: fallbackLabel, text: "" };
  });
}

export function ChallengeAttempt({ schedule }: { schedule: Schedule }) {
  const router = useRouter();
  const [question, setQuestion] = useState<Record<string, unknown> | null>(null);
  const [selected, setSelected] = useState("");
  const [result, setResult] = useState<Record<string, unknown> | null>(null);
  const [solution, setSolution] = useState<Record<string, unknown> | null>(null);
  const [elapsed, setElapsed] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [busy, startTransition] = useTransition();
  const options = normalizeOptions(question?.options);
  const startedAt = typeof question?.started_at === "string" ? question.started_at : null;

  useEffect(() => {
    if (!startedAt || result) return;
    const update = () => setElapsed(Math.max(0, Math.floor((Date.now() - new Date(startedAt).getTime()) / 1000)));
    update();
    const timer = window.setInterval(update, 1000);
    return () => window.clearInterval(timer);
  }, [startedAt, result]);

  function start() {
    setError(null);
    startTransition(async () => {
      const response = await startChallenge(schedule.id);
      if (!response.ok) {
        if (response.code === "AUTH_REQUIRED") router.push(`/login?next=${encodeURIComponent("/challenge")}`);
        else setError(response.error);
        return;
      }
      setQuestion(response.data);
    });
  }

  function submit() {
    setError(null);
    startTransition(async () => {
      const response = await submitChallenge(schedule.id, selected);
      if (!response.ok) {
        if (response.code === "AUTH_REQUIRED") router.push(`/login?next=${encodeURIComponent("/challenge")}`);
        else setError(response.error);
        return;
      }
      setResult(response.data);
      if (response.data.solution_released === true) {
        const released = await getChallengeResult(schedule.id);
        if (released.ok) setSolution(released.data);
      }
    });
  }

  return (
    <section className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-8">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-[var(--accent)]">{schedule.subject} · Daily challenge</p>
          <h2 className="mt-2 text-2xl font-semibold tracking-tight">{schedule.title}</h2>
        </div>
        {question && !result ? <div className="rounded-xl border border-[var(--border)] px-3 py-2 text-right"><p className="text-[10px] uppercase tracking-widest text-[var(--muted)]">Elapsed</p><p className="font-mono text-lg tabular-nums">{Math.floor(elapsed / 60).toString().padStart(2, "0")}:{(elapsed % 60).toString().padStart(2, "0")}</p></div> : null}
      </div>

      {!question ? (
        <div className="mt-6">
          <p className="text-sm leading-6 text-[var(--muted)]">The server verifies your signed-in session and starts the attempt before returning question content.</p>
          <button onClick={start} disabled={busy} className="mt-5 rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)] disabled:opacity-60">{busy ? "Starting…" : "Start attempt"}</button>
        </div>
      ) : (
        <div className="mt-6">
          <div className="text-base leading-8" dangerouslySetInnerHTML={{ __html: renderQuestionText(typeof question.statement === "string" ? question.statement : "") }} />
          {options.length ? (
            <fieldset disabled={Boolean(result) || busy} className="mt-5 grid gap-3">
              <legend className="mb-3 text-sm font-semibold">Choose one answer</legend>
              {options.map((option) => (
                <label key={option.id} className={`flex cursor-pointer items-start gap-3 rounded-xl border p-4 transition-colors ${selected === option.label ? "border-[var(--accent)] bg-[var(--accent)]/5" : "border-[var(--border)] hover:bg-white/5"}`}>
                  <input type="radio" name="challenge-answer" value={option.label} checked={selected === option.label} onChange={() => setSelected(option.label)} className="mt-1 accent-[var(--accent)]" />
                  <span className="grid size-6 shrink-0 place-items-center rounded-full border border-[var(--border)] text-xs font-semibold">{option.label}</span>
                  <span className="min-w-0 flex-1">
                    {option.text ? <span dangerouslySetInnerHTML={{ __html: renderQuestionText(option.text) }} /> : null}
                    {option.imagePath && isSafeAssetPath(option.imagePath) ? <img src={`/${option.imagePath}`} alt={`Option ${option.label}`} loading="lazy" decoding="async" className="mt-3 h-auto max-h-64 max-w-full rounded-lg border border-[var(--border)] object-contain" /> : null}
                  </span>
                </label>
              ))}
            </fieldset>
          ) : (
            <label className="mt-5 block text-sm font-medium">Your answer
              <input value={selected} onChange={(event) => setSelected(event.target.value)} disabled={Boolean(result) || busy} className="mt-2 w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3" />
            </label>
          )}
          {!result ? <button onClick={submit} disabled={busy || !selected.trim()} className="mt-6 rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)] disabled:opacity-50">{busy ? "Submitting…" : "Submit answer"}</button> : (
            <div className="mt-6 rounded-2xl border border-[var(--border)] bg-black/20 p-4">
              <p className="font-semibold">{result.is_correct === true ? "Correct answer." : "Answer submitted."}</p>
              <p className="mt-1 text-sm text-[var(--muted)]">Server-recorded time: {String(result.elapsed_seconds ?? elapsed)} seconds.</p>
              {solution?.solution_released === true ? <div className="mt-4"><p className="text-xs font-bold uppercase tracking-widest text-[var(--accent)]">Official solution</p><p className="mt-2 whitespace-pre-wrap text-sm leading-7">{String(solution.solution ?? "")}</p><p className="mt-2 text-sm">Correct answer: {String(solution.correct_answer ?? "")}</p></div> : <p className="mt-3 text-sm text-[var(--muted)]">The official solution will appear when the release time is reached.</p>}
            </div>
          )}
        </div>
      )}
      {error ? <p role="alert" className="mt-4 rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-sm text-red-200">{error}</p> : null}
      <p className="mt-6 border-t border-[var(--border)] pt-4 text-xs leading-5 text-[var(--muted)]">The database enforces attempt eligibility and records the submission time. The on-screen timer is informational only.</p>
    </section>
  );
}
