"use client";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { reviewPyqQuestion } from "@/app/admin/pyq/actions";

export function PyqReviewActions({
  id,
  isPublished,
  reviewStatus,
}: {
  id: string;
  isPublished: boolean;
  reviewStatus: string;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  function review(approve: boolean, publish: boolean) {
    const message = publish
      ? "Publish this question for students after checking its source, answer and images?"
      : approve
        ? "Approve this question as an unpublished draft?"
        : "Return this question to draft status?";
    if (!window.confirm(message)) return;
    setError(null);
    startTransition(async () => {
      const result = await reviewPyqQuestion({ questionId: id, approve, publish, reviewNotes: [] });
      if (!result.ok) {
        setError(result.error);
        return;
      }
      router.refresh();
    });
  }
  return (
    <div className="flex flex-wrap items-center gap-2">
      {!isPublished ? (
        <>
          <button
            type="button"
            disabled={pending}
            onClick={() => review(true, false)}
            className="rounded-lg border border-[var(--border)] px-3 py-2 text-xs font-semibold disabled:opacity-50"
          >
            Approve draft
          </button>
          <button
            type="button"
            disabled={pending || reviewStatus !== "approved"}
            onClick={() => review(true, true)}
            className="rounded-lg bg-[var(--accent)] px-3 py-2 text-xs font-bold text-[var(--accent-foreground)] disabled:opacity-40"
          >
            Publish
          </button>
        </>
      ) : (
        <button
          type="button"
          disabled={pending}
          onClick={() => review(false, false)}
          className="rounded-lg border border-[var(--border)] px-3 py-2 text-xs font-semibold disabled:opacity-50"
        >
          Unpublish
        </button>
      )}
      {error ? (
        <p role="alert" className="w-full text-xs text-red-300">
          {error}
        </p>
      ) : null}
    </div>
  );
}
