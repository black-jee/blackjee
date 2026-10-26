"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { savePyqQuestion } from "@/app/admin/pyq/actions";
import katex from "katex";

function parseOptions(raw: string) {
  return raw
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line, index) => {
      const [labelPart, textPart = "", imagePart = ""] = line.split("|");
      const label = labelPart.trim() || String.fromCharCode(65 + index);
      return {
        id: label.toLowerCase(),
        label,
        text: textPart.trim(),
        ...(imagePart.trim() ? { imagePath: imagePart.trim() } : {}),
      };
    });
}

const inputClass =
  "w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-2.5 text-sm";
const labelClass = "block min-w-0 space-y-1.5 text-sm font-medium";

function MathPreview({ text }: { text: string }) {
  const tokens = text.split(/(\$\$[\s\S]+?\$\$|\\\[[\s\S]+?\\\]|\$[^$\n]+\$|\\\([\s\S]+?\\\))/g);
  if (!text.trim()) return <span className="text-sm text-[var(--muted)]">Your formatted preview will appear here.</span>;
  return (
    <div className="whitespace-pre-wrap break-words text-sm leading-7">
      {tokens.map((token, index) => {
        let math: string | null = null;
        let display = false;
        if (token.startsWith("$$") && token.endsWith("$$")) {
          math = token.slice(2, -2);
          display = true;
        } else if (token.startsWith("\\[") && token.endsWith("\\]")) {
          math = token.slice(2, -2);
          display = true;
        } else if (token.startsWith("$") && token.endsWith("$")) {
          math = token.slice(1, -1);
        } else if (token.startsWith("\\(") && token.endsWith("\\)")) {
          math = token.slice(2, -2);
        }
        if (math === null) return <span key={index}>{token}</span>;
        const html = katex.renderToString(math, { displayMode: display, throwOnError: false, strict: "ignore" });
        return <span key={index} className={display ? "my-2 block max-w-full overflow-x-auto" : "inline-block max-w-full align-middle"} dangerouslySetInnerHTML={{ __html: html }} />;
      })}
    </div>
  );
}


