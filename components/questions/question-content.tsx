import { isSafeAssetPath, type QuestionContent } from "@/lib/questions/schema";
import { renderQuestionText } from "@/lib/questions/render";

type Props = {
  question: QuestionContent;
  className?: string;
};

function SafeAsset({ path, alt }: { path?: string; alt: string }) {
  if (!path || !isSafeAssetPath(path)) {
    return (
      <span className="my-2 block rounded-lg border border-dashed border-[var(--border)] px-3 py-2 text-xs text-[var(--muted)]">
        Image unavailable
      </span>
    );
  }

  return (
    // Asset paths are relative and validated; use a native image to preserve exact diagram pixels.
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={`/${path}`}
      alt={alt}
      loading="lazy"
      decoding="async"
      className="my-3 h-auto max-h-[28rem] max-w-full rounded-lg border border-[var(--border)] object-contain"
    />
  );
}

export function QuestionContent({ question, className }: Props) {
  return (
    <article className={className}>
      <div
        className="question-statement text-base leading-8"
        dangerouslySetInnerHTML={{ __html: renderQuestionText(question.statement) }}
      />
      {question.statementImagePath ? (
        <SafeAsset path={question.statementImagePath} alt="Question diagram" />
      ) : null}

      {question.options.length > 0 ? (
        <ol className="mt-5 grid gap-3" aria-label="Answer options">
          {question.options.map((option) => (
            <li
              key={option.id}
              className="flex min-w-0 items-start gap-3 rounded-xl border border-[var(--border)] bg-[var(--surface)] p-3 sm:p-4"
            >
              <span className="grid size-7 shrink-0 place-items-center rounded-full border border-[var(--border)] text-xs font-semibold">
                {option.label}
              </span>
              <div className="min-w-0 flex-1">
                {option.text ? (
                  <div dangerouslySetInnerHTML={{ __html: renderQuestionText(option.text) }} />
                ) : null}
                {option.imagePath ? <SafeAsset path={option.imagePath} alt={`Option ${option.label} image`} /> : null}
              </div>
            </li>
          ))}
        </ol>
      ) : null}
    </article>
  );
}
