/* eslint @next/next/no-img-element: off -- preserve exact aspect ratios for exam diagrams. */
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { gradePyqQuestion } from "@/app/pyq/actions";
import { QuestionContent } from "@/components/questions/question-content";
import { renderQuestionText } from "@/lib/questions/render";
import { isSafeAssetPath, type QuestionContent as QuestionData } from "@/lib/questions/schema";

type Props = {
  id: string;
  number: number;
  title: string;
  exam: string;
  year: number | null;
  question: QuestionData;
};

export function PyqPracticeCard({ id, number, title, exam, year, question }: Props) {
  const router = useRouter();
  const [answer, setAnswer] = useState("");
  const [result, setResult] = useState<Record<string, unknown> | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, startTransition] = useTransition();

  function submit() {
    setError(null);
    startTransition(async () => {
      const response = await gradePyqQuestion(id, answer);
      if (!response.ok) {
        if (response.code === "AUTH_REQUIRED")
          router.push(`/login?next=${encodeURIComponent("/pyq")}`);
        else setError(response.error);
        return;
      }
      setResult(response.data);
    });
  }

  const isCorrect = result?.is_correct === true;
  const unlocked = result?.solution_unlocked === true;

  return (
    <article
      aria-labelledby={`pyq-question-${id}`}
      className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5 transition-colors sm:p-7"
    >
      <div className="mb-5 flex flex-wrap items-center gap-2 text-xs text-[var(--muted)]">
        <span className="rounded-full border border-[var(--border)] bg-white/[0.03] px-2.5 py-1 font-semibold text-[var(--text)]">
          {question.subject}
        </span>
        <span className="rounded-full bg-white/[0.03] px-2.5 py-1">
          {exam}{year ? ` · ${year}` : ""}
        </span>
        {question.chapter ? (
          <span className="rounded-full bg-white/[0.03] px-2.5 py-1">{question.chapter}</span>
        ) : null}
        <span className="ml-auto rounded-full border border-[var(--border)] px-2.5 py-1 font-medium">
          Q{number}
        </span>
      </div>
      <h2 id={`pyq-question-${id}`} className="mb-4 text-lg font-semibold leading-7 sm:text-xl">
        {title}
      </h2>
      <QuestionContent question={{ ...question, options: [] }} />
      {question.options.length ? (
        <fieldset disabled={busy || isCorrect || unlocked} className="mt-5 grid gap-3">
          <legend className="mb-2 text-sm font-semibold">Choose an answer</legend>
          {question.options.map((option) => (
            <label
              key={option.id}
              className={`flex cursor-pointer items-start gap-3 rounded-xl border p-3 transition-colors focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-[var(--accent)] ${answer === option.label ? "border-[var(--accent)] bg-[var(--accent)]/10 shadow-[0_0_0_1px_var(--accent)]" : "border-[var(--border)] hover:border-[var(--muted)]/70 hover:bg-white/[0.04]"}`}
            >
              <input
                type="radio"
                name={`pyq-${id}`}
                value={option.label}
                checked={answer === option.label}
                onChange={() => setAnswer(option.label)}
                className="mt-1 accent-[var(--accent)]"
              />
              <span className="grid size-6 shrink-0 place-items-center rounded-full border border-[var(--border)] text-xs font-semibold">
                {option.label}
              </span>
              <span className="min-w-0 flex-1">
                {option.text ? (
                  <span dangerouslySetInnerHTML={{ __html: renderQuestionText(option.text) }} />
                ) : null}
                {option.imagePath && isSafeAssetPath(option.imagePath) ? (
                  <img
                    src={`/${option.imagePath}`}
                    alt={`Option ${option.label}`}
                    loading="lazy"
                    decoding="async"
                    className="mt-3 h-auto max-h-64 max-w-full rounded-lg border border-[var(--border)] object-contain"
                  />
                ) : null}
              </span>
            </label>
          ))}
        </fieldset>
      ) : (
        <label className="mt-5 block text-sm font-medium">
          Your answer
          <input
            value={answer}
            onChange={(event) => setAnswer(event.target.value)}
            disabled={busy || isCorrect || unlocked}
            className="mt-2 w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-3"
          />
        </label>
      )}
      {!isCorrect && !unlocked ? (
        <button
          type="button"
          onClick={submit}
          disabled={busy || !answer.trim()}
          aria-busy={busy}
          className="mt-5 min-h-11 rounded-xl bg-[var(--accent)] px-5 py-3 text-sm font-bold text-[var(--accent-foreground)] transition-opacity hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[var(--accent)] disabled:cursor-not-allowed disabled:opacity-50"
        >
          {busy ? "Checking…" : "Check answer"}
        </button>
      ) : null}
      {error ? (
        <p role="alert" className="mt-4 text-sm text-red-200">
          {error}
        </p>
      ) : null}
      {result ? (
        <div aria-live="polite" aria-atomic="true" className="mt-5 rounded-2xl border border-[var(--border)] bg-black/20 p-4">
          <p className={isCorrect ? "font-semibold text-[var(--accent)]" : "font-semibold"}>
            {isCorrect ? "Correct answer." : "Not quite. Try again."}
          </p>
          {typeof result.attempts_until_solution === "number" && !unlocked && !isCorrect ? (
            <p className="mt-2 text-sm text-[var(--muted)]">
              The worked solution unlocks after two incorrect attempts.{" "}
              {result.attempts_until_solution} incorrect attempt(s) remaining.
            </p>
          ) : null}
          {unlocked ? (
            <div className="mt-4">
              <p className="text-xs font-bold uppercase tracking-widest text-[var(--accent)]">
                Worked solution unlocked
              </p>
              <p
                className="mt-2 whitespace-pre-wrap text-sm leading-7"
                dangerouslySetInnerHTML={{
                  __html: renderQuestionText(String(result.solution ?? "")),
                }}
              />
              <p className="mt-3 text-sm">Correct answer: {String(result.correct_answer ?? "")}</p>
            </div>
          ) : null}
          {isCorrect && !unlocked ? (
            <p className="mt-2 text-sm text-[var(--muted)]">
              Your answer is correct. The worked solution remains gated by the server.
            </p>
          ) : null}
        </div>
      ) : null}
    </article>
  );
}