export function PyqAuthoringForm() {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [notice, setNotice] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [statement, setStatement] = useState("");
  const [solution, setSolution] = useState("");
  const [optionsText, setOptionsText] = useState("A|\nB|\nC|\nD|");
  const [subject, setSubject] = useState("Physics");
  const [questionType, setQuestionType] = useState("single_correct");

  function updateOptionLine(index: number, field: "label" | "text" | "imagePath", value: string) {
    const rows = optionsText.split("\n");
    while (rows.length <= index) rows.push("||");
    const parts = (rows[index] ?? "").split("|");
    while (parts.length < 3) parts.push("");
    const fieldIndex = field === "label" ? 0 : field === "text" ? 1 : 2;
    parts[fieldIndex] = value;
    rows[index] = parts.slice(0, 3).join("|");
    setOptionsText(rows.join("\n"));
  }

  function submit(formData: FormData) {
    setError(null);
    setNotice(null);
    const yearRaw = String(formData.get("year") ?? "").trim();
    const pageRaw = String(formData.get("sourcePage") ?? "").trim();
    const tags = String(formData.get("tags") ?? "")
      .split(",")
      .map((v) => v.trim())
      .filter(Boolean);
    const assetPaths = String(formData.get("assetPaths") ?? "")
      .split("\n")
      .map((v) => v.trim())
      .filter(Boolean);
    const reviewNotes = String(formData.get("reviewNotes") ?? "")
      .split("\n")
      .map((v) => v.trim())
      .filter(Boolean);
    const options = parseOptions(optionsText);
    const correctAnswer = String(formData.get("correctAnswer") ?? "").trim();
    if (
      questionType === "single_correct" &&
      !options.some((option) => option.label.toUpperCase() === correctAnswer.toUpperCase())
    ) {
      setError("Correct answer must match an option label (A, B, C, D…).");
      return;
    }
    startTransition(async () => {
      const response = await savePyqQuestion({
        questionId: null,
        sourceId: String(formData.get("sourceId") ?? ""),
        title: String(formData.get("title") ?? ""),
        exam: String(formData.get("exam") ?? "JEE Main"),
        year: yearRaw ? Number(yearRaw) : null,
        session: String(formData.get("session") ?? ""),
        subject,
        chapter: String(formData.get("chapter") ?? ""),
        statement,
        statementImagePath: String(formData.get("statementImagePath") ?? ""),
        options,
        questionType,
        marksCorrect: Number(formData.get("marksCorrect") ?? 4),
        marksWrong: Number(formData.get("marksWrong") ?? -1),
        correctAnswer,
        solution: String(formData.get("solution") ?? ""),
        sourcePdf: String(formData.get("sourcePdf") ?? ""),
        sourcePage: pageRaw ? Number(pageRaw) : null,
        tags,
        assetPaths,
        reviewNotes,
      });
      if (!response.ok) {
        setError(response.error);
        return;
      }
      setNotice("Saved as a draft. It is not visible to students until reviewed and published.");
      setStatement("");
      setSolution("");
      setOptionsText("A|\nB|\nC|\nD|");
      (document.querySelector("form[data-pyq-authoring]") as HTMLFormElement | null)?.reset();
      router.refresh();
    });
  }

  return (
    <form
      data-pyq-authoring
      onSubmit={(event) => {
        event.preventDefault();
        submit(new FormData(event.currentTarget));
      }}
      className="space-y-5"
    >
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface-raised)] p-4 sm:p-5">
        <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--accent)]">Step 1 · Paper setup</p>
        <h3 className="mt-1 text-lg font-semibold">Exam, subject and numbering</h3>
        <p className="mt-1 text-sm leading-5 text-[var(--muted)]">Choose the correct PCM subject and use a stable source ID. Paper slot numbers should stay consistent from 001 to 075.</p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <label className={labelClass}>
          Question title
          <input
            name="title"
            required
            maxLength={240}
            placeholder="JEE Main 2026 · Physics Q1"
            className={inputClass}
          />
        </label>
        <label className={labelClass}>
          Stable source ID
          <input
            name="sourceId"
            maxLength={160}
            placeholder="BJ-JM-2026-S1-PHY-001"
            className={inputClass}
          />
        </label>
        <label className={labelClass}>
          Exam
          <input name="exam" defaultValue="JEE Main" maxLength={80} className={inputClass} />
        </label>
        <label className={labelClass}>
          Subject
          <select
            value={subject}
            onChange={(event) => setSubject(event.target.value)}
            className={inputClass}
          >
            <option>Physics</option>
            <option>Chemistry</option>
            <option>Mathematics</option>
          </select>
        </label>
        <label className={labelClass}>
          Year
          <input
            name="year"
            type="number"
            min="2000"
            max="2100"
            placeholder="2026"
            className={inputClass}
          />
        </label>
        <label className={labelClass}>
          Session / shift
          <input
            name="session"
            maxLength={120}
            placeholder="4 April Shift 1"
            className={inputClass}
          />
        </label>
        <label className={labelClass}>
          Chapter
          <input
            name="chapter"
            maxLength={160}
            placeholder="Current Electricity"
            className={inputClass}
          />
        </label>
        <label className={labelClass}>
          Question type
          <select
            value={questionType}
            onChange={(event) => setQuestionType(event.target.value)}
            className={inputClass}
          >
            <option value="single_correct">Single correct</option>
            <option value="numerical">Numerical</option>
          </select>
        </label>
        <label className={labelClass}>
          Marks for correct
          <input
            name="marksCorrect"
            type="number"
            min="1"
            max="20"
            defaultValue="4"
            required
            className={inputClass}
          />
        </label>
        <label className={labelClass}>
          Marks for wrong
          <input
            name="marksWrong"
            type="number"
            min="-20"
            max="0"
            defaultValue="-1"
            required
            className={inputClass}
          />
        </label>
      </div>
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface-raised)] p-4 sm:p-5">
        <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--accent)]">Step 2 · Question</p>
        <h3 className="mt-1 text-lg font-semibold">Question wording and diagram</h3>
        <p className="mt-1 text-sm leading-5 text-[var(--muted)]">Use plain text for wording. Inline maths: <code>$...$</code> or <code>\(...\)</code>. Display equation: <code>$...$</code> or <code>\[...\]</code>.</p>
      </div>
      <label className={labelClass}>
        Question statement
        <textarea
          value={statement}
          onChange={(event) => setStatement(event.target.value)}
          required
          maxLength={100000}
          rows={5}
          placeholder="Enter the exact question wording. Use LaTeX delimiters for mathematics."
          className={inputClass}
        />
      </label>
      <div className="rounded-xl border border-dashed border-[var(--border)] bg-[var(--surface-raised)] p-3 sm:p-4">
        <p className="mb-2 text-xs font-bold uppercase tracking-wider text-[var(--muted)]">Formatted question preview</p>
        <MathPreview text={statement} />
      </div>
      <label className={labelClass}>
        Question diagram path (optional)
        <input
          name="statementImagePath"
          maxLength={500}
          placeholder="assets/questions/paper/q1.png"
          className={inputClass}
        />
      </label>
      <section className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4 sm:p-5">
        <div className="mb-4">
          <h3 className="text-base font-semibold">Answer options</h3>
          <p className="mt-1 text-sm leading-5 text-[var(--muted)]">Enter one option per line using Label|option text|optional image path. Example: A|12 N|. The preview below separates each choice for easy checking.</p>
        </div>
        <div className="space-y-3">
          {parseOptions(optionsText).map((option, index) => (
            <div key={index} className="rounded-xl border border-[var(--border)] bg-[var(--surface-raised)] p-3 sm:p-4">
              <div className="mb-3 flex items-center gap-3">
                <span className="grid size-9 shrink-0 place-items-center rounded-lg border border-[var(--border)] bg-[var(--surface)] font-bold">{option.label}</span>
                <p className="text-sm font-semibold">Option {option.label}</p>
              </div>
              <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
                <label className={labelClass}>Option label<input value={option.label} onChange={(event) => updateOptionLine(index, "label", event.target.value)} maxLength={4} className={inputClass} placeholder="A" /></label>
                <label className={labelClass}>Option image path <span className="font-normal text-[var(--muted)]">Optional</span><input value={option.imagePath ?? ""} onChange={(event) => updateOptionLine(index, "imagePath", event.target.value)} maxLength={500} className={inputClass} placeholder="assets/questions/q1-option-a.png" /></label>
              </div>
              <label className={labelClass + " mt-3"}>Option text<textarea value={option.text} onChange={(event) => updateOptionLine(index, "text", event.target.value)} rows={2} className={inputClass + " leading-6"} placeholder={"Enter the full text for option " + option.label} /></label>
            </div>
          ))}
          <div className="flex flex-wrap gap-2">
            <button type="button" onClick={() => { const current = parseOptions(optionsText); if (current.length < 8) setOptionsText(optionsText + (optionsText.endsWith("\n") ? "" : "\n") + String.fromCharCode(65 + current.length) + "||"); }} disabled={parseOptions(optionsText).length >= 8} className="rounded-xl border border-[var(--border)] px-4 py-2.5 text-sm font-semibold disabled:opacity-40">+ Add option</button>
            <button type="button" onClick={() => { const rows = optionsText.split("\n"); if (rows.length > 2) setOptionsText(rows.slice(0, -1).join("\n")); }} disabled={parseOptions(optionsText).length <= 2} className="rounded-xl border border-[var(--border)] px-4 py-2.5 text-sm font-semibold disabled:opacity-40">Remove last option</button>
          </div>
        </div>
        <div className="mt-4 grid gap-2 sm:grid-cols-2">
          {parseOptions(optionsText).map((option) => (
            <div key={option.label} className="flex min-h-14 gap-3 rounded-xl border border-[var(--border)] bg-[var(--surface-raised)] p-3">
              <span className="grid size-8 shrink-0 place-items-center rounded-lg border border-[var(--border)] font-bold">{option.label}</span>
              <span className="min-w-0 flex-1 self-center">{option.text ? <MathPreview text={option.text} /> : option.imagePath ? <span className="break-words text-sm text-[var(--muted)]">Image: {option.imagePath}</span> : <span className="text-sm text-[var(--muted)]">Option text is empty</span>}</span>
            </div>
          ))}
        </div>
      </section>
      <div className="grid gap-4 sm:grid-cols-2">
        <label className={labelClass}>
          Correct answer / numerical answer
          <input
            name="correctAnswer"
            required
            maxLength={100}
            placeholder="A or exact numeric value"
            className={inputClass}
          />
        </label>
        <label className={labelClass}>
          Source PDF / reference
          <input
            name="sourcePdf"
            maxLength={500}
            placeholder="Original paper filename or citation"
            className={inputClass}
          />
        </label>
        <label className={labelClass}>
          Source page
          <input
            name="sourcePage"
            type="number"
            min="1"
            max="10000"
            placeholder="Page number"
            className={inputClass}
          />
        </label>
        <label className={labelClass}>
          Tags (comma separated)
          <input
            name="tags"
            maxLength={2000}
            placeholder="jee-main, 2026, mechanics"
            className={inputClass}
          />
        </label>
      </div>
      <section className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4 sm:p-5">
        <div className="mb-4">
          <h3 className="text-base font-semibold">Worked solution</h3>
          <p className="mt-1 text-sm leading-5 text-[var(--muted)]">Write the formula, substitution, calculation and final result clearly. This is saved with the draft for review.</p>
        </div>
        <label className={labelClass}>
          Step-by-step solution
          <textarea
            name="solution"
            value={solution}
            onChange={(event) => setSolution(event.target.value)}
            maxLength={100000}
            rows={7}
            placeholder={"Step 1: Write the relevant formula…\nStep 2: Substitute the given values…\nStep 3: Calculate the final answer with units."}
            className={inputClass + " leading-6"}
          />
        </label>
        {solution.trim() ? <div className="mt-4 rounded-xl border border-[var(--border)] bg-[var(--surface-raised)] p-4"><p className="mb-2 text-xs font-bold uppercase tracking-wider text-[var(--muted)]">Solution preview</p><MathPreview text={solution} /></div> : null}
      </section>
      <label className={labelClass}>
        Additional asset paths (one per line)
        <textarea
          name="assetPaths"
          rows={2}
          className={inputClass}
          placeholder="assets/questions/paper/diagram.png"
        />
      </label>
      <label className={labelClass}>
        Review notes (one per line)
        <textarea
          name="reviewNotes"
          rows={2}
          className={inputClass}
          placeholder="Source checked; formula and answer independently verified."
        />
      </label>
      {notice ? (
        <p role="status" className="rounded-xl border border-[var(--accent)]/30 p-3 text-sm">
          {notice}
        </p>
      ) : null}
      {error ? (
        <p
          role="alert"
          className="rounded-xl border border-red-400/30 bg-red-400/10 p-3 text-sm text-red-200"
        >
          {error}
        </p>
      ) : null}
      <button
        type="submit"
        disabled={pending}
        className="sticky bottom-3 z-10 w-full rounded-xl bg-[var(--accent)] px-5 py-3.5 text-sm font-bold text-[var(--accent-foreground)] shadow-lg disabled:opacity-50 sm:static sm:w-auto"
      >
        {pending ? "Saving draft…" : "Save question as draft"}
      </button>
      <p className="text-xs leading-5 text-[var(--muted)]">
        Saving does not approve or publish the question. Server-side validation and the database
        enforce administrator access, safe asset paths, and answer-key consistency.
      </p>
    </form>
  );
}
