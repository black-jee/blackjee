"use client";

import { useMemo, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { bulkSavePyqQuestions } from "@/app/admin/pyq/actions";

type ExtractedQuestion = {
  questionNumber: number;
  sourcePage?: number;
  title: string;
  sourceId: string;
  exam: string;
  year: number;
  session: string;
  subject: "Physics" | "Chemistry" | "Mathematics";
  chapter?: string;
  statement: string;
  options: { id?: string; label: string; text: string; visualPlaceholder?: string }[];
  visualTypes?: string[];
  visualSlots?: { question?: { placeholder?: string }; matchTable?: { required?: boolean }; reaction?: { required?: boolean }; circular?: { required?: boolean } };
  correctAnswer: string;
  solution?: string;
  sourcePdf?: string;
  tags?: string[];
  reviewNotes?: string[];
};

type Bundle = { format?: string; questions?: ExtractedQuestion[] };

const inputClass =
  "block w-full rounded-xl border border-[var(--border)] bg-black/20 px-3 py-2.5 text-sm";

export function PyqBulkImport() {
  const router = useRouter();
  const [bundle, setBundle] = useState<Bundle | null>(null);
  const [fileName, setFileName] = useState("");
  const [pdfName, setPdfName] = useState("");
  const [extracting, setExtracting] = useState(false);
  const [pdfError, setPdfError] = useState<string | null>(null);
  const [year, setYear] = useState(String(new Date().getFullYear()));
  const [subject, setSubject] = useState<ExtractedQuestion["subject"]>("Physics");
  const [session, setSession] = useState("");
  const [answerKeyText, setAnswerKeyText] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [report, setReport] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const questions = useMemo(
    () => (Array.isArray(bundle?.questions) ? bundle.questions : []),
    [bundle],
  );
  const ready = questions.filter(
    (q) =>
      typeof q.statement === "string" &&
      q.statement.trim().length > 0 &&
      typeof q.correctAnswer === "string" &&
      q.correctAnswer.trim().length > 0 &&
      typeof q.sourceId === "string" &&
      q.sourceId.trim().length > 0,
  );

  async function readPdf(file?: File) {
    setPdfError(null);
    setError(null);
    setReport(null);
    if (!file) return;
    if (file.type !== "application/pdf" && !file.name.toLowerCase().endsWith(".pdf")) {
      setPdfError("Choose a PDF file.");
      return;
    }
    if (file.size > 40 * 1024 * 1024) {
      setPdfError("PDF must be 40 MB or smaller.");
      return;
    }
    setExtracting(true);
    try {
      const pdfWindow = window as Window & { pdfjsLib?: any };
      if (!pdfWindow.pdfjsLib) {
        await new Promise<void>((resolve, reject) => {
          const script = document.createElement("script");
          script.src = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js";
          script.onload = () => resolve();
          script.onerror = () => reject(new Error("Could not load the PDF reader. Check your connection and try again."));
          document.head.appendChild(script);
        });
      }
      const pdfjs = pdfWindow.pdfjsLib;
      if (!pdfjs) throw new Error("PDF reader did not initialize.");
      pdfjs.GlobalWorkerOptions.workerSrc = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js";
      const pdf = await pdfjs.getDocument({ data: await file.arrayBuffer() }).promise;
      const pages: { page: number; text: string }[] = [];
      for (let pageNo = 1; pageNo <= pdf.numPages; pageNo += 1) {
        const page = await pdf.getPage(pageNo);
        const content = await page.getTextContent();
        const rows = new Map<number, string[]>();
        for (const item of content.items as any[]) {
          if (typeof item.str !== "string" || !item.str.trim()) continue;
          const y = Math.round(item.transform?.[5] ?? 0);
          rows.set(y, [...(rows.get(y) ?? []), item.str.trim()]);
        }
        pages.push({
          page: pageNo,
          text: [...rows.entries()].sort((a, b) => b[0] - a[0]).map(([, values]) => values.join(" ")).join("\n"),
        });
      }
      const lines = pages.flatMap((page) => page.text.split("\n").map((text) => ({ page: page.page, text: text.trim() })).filter((row) => row.text));
      const startPattern = /^(?:question\s*)?(\d{1,3})[.)\]:-]\s+(.+)$/i;
      const optionPattern = /^(?:\(([A-D1-4])\)|([A-D])[.)]|option\s*([A-D1-4])\s*[:.)-])\s*(.*)$/i;
      const parsed: { questionNumber: number; sourcePage: number; statement: string; options: { label: string; text: string }[] }[] = [];
      let current: (typeof parsed)[number] | null = null;
      for (const line of lines) {
        const qMatch = line.text.match(startPattern);
        if (qMatch) {
          if (current) parsed.push(current);
          current = { questionNumber: Number(qMatch[1]), sourcePage: line.page, statement: qMatch[2], options: [] };
          continue;
        }
        if (!current) continue;
        const optionMatch = line.text.match(optionPattern);
        if (optionMatch) {
          const marker = optionMatch[1] || optionMatch[2] || optionMatch[3] || "";
          const label = ({ "1": "A", "2": "B", "3": "C", "4": "D" } as Record<string, string>)[marker.toUpperCase()] || marker.toUpperCase();
          current.options.push({ label, text: optionMatch[4] || "" });
        } else if (current.options.length) {
          const last = current.options[current.options.length - 1];
          last.text = (last.text + " " + line.text).trim();
        } else {
          current.statement = (current.statement + "\n" + line.text).trim();
        }
      }
      if (current) parsed.push(current);
      if (!parsed.length) throw new Error("No numbered questions detected. This may be a scanned PDF; OCR is not included in browser extraction.");
      const answers: Record<string, string> = {};
      for (const pair of answerKeyText.split(/[\n,;]+/)) {
        const match = pair.trim().match(/^(\d{1,3})\s*[:= -]\s*([A-D1-4]|\d+(?:\.\d+)?)$/i);
        if (match) answers[match[1]] = ({ "1": "A", "2": "B", "3": "C", "4": "D" } as Record<string, string>)[match[2]] || match[2].toUpperCase();
      }
      const candidates: ExtractedQuestion[] = parsed.slice(0, 100).map((q) => ({
        questionNumber: q.questionNumber,
        sourcePage: q.sourcePage,
        title: "JEE Main " + year + " " + subject + " Q" + q.questionNumber,
        sourceId: "jee-main-" + year + "-" + (session.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-") || "unspecified") + "-" + subject.toLowerCase() + "-q" + q.questionNumber,
        exam: "JEE Main",
        year: Number(year),
        session,
        subject,
        statement: q.statement,
        options: q.options,
        correctAnswer: answers[String(q.questionNumber)] || "",
        solution: "",
        sourcePdf: file.name,
        tags: ["browser-pdf-extraction", "needs-manual-review"],
        reviewNotes: ["Browser PDF text extraction is heuristic; compare every question with the original PDF.", "Check scientific notation, equations, options, and visual elements manually."],
      }));
      setBundle({ format: "blackjee-pyq-drafts-v1", questions: candidates });
      setFileName(file.name.replace(/\.pdf$/i, ".json"));
      setPdfName(file.name);
    } catch (cause) {
      setPdfError(cause instanceof Error ? cause.message : "Could not extract text from this PDF.");
    } finally {
      setExtracting(false);
    }
  }

  function downloadBundle() {
    if (!bundle) return;
    const blob = new Blob([JSON.stringify(bundle, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = fileName || "pyq-drafts.json";
    anchor.click();
    URL.revokeObjectURL(url);
  }

  async function readFile(file?: File) {
    setError(null);
    setReport(null);
    setBundle(null);
    if (!file) return;
    try {
      const parsed = JSON.parse(await file.text()) as Bundle;
      if (!Array.isArray(parsed.questions) || parsed.questions.length === 0) {
        throw new Error("This JSON does not contain a non-empty questions array.");
      }
      if (parsed.questions.length > 100) {
        throw new Error("Import at most 100 questions per batch.");
      }
      setBundle(parsed);
      setFileName(file.name);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Could not read the JSON file.");
    }
  }

  function importDrafts() {
    if (!ready.length) {
      setError("No valid questions with an answer key are ready to import.");
      return;
    }
    setError(null);
    setReport(null);
    startTransition(async () => {
      const payload = ready.map((q) => {
        const options = Array.isArray(q.options)
          ? q.options.map((option, index) => {
              const label = String(option.label || String.fromCharCode(65 + index)).trim();
              return {
                id: String(option.id || label.toLowerCase()),
                label,
                text: String(option.text || ""),
                visualPlaceholder: option.visualPlaceholder || "[OPTION VISUAL SLOT — add/crop image here if required]",
              };
            })
          : [];
        const isMultipleChoice = options.length >= 2;
        return {
          questionId: null,
          sourceId: q.sourceId,
          title: q.title,
          exam: q.exam || "JEE Main",
          year: Number(q.year),
          session: q.session || "",
          subject: q.subject,
          chapter: q.chapter || "",
          statement: q.statement,
          statementImagePath: "",
          options,
          questionType: isMultipleChoice ? "single_correct" : "numerical",
          marksCorrect: 4,
          marksWrong: -1,
          correctAnswer: q.correctAnswer.trim(),
          solution: "",
          sourcePdf: q.sourcePdf || fileName,
          sourcePage: Number.isInteger(q.sourcePage) ? q.sourcePage : null,
          tags: [...new Set([...(q.tags || []), "bulk-pdf-extraction", "needs-diagram-review"])],
          assetPaths: [],
          reviewNotes: [
            ...(q.reviewNotes || []),
            "Bulk-imported draft: verify question text, option mapping and answer key.",
            "Visual types detected (heuristic): " + ((q.visualTypes || []).join(", ") || "none detected") + ".",
            "Question visual placeholder: " + (q.visualSlots?.question?.placeholder || "[QUESTION VISUAL SLOT — check source PDF]"),
            ...(q.visualSlots?.matchTable?.required ? ["Match-the-following table placeholder required."] : []),
            ...(q.visualSlots?.reaction?.required ? ["Chemical reaction / structure placeholder required."] : []),
            ...(q.visualSlots?.circular?.required ? ["Circular / loop diagram placeholder required."] : []),
            "Diagram, graph, reaction, table, and option visuals must be checked manually.",
            "Detailed solution intentionally pending.",
          ],
        };
      });
      const result = await bulkSavePyqQuestions(payload);
      setReport(
        `Saved ${result.saved.length} drafts. ${result.failed.length} failed.` +
          (result.failed.length
            ? " Failed rows (1-based within the ready set): " +
              result.failed.map((item) => `${item.index + 1}: ${item.error}`).join(" · ")
            : ""),
      );
      router.refresh();
    });
  }

  return (
    <section className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-7">
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--accent)]">
        Bulk import
      </p>
      <h2 className="mt-2 text-2xl font-semibold tracking-tight">Import extracted PDF questions</h2>
      <p className="mt-2 max-w-3xl text-sm leading-6 text-[var(--muted)]">
        Upload a text-based PDF to extract numbered question candidates in your browser. Extraction is heuristic; review every item against the original. Scanned PDFs need OCR, and diagrams or detailed solutions must be checked separately.
      </p>
      <div className="mt-5 grid gap-3 rounded-2xl border border-[var(--border)] p-4 sm:grid-cols-2">
        <label className="space-y-2 text-sm font-medium">PDF file (max 40 MB)
          <input type="file" accept=".pdf,application/pdf" className={inputClass} disabled={extracting} onChange={(event) => void readPdf(event.currentTarget.files?.[0])} />
        </label>
        <label className="space-y-2 text-sm font-medium">Year
          <input type="number" min="2000" max="2100" value={year} onChange={(event) => setYear(event.currentTarget.value)} className={inputClass} />
        </label>
        <label className="space-y-2 text-sm font-medium">Subject
          <select value={subject} onChange={(event) => setSubject(event.currentTarget.value as ExtractedQuestion["subject"])} className={inputClass}>
            <option>Physics</option><option>Chemistry</option><option>Mathematics</option>
          </select>
        </label>
        <label className="space-y-2 text-sm font-medium">Session / shift
          <input value={session} onChange={(event) => setSession(event.currentTarget.value)} placeholder="e.g. 4 April Shift 1" className={inputClass} />
        </label>
        <label className="space-y-2 text-sm font-medium sm:col-span-2">Optional answer key (e.g. 1:A, 2:C, 3:12)
          <textarea value={answerKeyText} onChange={(event) => setAnswerKeyText(event.currentTarget.value)} placeholder="Paste answer key to match question numbers" rows={3} className={inputClass} />
        </label>
        {extracting ? <p role="status" className="text-sm text-[var(--muted)] sm:col-span-2">Reading PDF pages and extracting text…</p> : null}
        {pdfError ? <p role="alert" className="text-sm text-red-300 sm:col-span-2">{pdfError}</p> : null}
        {pdfName ? <p className="text-xs text-[var(--muted)] sm:col-span-2">Selected PDF: {pdfName}. To apply a changed answer key, reselect the PDF.</p> : null}
      </div>
      <ol className="mt-4 grid gap-3 text-sm sm:grid-cols-3">
        <li className="rounded-xl border border-[var(--border)] p-3">
          <span className="block text-xs font-bold uppercase tracking-wide text-[var(--accent)]">01 · Extract</span>
          <span className="mt-1 block">Run the local Python extractor on your PDF.</span>
        </li>
        <li className="rounded-xl border border-[var(--border)] p-3">
          <span className="block text-xs font-bold uppercase tracking-wide text-[var(--accent)]">02 · Check</span>
          <span className="mt-1 block">Review question count, subject, shift and answer-key matches.</span>
        </li>
        <li className="rounded-xl border border-[var(--border)] p-3">
          <span className="block text-xs font-bold uppercase tracking-wide text-[var(--accent)]">03 · Import</span>
          <span className="mt-1 block">Save up to 100 questions per batch as unpublished drafts.</span>
        </li>
      </ol>
      <label className="mt-5 block space-y-2 text-sm font-medium">
        Or import an existing JSON bundle
        <input
          type="file"
          accept=".json,application/json"
          className={inputClass}
          onChange={(event) => void readFile(event.currentTarget.files?.[0])}
        />
      </label>
      {fileName ? <p className="mt-2 text-xs text-[var(--muted)]">Selected: {fileName}</p> : null}
      {bundle ? (
        <div className="mt-4 rounded-2xl border border-[var(--border)] p-4 text-sm">
          <p className="font-semibold">{questions.length} question candidates found</p>
          <p className="mt-1 text-[var(--muted)]">
            {ready.length} ready to save · {questions.length - ready.length} missing statement, source ID
            or answer key (will be skipped)
          </p>
          <p className="mt-2 text-xs leading-5 text-[var(--muted)]">
            Each saved record will remain a draft. Check the extracted statement, options, source page,
            and answer key in the review list before publishing.
          </p>
        </div>
      ) : null}
      {bundle ? <button type="button" onClick={downloadBundle} className="mt-3 rounded-xl border border-[var(--border)] px-4 py-2.5 text-sm font-semibold">Download extracted JSON</button> : null}
      {error ? <p role="alert" className="mt-3 text-sm text-red-300">{error}</p> : null}
      {report ? (
        <p role="status" className="mt-3 rounded-xl border border-[var(--border)] p-4 text-sm leading-6">
          {report}
        </p>
      ) : null}
      <button
        type="button"
        disabled={pending || ready.length === 0}
        onClick={importDrafts}
        className="mt-4 rounded-xl bg-[var(--accent)] px-4 py-2.5 text-sm font-bold text-[var(--accent-foreground)] disabled:cursor-not-allowed disabled:opacity-50"
      >
        {pending ? "Saving drafts…" : `Save ${ready.length} drafts`}
      </button>
    </section>
  );
}
