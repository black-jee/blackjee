import type {
  QuestionContent as QuestionContentData,
  QuestionOption,
} from "@/lib/questions/schema";

export type PyqRow = {
  id: string;
  source_id: string | null;
  title: string;
  exam: string;
  year: number | null;
  subject: "Physics" | "Chemistry" | "Mathematics";
  chapter: string | null;
  difficulty: "Main" | "Advanced" | "Mixed";
  statement: string;
  statement_image_path: string | null;
  options: unknown;
  tags: string[] | null;
  asset_paths: string[] | null;
};

export function toPyqOptions(raw: unknown): QuestionOption[] {
  if (!Array.isArray(raw)) return [];
  return raw.slice(0, 12).map((item, index) => {
    const fallback = String.fromCharCode(65 + index);
    if (typeof item === "string") return { id: String(index), label: fallback, text: item };
    const value = item && typeof item === "object" ? (item as Record<string, unknown>) : {};
    return {
      id: typeof value.id === "string" ? value.id : String(index),
      label:
        typeof value.label === "string"
          ? value.label
          : typeof value.letter === "string"
            ? value.letter
            : fallback,
      text:
        typeof value.text === "string"
          ? value.text
          : typeof value.value === "string"
            ? value.value
            : "",
      imagePath:
        typeof value.imagePath === "string"
          ? value.imagePath
          : typeof value.image_path === "string"
            ? value.image_path
            : undefined,
    };
  });
}

export function toPyqQuestion(row: PyqRow): QuestionContentData {
  return {
    sourceId: row.source_id || row.id,
    statement: row.statement,
    statementImagePath: row.statement_image_path ?? undefined,
    options: toPyqOptions(row.options),
    subject: row.subject,
    chapter: row.chapter ?? undefined,
    assetPaths: row.asset_paths ?? [],
  };
}
